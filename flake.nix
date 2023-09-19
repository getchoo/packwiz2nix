{
  description = "a tool for generating packages from packwiz modpacks";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    inherit (nixpkgs) lib;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = fn: lib.genAttrs systems (s: fn nixpkgs.legacyPackages.${s});
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    lib = forAllSystems (pkgs: let
      lib' = lib.makeScope pkgs.newScope (final: self.overlays.default final pkgs);
    in {
      inherit
        (lib')
        fetchPackwizModpack
        mkMultiMCPack
        ;
    });

    overlays.default = final: prev: (import ./lib final prev);
  };
}
