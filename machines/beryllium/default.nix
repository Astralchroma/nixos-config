{ modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "25.05";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

	fileSystems = {
		"/" = {
			device = "tmpfs";
			fsType = "tmpfs";
			options = [ "mode=755" ];
			neededForBoot = true;
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/4C51-A2F3";
			fsType = "vfat";
		};

		"/nix" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			fsType = "btrfs";
			options = [ "compress=lzo" "subvol=nix" ];
			neededForBoot = true;
		};

		"/etc/persistent" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=etc/persistent" ];
			neededForBoot = true;
		};

		"/etc/nixos" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=etc/nixos" ];
		};

		"/srv" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=srv" ];
		};
	};

	services.postgresql = {
		enable = true;

		package = pkgs.postgresql_17;
		dataDir = "/srv/postgresql/17";

		ensureUsers = [
			{
				name = "grafana";
				ensureDBOwnership = true;
				ensureClauses.login = true;
			}
		];

		ensureDatabases = [ "grafana" ];
	};

	services.grafana = {
		enable = true;

		dataDir = "/srv/grafana";

		settings = {
			server.domain = "monitoring.astralchroma.dev";

			database = {
				type = "postgres";
				user = "grafana";
				host = "/var/run/postgresql";
			};
		};
	};

	services.caddy = {
		enable = true;
		configFile = ./Caddyfile;
		dataDir = "/srv/caddy";
	};

	networking = {
		hostName = "beryllium";

		nftables.enable = true;
		useDHCP = true;

		firewall = {
			allowedTCPPorts = [ 80 443 ];
			allowedUDPPorts = [ 443 ];
		};
	};

	environment.etc = {
		"machine-id".source = "/etc/persistent/machine-id";

		"ssh/ssh_host_rsa_key".source = "/etc/persistent/ssh_host_rsa_key";
		"ssh/ssh_host_rsa_key.pub".source = "/etc/persistent/ssh_host_rsa_key.pub";
		"ssh/ssh_host_ed25519_key".source = "/etc/persistent/ssh_host_ed25519_key";
		"ssh/ssh_host_ed25519_key.pub".source = "/etc/persistent/ssh_host_ed25519_key.pub";
	};

	users = {
		mutableUsers = false;

		users.root.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";
		users.emily.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";
	};
}
