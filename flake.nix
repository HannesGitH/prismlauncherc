{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    prismlauncher_upstream = {
      url = "github:PrismLauncher/PrismLauncher";
    };
  };

  outputs =
    { nixpkgs, prismlauncher_upstream, ... }:
    let
      addPatches = pkg: patches:
        pkg.overrideAttrs
        (oldAttrs: { patches = (oldAttrs.patches or [ ]) ++ patches; });
    in rec
    {
      packages = {
        default = addPatches prismlauncher_upstream [ ./crack.patch ];
      };

      overlays.default = final: prev: {
        prismlauncher = packages.default;
      };
    };
}