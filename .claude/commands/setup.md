---
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, SlashCommand
argument-hint: [project-directory] [--cleanup [--dry-run]] [--validate] [--analyze] [--apply-report <report-path>] [--enhance-with-docs]
description: Setup or improve CLAUDE.md with smart extraction, cleanup optimization, validation, standards analysis, report-driven updates, and automatic documentation enhancement
command-type: primary
dependent-commands: orchestrate
---

# /setup - Project Standards Configuration

YOU ARE EXECUTING AS the /setup command.

**Documentation**: See `.claude/docs/guides/setup-command-guide.md` for complete architecture, usage examples, mode descriptions, and troubleshooting.

---

## Phase 0: Argument Parsing and Mode Detection

[EXECUTION-CRITICAL: Execute this bash block immediately]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse arguments - Priority: apply-report > enhance > cleanup > validate > analyze > standard
MODE="standard"; PROJECT_DIR=""; DRY_RUN=false; THRESHOLD="balanced"; REPORT_PATH=""

for arg in "$@"; do
  case "$arg" in
    --apply-report) shift; MODE="apply-report"; REPORT_PATH="$1"; shift ;;
    --enhance-with-docs) MODE="enhance" ;;
    --cleanup) MODE="cleanup" ;;
    --validate) MODE="validate" ;;
    --analyze) MODE="analyze" ;;
    --dry-run) DRY_RUN=true ;;
    --threshold) shift; THRESHOLD="$1"; shift ;;
    --*) echo "ERROR: Unknown flag: $arg"; exit 1 ;;
    *) [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$arg" ;;
  esac
done

# Default and validate
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$PWD"
[[ ! "$PROJECT_DIR" = /* ]] && PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"

if [ "$MODE" = "apply-report" ] && [ -z "$REPORT_PATH" ]; then
  echo "ERROR: --apply-report requires path. Usage: /setup --apply-report <path> [dir]"; exit 1
fi
if [ "$MODE" = "apply-report" ] && [ ! -f "$REPORT_PATH" ]; then
  echo "ERROR: Report not found: $REPORT_PATH. Run /setup --analyze first."; exit 1
fi
if [ "$DRY_RUN" = true ] && [ "$MODE" != "cleanup" ]; then
  echo "ERROR: --dry-run requires --cleanup"; exit 1
fi

echo "✓ Mode: $MODE | Project: $PROJECT_DIR"
export MODE PROJECT_DIR DRY_RUN THRESHOLD REPORT_PATH
```

---

## Phase 1: Standard Mode - CLAUDE.md Generation

[EXECUTION-CRITICAL: Execute when MODE=standard]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

[ "$MODE" != "standard" ] && echo "Skipping Phase 1 (MODE=$MODE)" && exit 0

echo "Phase 1: Generating CLAUDE.md"

# Detect testing
DETECT_OUTPUT=$("${LIB_DIR}/detect-testing.sh" "$PROJECT_DIR" 2>&1)
TEST_SCORE=$(echo "$DETECT_OUTPUT" | grep "^SCORE:" | cut -d: -f2)
TEST_FRAMEWORKS=$(echo "$DETECT_OUTPUT" | grep "^FRAMEWORKS:" | cut -d: -f2-)

# Generate protocols
TESTING_SECTION=$("${LIB_DIR}/generate-testing-protocols.sh" "$TEST_SCORE" "$TEST_FRAMEWORKS" 2>&1)
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"

cat > "$CLAUDE_MD_PATH" << 'EOF'
# Project Configuration Index

## Code Standards
[Used by: /implement, /refactor, /plan]

- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters
- **Naming**: snake_case
- **Error Handling**: Language-appropriate patterns
- **Documentation**: Every directory has README.md

## Testing Protocols
[Used by: /test, /test-all, /implement]

EOF

echo "$TESTING_SECTION" >> "$CLAUDE_MD_PATH"

cat >> "$CLAUDE_MD_PATH" << 'EOF'

## Documentation Policy
[Used by: /document, /plan]

- Every subdirectory has README.md
- Clear, concise language
- Code examples with syntax highlighting

## Standards Discovery
[Used by: all commands]

Commands discover standards by searching upward for CLAUDE.md, checking subdirectories, merging standards.

Fallback: use language defaults, suggest /setup, graceful degradation.
EOF

[ ! -f "$CLAUDE_MD_PATH" ] && echo "ERROR: CLAUDE.md not created" && exit 1
echo "✓ Created: $CLAUDE_MD_PATH"
```

---

## Phase 2: Cleanup Mode - Section Extraction

[EXECUTION-CRITICAL: Execute when MODE=cleanup]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

[ "$MODE" != "cleanup" ] && echo "Skipping Phase 2" && exit 0

echo "Phase 2: Cleanup Mode"
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"

[ ! -f "$CLAUDE_MD_PATH" ] && echo "ERROR: CLAUDE.md not found. Run /setup first." && exit 1

# Build flags
FLAGS=""
[ "$DRY_RUN" = true ] && FLAGS="--dry-run"
case "$THRESHOLD" in
  aggressive) FLAGS="$FLAGS --aggressive" ;;
  conservative) FLAGS="$FLAGS --conservative" ;;
  *) FLAGS="$FLAGS --balanced" ;;
esac

"${LIB_DIR}/optimize-claude-md.sh" "$CLAUDE_MD_PATH" $FLAGS
[ $? -ne 0 ] && echo "ERROR: Cleanup failed" && exit 1
echo "✓ Cleanup complete"
```

---

## Phase 3: Validation Mode - Structure Verification

[EXECUTION-CRITICAL: Execute when MODE=validate]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

[ "$MODE" != "validate" ] && echo "Skipping Phase 3" && exit 0

echo "Phase 3: Validation"
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"
[ ! -f "$CLAUDE_MD_PATH" ] && echo "ERROR: CLAUDE.md not found" && exit 1

# Check sections
REQUIRED=("Code Standards" "Testing Protocols" "Documentation Policy" "Standards Discovery")
MISSING=()
for sec in "${REQUIRED[@]}"; do
  grep -q "^## $sec" "$CLAUDE_MD_PATH" || MISSING+=("$sec")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "WARNING: Missing sections:"; printf '  - %s\n' "${MISSING[@]}"
else
  echo "✓ All sections present"
fi

# Check metadata
NO_META=$(grep -n "^## " "$CLAUDE_MD_PATH" | while read line; do
  ln=$(echo "$line" | cut -d: -f1)
  sed -n "$((ln + 1))p" "$CLAUDE_MD_PATH" | grep -q "\[Used by:" || echo "$line" | cut -d: -f2-
done)

[ -n "$NO_META" ] && echo "WARNING: Sections missing metadata:" && echo "$NO_META" || echo "✓ Metadata OK"
```

---

## Phase 4: Analysis Mode - Discrepancy Detection

[EXECUTION-CRITICAL: Execute when MODE=analyze]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

[ "$MODE" != "analyze" ] && echo "Skipping Phase 4" && exit 0

echo "Phase 4: Analysis"
REPORTS_DIR="${PROJECT_DIR}/.claude/specs/reports"
mkdir -p "$REPORTS_DIR"

NUM=$(ls -1 "$REPORTS_DIR" 2>/dev/null | grep -E "^[0-9]+_" | sed 's/_.*//' | sort -n | tail -1)
NUM=$(printf "%03d" $((NUM + 1)))
REPORT="${REPORTS_DIR}/${NUM}_standards_analysis.md"

cat > "$REPORT" << 'EOF'
# Standards Analysis Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Project**: $PROJECT_DIR

## Summary
Basic analysis. For comprehensive analysis, use /orchestrate with research agents.

## Gap Analysis
[FILL IN: Indentation] ___
[FILL IN: Error Handling] ___
[FILL IN: Testing] ___
EOF

[ ! -f "$REPORT" ] && echo "ERROR: Report not created" && exit 1
echo "✓ Report: $REPORT"
```

---

## Phase 5: Report Application

[EXECUTION-CRITICAL: Execute when MODE=apply-report]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

[ "$MODE" != "apply-report" ] && echo "Skipping Phase 5" && exit 0

echo "Phase 5: Applying report"
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"
BACKUP="${CLAUDE_MD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CLAUDE_MD_PATH" "$BACKUP" 2>/dev/null || true

FILLED=$(grep -E "\[FILL IN:" "$REPORT_PATH" | sed 's/\[FILL IN: \(.*\)\] \(.*\)/\1=\2/')
[ -z "$FILLED" ] && echo "WARNING: No filled gaps. Edit report first." && exit 0

echo "Found gaps:"; echo "$FILLED"
echo "NOTE: Manual review required for this version"
echo "Review $REPORT_PATH and update $CLAUDE_MD_PATH"
```

---

## Phase 6: Enhancement Mode

[EXECUTION-CRITICAL: Execute when MODE=enhance]

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

[ "$MODE" != "enhance" ] && echo "Skipping Phase 6" && exit 0

echo "Phase 6: Enhancement (delegating to /orchestrate)"
echo "Project: $PROJECT_DIR"

ORCH_MSG="Analyze documentation at ${PROJECT_DIR}, enhance CLAUDE.md.

Phase 1: Research (parallel) - Docs discovery, test analysis, TDD detection
Phase 2: Planning - Gap analysis
Phase 3: Implementation - Update CLAUDE.md
Phase 4: Documentation - Workflow summary

Project: ${PROJECT_DIR}"

echo "Invoking /orchestrate..."
echo "$ORCH_MSG"
echo "Wait for /orchestrate to complete"
```

---

**Troubleshooting**: See `.claude/docs/guides/setup-command-guide.md` for common issues and solutions.
