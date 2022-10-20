{
  inputs = {
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixgl.url = "github:joefiorini/nixGL?ref=patch-1";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, crane, fenix, flake-utils, nixpkgs, nixgl }:
    flake-utils.lib.eachDefaultSystem (system: 
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nixgl.overlay ];
          };
          fenix-pkgs = fenix.packages.${system};
          fenix-channel = (fenix-pkgs.stable);

          craneLib = crane.lib.${system}.overrideToolchain
            fenix.packages.${system}.minimal.toolchain;

        commonArgs = {
          src = ./.;
          buildInputs = with pkgs; [
            xorg.libX11
            xorg.libX11.dev
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
          ];
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.pkgconfig
            pkgs.fontconfig
            fenix-channel.rustc
          ];
        };
          cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
            pname = "iced-deps";
          });

          icedPolkit = craneLib.buildPackage (commonArgs // {
            src = ./.;
          });

        in {
          defaultPackage = icedPolkit;
          devShell = pkgs.mkShell {
            buildInputs = cargoArtifacts.buildInputs ++ [
              pkgs.vulkan-loader
              pkgs.nixgl.auto.nixGLNvidia
              pkgs.nixgl.auto.nixVulkanNvidia
              pkgs.libGL
              pkgs.cmake
            ];
            nativeBuildInputs = cargoArtifacts.nativeBuildInputs ++ [
              fenix-pkgs.rust-analyzer
              fenix-channel.rustfmt
              fenix-channel.rustc
              fenix-channel.cargo
            ];
          };
    });
}
