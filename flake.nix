{
  # main
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    android.url = "github:tadfisher/android-nixpkgs";
    corepack.url = "github:SnO2WMaN/corepack-flake";
  };
  # dev
  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = with inputs; [
            devshell.overlay
          ];
        };
        android-version = "31.0.0";
        android-sdk = inputs.android.sdk.${system} (sdkPkgs:
          with sdkPkgs; [
            build-tools-31-0-0
            cmdline-tools-latest
            emulator
            platform-tools
            platforms-android-31
          ]);
        corepack = inputs.corepack.mkCorepack.${system} {
          nodejs = pkgs: pkgs.nodejs;
          pm = "pnpm";
        };
      in {
        devShells.default = pkgs.devshell.mkShell {
          packages = with pkgs; [
            alejandra
            treefmt
            android-sdk
            gradle
            jdk11
            nodejs
            corepack
          ];
          env = with pkgs; [
            {
              name = "JAVA_HOME";
              value = jdk11.home;
            }
            {
              name = "GRADLE_OPTS";
              # match build-tools version sdkPkgs.build-tools-vxxx
              value = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/31.0.0/aapt2";
            }
            {
              name = "ANDROID_HOME";
              value = "${android-sdk}/share/android-sdk";
            }
            {
              name = "ANDROID_SDK_ROOT";
              value = "${android-sdk}/share/android-sdk";
            }
            {
              name = "PATH";
              prefix = "${android-sdk}/share/android-sdk/emulator";
            }
            {
              name = "PATH";
              prefix = "${android-sdk}/share/android-sdk/platform-tools";
            }
          ];
        };
      }
    );
}
