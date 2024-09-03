let
	emily = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL";
	users = [ emily ];

	horizon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJiuSH1QYRaxoZGfrFJy1SWcP0miL09+m6fKnuPoRg7";
	outpost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTkdeQiCd4y+ZsIVyoMlMnnFUTqOX6qdWw/QLmsc4ck";
	systems = [ horizon ];
in {
	"aggregator_discord_token.age".publicKeys = [ emily outpost ];
	"autochroma-database_uri.age".publicKeys = [ emily outpost ];
	"autochroma-discord_token.age".publicKeys = [ emily outpost ];
	"rclone.conf.age".publicKeys = [ emily horizon ];
}
