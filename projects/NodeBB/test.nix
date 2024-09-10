{
  sources,
  pkgs,
  lib,
  ...
}: {
  name = "nodebb";

  nodes = {
    server = {config, ...}: {
      imports = [
        sources.modules.default
        sources.modules."services.nodebb"
        sources.examples."NodeBB/base"
      ];
    };
  };

  testScript = {nodes, ...}: ''
    start_all()
  '';
}
