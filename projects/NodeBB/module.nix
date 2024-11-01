{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.nodebb;
  settingsFormat = pkgs.formats.json {};
  varlibPath = x: "/var/lib/nodebb/" + x;
  setupConv = setupSettings: lib.strings.escapeShellArg (builtins.toJSON setupSettings);
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
      type = lib.types.path;
      example = "/etc/my-secrets/nodebb-base-config.json";
      description = ''
        Initial configuration for NodeBB, see
        <link xlink:href="https://docs.nodebb.org/configuring/config" />
        for supported base settings.

        Must be a string with a path to a JSON file, whose contents will be read at runtime.

        Warning: Custom settings for internal functions that you need to set (support for these is patched into NodeBB via
        the Nix packaging):
        - pidFile: A file where the pid of the currently-running NodeBB instance is kept & tracked
        - logDir: A directory where NodeBB can write its log files into
        - dataDir: A directory where NodeBB can write its runtime-produced data files into
        - publicSrcDir: A directory where NodeBB can put/use a read-writable copy of its public/src directory in/from

        Warning: Due to NodeBB rewriting its own config during initial setup, any changes to this option will not be applied
        to NodeBB once the service has been successfully set up once at runtime.
        Please resort to manually managing NodeBB's ${varlibPath "config.json"} at that point!
      '';
    };

    setupSettings = lib.mkOption rec {
      type = lib.types.path; # path, either to a file for copying into the store or a string with a path that will exist at runtime
      example = "/etc/my-secrets/nodebb-setup-config.json";
      description = ''
        Admin settings only needed for the automatic first-time setup of NodeBB.

        Must be a string with a path to a file, whose contents will be read at runtime.

        For example, the file is expected to contain something like the following:
        ${setupConv {
          "admin:username" = "admin";
          "admin:password" = "admin-pw";
          "admin:password:confirm" = "admin-pw";
          "admin:email" = "admin@example.org";
        }}
      '';
    };

    waitForDatabaseService = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "postgresql";
      description = ''
        A systemd unit for the used database type that must be running before NodeBB is launched. ".service" is automatically
        appended to the specified name.

        If null, not waiting for another service.
      '';
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

        path = [cfg.package] ++ (with pkgs; [jq]);

        script =
          ''
            set -euo pipefail

            # Expected to exist
            mkdir -p "$(jq -r ".upload_path" "${cfg.settings}")"/{category,files,profile,sounds,system}

            # User-writable copy of <nodebb>/lib/node_modules/nodebb/public/src, so copying it doesn't error out on store's missing write perms
            rm -rf "$(jq -r ".publicSrcDir" "${cfg.settings}")"
            cp -R --no-preserve=all ${cfg.package}/lib/node_modules/nodebb/public/src "$(jq -r ".publicSrcDir" "${cfg.settings}")"

            # Needed for webpack to be happy(?)
            rm -f ${varlibPath "node_modules"}
            ln -s ${cfg.package}/lib/node_modules/nodebb/node_modules ${varlibPath "node_modules"}
          ''
          + lib.optionalString (!configured) ''
            # Only use for initial setup, will immediately get overwritten
            cp --no-preserve=all "${cfg.settings}" ${varlibPath "config.json"}

            env setup="$(cat "${cfg.setupSettings}")" nodebb --config=${varlibPath "config.json"} -d -l setup

            touch ${configuredMarker}
          ''
          + ''

            nodebb --config=${varlibPath "config.json"} -d start &
          '';

        serviceConfig = {
          ExecCondition = "${pkgs.coreutils}/bin/test ${
            lib.optionalString (!configured) "!"
          } -f ${configuredMarker}";

          Type = "forking";
          WorkingDirectory = cfg.package;
          ReadWritePaths = [(varlibPath "")];

          # User and group
          User = "nodebb";
          Group = "nodebb";
        };
      }
      // lib.optionalAttrs (config.services.nodebb.waitForDatabaseService != null) (
        let
          serviceName = "${config.services.nodebb.waitForDatabaseService}.service";
        in {
          requires = [serviceName];
          after = [serviceName];
        }
      );
  in
    lib.mkIf cfg.enable {
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
