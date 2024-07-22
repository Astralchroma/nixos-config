{ config, lib, pkgs, inputs, ... }: {
	nixpkgs.config.allowUnfree = true;

	nixpkgs.overlays = [
		(self: super: {
			git-of-theseus = super.callPackage ./git-of-theseus.nix {};
		})
	];

	imports = [ ./hardware-configuration.nix ];

	nix.settings = {
		auto-optimise-store = true;
		experimental-features = [ "nix-command" "flakes" ];
		trusted-users = [ "@wheel" ];
	};

	nix.gc = {
		automatic = true;
		persistent = true;
		dates = "00:00";
		options = "--delete-older-than 30d";
	};

	system = {
		stateVersion = "24.05";

		autoUpgrade = {
			enable = true;
			persistent = true;
			flake = inputs.self.outPath;
			operation = "switch";
			flags = [ "--upgrade-all" "--verbose" "-L" ];
			dates = "00:00";
		};
	};

	time.timeZone = "Europe/London";
	i18n.defaultLocale = "en_GB.UTF-8";
	console.useXkbConfig = true;
	documentation.nixos.enable = false; 
	xdg.portal.enable = true;

	boot = {
		kernelPackages = pkgs.linuxPackages_zen;
		swraid.enable = true;
	};

	hardware = {
		opengl.extraPackages = [ pkgs.libGL ];

		bluetooth = {
			enable = true;
			powerOnBoot = true;
		};

		gpgSmartcards.enable = true;
	};

	networking = {
		hostName = "horizon";

		nameservers = [ "1.1.1.1" "8.8.8.8" ];
	};

	security = {
		rtkit.enable = true;
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

		xserver.xkb.layout = "gb";

		openssh = {
			enable = true;
			settings.PasswordAuthentication = false;
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
	};

	programs = { 
		steam.enable = true;
		gnupg.agent.enable = true;
		hyprland.enable = true;
		thunar.enable = true;
		wireshark.enable = true;
	};

	fonts = {
		packages = with pkgs; [ corefonts jetbrains-mono vistafonts ];
		fontconfig.defaultFonts.monospace = [ "Jetbrains Mono" ];
	};

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" "wireshark" ];
		packages = with pkgs; with config.nur.repos; [
			ags btop devenv direnv dunst fastfetch fd ffmpeg_7-full filezilla firefox gamemode gamescope gimp git
			git-of-theseus heroic hyprshot inkscape iuricarras.truckersmp-cli kdePackages.kdenlive kitty libreoffice
			lua53Packages.tl mangohud ncdu nltch.spotify-adblock nvtopPackages.amd obs-studio obsidian onefetch oxipng
			pavucontrol playerctl prismlauncher rclone rsync smartmontools swaylock unzip usbutils vesktop vlc vmtouch
			wget wine wine64 wireshark-qt wofi zip

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

	environment = {
		defaultPackages = [];
		systemPackages = [];
	};
}
