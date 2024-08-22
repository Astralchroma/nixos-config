{ inputs, pkgs, ... }: {
	nixpkgs.config.allowUnfree = true;

	nix.settings = {
		auto-optimise-store = true;
		experimental-features = [ "nix-command" "flakes" ];
		trusted-users = [ "@wheel" ];
	};

	nix.gc = {
		automatic = true;
		dates = "00:00";
		options = "--delete-older-than 30d";
	};
	
	system.autoUpgrade = {
		enable = true;
		flake = inputs.self.outPath;
		flags = [ "--upgrade-all" "--recreate-lock-file" "--verbose" "-L" ];
		dates = "00:00";
	};

	boot = {
		loader.grub = {
			device = "nodev";
			efiSupport = true;
			efiInstallAsRemovable = true;
		};

		initrd.systemd.enable = true;
	};

	services.openssh = {
		enable = true;
		settings = {
			PermitRootLogin = "no";
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
		};
	};

	console.keyMap = "uk";
	documentation.nixos.enable = false; 
	i18n.defaultLocale = "en_GB.UTF-8";
	networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
	time.timeZone = "Europe/London";

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		packages = with pkgs; [
			btop devenv direnv fastfetch fd git ncdu rclone rsync smartmontools unzip vmtouch wget zip
		];
	};
}
