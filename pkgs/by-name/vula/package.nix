{
  lib,
  python3,
  fetchgit,
  highctidh,
  wrapGAppsHook,
}: let
  inherit
    (lib)
    licenses
    maintainers
    ;
in
  python3.pkgs.buildPythonApplication {
    pname = "vula";
    version = "unstable-2024-05-17";

    src = fetchgit {
      url = "https://codeberg.org/vula/vula";
      rev = "b82933c2d45496afb91727e7ce3dff61ae262473";
      hash = "sha256-DVjEg28GFmA3fOgXZ8MQ7rwfZtt6WkK1qHnyTnYbKcY=";
    };

    # without removing `pyproject.toml` we don't end up with an executable.
    postPatch = ''
      rm pyproject.toml
      substituteInPlace vula/frontend/constants.py \
        --replace "IMAGE_BASE_PATH = '/usr/share/icons/vula/'" "IMAGE_BASE_PATH = '$out/${python3.sitePackages}/usr/share/icons/'"
    '';

    propagatedBuildInputs =
      (with python3.pkgs; [
        click
        cryptography
        hkdf
        packaging
        pillow
        pydbus
        pynacl
        pyroute2
        pyyaml
        qrcode
        schema
        tkinter
        zeroconf
      ])
      ++ [highctidh];

    nativeBuildInputs = [wrapGAppsHook];
    nativeCheckInputs = with python3.pkgs; [pytestCheckHook];

    #postInstall = ''
    #  mkdir -p $out/share/icons
    #  cp -r $src/misc/images/*.png $out/share/icons
    #'';

    meta = {
      description = "Automatic local network encryption";
      homepage = "https://vula.link/";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [lorenzleutgeb mightyiam stepbrobd];
      mainProgram = "vula";
    };
  }
