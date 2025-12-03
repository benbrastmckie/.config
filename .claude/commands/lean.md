---
allowed-tools: Task, Bash, Read, Grep, Glob
argument-hint: [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N]
description: Lean theorem proving workflow with lean-lsp-mcp integration
command-type: primary
dependent-agents:
  - lean-implementer
library-requirements:
  - error-handling.sh: ">=1.0.0"
documentation: See .claude/docs/guides/commands/lean-command-guide.md for usage
---

# /lean - Lean Theorem Proving Command

YOU ARE EXECUTING a Lean 4 theorem proving workflow that uses the lean-implementer agent with lean-lsp-mcp integration to prove theorems, search Mathlib, and verify proofs.

**Workflow Type**: lean-proving
**Expected Input**: Lean file path or plan file
**Expected Output**: Completed proofs with summaries

## Block 1a: Setup & Lean Project Detection

**EXECUTE NOW**: The user invoked `/lean [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N]`. This block captures arguments, validates Lean project, and prepares for lean-implementer invocation.

In the **bash block below**, replace `YOUR_LEAN_ARGS_HERE` with the actual lean arguments.

**Examples**:
- If user ran `/lean Test.lean`, change to: `echo "Test.lean" > "$TEMP_FILE"`
- If user ran `/lean plan.md --prove-all`, change to: `echo "plan.md --prove-all" > "$TEMP_FILE"`

```bash
# === PREPROCESSING SAFETY ===
set +H 2>/dev/null || true
set +o histexpand 2>/dev/null || true
set -e  # Fail-fast

# === CAPTURE LEAN ARGUMENTS ===
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/lean_arg_$(date +%s%N).txt"
# SUBSTITUTE THE LEAN ARGUMENTS IN THE LINE BELOW
echo "YOUR_LEAN_ARGS_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/lean_arg_path.txt"

# === READ AND PARSE ARGUMENTS ===
LEAN_ARGS=$(cat "$TEMP_FILE" 2>/dev/null || echo "")

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source error-handling.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/lean"
WORKFLOW_ID="lean_$(date +%s)"
USER_ARGS="$LEAN_ARGS"

echo "=== Lean Theorem Proving Workflow ==="
echo ""

# === PARSE ARGUMENTS ===
read -ra ARGS_ARRAY <<< "$LEAN_ARGS"
LEAN_FILE="${ARGS_ARRAY[0]:-}"
MODE="--prove-all"  # Default mode
MAX_ATTEMPTS=3      # Default max attempts per theorem

for arg in "${ARGS_ARRAY[@]:1}"; do
  case "$arg" in
    --prove-all) MODE="--prove-all" ;;
    --verify) MODE="--verify" ;;
    --max-attempts=*) MAX_ATTEMPTS="${arg#*=}" ;;
  esac
done

# === VALIDATE LEAN FILE ===
if [ -z "$LEAN_FILE" ]; then
  echo "ERROR: No Lean file or plan file specified" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "No file specified" "bash_block" "{}"
  exit 1
fi

# Resolve to absolute path
if [ ! -f "$LEAN_FILE" ]; then
  # Try relative to current directory
  if [ -f "$CLAUDE_PROJECT_DIR/$LEAN_FILE" ]; then
    LEAN_FILE="$CLAUDE_PROJECT_DIR/$LEAN_FILE"
  else
    echo "ERROR: File not found: $LEAN_FILE" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "file_error" "File not found: $LEAN_FILE" "bash_block" "{}"
    exit 1
  fi
fi

LEAN_FILE="$(cd "$(dirname "$LEAN_FILE")" && pwd)/$(basename "$LEAN_FILE")"

echo "Lean File: $LEAN_FILE"
echo "Mode: $MODE"
echo "Max Attempts: $MAX_ATTEMPTS"
echo ""

# === DETECT LEAN PROJECT ===
LEAN_PROJECT_DIR="$(dirname "$LEAN_FILE")"
while [ "$LEAN_PROJECT_DIR" != "/" ]; do
  if [ -f "$LEAN_PROJECT_DIR/lakefile.toml" ] || [ -f "$LEAN_PROJECT_DIR/lakefile.lean" ]; then
    break
  fi
  LEAN_PROJECT_DIR="$(dirname "$LEAN_PROJECT_DIR")"
done

if [ "$LEAN_PROJECT_DIR" = "/" ]; then
  echo "ERROR: Not a Lean 4 project (no lakefile.toml or lakefile.lean found)" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Not a Lean project" "bash_block" \
    "{\"file\": \"$LEAN_FILE\"}"
  exit 1
fi

echo "Lean Project: $LEAN_PROJECT_DIR"
echo ""

# === VERIFY MCP SERVER AVAILABILITY ===
if ! uvx --from lean-lsp-mcp --help >/dev/null 2>&1; then
  echo "ERROR: lean-lsp-mcp MCP server not available" >&2
  echo "  Install with: uvx --from lean-lsp-mcp" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "dependency_error" "lean-lsp-mcp not available" "bash_block" "{}"
  exit 1
fi

echo "MCP Server: Available"
echo ""

# === SETUP ARTIFACT PATHS ===
# Determine topic path from Lean file location
TOPIC_PATH="$(dirname "$LEAN_FILE")"

# Use .claude/specs structure if available, otherwise use project directory
if [ -d "$CLAUDE_PROJECT_DIR/.claude/specs" ]; then
  # Extract topic from Lean file path relative to project
  REL_PATH="${LEAN_FILE#$CLAUDE_PROJECT_DIR/}"
  TOPIC_NAME=$(echo "$REL_PATH" | sed 's/[^a-zA-Z0-9_-]/_/g' | cut -c1-50)
  TOPIC_PATH="$CLAUDE_PROJECT_DIR/.claude/specs/lean_$TOPIC_NAME"
  mkdir -p "$TOPIC_PATH/summaries" "$TOPIC_PATH/debug" 2>/dev/null
else
  TOPIC_PATH="$LEAN_PROJECT_DIR"
  mkdir -p "$TOPIC_PATH/.lean_summaries" 2>/dev/null
fi

SUMMARIES_DIR="$TOPIC_PATH/summaries"
DEBUG_DIR="$TOPIC_PATH/debug"

if [ ! -d "$SUMMARIES_DIR" ]; then
  SUMMARIES_DIR="$TOPIC_PATH/.lean_summaries"
  mkdir -p "$SUMMARIES_DIR" 2>/dev/null
fi

if [ ! -d "$DEBUG_DIR" ]; then
  DEBUG_DIR="$TOPIC_PATH"
fi

echo "Topic Path: $TOPIC_PATH"
echo "Summaries Directory: $SUMMARIES_DIR"
echo ""

# Calculate summary output path
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_PATH="$SUMMARIES_DIR/lean_proof_${TIMESTAMP}.md"

echo "Expected Summary: $SUMMARY_PATH"
echo ""
```

