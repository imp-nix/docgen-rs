/**
  imp.docgen - Documentation generator for Nix projects.

  # Example

  ```nix
  docgenLib.mk {
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
    manifest = ./docs/manifest.nix;
    srcDir = ./src;
    siteDir = ./docs;
    docgenPkg = inputs.docgen.packages.${system}.default;
  }
  ```

  # Options

  - `lib`: Nixpkgs lib
  - `pkgs`: Nixpkgs package set
  - `manifest`: Path to manifest file or manifest attrset
  - `srcDir`: Source directory to document
  - `siteDir`: Site directory for mdbook (optional)
  - `docgenPkg`: The docgen CLI package
  - `mdbookPkg`: mdbook package (default: pkgs.mdbook)
  - `optionsJson`: Path to options JSON for module docs (optional)
  - `anchorPrefix`: Prefix for anchors (default: "")
  - `name`: Output name (default: "docs")
  - `referenceDir`: Reference subdirectory (default: "reference")
  - `localPaths`: Local paths for serve/build scripts
  - `outputFiles`: Output file names
  - `extraFiles`: Extra files to copy to site
*/
let
  lib = { lib }: import ./lib.nix { inherit lib; };
  schema = { lib }: import ./schema.nix { inherit lib; };

  mk =
    {
      lib,
      pkgs,
      manifest,
      srcDir,
      siteDir ? null,
      extraFiles ? { },
      docgenPkg,
      mdbookPkg ? pkgs.mdbook,
      optionsJson ? null,
      anchorPrefix ? "",
      name ? "docs",
      referenceDir ? "reference",
      localPaths ? {
        site = "./docs";
        src = "./src";
      },
      outputFiles ? {
        files = "files.md";
        methods = "methods.md";
        options = "options.md";
      },
    }:
    import ./mkDocgen.nix {
      inherit
        lib
        pkgs
        manifest
        srcDir
        siteDir
        extraFiles
        mdbookPkg
        optionsJson
        anchorPrefix
        name
        referenceDir
        localPaths
        outputFiles
        ;
      docgenPkg = docgenPkg;
      docgenLib = (import ./lib.nix { inherit lib; });
    };

in
{
  meta = {
    name = "docgen";
    description = "Documentation generator for Nix projects";
  };
  inherit lib schema mk;
}
