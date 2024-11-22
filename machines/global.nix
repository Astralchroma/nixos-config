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

	documentation = {
		man.enable = false;
		nixos.enable = false; 
	};

	console.keyMap = "uk";
	environment.defaultPackages = [];
	i18n.defaultLocale = "en_GB.UTF-8";
	time.timeZone = "Europe/London";

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL"
		];
	};
}
