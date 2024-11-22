{ modulesPath, ... }: {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "25.05";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

	fileSystems = {
		"/" = {
			device = "tmpfs";
			fsType = "tmpfs";
			options = [ "mode=755" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/4C51-A2F3";
			fsType = "vfat";
		};

		"/nix" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			fsType = "btrfs";
			options = [ "compress=lzo" "subvol=nix" ];
		};

		"/etc/nixos" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			fsType = "btrfs";
			options = [ "compress=lzo" "subvol=etc/nixos" ];
		};
	};

	networking = {
		useDHCP = true;
		hostName = "beryllium";
	};
}
