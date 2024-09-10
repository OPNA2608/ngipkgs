{
  pkgs,
  lib,
  sources,
} @ args: {
  packages = {
    inherit (pkgs) nodebb;
  };
  nixos = {
    modules.services.nodebb = ./module.nix;
    tests.nodebb = import ./test.nix args;
    examples = {
      base = {
        description = "Basic configuration.";
        path = ./example.nix;
      };
    };
  };
}
