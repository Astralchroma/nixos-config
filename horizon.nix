{ config, lib, pkgs, modulesPath, ... }: {
	nixpkgs.overlays = [
		(self: super: {
			git-of-theseus = super.callPackage ./git-of-theseus.nix {};
		})
	];

	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	system.stateVersion = "24.05";

	hardware = {
		graphics.extraPackages = [ pkgs.libGL ];

		bluetooth = {
			enable = true;
			powerOnBoot = true;
		};

		gpgSmartcards.enable = true;

		cpu.amd.updateMicrocode = true;
	};

	boot = {
		swraid.enable = true;
		bcache.enable = true;

		initrd.services.bcache.enable = true;
		initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "bcache" ];
		initrd.kernelModules = [ "bcache" ];

		kernelPackages = pkgs.linuxPackages_zen;
		kernelModules = [ "kvm-amd" "bcache" ];
		kernelParams = [ "libahci.ignore_sss=1" ];
		
		loader.grub.mirroredBoots = [
			{
				devices = [ "/dev/disk/by-uuid/8236-8023" ];
				path = "/boot2";
			}
		];
	};

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

	networking = {
		hostName = "horizon";
		defaultGateway = "192.168.1.254";
		useDHCP = false;

		interfaces.enp7s0.ipv4.addresses = [{
			address = "192.168.2.1";
			prefixLength = 16;
		}];
	};

	services = {
		pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;

			wireplumber.configPackages = [
				(pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
					bluez_monitor.properties = {
						["bluez5.enable-sbc-xq"] = true,
						["bluez5.enable-sbc"] = false,
						["bluez5.enable-msbc"] = false,
						["bluez5.enable-cvsd"] = false,
						["bluez5.enable-hw-volume"] = false,
						["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
					}
				'')
			];

		};

		displayManager.sddm = {
			enable = true;
			autoNumlock = true;
			wayland.enable = true;
		};

		syncthing = {
			enable = true;
			user = "emily";
			configDir = "/home/emily/.config/syncthing";
			overrideDevices = true;
			overrideFolders = true;
			settings = {
				devices = {
					"Phone" = { id = "QW5ZI4M-GFPS4KC-V6XZ43A-Y46P6KR-TBK7QKA-JJV75WI-DZPVUPG-44U3AQP"; };
				};
				folders = {
					"Journal" = {
						path = "/media/Data/Journal";
						devices = [ "Phone" ];
					};
				};
			};
		};

		blueman.enable = true;

		gnome.gnome-keyring.enable = true;
		envfs.enable = true;
		flatpak.enable = true;
	};

	security.rtkit.enable = true;

	programs = { 
		steam.enable = true;
		gnupg.agent.enable = true;
		hyprland.enable = true;
		wireshark.enable = true;
	};

	xdg.portal = {
		enable = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
		config.common.default = "gtk";
	};

	fonts = {
		packages = with pkgs; [ corefonts jetbrains-mono vistafonts ];
		fontconfig.defaultFonts.monospace = [ "Jetbrains Mono" ];
	};

	users.users.emily = {
		extraGroups = [ "wireshark" ];
		packages = with pkgs; with config.nur.repos; [
			ags dunst ffmpeg_7-full filezilla firefox gamemode gamescope gimp git-of-theseus heroic hyprshot inkscape
			iuricarras.truckersmp-cli kdePackages.kdenlive kitty libreoffice lua53Packages.tl mangohud nautilus
			nltch.spotify-adblock nvtopPackages.amd obs-studio obsidian onefetch oxipng pavucontrol playerctl
			prismlauncher swaylock usbutils vesktop vlc winetricks wine wine64 wireshark-qt wofi xorg.xcursorthemes

			(vscode-with-extensions.override {
				vscode = vscodium;
				vscodeExtensions = with vscode-extensions; [
					rust-lang.rust-analyzer
					tamasfe.even-better-toml
					jnoortheen.nix-ide
					mkhl.direnv
				] ++ vscode-utils.extensionsFromVscodeMarketplace [
					{
						name = "wgsl";
						publisher = "PolyMeilex";
						version = "0.1.17";
						sha256 = "sha256-vGqvVrr3wNG6HOJxOnJEohdrzlBYspysTLQvWuP0QIw=";
					}
					{
						name = "discord-vscode";
						publisher = "icrawl";
						version = "5.8.0";
						sha256 = "sha256-IU/looiu6tluAp8u6MeSNCd7B8SSMZ6CEZ64mMsTNmU=";
					}
					{
						name = "vscode-teal";
						publisher = "pdesaulniers";
						version = "0.9.0";
						sha256 = "sha256-eMKdG5rFUPzRTm2dzRFpMnhugd52UjxHW1hhpnZqErA=";
					}
				];
			})
		];
	};
}
