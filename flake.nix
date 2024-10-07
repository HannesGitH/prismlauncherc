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
      inherit (nixpkgs) lib;

      addPatches = pkg: patches:
        pkg.overrideAttrs
        (oldAttrs: { patches = (oldAttrs.patches or [ ]) ++ patches; });
      systems = lib.systems.flakeExposed;

      forAllSystems = lib.genAttrs systems;
    in rec
    {
      packages = forAllSystems (system: {
        default = 
          (ups: 
            ups.prismlauncher.override {
              prismlauncher-unwrapped = (addPatches ups.prismlauncher-unwrapped [ ./crack.patch ]);
            }
          ) prismlauncher_upstream.packages.${system};
      });

      overlays.default = final: prev: {
        prismlauncher = packages.${final.system}.default;
      };
    };
}