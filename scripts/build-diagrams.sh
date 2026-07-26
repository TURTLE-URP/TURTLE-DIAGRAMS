#!/usr/bin/env bash
set -euo pipefail

find diagrams -name "*.mmd" | while read -r input; do
    relative="${input#diagrams/}"
    base="${relative%.mmd}"

    svg_output="public/svgs/${base}.svg"
    png_output="public/images/${base}.png"

    mkdir -p "$(dirname "$svg_output")"
    mkdir -p "$(dirname "$png_output")"

    npx mmdc -i "$input" -o "$svg_output" -p puppeteer-config.json
    echo "✔ $input -> $svg_output"

    npx mmdc -i "$input" -o "$png_output" -s 4 -b white -p puppeteer-config.json
    echo "✔ $input -> $png_output"
done