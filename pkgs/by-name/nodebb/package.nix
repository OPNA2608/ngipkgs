{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  pkg-config,
  vips,
  writeText,
}:
buildNpmPackage rec {
  pname = "nodebb";
  version = "3.8.4";

  src = fetchFromGitHub {
    owner = "NodeBB";
    repo = "NodeBB";
    rev = "refs/tags/v${version}";
    hash = "sha256-ejvFtTLSnh6YUOGNj1Py+WQsLYh4gEf9Q2ZYvaVDqQ8=";
  };

  npmDepsHash = "sha256-9jLAYTiZqhgolDnAvRbyxsaEfq4qNr4/sdZ2a+sea4s=";

  postPatch = ''
    ln -s install/package.json
    cp ${./package-lock.json} ./package-lock.json

    patchShebangs nodebb

    # Doesn't allow to change logging location, introduce custom option
    substituteInPlace install/web.js \
      --replace-fail "filename: 'logs/webinstall.log'" "filename: path.join(nconf.get('logDir') || (path.join('.', 'logs')), 'webinstall.log')"

    # Actually signal failure when automatic setup failed
    substituteInPlace src/install.js \
      --replace-fail 'process.exit()' 'process.exit(1)' \
      --replace-fail "ignoring setup values from json'" "ignoring setup values from json: ' + err.message"
  '';

  # Patch embedded sass compilers in node dependencies
  preConfigure = ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(find node_modules -type f -executable -path '*/dart-sass/src/dart')
  '';

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    vips
  ];

  /*
  env = {
    NODEBB_ADMIN_USERNAME = "admin";
    NODEBB_ADMIN_PASSWORD = "password123";
    NODEBB_ADMIN_EMAIL = "root@localhost";
  };

  buildPhase = ''
    runHook preConfigure

    ./nodebb setup

    runHook postConfigure
  '';
  */

  dontBuild = true;

  postInstall = ''
    install -m644 install/package.json $out/lib/node_modules/nodebb/package.json

    mkdir -p $out/bin
    ln -s $out/lib/node_modules/nodebb/nodebb $out/bin/nodebb
  '';

  # TODO meta
}
