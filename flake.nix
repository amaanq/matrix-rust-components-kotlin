{
  description = "SchildiChat Matrix Rust Components Kotlin - SDK AAR Builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, fenix }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };

          androidComposition = pkgs.androidenv.composeAndroidPackages {
            platformVersions = [
              "35"
              "34"
            ];
            buildToolsVersions = [
              "35.0.0"
              "34.0.0"
            ];
            includeNDK = true;
          };

          androidSdk = androidComposition.androidsdk;

          rustToolchain = fenix.packages.${system}.combine [
            fenix.packages.${system}.stable.cargo
            fenix.packages.${system}.stable.rustc
            fenix.packages.${system}.stable.rust-std
            fenix.packages.${system}.stable.rust-src
            fenix.packages.${system}.targets.aarch64-linux-android.stable.rust-std
            fenix.packages.${system}.targets.armv7-linux-androideabi.stable.rust-std
            fenix.packages.${system}.targets.i686-linux-android.stable.rust-std
            fenix.packages.${system}.targets.x86_64-linux-android.stable.rust-std
          ];
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              androidSdk
              rustToolchain
              pkgs.cargo-ndk
              pkgs.jdk17
              pkgs.gradle
              pkgs.protobuf
              pkgs.git
            ];

            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

            shellHook = ''
              export JAVA_HOME=${pkgs.jdk17}
              export GRADLE_USER_HOME=$(pwd)/.gradle

              # Find the NDK version dynamically
              NDK_DIR=$(ls -d $ANDROID_SDK_ROOT/ndk/* 2>/dev/null | head -1)
              if [ -n "$NDK_DIR" ]; then
                export ANDROID_NDK_HOME="$NDK_DIR"
                export ANDROID_NDK="$NDK_DIR"
              fi

              echo "sdk.dir=$ANDROID_SDK_ROOT" > local.properties
              [ -n "$ANDROID_NDK_HOME" ] && echo "ndk.dir=$ANDROID_NDK_HOME" >> local.properties

              echo "SchildiChat Rust SDK Builder"
              echo "NDK: $ANDROID_NDK_HOME"
              echo ""
              echo "Build AAR (aarch64 only, for testing):"
              echo "  ./scripts/build.sh -p ../schildichat-matrix-rust-sdk -m sdk -t aarch64-linux-android"
              echo ""
              echo "Build AAR (all architectures, release):"
              echo "  ./scripts/build.sh -p ../schildichat-matrix-rust-sdk -m sdk -r"
            '';
          };
        }
      );
    };
}
