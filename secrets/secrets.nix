let
  emily = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL";
  users = [ emily ];

  horizon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJiuSH1QYRaxoZGfrFJy1SWcP0miL09+m6fKnuPoRg7";
  systems = [ horizon ];
in {
  "rclone.conf.age".publicKeys = [ emily horizon ];
}
