{
	inputs = {
		nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
		nur.url = github:nix-community/NUR;
		ags.url = github:Aylur/ags;
	};

	outputs = inputs@{ self, nixpkgs, nur, ags }: {
		nixosConfigurations.horizon = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [ nur.nixosModules.nur ./configuration.nix ];
		};
	};
}
