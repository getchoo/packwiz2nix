final: prev: {
  fetchPackwizModpack = final.callPackage ./fetchPackwizModpack.nix {};

  packwiz-installer-bootstrap = prev.callPackage ./packwiz-installer-bootstrap.nix {};
  packwiz-installer = prev.callPackage ./packwiz-installer.nix {};
}
