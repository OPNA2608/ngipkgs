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

      virtualisation.memorySize = 2047;

      # Need an actual logged-in user to test with
      users.users.alice = {
        description = "Alice Foobar";
        password = "foobar";
        isNormalUser = true;
        extraGroups = ["wheel"];
        uid = 1000;
      };

      services.xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
        windowManager.icewm.enable = true;
      };

      # Automatic log-in
      services.displayManager = {
        defaultSession = "none+icewm";
        autoLogin = {
          enable = true;
          user = "alice";
        };
      };

      environment.systemPackages = with pkgs; [
        firefox
      ];
    };
  };

  testScript = {nodes, ...}: ''
    start_all()

    server.sleep(120)
  '';
}
