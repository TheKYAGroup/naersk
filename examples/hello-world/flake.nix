{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, flake-utils, naersk, nixpkgs, nixpkgs-mozilla }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk {};

	buildPackageFor = releaseMode: naersk'.buildPackage {
	  src = ./.;
	  release = releaseMode;
	  # openssl_3 is reuired for SageSdk
          nativeBuildInputs = with pkgs; [ makeWrapper openssl_3 ];
	  postInstall = ''
	    wrapProgram $out/bin/hello-world\
              --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath [ pkgs.openssl_3 ]}
	  '';
	};

      in rec {
        # For `nix build` & `nix run`:
        defaultPackage = debugPackage;

	# Debug build
        packages.debug = debugPackage;
	# Release mode
        packages.release = releasePackage;

        debugPackage = buildPackageFor false;
        releasePackage = buildPackageFor true;

        # For `nix develop`:
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rustc cargo openssl_3 ];
        };
      }
    );
}
