{
  config,
  pkgs,
  lib,
  ...
}: let
  nodebbDatabase = "nodebb";
  varlibPath = x: "/var/lib/nodebb/" + x;
in {
  services.nodebb = {
    enable = true;

    settings = rec {
      url = "http://127.0.0.1:4560";
      secret = "cookie-sessions-hash-secret"; # not secure, don't use this as-is

      database = "postgres";
      ${database} = {
        host = "localhost";
        port = config.services.postgresql.settings.port;
        password = "nodebb-pw"; # not secure, don't use this as-is
        database = nodebbDatabase;
      };

      logFile = varlibPath "logs/output.log";
      upload_path = varlibPath "uploads";

      # This is only needed for first-time setup, make sure to delete this afterwards!
      setup = let
        self = {
          "admin:username" = "admin";
          "admin:password" = "admin-pw"; # not secure, don't use this as-is
          "admin:email" = "admin@example.org";
        };
      in (builtins.toJSON (self // {"admin:password:confirm" = self.${"admin:password"};}));

      # Nix-added options.
      pidFile = varlibPath "pidfile";
      logDir = varlibPath "logs";
      dataDir = varlibPath "build";
      publicSrcDir = varlibPath "public-src-copy";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [config.services.nodebb.settings.postgres.database];
    ensureUsers = [
      {
        name = "nodebb";
        ensureDBOwnership = nodebbDatabase == "nodebb";
      }
    ];
    authentication = ''
      host ${nodebbDatabase} nodebb all md5
    '';

    # This may need to be done interactively, or merged into an existing script, based on your setup
    initialScript = pkgs.writeText "init-nodebb-postgresql-user" ''
      CREATE USER nodebb PASSWORD '${config.services.nodebb.settings.postgres.password}';
    '';
  };
}
