#!/usr/bin/env bash
# Mermaid renderer (.mmd -> SVG + PNG via mermaid-cli)
#
# Contract: render_mmd <input> <svg_out> <png_out>

render_mmd() {
  local input="$1"
  local svg_out="$2"
  local png_out="$3"
  local puppeteer_config="${ROOT_DIR}/puppeteer-config.json"

  require_cmd npx "Install Node.js and run: npm install"

  ensure_dir_for "$svg_out"
  ensure_dir_for "$png_out"

  npx mmdc -i "$input" -o "$svg_out" -p "$puppeteer_config"
  log_ok "$input -> $svg_out"

  npx mmdc -i "$input" -o "$png_out" -s 4 -b white -p "$puppeteer_config"
  log_ok "$input -> $png_out"
}
