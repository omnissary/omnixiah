_self: super: {
  jailer = super.jailer.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ super.postgresql_jdbc ];

    postFixup = (old.postFixup or "") + ''
      cat > $out/bin/jailer <<EOF2
      #!/usr/bin/env bash
      CFG="\''${XDG_CONFIG_HOME:-\$HOME/.config}/jailer"
      mkdir -p "\$CFG"
      cp -n $out/share/driverlist.csv \$CFG
      cd "\$CFG"
      export _JAVA_AWT_WM_NONREPARENTING=1
      exec ${super.jre}/bin/java \
        -cp "$out/share/java/jailer.jar:$out/share/java/lib/*:${super.postgresql_jdbc}/share/java/postgresql-jdbc.jar" \
        net.sf.jailer.ui.JailerUI
      EOF2
      chmod +x $out/bin/jailer
    '';
  });
}
