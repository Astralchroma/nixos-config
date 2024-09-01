{
	inputs = {
		agenix.url = github:ryantm/agenix;
		ags.url = github:Aylur/ags;
		nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
		nur.url = github:nix-community/NUR;
	};

	outputs = inputs@{ self, agenix, ags, nixpkgs, nur }: {
		nixosConfigurations.horizon = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.nixosModules.nur
				./defaults.nix
				./horizon.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};

		nixosConfigurations.outpost = nixpkgs.lib.nixosSystem {
			system = "aarch64-linux";
			modules = [
				./defaults.nix
				./outpost.nix
			];
			specialArgs = { inherit inputs; };
		};
	};
}
