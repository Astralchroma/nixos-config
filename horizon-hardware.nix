{ config, lib, pkgs, modulesPath, ... }: {
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/82f96cc5-08c4-4303-85c6-322aef0eeed6";
			fsType = "btrfs";
			options = [ "compress=zstd:15" ];
		};

		"/media/Archive" = {
			device = "/dev/disk/by-uuid/82f96cc5-08c4-4303-85c6-322aef0eeed6";
			fsType = "btrfs";
			options = [ "subvol=/Archive" ];
		};

		"/media/Data" = {
			device = "/dev/disk/by-uuid/82f96cc5-08c4-4303-85c6-322aef0eeed6";
			fsType = "btrfs";
			options = [ "subvol=/Data" ];
		};

		"/media/Library" = {
			device = "/dev/disk/by-uuid/82f96cc5-08c4-4303-85c6-322aef0eeed6";
			fsType = "btrfs";
			options = [ "subvol=/Library" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/8292-4648";
			fsType = "vfat";
		};

		"/boot2" = {
			device = "/dev/disk/by-uuid/8236-8023";
			fsType = "vfat";
		};
	};

	boot.loader.grub = {
		enable = true;

		device = "nodev";
		efiSupport = true;
		efiInstallAsRemovable = true;

		mirroredBoots = [
			{
				devices = [ "/dev/disk/by-uuid/8236-8023" ];
				path = "/boot2";
			}
		];
	};

	boot.bcache.enable = true;
	boot.swraid.enable = true;
	
	boot.initrd.services.bcache.enable = true;

	boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "bcache" ];
	boot.initrd.kernelModules = [ "bcache" ];
	
	boot.initrd.systemd.emergencyAccess = true;
	boot.initrd.systemd.enable = true;

	boot.kernelModules = [ "kvm-amd" "bcache" ];
	boot.extraModulePackages = [ ];
	boot.kernelParams = [ "libahci.ignore_sss=1" ];

	# boot.swraid.mdadmConf = "PROGRAM /etc/nixos/webhook";

	# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
	# (the default) this is the recommended approach. When using systemd-networkd it's
	# still possible to use this option, but it's recommended to use it in conjunction
	# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
	networking.useDHCP = lib.mkDefault false;
	# networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

	networking.interfaces.enp7s0.ipv4.addresses = [{
		address = "192.168.2.1";
		prefixLength = 16;
	}];

	networking.defaultGateway = "192.168.1.254";

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
