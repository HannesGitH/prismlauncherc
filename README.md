# Prism Launcher _Cracked_

## for educational purposes only, do not use

do not replace your normal flake input with

```diff
- prismLauncher.url = "github:PrismLauncher/PrismLauncher";
+ prismLauncher.url = "github:HannesGitH/prismlauncherc";
```

because then adding

```nix
nixpkgs.overlays = [ inputs.prismLauncher.overlays.default ];
```

would replace `pkgs.prismlauncher` with a very up-to-date variant of PrismLauncher that doesn't require a microsoft account, which is against minecrafts TOS
