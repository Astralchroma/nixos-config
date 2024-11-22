{ ... }: {
	nix.settings.experimental-features = [ "flakes" ];

	boot = {
		loader.systemd-boot = {
			enable = true;
			editor = false;
		};

		loader.efi.canTouchEfiVariables = true;

		initrd.systemd.enable = true;
	};

	services.openssh = {
		enable = true;
		settings = {
			KbdInteractiveAuthentication = false;
			PasswordAuthentication = false;
			PermitRootLogin = "no";
		};
	};

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL"
		];
	};
}
