#!/usr/bin/env bash
# Orchestrator: discover diagram sources and dispatch to format renderers.
#
# To support a new format later:
#   1. Add the extension to EXTENSIONS below
#   2. Add scripts/renderers/<ext>.sh exporting render_<ext>
#   3. Install any tools the renderer needs (local + CI workflow)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Supported source extensions (add new ones here when adding a renderer)
EXTENSIONS=(mmd puml)

for ext in "${EXTENSIONS[@]}"; do
  renderer="$SCRIPT_DIR/renderers/${ext}.sh"
  if [[ ! -f "$renderer" ]]; then
    log_err "Missing renderer for .${ext}: $renderer"
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$renderer"
done

find_expr=( "(" "-name" "*.${EXTENSIONS[0]}" )
for ext in "${EXTENSIONS[@]:1}"; do
  find_expr+=(-o -name "*.${ext}")
done
find_expr+=(")")

mapfile -t inputs < <(find diagrams -type f "${find_expr[@]}" | sort)

if [[ ${#inputs[@]} -eq 0 ]]; then
  echo "No diagrams found under diagrams/ for: ${EXTENSIONS[*]}"
  exit 0
fi

for input in "${inputs[@]}"; do
  relative="${input#diagrams/}"
  ext="${input##*.}"
  base="${relative%.*}"

  svg_output="public/svgs/${base}.svg"
  png_output="public/images/${base}.png"

  render_fn="render_${ext}"
  if ! declare -F "$render_fn" >/dev/null; then
    log_err "No renderer function ${render_fn} for ${input}"
    exit 1
  fi

  "$render_fn" "$input" "$svg_output" "$png_output"
done

echo "Done. Processed ${#inputs[@]} diagram(s)."
