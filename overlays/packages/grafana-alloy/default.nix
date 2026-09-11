_self: super: {
  grafana-alloy = super.callPackage (
    {
      lib,
      stdenv,
      fetchFromGitea,
      fetchNpmDeps,
      buildGoModule,
      buildNpmPackage,
      systemd,
      installShellFiles,
      versionCheckHook,
      nixosTests,
      lld,
      useLLD ? stdenv.hostPlatform.isArmv7,
    }:

    let
      beylaVersion = "v3.9.8";
      rev = "a8f71c0b095656fa611e233c0b40f801b82e7649";
    in

    buildGoModule (finalAttrs: {
      pname = "grafana-alloy";
      version = "1.16.0-a8f71c0b0";

      src = fetchFromGitea {
        domain = "git.tatikoma.dev";
        owner = "corpix";
        repo = "alloy";
        inherit rev;
        hash = "sha256-x1Dt3Vq5b8eIKePJ/0y+17a/GVtaWzgGfqa11u5Dz+0=";
      };

      npmDeps = fetchNpmDeps {
        src = "${finalAttrs.src}/internal/web/ui";
        hash = "sha256-1idC+GSLhmkF6p4qcFKxxsxBW3lJUuKZnHJMHSdX3sw=";
      };

      frontend = buildNpmPackage {
        pname = "alloy-frontend";
        inherit (finalAttrs) version src;

        sourceRoot = "${finalAttrs.src.name}/internal/web/ui";

        inherit (finalAttrs) npmDeps;

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -av dist $out/share

          runHook postInstall
        '';
      };

      patchPhase = ''
        cp -av ${finalAttrs.frontend}/share internal/web/ui/dist

        goSumBeylaVersion="$(grep beyla go.sum | head -1 | cut -d ' ' -f2)"
        if [[ "$goSumBeylaVersion" != "${beylaVersion}" ]]; then
          echo "beyla version in go.sum ($goSumBeylaVersion) doesn't match the one set in the expression (${beylaVersion}), needs updating."
          exit 1
        fi
      '';

      modRoot = "collector";

      proxyVendor = true;
      vendorHash = "sha256-5gTOz+Zkax+ixByXaVSyMzYBKBtaxNpYDUEes3pflc0=";

      subPackages = [ "." ];

      ldflags = [
        "-s"
        "-w"
        "-X github.com/grafana/alloy/internal/build.Version=${finalAttrs.version}"
        "-X github.com/grafana/alloy/internal/build.Branch=corpix"
        "-X github.com/grafana/alloy/internal/build.Revision=${rev}"
        "-X github.com/grafana/alloy/internal/build.BuildUser=nix@nixpkgs"
        "-X github.com/grafana/alloy/internal/build.BuildDate=1970-01-01T00:00:00Z"
        "-X github.com/grafana/beyla/v3/pkg/buildinfo.Version=${beylaVersion}"
      ];

      tags = [
        "embedalloyui"
        "netgo"
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        "promtail_journal_enabled"
      ];

      env =
        lib.optionalAttrs useLLD {
          NIX_CFLAGS_LINK = "-fuse-ld=lld";
        }
        // lib.optionalAttrs stdenv.hostPlatform.isLinux {
          NIX_CFLAGS_COMPILE = "-I${lib.getDev systemd}/include";
        };

      nativeBuildInputs = [
        installShellFiles
      ]
      ++ lib.optionals useLLD [ lld ];

      postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
        mv -v $out/bin/otel_engine $out/bin/alloy

        installShellCompletion --cmd alloy \
          --bash <($out/bin/alloy completion bash) \
          --fish <($out/bin/alloy completion fish) \
          --zsh <($out/bin/alloy completion zsh)
      '';

      doInstallCheck = true;
      nativeInstallCheckInputs = [ versionCheckHook ];
      versionCheckProgramArg = "-v";

      postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
        patchelf \
          --set-rpath "${
            lib.makeLibraryPath [ (lib.getLib systemd) ]
          }:$(patchelf --print-rpath $out/bin/alloy)" \
          $out/bin/alloy
      '';

      passthru = {
        tests = {
          inherit (nixosTests) alloy;
        };
        inherit (finalAttrs) npmDeps;
      };

      meta = {
        description = "OpenTelemetry Collector distribution with programmable pipelines";
        longDescription = ''
          Grafana Alloy is an open source OpenTelemetry Collector distribution with
          built-in Prometheus pipelines and support for metrics, logs, traces, and
          profiles.
        '';
        homepage = "https://grafana.com/oss/alloy";
        changelog = "https://git.tatikoma.dev/corpix/alloy/src/commit/${rev}/CHANGELOG.md";
        license = lib.licenses.asl20;
        platforms = lib.platforms.unix;
        mainProgram = "alloy";
      };
    })
  ) { };
}