## Block 1b: lean-implementer Invocation [HARD BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer agent.

Task {
  subagent_type: "general-purpose"
  description: "Lean theorem proving for ${LEAN_FILE} with mandatory summary creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
    - max_attempts: ${MAX_ATTEMPTS}

    Execute proof development workflow for mode: ${MODE}

    ${MODE == '--verify' ? 'Verification mode: Check existing proofs without modification.' : 'Prove all unproven theorems (sorry markers).'}

    Return: IMPLEMENTATION_COMPLETE: 1
    summary_path: /path/to/summary
    theorems_proven: [...]
    theorems_partial: [...]
    tactics_used: [...]
    mathlib_theorems: [...]
    diagnostics: []
  "
}

## Block 1c: Verification & Diagnostics

**EXECUTE NOW**: Verify summary creation and parse lean-implementer output.

```bash
# Re-source error-handling if needed
if ! declare -F log_command_error >/dev/null 2>&1; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to re-source error-handling.sh" >&2
    exit 1
  fi
fi

# Re-initialize workflow metadata (subprocess isolation)
COMMAND_NAME="/lean"
WORKFLOW_ID="lean_$(date +%s)"
USER_ARGS="$LEAN_ARGS"

# === VALIDATE SUMMARY EXISTENCE ===
SUMMARY_FOUND="false"

# Check for summary in expected location
if [ -f "$SUMMARY_PATH" ] && [ $(stat -c%s "$SUMMARY_PATH" 2>/dev/null || echo "0") -ge 100 ]; then
  SUMMARY_FOUND="true"
  echo "Summary validated: $SUMMARY_PATH"
else
  # Check for any recent summary in directory
  LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -5 2>/dev/null | head -1)

  if [ -n "$LATEST_SUMMARY" ] && [ $(stat -c%s "$LATEST_SUMMARY" 2>/dev/null || echo "0") -ge 100 ]; then
    SUMMARY_PATH="$LATEST_SUMMARY"
    SUMMARY_FOUND="true"
    echo "Summary found: $SUMMARY_PATH"
  else
    echo "ERROR: Summary file not created or too small (<100 bytes)" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "agent_error" "lean-implementer did not create summary" "verification_block" \
      "{\"expected_path\": \"$SUMMARY_PATH\", \"summaries_dir\": \"$SUMMARIES_DIR\"}"
    exit 1
  fi
fi

echo ""

# === PARSE OUTPUT SIGNAL ===
# Extract key metrics from agent output (would be in agent response)
# For now, we'll read from summary file

THEOREMS_PROVEN=0
THEOREMS_PARTIAL=0
DIAGNOSTICS_COUNT=0

if [ -f "$SUMMARY_PATH" ]; then
  # Parse summary for metrics
  THEOREMS_PROVEN=$(grep -c "Status.*COMPLETE" "$SUMMARY_PATH" 2>/dev/null || echo "0")
  THEOREMS_PARTIAL=$(grep -c "Status.*PARTIAL" "$SUMMARY_PATH" 2>/dev/null || echo "0")

  # Check for diagnostics section
  if grep -q "## Diagnostics" "$SUMMARY_PATH"; then
    DIAGNOSTICS_COUNT=$(sed -n '/## Diagnostics/,/##/p' "$SUMMARY_PATH" | grep -c "ERROR\|WARNING" 2>/dev/null || echo "0")
  fi
fi

echo "Theorems Proven: $THEOREMS_PROVEN"
echo "Theorems Partial: $THEOREMS_PARTIAL"
echo "Diagnostics: $DIAGNOSTICS_COUNT"
echo ""

# === VALIDATE PROOF COMPLETENESS ===
SORRY_COUNT=$(grep -c "sorry" "$LEAN_FILE" 2>/dev/null || echo "0")

if [ "$MODE" = "--prove-all" ] && [ "$SORRY_COUNT" -gt 0 ]; then
  echo "WARNING: $SORRY_COUNT sorry markers remain in file" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "execution_error" "Proof incomplete: $SORRY_COUNT sorry remain" "verification_block" \
    "{\"file\": \"$LEAN_FILE\", \"sorry_count\": $SORRY_COUNT}"
fi

if [ "$DIAGNOSTICS_COUNT" -gt 0 ]; then
  echo "WARNING: $DIAGNOSTICS_COUNT diagnostic issues detected" >&2
fi

echo "Verification complete"
echo ""
```

