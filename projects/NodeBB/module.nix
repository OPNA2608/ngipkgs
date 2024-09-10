{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.nodebb;
  settingsFormat = pkgs.formats.json {};
  configFile = settingsFormat.generate "config.json" cfg.settings;
  varlibPath = x: "/var/lib/nodebb/" + x;
in {
  options.services.nodebb = {
    enable = lib.mkEnableOption ''
      NodeBB, the forum software built for the modern web
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodebb;
      defaultText = lib.literalExpression "pkgs.nodebb";
      description = "NodeBB package to use.";
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      example = {
        url = "http://127.0.0.1:4560";
        secret = "cookie-sessions-hash-secret";
        database = "postgres";
        postgres = {
          host = "127.0.0.1";
          port = "4561";
          password = "nodebb-pw";
          database = "nodebb-db";
        };

        logFile = varlibPath "logs/output.log";
        upload_path = varlibPath "uploads";
      };
      description = ''
        Configuration for NodeBB, see
        <link xlink:href="https://docs.nodebb.org/configuring/config" />
        for supported settings.
      '';
    };

    waitForDatabaseService = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        {
          postgres = "postgresql.service";
          mongo = "mongodb.service";
          # Redis setup is not straight-forward, cannot assume name
        }
        .${cfg.settings.database}
        or null;
    };
  };

  config = let
    mkNodeBBService = configured: let
      configuredMarker = varlibPath ".is-nix-configured";
    in
      {
        description = "Management of declaratively configured NodeBB${
          lib.optionalString (!configured) " (initial)"
        }";

        wantedBy = ["multi-user.target"];

        script = lib.getExe (
          pkgs.writeShellApplication {
            name = "nodebb${lib.optionalString (!configured) "-initial"}-script";

            runtimeInputs = [cfg.package] ++ (with pkgs; []);

            text =
              ''
                set -euo pipefail

              ''
              + lib.optionalString (!configured) ''
                cp --no-preserve=all ${configFile} ${varlibPath "config.json"}
                nodebb setup --config=${varlibPath "config.json"}
                touch ${configuredMarker}
              ''
              + ''

                nodebb start --config=${varlibPath "config.json"}
              '';
          }
        );

        serviceConfig = {
          ExecCondition = "${pkgs.coreutils}/bin/test ${
            lib.optionalString (!configured) "!"
          } -f ${configuredMarker}";

          Type = "oneshot";
          WorkingDirectory = cfg.package;
          ReadWritePaths = [(varlibPath "")];

          # User and group
          User = "nodebb";
          Group = "nodebb";
        };
      }
      // lib.optionalAttrs (config.services.nodebb.waitForDatabaseService != null) {
        requires = [config.services.nodebb.waitForDatabaseService];
        after = [config.services.nodebb.waitForDatabaseService];
      };
  in {
    systemd.services = {
      nodebb-initial = mkNodeBBService false;
      nodebb = mkNodeBBService true;
    };

    users.users.nodebb = {
      isNormalUser = true;
      description = "NodeBB user";
      group = "nodebb";
      home = varlibPath "";
    };
    users.groups.nodebb = {};
  };

  meta.maintainers = [];
}
