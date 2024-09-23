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

    # Upstream doesn't create lockfile
    cp ${./package-lock.json} ./package-lock.json

    patchShebangs nodebb

    # Doesn't allow to change logging location, introduce custom option
    substituteInPlace install/web.js \
      --replace-fail "filename: 'logs/webinstall.log'" "filename: path.join(nconf.get('logDir') || (path.join('.', 'logs')), 'webinstall.log')"

    # Doesn't allow to change pidfile location, introduce custom option
    substituteInPlace loader.js \
      --replace-fail "path.join(__dirname, 'pidfile')" "nconf.get('pidFile') || path.join(__dirname, 'pidfile')"

    # Many places want to write runtime data into build output, introduce custom option for redirecting to config-defined location

    substituteInPlace src/meta/cacheBuster.js src/meta/js.js src/languages.js webpack.installer.js test/emailer.js test/build.js \
      --replace-fail "'use strict';" "'use strict'; const nconf = require('nconf');"

    substituteInPlace src/meta/cacheBuster.js src/meta/build.js src/meta/js.js src/meta/css.js src/routes/meta.js src/routes/index.js test/mocks/databasemock.js \
      --replace-fail "path.join(__dirname, '../../build/" "path.join(nconf.get('dataDir') || (path.join(__dirname, '../../build')), '"

    substituteInPlace src/meta/js.js \
      --replace-fail "path.join(__dirname, \`../../build/" "path.join(nconf.get('dataDir') || (path.join(__dirname, '../../build')), \`"

    substituteInPlace src/languages.js test/emailer.js test/build.js install/web.js \
      --replace-fail "path.join(__dirname, '../build/" "path.join(nconf.get('dataDir') || (path.join(__dirname, '../build')), '"

    substituteInPlace install/web.js src/prestart.js src/meta/languages.js \
      --replace-fail "path.join(paths.baseDir, 'build/" "path.join(nconf.get('dataDir') || (path.join(paths.baseDir, 'build')), '"

    substituteInPlace src/meta/build.js \
      --replace-fail "path.resolve(__dirname, '../../build/" "path.resolve(nconf.get('dataDir') || (path.join(__dirname, '../../build')), '"

    substituteInPlace webpack.installer.js \
      --replace-fail "path.resolve(__dirname, 'build/" "path.resolve(nconf.get('dataDir') || (path.join(__dirname, 'build')), '"

    substituteInPlace webpack.common.js \
      --replace-fail "'./build/active_plugins.json'" "path.join(nconf.get('dataDir') || (path.join(__dirname, 'build')), 'active_plugins.json')" \
      --replace-fail "'./build/public/src/client.js'" "path.join(nconf.get('dataDir') || (path.join(__dirname, 'build')), 'public/src/client.js')" \
      --replace-fail "'./build/public/src/admin/admin.js'" "path.join(nconf.get('dataDir') || (path.join(__dirname, 'build')), 'public/src/admin/admin.js')" \
      --replace-fail "'build/public/src/modules'" "path.join(nconf.get('dataDir') || (path.join(__dirname, 'build')), 'public/src/modules')" \
      --replace-fail "'build/public/src'" "path.join(nconf.get('dataDir') || (path.join(__dirname, 'build')), 'public/src')" \

    # When this copies from the store, it applies its 505 permissions before creating subdirs. Permission-normalised copy provided by module
    substituteInPlace src/meta/js.js \
      --replace-fail "path.join(__dirname, \`../../public/src\`)" "nconf.get('publicSrcDir') || (path.join(__dirname, '../../public/src'))"

    # Correct permissions copied from store, so subsequent copies don't fail
    substituteInPlace src/meta/css.js \
      --replace-fail \
      "fs.promises.copyFile(path.join(fonts.path, file.name), path.join(nconf.get('dataDir') || (path.join(__dirname, '../../build')), 'public/fontawesome/webfonts/', file.name))" \
      "fs.promises.copyFile(path.join(fonts.path, file.name), path.join(nconf.get('dataDir') || (path.join(__dirname, '../../build')), 'public/fontawesome/webfonts/', file.name)).then(async function() { return fs.promises.chmod(path.join(nconf.get('dataDir') || (path.join(__dirname, '../../build')), 'public/fontawesome/webfonts/', file.name), '600'); })"

    # Don't force logFile to be within build output dir
    substituteInPlace loader.js \
      --replace-fail "path.join(__dirname, nconf.get('logFile') || 'logs/output.log')" "nconf.get('logFile') || path.join(__dirname, 'logs/output.log')"

    # Also use new variables as application-wide constants (when they're actually used)
    # And use config when passed
    substituteInPlace src/constants.js \
      --replace-fail "path.join(baseDir, 'pidfile')" "nconf.get('pidFile') || path.join(baseDir, 'pidfile')" \
      --replace-fail "path.join(baseDir, 'config.json')" "nconf.get('config') || path.join(baseDir, 'config.json')" \

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
