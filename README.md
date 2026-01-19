# Bambu Studio Nix

A Nix derivation for building [Bambu Studio](https://github.com/bambulab/BambuStudio) from source on Linux.

Bambu Studio is BambuLab's open-source slicer software for 3D printers, forked from PrusaSlicer. This repository provides a Nix expression to build it reproducibly on NixOS and other Linux distributions with Nix installed.

## Current Version

**v02.04.00.70** (Bambu Studio 2.4.0)

## Requirements

- [Nix package manager](https://nixos.org/download.html)
- Linux system (x86_64)

## Building

### Quick Build

```bash
nix-build
```

The resulting binary will be available at `./result/bin/bambu-studio`.

### Development Shell

To enter a shell with Bambu Studio available:

```bash
nix-shell
bambu-studio
```

The development shell also includes debugging tools (gdb, strace, ltrace).

### Install in Profile

```bash
nix-env -f default.nix -i
```

## Usage with Flakes

You can reference this derivation in your flake:

```nix
{
  inputs.bambu-studio-nix.url = "github:YOUR_USERNAME/bambu_studio_nix";

  outputs = { self, nixpkgs, bambu-studio-nix }: {
    # Use bambu-studio-nix.packages.x86_64-linux.default
  };
}
```

Or import directly:

```nix
{ pkgs ? import <nixpkgs> {} }:
let
  bambu-studio = import (fetchTarball "https://github.com/YOUR_USERNAME/bambu_studio_nix/archive/main.tar.gz") { inherit pkgs; };
in
  # ...
```

## Patches Applied

This build includes several patches to work with Nix:

- **webkit2gtk linking** - Fixes linking against webkit2gtk for the embedded browser
- **opencv linking** - Fixes opencv library linking issues
- **no-osmesa** - Removes OSMesa dependency (not needed for desktop use)
- **no-cereal** - Uses system cereal library
- **cmake** - CMake 4 compatibility fixes
- **gcc15 stdint** - Includes missing stdint header for gcc15

## Troubleshooting

### Build fails with missing dependencies

Ensure your nixpkgs channel is up to date:

```bash
nix-channel --update
```

### Runtime crashes

The derivation includes a workaround for intermittent crashes by preloading the GLEW library. If you still experience issues, try running with:

```bash
GDK_BACKEND=x11 bambu-studio
```

### Network features not working

The GIO SSL/TLS support requires `glib-networking`. This is included in the build and should work automatically. If you have issues with Bambu Cloud login, ensure your system has proper certificate bundles.

## Updating to New Versions

When a new Bambu Studio version is released:

1. Update `version` in `default.nix`
2. Update the `hash` in the `fetchFromGitHub` block (use `lib.fakeHash` first to get the correct hash)
3. Check if any patches need updating or can be removed

## License

Bambu Studio is licensed under AGPL-3.0-or-later. This Nix packaging is provided under the same license.

## Links

- [Bambu Studio GitHub](https://github.com/bambulab/BambuStudio)
- [Bambu Studio Release Notes](https://wiki.bambulab.com/en/software/bambu-studio/release)
- [Bambu Lab Website](https://bambulab.com/)
