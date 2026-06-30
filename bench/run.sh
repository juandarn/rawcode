#!/bin/bash
# Reproduce the rawcode HumanEval A/B. Requires: claude CLI, python3, curl.
set -e
cd "$(dirname "$0")"
N="${1:-40}"

if [ ! -f HumanEval.jsonl ]; then
  echo "Downloading HumanEval..."
  curl -fsSL -o HumanEval.jsonl.gz \
    "https://raw.githubusercontent.com/openai/human-eval/master/data/HumanEval.jsonl.gz"
  gunzip -kf HumanEval.jsonl.gz
fi

echo "Running A/B over $N problems (baseline vs rawcode)..."
python3 eval.py "$N"
echo
python3 analyze.py
