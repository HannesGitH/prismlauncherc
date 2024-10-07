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

      patch = system: (pkgs: src: pkgs.stdenvNoCC.mkDerivation {
        name = "prism-launcher-patch";
        src = src;
        nativeBuildInputs = with pkgs; [ git gawk ];
        buildPhase = ''
          echo "patching"
          awk '/bool AccountList::anyAccountIsValid\(\)/ { print; getline; print "{"; print "    return true;"; next }1' launcher/minecraft/auth/AccountList.cpp > temp
          echo "generating patch"
          git --no-pager diff --no-index launcher/minecraft/auth/AccountList.cpp temp > crack.patch || true
          echo "done"
        '';
        installPhase = ''
          cp crack.patch $out
        '';
      }) nixpkgs.legacyPackages.${system}.pkgs;
    in rec
    {
      packages = forAllSystems (system: {
        default = 
          (ups: 
            ups.prismlauncher.override {
              prismlauncher-unwrapped = addPatches ups.prismlauncher-unwrapped [ (patch system ups.prismlauncher-unwrapped.src) ];
            }
          ) prismlauncher_upstream.packages.${system};
      });

      overlays.default = final: prev: {
        prismlauncher = packages.${final.system}.default;
      };
    };
}