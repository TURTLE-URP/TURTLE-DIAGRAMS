#!/usr/bin/env bash
set -euo pipefail

find diagrams -name "*.mmd" | while read -r input; do
    relative="${input#diagrams/}"
    output="public/svgs/${relative%.mmd}.svg"

    mkdir -p "$(dirname "$output")"

    npx mmdc -i "$input" -o "$output" -p puppeteer-config.json

    echo "✔ $input -> $output"
done