final: _prev: {
  awesome-git = final.callPackage (
    {
      pkgs,
      fetchurl,
      lua ? pkgs.lua5_3,
      ...
    }:
    let
      inherit (pkgs)
        asciidoctor
        cairo
        cmake
        dbus
        docbook_xml_dtd_45
        docbook_xsl
        doxygen
        findXMLCatalogs
        gdk-pixbuf
        git
        gobject-introspection
        gtk3
        hicolor-icon-theme
        imagemagick
        libpthread-stubs
        librsvg
        libstartup_notification
        libxau
        libxcb
        libxcb-cursor
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libxcb-util
        libxcb-wm
        libxdg_basedir
        libxdmcp
        libxkbcommon
        libxshmfence
        makeFontsConf
        makeWrapper
        net-tools
        pango
        pkg-config
        stdenv
        which
        xcbutilxrm
        xmlto
        ;
      rev = "0f4b74f70c7da8dbb536865850e44d17f179b4b5";
      luaEnv = lua.withPackages (ps: [
        ps.lgi
        ps.ldoc
        ps.cjson
        ps.luafilesystem
        ps.http
      ]);
      src = fetchurl {
        url = "https://git.tatikoma.dev/corpix/awesomewm/archive/${rev}.tar.gz";
        hash = "sha256-Wb317l8NpTSi0je66o6XV+jaObmv+Sm+qck0oBKbVYI=";
      };
    in
    stdenv.mkDerivation rec {
      pname = "awesome";
      version = "git-${builtins.substring 0 7 rev}";

      inherit src;

      nativeBuildInputs = [
        cmake
        doxygen
        imagemagick
        makeWrapper
        pkg-config
        xmlto
        docbook_xml_dtd_45
        docbook_xsl
        findXMLCatalogs
        asciidoctor
        gobject-introspection
        git
      ];

      buildInputs = [
        cairo
        librsvg
        dbus
        gdk-pixbuf
        luaEnv
        libpthread-stubs
        libstartup_notification
        libxdg_basedir
        net-tools
        pango
        libxcb-cursor
        libxau
        libxdmcp
        libxcb
        libxshmfence
        libxcb-util
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
        libxcb-wm
        libxkbcommon
        xcbutilxrm
        hicolor-icon-theme
        gtk3
      ]
      ++ [ lua ];

      cmakeFlags = [
        "-DOVERRIDE_VERSION=${version}"
        "-DLUA_LIBRARY=${lua}/lib/liblua.so"
        "-DLUA_INCLUDE_DIR=${lua}/include"
      ];

      GI_TYPELIB_PATH = "${pango.out}/lib/girepository-1.0";
      LUA_CPATH = "${luaEnv}/lib/lua/${lua.luaversion}/?.so";
      LUA_PATH = "${luaEnv}/share/lua/${lua.luaversion}/?.lua;;";

      FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ ]; };

      postPatch = ''
        patchShebangs tests/examples/_postprocess.lua
      '';

      postInstall = ''
        mv "$out/bin/awesome" "$out/bin/.awesome-wrapped"
        makeWrapper "$out/bin/.awesome-wrapped" "$out/bin/awesome" \
          --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
          --add-flags '--search ${luaEnv}/lib/lua/${lua.luaversion}' \
          --add-flags '--search ${luaEnv}/share/lua/${lua.luaversion}' \
          --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH"
        wrapProgram $out/bin/awesome-client \
          --prefix PATH : "${which}/bin"
      '';
    }
  ) { };
}
