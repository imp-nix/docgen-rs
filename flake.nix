{
  description = "Documentation generator CLI for Nix projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    imp.url = "github:imp-nix/imp.lib";
    imp.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      imp,
    }:
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f system);

      mkDocgenCli =
        { rustPlatform, ... }:
        let
          cargo = lib.importTOML ./Cargo.toml;
        in
        rustPlatform.buildRustPackage {
          pname = "docgen";
          version = cargo.package.version;
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          postInstall = ''
            mv $out/bin/nixdoc $out/bin/docgen
          '';
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage mkDocgenCli { };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          docgen = self.packages.${system}.default.overrideAttrs (prev: {
            doCheck = true;
            postCheck = prev.postCheck or "" + ''
              ${pkgs.clippy}/bin/cargo-clippy --no-deps -- -D warnings
            '';
          });
        }
      );

      formatter = forAllSystems (
        system:
        imp.formatterLib.make {
          pkgs = nixpkgs.legacyPackages.${system};
          treefmt-nix = imp.inputs.treefmt-nix;
          rust = true;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              cargo
              cargo-insta
              clippy
              rustfmt
              rustc
            ];
          };
        }
      );
    };
}
