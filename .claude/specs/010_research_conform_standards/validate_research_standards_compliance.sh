#!/bin/bash
# validate_research_standards_compliance.sh - Comprehensive standards validation

set -e

FAILED=0
CLAUDE_PROJECT_DIR="/home/benjamin/.config"
RESEARCH_CMD="${CLAUDE_PROJECT_DIR}/.claude/commands/research.md"

echo "========================================="
echo "Standards Compliance Validation"
echo "========================================="
echo ""

# Validation 1: Block size threshold (<400 lines)
echo "Validation 1: Block size threshold (<400 lines)"
echo "-----------------------------------------------"

BLOCK_NUM=0
OVERSIZED=0

awk '/^```bash$/,/^```$/' "$RESEARCH_CMD" | \
  awk 'BEGIN {block=0; count=0}
       /^```bash$/ {
         if (count > 0) {
           block++;
           if (count > 400) {
             print "Block " block ": " count " lines - EXCEEDS LIMIT";
             exit 1;
           } else {
             print "Block " block ": " count " lines - OK";
           }
         }
         block++;
         count=0;
         next;
       }
       /^```$/ {next}
       {count++}
       END {
         if (count > 0) {
           block++;
           if (count > 400) {
             print "Block " block ": " count " lines - EXCEEDS LIMIT";
             exit 1;
           } else {
             print "Block " block ": " count " lines - OK";
           }
         }
       }'

BLOCK_SIZE_EXIT=$?
if [ $BLOCK_SIZE_EXIT -ne 0 ]; then
  echo "FAIL: Found block(s) exceeding 400 line limit"
  FAILED=1
else
  echo "PASS: All bash blocks under 400 lines"
fi

echo ""

# Validation 2: Explicit array declarations
echo "Validation 2: Explicit array declarations"
echo "-----------------------------------------"

if grep -q "declare -a TOPICS_ARRAY" "$RESEARCH_CMD"; then
  echo "PASS: Explicit TOPICS_ARRAY declaration found"
else
  echo "FAIL: Missing explicit TOPICS_ARRAY declaration"
  FAILED=1
fi

if grep -q "declare -a REPORT_PATHS_ARRAY" "$RESEARCH_CMD"; then
  echo "PASS: Explicit REPORT_PATHS_ARRAY declaration found"
else
  echo "FAIL: Missing explicit REPORT_PATHS_ARRAY declaration"
  FAILED=1
fi

echo ""

# Validation 3: Quoted array expansions
echo "Validation 3: Quoted array expansions"
echo "-------------------------------------"

# Check TOPICS_ARRAY
UNQUOTED=$(grep -n '\${TOPICS_ARRAY\[' "$RESEARCH_CMD" | grep -v '"' | grep -v '#' || echo "")
if [ -z "$UNQUOTED" ]; then
  echo "PASS: All TOPICS_ARRAY expansions properly quoted"
else
  echo "FAIL: Found unquoted TOPICS_ARRAY expansions:"
  echo "$UNQUOTED"
  FAILED=1
fi

# Check REPORT_PATHS_ARRAY
UNQUOTED=$(grep -n '\${REPORT_PATHS_ARRAY\[' "$RESEARCH_CMD" | grep -v '"' | grep -v '#' || echo "")
if [ -z "$UNQUOTED" ]; then
  echo "PASS: All REPORT_PATHS_ARRAY expansions properly quoted"
else
  echo "FAIL: Found unquoted REPORT_PATHS_ARRAY expansions:"
  echo "$UNQUOTED"
  FAILED=1
fi

echo ""

# Validation 4: Library sourcing patterns
echo "Validation 4: Library sourcing patterns"
echo "---------------------------------------"

if bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/check-library-sourcing.sh" "$RESEARCH_CMD" 2>&1 | grep -q "ERROR"; then
  echo "FAIL: Library sourcing validation failed"
  bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/check-library-sourcing.sh" "$RESEARCH_CMD"
  FAILED=1
else
  echo "PASS: Three-tier library sourcing pattern validated"
fi

echo ""

# Validation 5: Bash conditional linter
echo "Validation 5: Bash conditional patterns"
echo "---------------------------------------"

if bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint_bash_conditionals.sh" "$RESEARCH_CMD" 2>&1 | grep -q "ERROR"; then
  echo "FAIL: Bash conditional validation failed"
  bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint_bash_conditionals.sh" "$RESEARCH_CMD"
  FAILED=1
else
  echo "PASS: Bash conditional patterns validated"
fi

echo ""

# Validation 6: Manual checklist
echo "Validation 6: Manual checklist verification"
echo "-------------------------------------------"

# Check for set +H in all bash blocks
SET_H_COUNT=$(grep -c "set +H 2>/dev/null" "$RESEARCH_CMD" || echo 0)
if [ "$SET_H_COUNT" -ge 4 ]; then
  echo "PASS: All bash blocks have 'set +H' ($SET_H_COUNT blocks)"
else
  echo "FAIL: Missing 'set +H' in some blocks (found $SET_H_COUNT, expected >= 4)"
  FAILED=1
fi

# Check for output suppression (library sourcing with 2>/dev/null)
if grep -q "source.*2>/dev/null" "$RESEARCH_CMD"; then
  echo "PASS: Output suppression applied to library sourcing"
else
  echo "FAIL: Missing output suppression in library sourcing"
  FAILED=1
fi

# Check for checkpoint markers
CHECKPOINT_COUNT=$(grep -c "CHECKPOINT:" "$RESEARCH_CMD" || echo 0)
if [ "$CHECKPOINT_COUNT" -ge 3 ]; then
  echo "PASS: Checkpoint markers present ($CHECKPOINT_COUNT found)"
else
  echo "FAIL: Insufficient checkpoint markers (found $CHECKPOINT_COUNT, expected >= 3)"
  FAILED=1
fi

# Check for Task invocation patterns
if grep -q "**EXECUTE NOW**:" "$RESEARCH_CMD"; then
  echo "PASS: Task invocation imperative directives found"
else
  echo "WARNING: Task invocation directives may be missing"
fi

# Check for error handling trap setup
if grep -q "setup_bash_error_trap" "$RESEARCH_CMD"; then
  echo "PASS: Error handling traps configured"
else
  echo "FAIL: Missing error handling trap setup"
  FAILED=1
fi

# Check for state persistence calls
if grep -q "append_workflow_state" "$RESEARCH_CMD"; then
  echo "PASS: State persistence calls found"
else
  echo "FAIL: Missing state persistence calls"
  FAILED=1
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
  echo "RESULT: ALL VALIDATIONS PASSED"
  echo "========================================="
  echo ""
  echo "The /research command complies with all CLAUDE.md standards:"
  echo "  - Block size limits (<400 lines per block)"
  echo "  - Explicit array declarations (declare -a)"
  echo "  - Quoted array expansions"
  echo "  - Three-tier library sourcing"
  echo "  - Preprocessing safety (set +H)"
  echo "  - Output suppression (2>/dev/null)"
  echo "  - Error handling (bash error traps)"
  echo "  - State persistence patterns"
  echo ""
  exit 0
else
  echo "RESULT: SOME VALIDATIONS FAILED"
  echo "========================================="
  exit 1
fi
