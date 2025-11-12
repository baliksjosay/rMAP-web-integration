#!/usr/bin/env bash
set -euo pipefail

# =====================================================
#  rMAP Resume Script (mirrors backend buildArgs logic)
# =====================================================
# Usage:
#   ./rmap-resume.sh <job_id> <stage> [threads]
# Example:
#   ./rmap-resume.sh f72d80e8-b4dd-4a55-85c8-4d298e63e586 trim 12

JOB_ID="${1:-}"
STAGE="${2:-}"
THREADS="${3:-$(nproc)}"

if [ -z "$JOB_ID" ] || [ -z "$STAGE" ]; then
  echo "Usage: $0 <job_id> <stage> [threads]"
  exit 1
fi

BASE="/opt/web/api/data/jobs/${JOB_ID}"
INPUT="${BASE}/incoming"
OUTPUT="${BASE}/output"
REF="/opt/web/api/data/references/S.aureus.gbk"
LOG_DIR="${BASE}/logs"
mkdir -p "$LOG_DIR"

# Verify structure
[[ -d "$INPUT" ]]  || { echo "❌ Missing input dir $INPUT"; exit 1; }
[[ -d "$OUTPUT" ]] || { echo "❌ Missing output dir $OUTPUT"; exit 1; }

# -------- Stage → Flags mapping ----------
FLAGS=""
ASSEMBLER="megahit"

case "$STAGE" in
  all)         FLAGS="-f -q -a ${ASSEMBLER} -vc -m -p -s -g" ;;
  quality|qc)  FLAGS="-f" ;;
  trim)        FLAGS="-q" ;;
  assembly)    FLAGS="-a ${ASSEMBLER}" ;;
  varcall|vc)  FLAGS="-vc" ;;
  amr)         FLAGS="-m" ;;
  phylogeny|p) FLAGS="-p" ;;
  pangenome|s) FLAGS="-s" ;;
  geneele|g)   FLAGS="-g" ;;
  *)
    echo "❌ Unknown stage: $STAGE"
    echo "Valid: all quality trim assembly varcall amr phylogeny pangenome geneele"
    exit 1
    ;;
esac

CMD=( rMAP -t "$THREADS" -r "$REF" -i "$INPUT" -o "$OUTPUT" $FLAGS )

echo "---------------------------------------------------"
echo "🧬 Resuming job $JOB_ID at stage: $STAGE"
echo "CMD: ${CMD[*]}"
echo "---------------------------------------------------"

"${CMD[@]}" &> "$LOG_DIR/${STAGE}.log"

echo "✅ Stage '$STAGE' completed."
echo "📄 Log saved to: $LOG_DIR/${STAGE}.log"