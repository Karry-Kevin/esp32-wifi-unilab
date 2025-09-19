下面给你设计一套“双机互学”的 Wi-Fi 全景实验 ——  
**项目代号：ESP32-WiFi-UniLab**  
由两个 ESP32（A 端 + B 端）配合完成，覆盖 95% 日常开发中会碰到的 Wi-Fi 知识点。  
做完以后，你能独立写出：

* 稳定连接的 STA / AP / APSTA

* 安全加密、空中升级、Mesh、Sniffer、节能、故障自愈……

* 还能把整套流程自动化测试、图形化看日志、远程升级。

* * *

一、总览
----

1. 硬件：2 × ESP32 开发板（≥4 MB Flash），1 台电脑（Linux/Win/WSL 均可），1 个 2.4 GHz 路由器（可关闭 5 GHz）。

2. 软件：ESP-IDF v5.x（master 也可），vscode/esp-idf-extension，Python≥3.8，Wireshark。

3. 仓库结构（单 repo，两套 firmware）

复制
    esp32-wifi-unilab/
     ├─ components/         # 自己写的通用组件
     ├─ firmware/
     │   ├─ unilab_node_a/  # 客户端／STA／Sensor 端
     │   └─ unilab_node_b/  # 服务器／AP／Cloud 端
     ├─ tools/
     │   ├─ pytest/         # 自动化测试脚本
     │   ├─ ota_server/     # 简易 Python OTA 服务器
     │   └─ sniffer_bridge/ # 把 ESP32 变 Packet-Injector
     └─ docs/               # 每一步的知识要点与 Debug 清单

* * *

二、Node A（客户端 / 传感器端）需求清单
------------------------

表格

复制

| 模块                     | 必须掌握的知识点                       | 具体功能要求                                                                                                 |
| ---------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| 1. STA 基础              | NVS 存储 Wi-Fi 凭据、重连策略、事件循环      | ① 开机自动连接预存路由器；② 断网 30 s 后重连；③ 连接成功后闪蓝灯 3 次。                                                            |
| 2. SmartConfig / BluFi | 空中配网、广播/组播/蓝牙配网差异              | ① 长按 KEY 进入 SmartConfig（ESP-Touch），手机小程序配网；② 支持 BluFi 备选；③ 配网失败回退 AP 模式（见 3）。                          |
| 3. SoftAP fallback     | DHCP server、DNS captive portal | ① 如果 60 s 未连上路由器，启动 SoftAP（SSID=UNILAB_A_xxxx）；② 弹出 Captive Portal，网页表单输入路由器 SSID/PWD；③ 成功后自动重启。       |
| 4. 深度睡眠 + GPIO 唤醒      | 功耗测量、RTC memory 保活             | ① 每 30 s 采集一次温湿度（SHT30），醒来 300 ms 内发数据；② 通过 RTC memory 记录已发序号，防止丢包；③ 平均电流 < 100 µA。                    |
| 5. OTA 升级              | HTTPS OTA、证书校验、回滚机制            | ① 定时（或服务器推送）检查版本；② 下载签名固件（tools/ota_server 提供 ECDSA 签名）；③ 升级失败自动回滚；④ 通过 MQTT 上报升级进度。                   |
| 6. TLS / MQTT          | 证书链、双向认证、QoS、遗嘱消息              | ① 连接 Mosquitto（Node B），端口 8883，TLS1.3；② 使用 mbedTLS 硬件加速；③ 发布主题 `unilab/a/sensors`，订阅 `unilab/a/cmd/#`。 |
| 7. Sniffer 模式          | 混杂模式、IEEE802.11 帧格式、RSSI 指纹    | ① 可远程指令进入 sniffer 模式；② 抓取 1 min 附近 Beacon/ProbeReq；③ 通过 UDP 把 PCAP 发给 Wireshark 实时解码。                  |
| 8. 日志远程上传              | syslog、UDP 广播、QoS 队列           | ① 所有 LOGI/LOGE 通过 UDP 发送到 Node B 的 514 端口；② Node B 用 Python 脚本落盘，网页实时 tail。                            |

* * *

三、Node B（服务器 / 云网关端）需求清单
------------------------

表格

复制

