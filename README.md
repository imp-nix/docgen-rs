# docgen

Documentation generator CLI for Nix projects.

Extracts RFC-style docstrings from Nix files and generates mdBook-compatible markdown.

## Installation

```nix
{
  inputs.docgen.url = "github:imp-nix/docgen-rs";
}
```

## Usage

```bash
# Extract function docs from a file
docgen --file src/api.nix --category "API" --description "Core API"

# Extract file-level doc comment
docgen file-doc --file src/default.nix

# Render options from JSON
docgen options --file options.json --title "Module Options"
```

## With imp.lib

Use `imp.docgenLib` for the full documentation pipeline:

```nix
imp.docgenLib.make {
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  manifest = ./docs/manifest.nix;
  srcDir = ./src;
  siteDir = ./docs;
  docgenPkg = inputs.docgen.packages.${system}.default;
}
```
