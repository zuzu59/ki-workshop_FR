#!/bin/sh
# EXERCISES.md -> docs/EXERCISES.pdf (A4). Nécessite Pandoc et Weasyprint (Linux).
# apt update && apt install -y pandoc weasyprint

set -e
cd "$(dirname "$0")/.."

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

pandoc EXERCISES_FR.md -f gfm -s --metadata pagetitle="Exercices – Atelier gPlug" \
  -c docs/pdf.css --embed-resources -o "$T/ex.html"

weasyprint "$T/ex.html" docs/EXERCISES_FR.pdf

echo "Généré : docs/EXERCISES_FR.pdf"

