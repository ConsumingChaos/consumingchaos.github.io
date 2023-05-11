let
  users = {
    "jleitch" = {
      userName = "James Leitch";
      email = "jleitch@consumingchaos.com";
      githubUser = "rickvanprim";
    };
  };
in
{
  userName = user: (builtins.getAttr user users).userName;
  email = user: (builtins.getAttr user users).email;
  githubUser = user: (builtins.getAttr user users).githubUser;
}
