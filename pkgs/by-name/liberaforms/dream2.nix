{
  lib,
  config,
  dream2nix,
  ...
}:
# TODO: migrate away from dream2nix
# https://github.com/ngi-nix/ngipkgs/issues/1125
let
  version = "3.1.1";
  src = config.deps.fetchFromGitLab {
    owner = "liberaforms";
    repo = "liberaforms";
    rev = "v${version}";
    hash = "sha256-RpEaO/3jje/ABdIGrnBo1sYPHpuUuDfe4uuJON9RiqY=";
  };

  # Python dependencies need an explicit format
  # https://github.com/NixOS/nixpkgs/pull/421660
  pyprojectOverrides =
    lib.genAttrs
      [
        "markupsafe"
        "feedgen"
        "pyqrcode"
        "sqlalchemy-json"
        "typed-ast"
        "unicodecsv"
      ]
      (name: {
        buildPythonPackage.pyproject = true;
      });
in
{
  imports = [ dream2nix.modules.dream2nix.pip ];

  deps =
    { nixpkgs, ... }:
    {
      inherit (nixpkgs)
        fetchFromGitLab
        file
        libxml2
        libxslt
        postgresql
        postgresqlTestHook
        runCommand
        replaceVars
        ;
      python = nixpkgs.python311;
    };

  name = "liberaforms";
  inherit version;

  buildPythonPackage.format = "other";

  mkDerivation = {
    inherit src;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      cp -R ${src}/. $out

      runHook postInstall
    '';

    doCheck = true;

    nativeCheckInputs = [
      config.deps.postgresql
      config.deps.postgresqlTestHook
      config.public.env
    ];

    preCheck = ''
      export LANG=C.UTF-8
      export PGUSER=db_user
      export postgresqlEnableTCP=1
    '';

    checkPhase = ''
      runHook preCheck

      # Run pytest on the installed version. A running postgres database server is needed.
      (cd tests && cp test.ini.example test.ini && pytest -k "not test_save_smtp_config") #TODO why does this break?

      runHook postCheck
    '';

    # avoid writing in the migration process
    postFixup = ''
      cp $out/assets/brand/logo-default.png $out/assets/brand/logo.png
      cp $out/assets/brand/favicon-default.ico $out/assets/brand/favicon.ico
      sed -i "/shutil.copyfile/d" $out/liberaforms/models/site.py
      sed -i "/brand_dir/d" $out/migrations/versions/6f0e2b9e9db3_.py
    '';
  };

  public = {
    env = config.public.pyEnv;
    meta = {
      description = "Free form software";
      homepage = "https://gitlab.com/liberaforms/liberaforms";
      license = lib.licenses.agpl3Plus;
      platforms = lib.platforms.all;
    };
  };

  pip = {
    requirementsFiles = [ "${src}/requirements.txt" ];
    requirementsList = [
      "factory-boy"
      "faker"
      "polib"
      "pytest-dotenv"
    ];
    nativeBuildInputs = [
      config.deps.postgresql
      config.deps.libxml2.dev
      config.deps.libxslt.dev
    ];
    pipFlags = [
      "--no-binary"
      "python-magic"
    ];
    overrides = {
      lxml = {
        mkDerivation = {
          nativeBuildInputs = [
            config.deps.libxml2.dev
            config.deps.libxslt.dev
          ];
        };
      };
      python-magic = {
        buildPythonPackage.pyproject = true;
        mkDerivation = {
          patches = [
            (config.deps.replaceVars ./libmagic-path.patch {
              libmagic = "${config.deps.file}/lib/libmagic.so";
            })
          ];
        };
      };
      flask-session2 = {
        mkDerivation = {
          dontBuild = true;
        };
      };
    }
    // pyprojectOverrides;
    flattenDependencies = true;
  };

  paths.lockFile = lib.mkForce "../lock.json";
}
