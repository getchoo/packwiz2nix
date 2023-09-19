{
  lib,
  stdenvNoCC,
  zip,
  strip-nondeterminism,
  packwiz-installer-bootstrap,
}: {
  pname ? null,
  version ? "",
  src ? null,
  extraFiles ? {},
  instanceCfg,
  ...
} @ args:
stdenvNoCC.mkDerivation (finalAttrs:
    {
      pname = src.pname or pname;
      version = src.version or version;

      dontUnpack = true;
      dontConfig = true;
      dontBuild = true;

      nativeBuildInputs = [zip];

      installPhase = let
        modpackFiles =
          {
            "packwiz-installer-bootstrap.jar" = packwiz-installer-bootstrap;
            "instance.cfg" = instanceCfg;
          }
          // extraFiles;
      in
        ''
          runHook preInstall

          mkdir -p $out
          tmp="$(mktemp -d)"
        ''
        + (lib.concatLines (
          lib.mapAttrsToList
          (name: file: ''
            mkdir -p "$tmp"/"$(dirname ${name})"
            cp -as ${file} "$tmp"/${name}
          '')
          modpackFiles
        ))
        + ''
				  cd "$tmp"
          zip -r $out/${finalAttrs.pname}-${finalAttrs.version}.zip {*,.*}

          ${lib.getExe strip-nondeterminism} $out/${finalAttrs.pname}-${finalAttrs.version}.zip
        '';
    }
    // args)
