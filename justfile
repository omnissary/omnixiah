set shell := ["bash", "-cu"]
set lazy := true

nix_flags := "--accept-flake-config"
system := `nix eval --raw --impure --expr builtins.currentSystem`

default:
  just profiles

profiles:
  nix eval {{nix_flags}} --json .#lib.profiles | jq -r 'to_entries[] | "\(.key)\t\(.value.system)\t\(.value.description)"'

eval profile="minimal":
  nix eval {{nix_flags}} --raw .#nixosConfigurations.{{profile}}.config.networking.hostName

build profile="minimal" nix_build_args="":
  nix build {{nix_flags}} --show-trace {{nix_build_args}} .#packages.{{system}}.{{profile}}

run profile="minimal":
  nix run {{nix_flags}} .#{{profile}}

lint:
  nix flake check {{nix_flags}} --show-trace

test test="all":
  if [[ "{{test}}" == "all" ]]; then \
    attrs=$(nix eval {{nix_flags}} --json .#lib.tests | jq -r --arg system "{{system}}" 'keys | map(".#checks.\($system).module-" + .) | join(" ")'); \
    nix build {{nix_flags}} --show-trace ${attrs}; \
  else \
    nix build {{nix_flags}} --show-trace .#checks.{{system}}.module-{{test}}; \
  fi

fmt:
  nix fmt {{nix_flags}}
