# TODO
# - `npm run generate-local-config-from-env` generates a config to override built-in defaults.
#   Generate this config via module.
{
  lib,
  buildNpmPackage,
  fetchFromGitea,
  fetchFromGitHub,
  fetchNpmDeps,
  tsx,
}:

let
  visual-viewport = fetchFromGitHub {
    owner = "WICG";
    repo = "visual-viewport";
    rev = "44deaba64b1c2c474bf5a4ece07eefa93b2fb028";
    hash = "sha256-uMNqmMBDmz2zmPYjpVuQeCw4DsSm8DYhC33jOpMQj+w=";
  };
in
buildNpmPackage rec {
  pname = "inventaire";
  version = "3.0.1-beta";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "inventaire";
    repo = "inventaire";
    tag = "v${version}";
    hash = "sha256-BKsejw+Q5MwBKGFC4FYlOqb08Q5mJ7l5z/A4kGBA9zU=";
  };

  npmDeps = fetchNpmDeps {
    src = ./.;
    hash = "sha256-Q8pMDDOj3SDjvXHRUbdiKTE9AnzcNYk9paAYTt6t2V0=";
  };

  postPatch = ''
    cp -v ${npmDeps.src}/package-lock.json ./

    patchShebangs scripts

    substituteInPlace scripts/postinstall.sh \
      --replace-fail 'git config' '# git config' \
      --replace-fail 'ln -s ../scripts/githooks' '# ln -s ../scripts/githooks' \
      --replace-fail 'npm run update-i18n' 'echo "[Nix] Taking inventaire-i18n from package-lock.json"' \
      --replace-fail 'npm run build' 'echo "[Nix] Building later"' \
      --replace-fail '[ -e client ] && exit 0' 'echo "[Nix] Always skipping client build" && exit 0' \

    substituteInPlace scripts/update_i18n.sh \
      --replace-fail '  pnpm i' '  echo [Nix] Skipping: pnpm i' \
      --replace-fail '  npm i' '  echo [Nix] Skipping:  npm i' \

    #substituteInPlace scripts/build \
    #  --replace-fail './scripts/check_build_environment.sh' 'echo "[Nix] Not running: ./scripts/check_build_environment.sh"'

    #  --replace-fail \
    #    'curl -sk https://raw.githubusercontent.com/WICG/visual-viewport/44deaba/polyfill/visualViewport.js >> ./vendor/visual_viewport_polyfill.js' \
    #    'cat ${visual-viewport}/polyfill/visualViewport.js >> ./vendor/visual_viewport_polyfill.js' \
    #  --replace-fail 'rm -rf ./node_modules/.cache' '# rm -rf ./node_modules/.cache'
  '';

  makeCacheWritable = true;

  nativeBuildInputs = [
    tsx
  ];

  preBuild = ''
    ls -ahl node_modules/@elastic/elasticsearch/lib/api/types.js
  '';
}
