#!/usr/bin/env bash
# PlantUML renderer (.puml -> SVG + PNG via plantuml.jar)
#
# Contract: render_puml <input> <svg_out> <png_out>
#
# JAR resolution order:
#   1. PLANTUML_JAR (env)
#   2. tools/plantuml.jar (repo-relative)

resolve_plantuml_jar() {
  if [[ -n "${PLANTUML_JAR:-}" && -f "$PLANTUML_JAR" ]]; then
    printf '%s\n' "$PLANTUML_JAR"
    return 0
  fi

  local default_jar="${ROOT_DIR}/tools/plantuml.jar"
  if [[ -f "$default_jar" ]]; then
    printf '%s\n' "$default_jar"
    return 0
  fi

  return 1
}

# Fail if PlantUML wrote an error diagram or printed a Java exception.
plantuml_output_ok() {
  local out_file="$1"
  local err_file="$2"

  if [[ ! -s "$out_file" ]]; then
    log_err "PlantUML produced an empty output: $out_file"
    return 1
  fi

  if grep -Eq 'Exception |An error has been reported|UnparsableGraphvizException' "$err_file"; then
    log_err "PlantUML failed while rendering (see stderr above)."
    cat "$err_file" >&2
    return 1
  fi

  if grep -Eq 'An error has been reported|UnparsableGraphvizException' "$out_file"; then
    log_err "PlantUML wrote an error diagram to: $out_file"
    return 1
  fi

  return 0
}

render_plantuml_format() {
  local format="$1"
  local input="$2"
  local out_file="$3"
  local jar="$4"
  local err_file
  err_file="$(mktemp)"

  # Headless for CI / servers without a display
  # -pipe keeps output paths under our control (avoids @startuml name clashes)
  if ! java -Djava.awt.headless=true -jar "$jar" "-t${format}" -pipe <"$input" >"$out_file" 2>"$err_file"; then
    log_err "PlantUML exited with error for $input ($format)"
    cat "$err_file" >&2
    rm -f "$err_file" "$out_file"
    return 1
  fi

  if ! plantuml_output_ok "$out_file" "$err_file"; then
    rm -f "$err_file" "$out_file"
    return 1
  fi

  # Surface non-fatal warnings if any
  if [[ -s "$err_file" ]]; then
    cat "$err_file" >&2
  fi
  rm -f "$err_file"
  log_ok "$input -> $out_file"
}

render_puml() {
  local input="$1"
  local svg_out="$2"
  local png_out="$3"
  local jar

  require_cmd java "Install a JDK 17+ (e.g. Temurin) and ensure java is on PATH"
  require_cmd dot "Install Graphviz so the 'dot' binary is available"

  if ! jar="$(resolve_plantuml_jar)"; then
    log_err "PlantUML JAR not found."
    log_err "Set PLANTUML_JAR or place the jar at tools/plantuml.jar"
    return 1
  fi

  ensure_dir_for "$svg_out"
  ensure_dir_for "$png_out"

  render_plantuml_format svg "$input" "$svg_out" "$jar" || return 1
  render_plantuml_format png "$input" "$png_out" "$jar" || return 1
}
