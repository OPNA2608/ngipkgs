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

    # tsc is not happy with the way all of these elasticsearch types get imported

    substituteInPlace server/controllers/items/lib/search_users_items.ts \
      --replace-fail \
        "import type { QueryDslBoolQuery, QueryDslQueryContainer } from '@elastic/elasticsearch/lib/api/types.js'" \
        "import type { estypes } from '@elastic/elasticsearch'" \
      --replace-fail 'QueryDslBoolQuery' 'estypes.QueryDslBoolQuery' \
      --replace-fail 'QueryDslQueryContainer' 'estypes.QueryDslQueryContainer' \

    substituteInPlace server/controllers/search/lib/social_query_builder.ts \
      --replace-fail \
        "import type { QueryDslQueryContainer, SearchRequest } from '@elastic/elasticsearch/lib/api/types.js'" \
        "import type { estypes } from '@elastic/elasticsearch'" \
      --replace-fail 'QueryDslQueryContainer' 'estypes.QueryDslQueryContainer' \
      --replace-fail 'SearchRequest' 'estypes.SearchRequest' \

    substituteInPlace server/lib/elasticsearch.ts \
      --replace-fail \
        "import type { SearchRequest, SearchResponse, SearchHitsMetadata } from '@elastic/elasticsearch/lib/api/types.js'" \
        "import type { estypes } from '@elastic/elasticsearch'" \
      --replace-fail 'SearchRequest' 'estypes.SearchRequest' \
      --replace-fail 'SearchResponse' 'estypes.SearchResponse' \
      --replace-fail 'SearchHitsMetadata' 'estypes.SearchHitsMetadata' \

    substituteInPlace server/lib/search_by_distance.ts \
      --replace-fail \
        "import type { SearchRequest } from '@elastic/elasticsearch/lib/api/types.js'" \
        "import type { estypes } from '@elastic/elasticsearch'" \
      --replace-fail 'SearchRequest' 'estypes.SearchRequest' \

    substituteInPlace server/lib/search_by_position.ts \
      --replace-fail \
        "import type { SearchRequest } from '@elastic/elasticsearch/lib/api/types.js'" \
        "import type { estypes } from '@elastic/elasticsearch'" \
      --replace-fail 'SearchRequest' 'estypes.SearchRequest' \
  '';

  makeCacheWritable = true;

  nativeBuildInputs = [
    tsx
  ];

  buildInputs = [
    tsx
  ];

  postInstall = ''
    cp -r dist $out/lib/node_modules/inventaire/

    # Fix borked symlinks
    for candidate in $out/lib/node_modules/inventaire/dist/*; do
      if [ -L "$candidate" ]; then
        linkName="$(basename "$candidate")"
        rm "$candidate"
        if [ -e "$(dirname "$candidate")/../''${linkName}" ]; then
          ln -vs ../"$linkName" "$candidate"
        else
          mkdir "$candidate"
        fi
      fi
    done

    # Launcher
    mkdir -p $out/bin
    cat <<EOF >$out/bin/inventaire
    #!/bin/sh

    ${lib.getExe tsx} $out/lib/node_modules/inventaire/dist/server/server.js
    EOF
    chmod +x $out/bin/inventaire
  '';
}
