{
	inputs = {
		agenix.url = github:ryantm/agenix;
		ags.url = github:Aylur/ags;
		axolotlClientApi.url = github:AxolotlClient/AxolotlClient-API;
		nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
		nur.url = github:nix-community/NUR;
	};

	outputs = inputs@{ self, agenix, ags, axolotlClientApi, nixpkgs, nur }: {
		nixosConfigurations.horizon = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.nixosModules.nur
				./global.nix
				./graphical.nix
				./horizon.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};

		nixosConfigurations.starship = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.nixosModules.nur
				./global.nix
				./graphical.nix
				./starship.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};

		nixosConfigurations.outpost = nixpkgs.lib.nixosSystem {
			system = "aarch64-linux";
			modules = [
				axolotlClientApi.nixosModules.default
				./global.nix
				./outpost.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};
	};
}
