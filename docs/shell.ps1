gh api graphql -f query='
query($login:String!) {
  user(login:$login) {
    projectsV2(first:20) {
      nodes { id title number }
    }
  }
}' -F login=Karry-Kevin