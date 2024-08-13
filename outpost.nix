{ inputs, modulesPath, pkgs, ... }: let
	values = builtins.fromJSON (builtins.readFile ./values.json);
in {
	nixpkgs.config.allowUnfree = true;

	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	nix = {
		settings = {
			auto-optimise-store = true;
			experimental-features = [ "nix-command" "flakes" ];
			trusted-users = [ "@wheel" ];
		};

		gc = {
			automatic = true;
			dates = "00:00";
			options = "--delete-older-than 30d";
		};
	};

	boot = {
		initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

		loader.grub = {
			device = "nodev";
			efiSupport = true;
			efiInstallAsRemovable = true;
		};
	};

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/0a2e0044-98e6-43c7-9900-d1885b1bd4d0";
			fsType = "btrfs";
			options = [ "compress=lzo" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/E625-43E4";
			fsType = "vfat";
		};
	};

	system = {
		stateVersion = "24.11";

		autoUpgrade = {
			enable = true;
			flake = inputs.self.outPath;
			flags = [ "--upgrade-all" "--recreate-lock-file" "--verbose" "-L" ];
			dates = "00:00";
		};
	};

	networking = {
		hostName = "outpost";
		nameservers = [ "1.1.1.1" "8.8.8.8" ];
		useDHCP = true;
	};

	services.openssh = {
		enable = true;
		settings = {
			PermitRootLogin = "no";
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
		};
	};

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		packages = with pkgs; [
			btop devenv direnv fastfetch fd git mongosh ncdu rclone rsync smartmontools unzip vmtouch wget zip
		];
	};

	virtualisation = {
		containers.enable = true;

		podman = {
			enable = true;
			dockerCompat = true;
			defaultNetwork.settings.dns_enabled = true;
		};

		oci-containers.containers = {
			caddy = {
				image = "caddy:alpine";
				ports = [
					"0.0.0.0:80:80"
					"0.0.0.0:443:443"
				];
				volumes = [
					"/srv/caddy/Caddyfile:/etc/caddy/Caddyfile"
					"/srv/caddy/config/:/config/caddy/"
					"/srv/caddy/data/:/data/caddy/"
					"/srv/http/:/srv/"
				];
			};

			mongo = {
				image = "mongo";
				ports = [ "127.0.0.1:27017:27017" ];
				environment = {
					MONGO_INITDB_ROOT_USERNAME = "root";
					MONGO_INITDB_ROOT_PASSWORD = values.mongo_password;
				};
				volumes = [ "/srv/mongodb:/data/db" ];
			};

			aggregator = {
				image = "eclipse-temurin:17-jre";
				environment = {
					DISCORD_TOKEN = values.discord_token;
					MONGO_URI = values.mongo_uri;
					MONGO_DATABASE = "aggregator";
					OWNER_SNOWFLAKE = "521031433972744193";
				};
				volumes = [ "/srv/aggregator:/srv" ];
				cmd = [ "java" "-jar" "/srv/build/libs/Aggregator-1.4.1-all.jar" ];
			};
		};
	};

	time.timeZone = "Europe/London";
	i18n.defaultLocale = "en_GB.UTF-8";
	console.keyMap = "uk";
	documentation.nixos.enable = false;
}
