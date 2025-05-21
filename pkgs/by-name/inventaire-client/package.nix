{
  lib,
  buildNpmPackage,
  fetchFromGitea,
  fetchFromGitHub,
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
  pname = "inventaire-client";
  version = "3.0.1-beta";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "inventaire";
    repo = "inventaire-client";
    tag = "v${version}";
    hash = "sha256-Ores7/dQXRVDIW3Namqe4Qpa9PXoeI6ntA1z5eLaGoU=";
  };

  npmDepsHash = "sha256-KzjrX21pnIjOlqYGn+4AGq1vI0BXXVDvRDpp4N5PDgg=";

  postPatch = ''
    patchShebangs scripts

    substituteInPlace scripts/postinstall \
      --replace-fail 'git config' '# git config' \
      --replace-fail \
        'curl -sk https://raw.githubusercontent.com/WICG/visual-viewport/44deaba/polyfill/visualViewport.js >> ./vendor/visual_viewport_polyfill.js' \
        'cat ${visual-viewport}/polyfill/visualViewport.js >> ./vendor/visual_viewport_polyfill.js' \
      --replace-fail 'ln -s ../scripts/githooks' '# ln -s ../scripts/githooks'
      --replace-fail 'rm -rf ./node_modules/.cache' '# rm -rf ./node_modules/.cache'

    substituteInPlace scripts/build \
      --replace-fail './scripts/check_build_environment.sh' 'echo "[Nix] Not running: ./scripts/check_build_environment.sh"'
  '';

  makeCacheWritable = true;
  #npmFlags = [ "--loglevel=verbose" ];
}