## Block 2: Completion & Summary

**EXECUTE NOW**: Display completion summary and emit PROOF_COMPLETE signal.

```bash
# Re-source error-handling if needed
if ! declare -F log_command_error >/dev/null 2>&1; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || true
fi

# === CONSOLE SUMMARY ===
cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║ LEAN THEOREM PROVING COMPLETE            ║
╠═══════════════════════════════════════════════════════╣
EOF

echo "║ Summary: $THEOREMS_PROVEN theorems proven, $THEOREMS_PARTIAL partial"
echo "║ File: $(basename "$LEAN_FILE")"
echo "║ Mode: $MODE"

if [ "$SORRY_COUNT" -eq 0 ]; then
  echo "║ Status: All proofs complete ✓"
else
  echo "║ Status: $SORRY_COUNT sorry markers remain"
fi

if [ "$DIAGNOSTICS_COUNT" -gt 0 ]; then
  echo "║ Diagnostics: $DIAGNOSTICS_COUNT issues"
fi

cat << 'EOF'
╠═══════════════════════════════════════════════════════╣
║ Artifacts:                      ║
EOF

echo "║ └─ Summary: $(basename "$SUMMARY_PATH")"

cat << 'EOF'
╠═══════════════════════════════════════════════════════╣
║ Next Steps:                      ║
║ 1. Review proofs in Lean file             ║
║ 2. Run lean build to verify compilation        ║
║ 3. Check summary for tactic explanations        ║
╚═══════════════════════════════════════════════════════╝
EOF

echo ""

# === EMIT COMPLETION SIGNAL ===
echo "PROOF_COMPLETE: $THEOREMS_PROVEN"
echo "summary_path: $SUMMARY_PATH"
echo "lean_file: $LEAN_FILE"
echo "theorems_proven: $THEOREMS_PROVEN"
echo "theorems_partial: $THEOREMS_PARTIAL"
echo "diagnostics_count: $DIAGNOSTICS_COUNT"
echo "sorry_remaining: $SORRY_COUNT"

# Cleanup
rm -f "$TEMP_FILE" "${HOME}/.claude/tmp/lean_arg_path.txt" 2>/dev/null

echo ""
echo "Lean workflow complete"
```

## Notes

### Mode-Specific Behavior

**--prove-all (default)**:
- Identifies all theorems with `sorry` markers
- Attempts to prove each theorem using lean-lsp-mcp tools
- Creates summary with all attempted proofs

**--verify**:
- Checks existing proofs without modification (max_attempts=0)
- Runs `lean_build` to verify compilation
- Checks `lean_diagnostic_messages` for errors
- Creates verification summary

### MCP Tool Integration

The lean-implementer agent uses these MCP tools:
- `lean_goal` - Extract proof goals
- `lean_leansearch` - Natural language theorem search
- `lean_loogle` - Type-based theorem search
- `lean_multi_attempt` - Multi-proof screening
- `lean_build` - Project compilation
- `lean_diagnostic_messages` - Error checking

### Error Handling

Errors are logged to `.claude/data/logs/errors.jsonl` with:
- **validation_error**: Invalid arguments, missing files
- **dependency_error**: MCP server not available, not a Lean project
- **agent_error**: lean-implementer failure
- **execution_error**: Proof incomplete, diagnostics errors
- **file_error**: File not found

### Integration with /plan and /test

1. **Create plan**: `/plan "Formalize TM modal axioms in Lean"`
2. **Prove theorems**: `/lean path/to/plan.md --prove-all`
3. **Verify compilation**: `cd project && lake build`

## Success Criteria

Workflow is successful if:
- ✅ lean-implementer agent invoked correctly
- ✅ Summary created in summaries directory (≥100 bytes)
- ✅ Proof completion tracked (theorems_proven count)
- ✅ Diagnostics checked and reported
- ✅ All errors logged to errors.jsonl
