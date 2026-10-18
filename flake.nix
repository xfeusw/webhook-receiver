{
  description = "A reproducible Node.js development environment with modern tooling.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Granular builder helper for consumer flakes (Way A)
      mkNodeShell =
        {
          pkgs,
          nodePackage ? pkgs.nodejs_22,
          extraPackages ? [ ],
          env ? { },
          shellHook ? "",
        }:
        let
          baseShell = pkgs.mkShell {
            packages =
              [
                nodePackage
                pkgs.yarn
                pkgs.pnpm
                pkgs.typescript
                pkgs.prettier
                pkgs.eslint
              ]
              ++ extraPackages;

            shellHook = ''
              echo "Entering Node.js development environment with Node.js ${nodePackage.version}, yarn & pnpm."
            '';
          };
        in
        baseShell.overrideAttrs (oldAttrs: {
          env = oldAttrs.env or { } // env;
          shellHook = (oldAttrs.shellHook or "") + "\n" + shellHook;
        });
    in
    {
      # Granular Library helper functions for consumer flakes
      lib = {
        inherit mkNodeShell;
      };

      # Scaffolding templates for 'nix flake init' (Way B)
      templates = {
        default = {
          path = ./.;
          description = "A reproducible Node.js development environment with modern tooling";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        defaultShell = mkNodeShell { inherit pkgs; };
      in
      {
        devShells = {
          default = defaultShell;
        };

        checks = {
          default = defaultShell;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "node-env-info" ''
              echo "=== Node.js Nix Development Environment ==="
              ${pkgs.nodejs_22}/bin/node --version
            '';
          };
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
