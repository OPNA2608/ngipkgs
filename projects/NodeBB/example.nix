{
  config,
  pkgs,
  lib,
  ...
}: let
  nodebbDatabaseName = "nodebb";
  nodebbDatabasePassword = "nodebb-pw";
  generateJsonFile = (pkgs.formats.json {}).generate;
  varlibPath = x: "/var/lib/nodebb/" + x;
in {
  services.nodebb = {
    enable = true;

    # This is NOT secure! Consider using a secrets management mechanism instead.
    settings = generateJsonFile "config.json" rec {
      url = "http://127.0.0.1:4560";
      secret = "cookie-sessions-hash-secret"; # not secure, don't use this as-is

      database = "postgres";
      ${database} = {
        host = "localhost";
        port = config.services.postgresql.settings.port;
        database = nodebbDatabaseName;
        password = nodebbDatabasePassword; # not secure, don't use this as-is
      };

      logFile = varlibPath "logs/output.log";
      upload_path = varlibPath "uploads";

      # Nix-added options.
      pidFile = varlibPath "pidfile";
      logDir = varlibPath "logs";
      dataDir = varlibPath "build";
      publicSrcDir = varlibPath "public-src-copy";
    };

    # This is NOT secure! Consider using a secrets management mechanism instead.
    setupSettings = let
      self = {
        "admin:username" = "admin";
        "admin:password" = "admin-pw"; # not secure, don't use this as-is
        "admin:email" = "admin@example.org";
      };
    in
      generateJsonFile "setup.json" (self // {"admin:password:confirm" = self.${"admin:password"};});

    waitForDatabaseService = "postgresql";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [nodebbDatabaseName];
    ensureUsers = [
      {
        name = "nodebb";
        ensureDBOwnership = nodebbDatabaseName == "nodebb";
      }
    ];
    authentication = ''
      host ${nodebbDatabaseName} nodebb all md5
    '';

    # This is NOT secure! Consider doing this interactively instead.
    # This may need to be done interactively, or merged into an existing script, based on your setup & database choice.
    initialScript = pkgs.writeText "init-nodebb-postgresql-user" ''
      CREATE USER nodebb PASSWORD '${nodebbDatabasePassword}';
    '';
  };
}
