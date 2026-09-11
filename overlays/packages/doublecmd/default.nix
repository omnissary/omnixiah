self: super: {
  doublecmd = super.doublecmd.overrideAttrs (oldAttrs: {
    version = "cfaadc34";

    src = super.fetchurl {
      url = "https://git.tatikoma.dev/corpix/doublecmd/archive/cfaadc346f5f1042369fcf9b983c503f3356b402.tar.gz";
      hash = "sha256-RzZzFGuOqK9xWu1Z+ooUiedEI5iT5TsXzyrRINwlSpk=";
    };

    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace plugins/wcx/sevenzip/src/platform/sevenziphlp.pas \
        --replace-fail "'/usr/lib/7zip/'" "'${super.p7zip.lib}/lib/p7zip/'"
      substituteInPlace plugins/wcx/sevenzip/src/platform/unix/activex.pas \
        --replace-fail '{.$define Z7_USE_VIRTUAL_DESTRUCTOR_IN_IUNKNOWN}' '{$define Z7_USE_VIRTUAL_DESTRUCTOR_IN_IUNKNOWN}'
    '';

    postBuild = (oldAttrs.postBuild or "") + ''
      dcLazbuild() {
        lazbuild \
          --lazarusdir=${super.lazarus}/share/lazarus \
          --widgetset=qt5 \
          "$@"
      }

      dcLazbuild plugins/wcx/torrent/src/torrent.lpi
      dcLazbuild plugins/wdx/textline/src/TextLine.lpi

      echo "=== produced plugin artifacts ==="
      find plugins -type f \
        \( -name '*.wcx' -o -name '*.wdx' -o -name '*.wfx' \
           -o -name '*.wlx' -o -name '*.dsx' \) -print | sort
      echo "================================="
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      pluginDir=$(echo "$out"/lib*/doublecmd/plugins)

      while IFS= read -r artifact; do
        base=$(basename "$artifact")
        ext=''${base##*.}
        name=''${base%.*}
        if [ -z "$(find "$pluginDir/$ext" -name "$base" 2>/dev/null)" ]; then
          echo "installing missing plugin: $base -> $pluginDir/$ext/$name/"
          install -Dm644 "$artifact" "$pluginDir/$ext/$name/$base"
        fi
      done < <(find plugins -type f \
        \( -name '*.wcx' -o -name '*.wdx' -o -name '*.wfx' \
           -o -name '*.wlx' -o -name '*.dsx' \))
    '';

    preFixup =
      (oldAttrs.preFixup or "")
      + ''
        qtWrapperArgs+=(
          --prefix LD_LIBRARY_PATH : ${
            super.lib.makeLibraryPath [
              super.libssh2
              super.openssl
            ]
          }
          --prefix PATH : ${super.lib.makeBinPath [ super.aria2 ]}
        )
      ''
      + super.lib.optionalString super.config.allowUnfree ''
        qtWrapperArgs+=(
          --prefix LD_LIBRARY_PATH : ${super.lib.makeLibraryPath [ self.unrar ]}
        )
      '';
  });
}
