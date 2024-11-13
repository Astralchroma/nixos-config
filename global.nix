{ inputs, lib, pkgs, ... }: {
	nixpkgs.config.allowUnfree = true;

	nix.settings = {
		auto-optimise-store = true;
		experimental-features = [ "nix-command" "flakes" ];
		trusted-users = [ "@wheel" ];
	};

	nix.gc = {
		automatic = true;
		dates = "09:15";
		options = "--delete-older-than 14d";
	};
	
	system.autoUpgrade = {
		enable = true;
		flake = inputs.self.outPath;
		flags = [ "--upgrade-all" "--recreate-lock-file" "--verbose" "-L" ];
		dates = "08:15";
	};

	boot = {
		loader.systemd-boot.enable = true;
		initrd.systemd.enable = true;
	};

	services = {
		speechd.enable = lib.mkForce false; # Not blind, so don't need it lol

		openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "no";
				PasswordAuthentication = false;
				KbdInteractiveAuthentication = false;
			};
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
