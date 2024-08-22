{ inputs, modulesPath, pkgs, ... }: let
	values = builtins.fromJSON (builtins.readFile ./values.json);
in {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "24.11";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

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

	networking = {
		hostName = "outpost";
		useDHCP = true;
	};

	users.users.emily.packages = [ pkgs.mongosh ];

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
}