| 模块                      | 必须掌握的知识点                     | 具体功能要求                                                                                                                       |
| ----------------------- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 1. SoftAP + DHCP + NAT  | 自定义网段、DNS 劫持、IP 转发           | ① 启动 AP（SSID=UNILAB_B, 密码 12345678），网段 192.168.4.0/24；② 把 STA 接口当 WAN，AP 当 LAN，实现 NAT 转发；③ 统计每个 STA 的流量。                     |
| 2. Mesh 根节点             | ESP-WIFI-MESH、自组网、自愈         | ① 允许最多 10 个 Node A 以 Mesh 叶子身份加入；② 如果父节点丢失，5 s 内重新选举；③ 通过 `mesh_examples/internal_comm` 实现零配置组网。                             |
| 3. MQTT Broker          | Mosquitto、ACL、WebSocket      | ① 本地启动 Mosquitto，监听 8883 & 9001（WebSocket）；② 配置 ACL：Node A 只能发布 `unilab/a/#`，Node B 可订阅 `#`；③ 提供网页端 MQTT-Explorer。           |
| 4. RESTful API          | HTTP 服务器、JSON、CORS           | ① 基于 ESP-IDF `http_server` 组件，提供 `/api/wifi_scan`, `/api/ota`, `/api/mesh_info`；② 支持 POST 触发远程 OTA；③ 返回纯 JSON，方便 Postman 测试。 |
| 5. WebSocket 实时日志       | 全双工、心跳、二进制帧                  | ① 路径 `/ws/log`，浏览器打开 `tools/web_console/index.html` 即可实时看到所有 Node A 的日志；② 支持 100 kHz 级刷新的 RSSI 曲线图。                          |
| 6. 空中抓包 + PCAP-over-UDP | 远程 Wi-Fi 诊断                  | ① 接收 Node A 发来的 802.11 帧，本地保存为 `sniff_xxx.pcap`；② 提供 `/api/download_pcap` 一键下载到电脑 Wireshark 分析。                              |
| 7. 自动化测试框架              | pytest、GitHub Actions、串口/SSH | ① `tools/pytest/test_unilab.py` 自动烧录、配网、OTA、断网重连、功耗采样；② 输出 Allure 报告；③ CI 每夜跑回归。                                             |

* * *

四、进阶挑战（Bonus）
-------------

1. **Wi-Fi 6 共存**  
   把路由器设成 802.11ax 模式，观察 ESP32 传统 802.11b/g/n 与 Wi-Fi 6 终端的共存性能，用 Node B 统计重传率。

2. **LR 模式远距离**  
   启用 ESP32-Sx 的 802.11 LR (Long Range) 模式，拉距到 1 km+，记录 RSSI vs 丢包率曲线。

3. **802.11k/v/r 漫游**  
   用两台路由器+同一个 ESS，让 Node A 作为 STA 实现无缝漫游，Node B 当控制器，通过 Beacon 请求/邻居列表实现毫秒级切换。

4. **PSK-SAE 过渡**  
   路由器同时开启 WPA2-PSK 和 WPA3-SAE，Node A 优先 SAE 失败回退 PSK，抓包观察 SAE 握手（Commit/Confirm）。

* * *

五、学习路线 & 文档输出
-------------

1. 每实现一个模块，就在 `docs/` 写一篇 “XX 模块完全指南”，包含：
   
   * 官方 API 调用序列图（PlantUML）
   
   * 常见错误码对照表（esp_err_t → 人类语言）
   
   * Wireshark 过滤表达式举例

2. 最后汇总成 PDF《ESP32 Wi-Fi 开发全景手册》，开源到 repo，成为简历亮点。

* * *

六、时间估算
------

* 全职 1 人：3 ~ 4 周可完整跑通主线功能。

* 兼职周末：2 个月左右，含 Bonus。

* 2 人小分队：A 负责 Node A+测试脚本，B 负责 Node B+前端，4 周交付。

* * *

七、下一步
-----

1. 拉 repo，先跑通 `hello_wifi` 例程，熟悉 idf.py menuconfig。

2. 把上面需求拆成 14 个 Milestone，用 GitHub Projects 管理。

3. 遇到任何具体卡点（比如 mbedTLS 证书链怎么烧、Mesh 如何打印父子拓扑），随时来问，我帮你逐层拆坑。

祝你在“双机互学”中把 ESP32 Wi-Fi 吃干榨净！
