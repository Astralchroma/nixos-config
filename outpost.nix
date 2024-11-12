{ config, inputs, modulesPath, pkgs, ... }: {
	nixpkgs.overlays = [
		(self: super: {
			autochroma = super.callPackage ./packages/autochroma.nix {};
		})
	];

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
				package = pkgs.mongodb-ce;
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

				# Fuck you cloudflare, let me use subsubdomains damn it
				# Fuck you let's encrypt, let me use `_` damn it
				virtualHosts."https://axolotlclient-api.astralchroma.dev".extraConfig = ''
					handle_path /dev/* {
						reverse_proxy http://localhost:8000
					}
				'';

				virtualHosts."https://solarscape.astralchroma.dev".extraConfig = ''
					respond "Not Found" 404
				'';

				# Fuck you cloudflare, let me use subsubdomains damn it
				virtualHosts."https://solarscape-api.astralchroma.dev".extraConfig = ''
					respond "Not Found" 404
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
					database.sqlite.path = "/srv/db.sqlite";
					dns.base_domain = "tailscale.astralchroma.dev";
					noise.private_key_path = "/srv/noise_private.key";
				};
			};

			systemd.services.headscale.serviceConfig.ReadWritePaths = "/srv";
		};
	};

	services = {
		tailscale.enable = true;

		postgresql = {
			enable = true;
			package = pkgs.postgresql_16;
			dataDir = "/srv/postgresql16";
			authentication = "local all emily peer";
		};

		axolotlClientApi = {
			enable = true;
			postgresUrl = "postgres:///axolotl_client-api";
		};
	};

	age.secrets.autochromaDiscordToken = {
		file = ./secrets/autochroma-discord_token.age;
		owner = "autochroma";
		group = "autochroma";
	};

	age.secrets.autochromaDatabaseUri = {
		file = ./secrets/autochroma-database_uri.age;
		owner = "autochroma";
		group = "autochroma";
	};

	users.users.autochroma = { isSystemUser = true; name = "autochroma"; group = "autochroma"; };
	users.groups.autochroma = {};

	systemd.services.autochroma = {
		description = "Autochroma Discord Bot";

		after = [ "postgresql.service" ];
		requires = [ "postgresql.service" ];

		upheldBy = [ "multi-user.target" ];

		serviceConfig = with config.age.secrets; {
			User = "autochroma";
			Group = "autochroma";

			Type = "exec";
			ExecStart = "${pkgs.autochroma}/bin/autochroma --discord-token-file ${autochromaDiscordToken.path} --database-uri-file ${autochromaDatabaseUri.path}";

			CapabilityBoundingSet = "";
			LockPersonality = true;
			MemoryDenyWriteExecute = true;
			NoNewPrivileges = true;
			PrivateDevices = true;
			PrivateMounts = true;
			PrivateTmp = true;
			PrivateUsers = true;
			ProcSubset = "pid";
			ProtectClock = true;
			ProtectControlGroups = true;
			ProtectHome = true;
			ProtectHostname = true;
			ProtectKernelLogs = true;
			ProtectKernelModules = true;
			ProtectKernelTunables = true;
			ProtectProc = "invisible";
			ProtectSystem = "strict";
			RemoveIPC = true;
			RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
			RestrictNamespaces = true;
			RestrictRealtime = true;
			RestrictSUIDSGID = true;
			SystemCallArchitectures = "native";
			SystemCallFilter = "@basic-io @file-system @io-event @network-io @process @signal ioctl madvise";
			UMask = "777";
		};
	};

	users.users.emily.packages = [ pkgs.mongosh ];
}
