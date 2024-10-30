{ config, inputs, lib, modulesPath, pkgs, ... }: {
	nixpkgs.overlays = [
		(self: super: {
			git-of-theseus = super.callPackage ./packages/git-of-theseus.nix {};
		})
	];

	hardware = {
		graphics.extraPackages = [ pkgs.libGL ];

		bluetooth = {
			enable = true;
			powerOnBoot = true;
		};

		gpgSmartcards.enable = true;
	};

	boot = {
		kernelPackages = pkgs.linuxPackages_zen;
		kernelParams = [ "libahci.ignore_sss=1" ];
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

		blueman.enable = true;
		envfs.enable = true;
		flatpak.enable = true;
		gnome.gnome-keyring.enable = true;
		pcscd.enable = true;
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

	users.users.emily = {
		packages = with pkgs; with config.nur.repos; [
			ags aseprite blockbench dunst firefox gamemode gamescope gimp git-of-theseus heroic hyprshot inkscape kitty
			libreoffice mangohud nautilus nltch.spotify-adblock obs-studio obsidian onefetch oxipng pavucontrol
			playerctl prismlauncher qoi renderdoc swaylock vesktop vlc wine wine64 winetricks wofi xorg.xcursorthemes
			yubikey-manager

			(vscode-with-extensions.override {
				vscode = vscodium;
				vscodeExtensions = with vscode-extensions; [
					jnoortheen.nix-ide
					mkhl.direnv
					rust-lang.rust-analyzer
					streetsidesoftware.code-spell-checker
					tamasfe.even-better-toml
					vadimcn.vscode-lldb
				] ++ vscode-utils.extensionsFromVscodeMarketplace [
					{
						name = "wgsl";
						publisher = "PolyMeilex";
						version = "0.1.17";
						sha256 = "sha256-vGqvVrr3wNG6HOJxOnJEohdrzlBYspysTLQvWuP0QIw=";
					}
				];
			})
		];
	};
}
