set shell := ["bash", "-cu"]
set lazy := true

nix_flags := "--accept-flake-config"
system := `nix eval --raw --impure --expr builtins.currentSystem`

ssh_control_dir := `dir="$(git rev-parse --show-toplevel)/.git/fork-sync-ssh"; mkdir -p "$dir"; printf '%s' "$dir"`
ssh_control := "-o ControlMaster=auto -o ControlPath=" + ssh_control_dir + "/%r@%h:%p -o ControlPersist=1h"
export GIT_SSH_COMMAND := "ssh " + ssh_control

sync_host := "git.tatikoma.dev"
sync_host_user := "gitea"
sync_host_port := "2222"

default:
  just profiles

profiles:
  nix eval {{nix_flags}} --json .#lib.profiles | jq -r 'to_entries[] | "\(.key)\t\(.value.system)\t\(.value.description)"'

eval profile="minimal":
  nix eval {{nix_flags}} --raw .#nixosConfigurations.{{profile}}.config.networking.hostName

build profile="minimal" nix_build_args="":
  nix build {{nix_flags}} --show-trace {{nix_build_args}} .#nixosConfigurations.{{profile}}.config.microvm.declaredRunner

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

update-list:
  maintenance/package-update/update list

update package:
  maintenance/package-update/update run {{package}}

update-all:
  maintenance/package-update/update run-all

update-continue package:
  maintenance/package-update/update continue {{package}}

update-abort package:
  maintenance/package-update/update abort {{package}}

sync-status:
  maintenance/fork-sync/sync status

sync repo *args:
  maintenance/fork-sync/sync prepare {{repo}} {{args}}

sync-all *args:
  maintenance/fork-sync/sync prepare-all {{args}}
  ssh {{ssh_control}} -O exit -p {{sync_host_port}} {{sync_host_user}}@{{sync_host}} 2>/dev/null || true

sync-continue repo:
  maintenance/fork-sync/sync continue {{repo}}

sync-abort repo:
  maintenance/fork-sync/sync abort {{repo}}

sync-push repo:
  maintenance/fork-sync/sync push {{repo}}

sync-push-all:
  maintenance/fork-sync/sync push-all
  ssh {{ssh_control}} -O exit -p {{sync_host_port}} {{sync_host_user}}@{{sync_host}} 2>/dev/null || true
