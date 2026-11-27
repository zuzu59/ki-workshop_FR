#!/bin/sh
# docker-run.sh – Workshop-Sandbox holen (beim ersten Mal) und opencode darin starten.
#   ./docker-run.sh            opencode im Container
#   ./docker-run.sh bash       Shell im Container (zum Prüfen)
#   ./docker-run.sh --build    Image lokal aus dem Dockerfile bauen statt von ghcr.io laden
# Sichtbar ist nur dieser Ordner (/work). Infomaniak-Zugang steckt im Workshop-Image (:workshop,
# nur am Workshop-Tag); sonst Basis-Image (:base) ohne Zugang. INFOMANIAK_PRODUCT_ID /
# INFOMANIAK_API_KEY aus der eigenen Shell haben Vorrang (eigener Zugang).
set -eu
cd "$(dirname "$0")"
IMAGE=ghcr.io/gplug-ch/ki-workshop:workshop
BASE=ghcr.io/gplug-ch/ki-workshop:base

have() { docker image inspect "$1" >/dev/null 2>&1; }

if [ "${1:-}" = "--build" ]; then
  shift
  docker build -t "$IMAGE" --build-arg WORKSHOP_VERSION="$(cat VERSION)" .
elif ! have "$IMAGE" && ! docker pull "$IMAGE" 2>/dev/null; then
  # Kein Workshop-Image (Workshop-Tag vorbei oder noch nicht): Basis-Image ohne Zugang
  have "$BASE" || docker pull "$BASE" \
    || { echo "Image nicht ladbar: ./docker-run.sh --build baut es lokal" >&2; exit 1; }
  IMAGE=$BASE
  [ -n "${INFOMANIAK_API_KEY:-}" ] \
    || echo "HINWEIS: Basis-Image ohne Infomaniak-Zugang, eigenen setzen: SETUP_OPENCODE.md Schritt 3" >&2
fi

# Eigene Werte nur durchreichen, wenn gesetzt: leeres -e würde die Werte aus dem Image löschen
env_args="-e NODE_TLS_REJECT_UNAUTHORIZED=0"
[ -n "${INFOMANIAK_PRODUCT_ID:-}" ] && env_args="$env_args -e INFOMANIAK_PRODUCT_ID"
[ -n "${INFOMANIAK_API_KEY:-}" ] && env_args="$env_args -e INFOMANIAK_API_KEY"
[ -n "${GPLUG:-}" ] && env_args="$env_args -e GPLUG"

# Linux: mit eigener UID laufen, damit Dateien im Ordner dir gehören (Docker Desktop macht das selbst)
user=""
[ "$(uname -s)" = "Linux" ] && user="--user $(id -u):$(id -g)"

# shellcheck disable=SC2086
exec docker run -it --rm $user $env_args --name opencode\
  -v "$PWD":/work -w /work \
  -v "$PWD/home_root/.config/opencode":/home/agent/.config/opencode \
  -v "$PWD/home_root/.local/share/opencode":/home/agent/.local/share/opencode \
  "$IMAGE" "$@"
