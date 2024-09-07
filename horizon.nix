{ config, inputs, lib, modulesPath, pkgs, ... }: {
	nixpkgs.overlays = [
		(self: super: {
			git-of-theseus = super.callPackage ./packages/git-of-theseus.nix {};
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
		
		loader.systemd-boot.extraInstallCommands = ''
			if ${pkgs.util-linux}/bin/mountpoint -q /boot2
			then
				printf "\033[1;34mMirroring /boot to /boot2. EFI System Partition will be redundant!\n"
				${pkgs.rsync}/bin/rsync -aUH --delete-after /boot/ /boot2/
			else
				printf "\033[1;31mMountpoint /boot2 does not exist! EFI System Partition will not be redundant!\n"
			fi
		'';
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

		firewall.allowedTCPPorts = [ 8096 ];
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
		envfs.enable = true;
		flatpak.enable = true;
		gnome.gnome-keyring.enable = true;
		jellyfin.enable = true;
		pcscd.enable = true;
		tailscale.enable = true;
	};

	security.rtkit.enable = true;

	programs = { 
		steam.enable = true;
		gnupg.agent.enable = true;
		hyprland.enable = true;
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

	environment.systemPackages = [
		inputs.agenix.packages."${pkgs.system}".default
		pkgs.rclone
	];

	age.secrets.rclone = {
		file = ./secrets/rclone.conf.age;
	};

	systemd.services.rclone = {
		enable = true;
		requires = [ "media-Data.mount" ];
		serviceConfig = {
			Type = "oneshot";
			ExecStart = "${pkgs.rclone}/bin/rclone --config ${config.age.secrets.rclone.path} sync --copy-links --order-by size,descending --delete-during --track-renames --verbose --delete-excluded --exclude-from /media/Data/.excluded --fast-list /media/Data backblaze:astralchroma-horizon";
		};
	};

	systemd.timers.rclone = {
		enable = true;
		wantedBy = [ "timers.target" ];
		timerConfig = {
			OnCalendar = "hourly";
			Persisent = true;
		};
	};

	users.users.emily = {
		packages = with pkgs; with config.nur.repos; [
			ags aseprite dunst firefox gamemode gamescope gimp git-of-theseus heroic hyprshot inkscape kitty libreoffice
			mangohud nautilus nltch.spotify-adblock nvtopPackages.amd obs-studio obsidian onefetch oxipng pavucontrol
			playerctl prismlauncher swaylock vesktop vlc winetricks wine wine64 wofi xorg.xcursorthemes yubikey-manager

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
