#!/usr/bin/env bash

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

docker_cli=false
docker_daemon=false
act_available=false
git_available=false
asciinema_available=false


has_cmd docker && docker_cli=true
docker info >/dev/null 2>&1 && docker_daemon=true
has_cmd act && act_available=true
has_cmd git && git_available=true
has_cmd asciinema && asciinema_available=true

 
echo "host_capabilities:"
echo "  architecture:       $(uname -m)"
echo "  docker_cli:         $docker_cli"
echo "  docker_daemon:      $docker_daemon"
echo "  act:                $act_available"
echo "  git:                $git_available"
echo "  asciinema:          $asciinema_available"
