{
  description =
    "Development projects for InternetWide.org, which builds a modern (domain) hosting stack intended to make users once more first-class citizens of the Internet.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    arpa2cm-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "arpa2cm";
      rev = "c3aa5b6ce5c3c14a66bbf27044c517186176cb66";
      flake = false;
    };

    arpa2common-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "arpa2common";
      rev = "c65fbe034a288ba504b4b68b62b1546b8c3ddf5a";
      flake = false;
    };

    steamworks-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "steamworks";
      rev = "93935c899cd14b7659af0dbca05c776f7dc85ff4";
      flake = false;
    };

    steamworks-pulleyback-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "steamworks-pulleyback";
      rev = "f63d89ba54f3919fa9c67aab9d59efad3f2dc9c7";
      flake = false;
    };

    quick-mem-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "quick-mem";
      rev = "4f8df4475ba5a48eaf633885c15f38f13b4f7392";
      flake = false;
    };

    quick-der-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "quick-der";
      rev = "bda3d1e8f6e021778531ab61a434960931dd88a1";
      flake = false;
    };

    lillydap-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "lillydap";
      rev = "7dd28599dad7068d0f373f01f4bb106fd14deca6";
      flake = false;
    };

    leaf-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "leaf";
      rev = "b3861efce0ba143f6eb5451aac5be24f18e6d8ab";
      flake = false;
    };

    quick-sasl-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "quick-sasl";
      rev = "9b7981254e14e53c41a118193ca550d503a46cba";
      flake = false;
    };

    tlspool-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "tlspool";
      rev = "dcfea4f6e504b9109d7f2300261a38d85db05025";
      flake = false;
    };

    tlspool-gui-src = {
      type = "gitlab";
      owner = "arpa2";
      repo = "tlspool-gui";
      rev = "371858d5b19d0d32ef12c13dd1284a9560f47f9d";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      allPackages = [
        "arpa2cm"
        "arpa2common"
        "steamworks"
        "quick-mem"
        "quick-der"
        "lillydap"
        "leaf"
        "quick-sasl"
        "tlspool"
        "tlspool-gui"
      ];

      # BEGIN Helper functions
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
      # END Helper functions
    in {
      overlay = final: prev:
        with final.pkgs; {
          arpa2cm = callPackage ./pkgs/arpa2cm { src = inputs.arpa2cm-src; };
          arpa2common =
            callPackage ./pkgs/arpa2common { src = inputs.arpa2common-src; };
          steamworks =
            callPackage ./pkgs/steamworks { src = inputs.steamworks-src; };
          #steamworks-pulleyback = callPackage ./pkgs/steamworks-pulleyback {
          #  src = inputs.steamworks-pulleyback-src;
          #};
          quick-mem =
            callPackage ./pkgs/quick-mem { src = inputs.quick-mem-src; };
          quick-der =
            callPackage ./pkgs/quick-der { src = inputs.quick-der-src; };
          lillydap = callPackage ./pkgs/lillydap { src = inputs.lillydap-src; };
          leaf = callPackage ./pkgs/leaf { src = inputs.leaf-src; };
          quick-sasl =
            callPackage ./pkgs/quick-sasl { src = inputs.quick-sasl-src; };
          tlspool = callPackage ./pkgs/tlspool { src = inputs.tlspool-src; };
          tlspool-gui = libsForQt5.callPackage ./pkgs/tlspool-gui {
            src = inputs.tlspool-gui-src;
          };
        };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          arpa2cm arpa2common steamworks quick-mem quick-der lillydap leaf
          quick-sasl tlspool tlspool-gui;
      });

      checks = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          arpa2cm arpa2common steamworks quick-mem quick-der lillydap leaf
          quick-sasl tlspool tlspool-gui;
      });
    };
}
