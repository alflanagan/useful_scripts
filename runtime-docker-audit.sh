#!/usr/bin/env bash
# runtime-audit.sh — what is actually executing your containers?
# Written for bash 5.x. Checked against Docker Engine 29.6.2, Podman 6.0.2,
# nerdctl 2.3.0 on Ubuntu 24.04.
set -uo pipefail

row() { printf '%-10s %-14s %s\n' "$1" "$2" "$3"; }

row TOOL VERSION "LOW-LEVEL RUNTIME"
printf '%.0s-' {1..50}; echo

if command -v docker >/dev/null 2>&1; then
  row docker \
    "$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo unavailable)" \
    "$(docker info --format '{{.DefaultRuntime}}' 2>/dev/null || echo unavailable)"
fi

if command -v podman >/dev/null 2>&1; then
  row podman \
    "$(podman version --format '{{.Client.Version}}' 2>/dev/null || echo unavailable)" \
    "$(podman info --format '{{.Host.OCIRuntime.Name}}' 2>/dev/null || echo unavailable)"
fi

if command -v nerdctl >/dev/null 2>&1; then
  row nerdctl \
    "$(nerdctl version --format '{{.Client.Version}}' 2>/dev/null || echo unavailable)" \
    "set in /etc/containerd/config.toml"
fi

echo
echo "Runtime binaries present on this host:"
for rt in runc crun youki; do
  if command -v "$rt" >/dev/null 2>&1; then
    printf '  %-6s %s\n' "$rt" "$("$rt" --version 2>/dev/null | head -n1)"
  fi
done
