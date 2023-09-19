{
  lib,
  stdenvNoCC,
  fetchurl,
  packwiz-installer-bootstrap,
  packwiz-installer,
  jre_headless,
  jq,
  moreutils,
  curl,
  cacert,
}: let
  fetchPackwizModpack = {
    pname ? "packwiz-pack",
    version ? "",
    url ? null,
    hash ? "",
    # Either 'server' or 'both' (to get client mods as well)
    side ? "server",
    # The derivation passes through a 'manifest' expression, that includes
    # useful metadata (such as MC version). When providing the manifest file itself,
    # this metadata can be used to automatically assign 'pname' and 'version'
    #
    # By default, if you access the 'manifest' expression, IFD will be used.
    # If you want to use 'manifest' without IFD or a manifest file, you can
    # also pass a manifestHash, which allows us to fetch it with
    # builtins.fetchurl instead.
    manifest ? null,
    manifestHash ? null,
    useManifest ? manifest != null,
    ...
  } @ args:
    assert lib.assertMsg (url == null -> manifest != null) "a url or manifest must be provided!";
      stdenvNoCC.mkDerivation (finalAttrs:
        {
          pname =
            if useManifest
            then finalAttrs.passthru.manifest.name
            else pname;

          version =
            if useManifest
            then finalAttrs.passthru.manifest.version
            else version;

          dontUnpack = true;

          buildInputs = [jre_headless jq moreutils curl cacert];

          buildPhase = ''
            ${lib.optionalString (!useManifest) "curl -L \"${url}\" > pack.toml"}

            java -jar ${packwiz-installer-bootstrap} \
              --bootstrap-main-jar ${packwiz-installer} \
              --bootstrap-no-update \
              --no-gui \
              --side ${side} \
              "${
              if useManifest
              then manifest
              else url
            }"
          '';

          installPhase = ''
            runHook preInstall

            # Fix non-determinism
            rm env-vars -r
            jq -Sc '.' packwiz.json | sponge packwiz.json

            mkdir -p $out
            cp * -r $out/

            runHook postInstall
          '';

          passthru = let
            drv = fetchPackwizModpack args;
          in {
            # Pack manifest as a nix expression
            # If manifestHash is not null or the manifest is directly provided,
            # then we can do this without IFD.
            # Otherwise, fallback to IFD.
            manifest = lib.importTOML (
              if manifestHash != null
              then
                builtins.fetchurl
                {
                  inherit url;
                  sha256 = manifestHash;
                }
              else if useManifest
              then manifest
              else "${drv}/pack.toml"
            );

            # Adds an attribute set of files to the derivation.
            # Useful to add server-specific mods not part of the pack.
            addFiles = files:
              stdenvNoCC.mkDerivation {
                inherit (drv) pname version;
                src = null;
                dontUnpack = true;
                dontConfig = true;
                dontBuild = true;
                dontFixup = true;

                installPhase =
                  ''
                    cp -as "${drv}" $out
                    chmod u+w -R $out
                  ''
                  + lib.concatLines (
                    lib.mapAttrsToList
                    (name: file: ''
                      mkdir -p "$out/$(dirname "${name}")"
                      cp -as "${file}" "$out/${name}"
                    '')
                    files
                  );

                passthru = {inherit (drv) manifest;};
                meta = drv.meta or {};
              };
          };

          dontFixup = true;

          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = hash;
        }
        // args);
in
  fetchPackwizModpack
