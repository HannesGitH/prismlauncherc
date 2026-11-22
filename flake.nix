{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    prismlauncher_upstream.url = "github:PrismLauncher/PrismLauncher";
  };

  outputs =
    { nixpkgs, prismlauncher_upstream, ... }:
    let
      inherit (nixpkgs) lib;

      addPatches =
        pkg: patches:
        pkg.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ patches;
        });

      systems = lib.systems.flakeExposed;
      forAllSystems = lib.genAttrs systems;
      _systemPkgs = system: nixpkgs.legacyPackages.${system}.pkgs;
      forAllSysPkgs = f: forAllSystems (system: f system (_systemPkgs system));
    in
    rec {
      packages = forAllSysPkgs (
        system: pkgs:
        let
          prismPkgs = prismlauncher_upstream.packages.${system};
        in
        rec {
          patch = pkgs.stdenvNoCC.mkDerivation {
            name = "prism-launcher-patch";
            src = prismPkgs.prismlauncher-unwrapped.src;
            nativeBuildInputs = with pkgs; [
              git
              gawk
            ];
            buildPhase = ''
              echo "patching"
              awk '/bool AccountList::anyAccountIsValid\(\)/               { print; getline; print "{"; print "    return true;"; next }1' launcher/minecraft/auth/AccountList.cpp > temp_account_list
              awk '/bool ownsMinecraft\(\) const/ { print "    bool ownsMinecraft() const { return true; }"; next }1' launcher/minecraft/auth/MinecraftAccount.h > temp_own_minecraft
              echo "generating patch"
              git --no-pager diff --no-index launcher/minecraft/auth/AccountList.cpp temp_account_list >> crack.patch || true
              git --no-pager diff --no-index launcher/minecraft/auth/MinecraftAccount.h temp_own_minecraft >> crack.patch || true
              echo "done"
            '';
            installPhase = ''
              cp crack.patch $out
            '';
          };
          default = prismPkgs.prismlauncher.override {
            prismlauncher-unwrapped = addPatches prismPkgs.prismlauncher-unwrapped [ patch ];
          };
        }
      );

      apps = forAllSysPkgs (
        system: pkgs: {
          default = {
            type = "app";
            program =
              let
                dir = packages.${system}.default;
              in
              if pkgs.stdenv.isDarwin then
                "${dir}/Applications/PrismLauncher.app/Contents/MacOS/prismlauncher"
              else
                "${dir}/bin/prismlauncher";
          };
        }
      );

      overlays.default = final: prev: {
        prismlauncher = packages.${final.system}.default;
      };
    };
}
