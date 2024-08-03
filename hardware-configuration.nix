{ config, lib, pkgs, modulesPath, ... }: {
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/3a004f86-d2f7-4b5c-af71-89e07171c4db";
			fsType = "btrfs";
			options = [ "compress=zstd:15" ];
		};

		"/media/Archive" = {
			device = "/dev/disk/by-uuid/3a004f86-d2f7-4b5c-af71-89e07171c4db";
			fsType = "btrfs";
			options = [ "subvol=/Archive" ];
		};

		"/media/Data" = {
			device = "/dev/disk/by-uuid/3a004f86-d2f7-4b5c-af71-89e07171c4db";
			fsType = "btrfs";
			options = [ "subvol=/Data" ];
		};

		"/media/Library" = {
			device = "/dev/disk/by-uuid/3a004f86-d2f7-4b5c-af71-89e07171c4db";
			fsType = "btrfs";
			options = [ "subvol=/Library" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/868F-0170";
			fsType = "vfat";
		};

		"/boot2" = {
			device = "/dev/disk/by-uuid/C49B-DBA8";
			fsType = "vfat";
		};

		"/boot3" = {
			device = "/dev/disk/by-uuid/3D62-7570";
			fsType = "vfat";
		};

		"/boot4" = {
			device = "/dev/disk/by-uuid/6359-0142";
			fsType = "vfat";
		};

#		"/boot5" = {
#			device = "/dev/disk/by-uuid/B587-2704";
#			fsType = "vfat";
#		};
	};

	boot.loader.grub = {
		enable = true;

		device = "nodev";
		efiSupport = true;
		efiInstallAsRemovable = true;

		mirroredBoots = [
			{
				devices = [ "/dev/disk/by-uuid/C49B-DBA8" ];
				path = "/boot2";
			}
			{
				devices = [ "/dev/disk/by-uuid/3D62-7570" ];
				path = "/boot3";
			}
			{
				devices = [ "/dev/disk/by-uuid/6359-0142" ];
				path = "/boot4";
			}
#			{
#				devices = [ "/dev/disk/by-uuid/B587-2704" ];
#				path = "/boot5";
#			}
		];
	};

	boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
	boot.initrd.kernelModules = [ ];

	boot.kernelModules = [ "kvm-amd" ];
	boot.extraModulePackages = [ ];

	# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
	# (the default) this is the recommended approach. When using systemd-networkd it's
	# still possible to use this option, but it's recommended to use it in conjunction
	# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
	networking.useDHCP = lib.mkDefault false;
	# networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

	networking.interfaces.enp7s0.ipv4.addresses = [{
		address = "192.168.2.10";
		prefixLength = 16;
	}];

	networking.defaultGateway = "192.168.1.254";

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
