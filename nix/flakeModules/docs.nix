/**
  Documentation generation flake-parts module.

  Provides `docs.*` options for generating API reference documentation
  from Nix source files and building mdBook documentation sites.

  # Example

  ```nix
  {
    inputs.docgen.url = "github:imp-nix/docgen-rs";
    inputs.docgen.inputs.nixpkgs.follows = "nixpkgs";

    outputs = inputs@{ flake-parts, ... }:
      flake-parts.lib.mkFlake { inherit inputs; } {
        imports = [ inputs.docgen.flakeModules.docs ];
        docs = {
          manifest = ./docs/manifest.nix;
          srcDir = ./src;
          siteDir = ./docs;
        };
      };
  }
  ```

  This adds three outputs: `apps.docs` serves the documentation locally with
  live reload, `apps.build-docs` builds to a local directory, and `packages.docs`
  produces a derivation containing the built site.
*/
{
  lib,
  config,
  inputs,
  self,
  ...
}:
let
  inherit (lib) mkOption types mkIf;

  hasDocgen = inputs ? docgen;

  # Use docgen library from flake input
  docgenLib = if hasDocgen then inputs.docgen.lib else { };
  docgenCoreLib = if hasDocgen then docgenLib.lib { inherit lib; } else { };
in
{
  options.docs = {
    enable = mkOption {
      type = types.bool;
      default = hasDocgen;
      description = ''
        Enable documentation generation.
        Automatically enabled when the docgen input is present.
      '';
    };

    manifest = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the docgen manifest file that describes documentation structure.
      '';
    };

    srcDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the source directory to generate API reference from.
      '';
    };

    siteDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the documentation site directory (contains book.toml, etc).
      '';
    };

    name = mkOption {
      type = types.str;
      default = "docs";
      description = ''
        Name for the documentation package.
      '';
    };

    anchorPrefix = mkOption {
      type = types.str;
      default = "";
      description = ''
        Prefix for anchor IDs in generated documentation.
      '';
    };

    optionsModule = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Optional path to a NixOS-style options module to document.
      '';
    };

    optionsPrefix = mkOption {
      type = types.str;
      default = "";
      description = ''
        Prefix for options (e.g., "imp." for imp.* options).
      '';
    };

    extraFiles = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = ''
        Extra files to copy into the documentation site.

        Keys are destination paths relative to the site's src/ directory.
        Values are source paths.
      '';
      example = lib.literalExpression ''
        { "extra.md" = ./extra.md; }
      '';
    };
  };

  config = mkIf (config.docs.enable && hasDocgen) (
    let
      cfg = config.docs;
    in
    {
      perSystem =
        { pkgs, system, ... }:
        let
          optionsJson =
            if cfg.optionsModule != null then
              let
                json = docgenCoreLib.optionsToJson {
                  optionsModule = cfg.optionsModule;
                  prefix = cfg.optionsPrefix;
                };
              in
              pkgs.writeText "${cfg.name}-options.json" json
            else
              null;

          dg = docgenLib.mk {
            inherit lib pkgs;
            inherit (cfg) name anchorPrefix extraFiles;
            docgenPkg = inputs.docgen.packages.${system}.default;
            manifest =
              if cfg.manifest == null then
                throw "docs.manifest must be set when docs are enabled"
              else
                cfg.manifest;
            srcDir =
              if cfg.srcDir == null then
                throw "docs.srcDir must be set when docs are enabled"
              else
                cfg.srcDir;
            siteDir = cfg.siteDir;
            inherit optionsJson;
          };
        in
        {
          apps.docs = {
            type = "app";
            meta.description = "Serve documentation locally with live reload";
            program = toString dg.serveDocsScript;
          };

          apps.build-docs = {
            type = "app";
            meta.description = "Build documentation to local directory";
            program = toString dg.buildDocsScript;
          };

          packages.docs = dg.docs;
        };
    }
  );
}
