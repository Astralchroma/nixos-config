{ config, inputs, modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "24.11";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/0a2e0044-98e6-43c7-9900-d1885b1bd4d0";
			fsType = "btrfs";
			options = [ "compress=lzo" ];
		};

		"/srv" = {
			device = "/dev/disk/by-uuid/0a2e0044-98e6-43c7-9900-d1885b1bd4d0";
			fsType = "btrfs";
			options = [ "subvol=/Server" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/E625-43E4";
			fsType = "vfat";
		};
	};

	networking = {
		hostName = "outpost";
		useDHCP = true;
		firewall.allowedTCPPorts = [ 80 443 ];
	};

	containers.mongo = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/mongo";
				isReadOnly = false;
			};
		};

		config = {
			nixpkgs.config.allowUnfree = true;
			system.stateVersion = "24.11";

			services.mongodb = {
				enable = true;
				dbpath = "/srv";
			};
		};
	};

	age.secrets.aggregator_discord_token = {
		file = ./secrets/aggregator_discord_token.age;
	};

	containers.aggregator = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/aggregator";
				isReadOnly = false;
			};
			"${config.age.secrets.aggregator_discord_token.path}" = {
				isReadOnly = true;
			};
		};

		config = {
			system.stateVersion = "24.11";

			environment.systemPackages = [ pkgs.jdk17 ];

			systemd.services.aggregator = {
				enable = true;
				description = "Aggregator";
				unitConfig.Type = "simple";
				script = ''DISCORD_TOKEN=$(cat "${config.age.secrets.aggregator_discord_token.path}") ${pkgs.jdk17}/bin/java -jar /srv/build/libs/Aggregator-1.4.1-all.jar'';
				wantedBy = [ "multi-user.target" ];
				environment = {
					MONGO_URI = "mongodb://localhost";
					MONGO_DATABASE = "aggregator";
					OWNER_SNOWFLAKE = "521031433972744193";
				};
			};
		};
	};

	containers.caddy = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/http";
				isReadOnly = true;
			};
		};

		config = {
			system.stateVersion = "24.11";

			services.caddy = {
				enable = true;
				email = "astralchroma@proton.me";

				virtualHosts."https://astralchroma.dev".extraConfig = ''
					@stripExtensions path_regexp strip (.*)\.(html)
					redir @stripExtensions {re.strip.1} permanent

					redir /index / permanent
					header / Link "<fonts/exo_2-reduced.ttf>;rel=preload;as=font,<fonts/exo_2-italic-reduced.ttf>;rel=preload;as=font,<images/background.svg>;rel=reload;as=image,<images/avatar.png>;rel=preload;as=image,<images/github.svg>;rel=preload;as=image,<images/youtube.svg>;rel=preload;as=image,<images/mail.svg>;rel=preload;as=image,<images/code.svg>;rel=preload;as=image,<images/globe.svg>;rel=preload;as=image"

					root * /srv/

					file_server {
						hide /srv/.git/
					}

					try_files {path} {path}/ {path}.html
				'';

				virtualHosts."https://www.astralchroma.dev".extraConfig = ''
					redir https://astralchroma.dev{uri} permanent
				'';

				virtualHosts."https://tailscale.astralchroma.dev".extraConfig = ''
					reverse_proxy http://localhost:8080
				'';

				virtualHosts."https://gateway.astralchroma.dev".extraConfig = ''
					reverse_proxy http://100.64.0.1:8096
				'';
			};
		};
	};

	containers.headscale = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/headscale";
				isReadOnly = false;
			};
		};

		config = {
			system.stateVersion = "24.11";

			services.headscale = {
				enable = true;

				settings = {
					server_url = "https://tailscale.astralchroma.dev/";
					db_path = "/srv/db.sqlite";
					private_key_path = "/srv/private.key";
					noise.private_key_path = "/srv/noise_private.key";
				};
			};

			systemd.services.headscale.serviceConfig.ReadWritePaths = "/srv";
		};
	};

	services.tailscale.enable = true;

	users.users.emily.packages = [ pkgs.mongosh ];
}
