#!/usr/bin/env bash
# validate-agent-invocation-pattern.sh
# Detects anti-patterns in orchestration command files

set -euo pipefail

# Usage: validate-agent-invocation-pattern.sh <command-file>
# Exit codes: 0 = pass, 1 = violations found

COMMAND_FILE="${1:-}"

if [[ -z "$COMMAND_FILE" ]]; then
  echo "ERROR: No command file specified"
  echo "Usage: $0 <command-file>"
  exit 2
fi

if [[ ! -f "$COMMAND_FILE" ]]; then
  echo "ERROR: File not found: $COMMAND_FILE"
  exit 2
fi

VIOLATIONS_FOUND=0
VIOLATION_COUNT=0

echo "Validating agent invocation patterns in: $COMMAND_FILE"
echo "========================================================"
echo ""

# Check 1: Detect YAML-style Task blocks
echo "[Check 1] Detecting YAML-style Task blocks..."
if grep -n "^Task {$" "$COMMAND_FILE" 2>/dev/null || \
   grep -n "^[[:space:]]*Task {$" "$COMMAND_FILE" 2>/dev/null; then
  echo "  ❌ VIOLATION: YAML-style Task blocks found"
  echo "     Task invocations should use imperative bullet-point pattern"
  echo "     Example: **EXECUTE NOW**: USE the Task tool with these parameters:"
  echo ""
  grep -n "^[[:space:]]*Task {" "$COMMAND_FILE" 2>/dev/null || true
  echo ""
  VIOLATIONS_FOUND=1
  ((VIOLATION_COUNT++))
else
  echo "  ✓ No YAML-style Task blocks found"
fi
echo ""

# Check 2: Detect markdown code fences around Task invocations
echo "[Check 2] Detecting code fences around Task invocations..."
# Look for ```yaml or ```markdown followed by Task within next 5 lines
YAML_FENCE_LINES=$(grep -n '```yaml' "$COMMAND_FILE" 2>/dev/null | cut -d: -f1 || true)
MD_FENCE_LINES=$(grep -n '```markdown' "$COMMAND_FILE" 2>/dev/null | cut -d: -f1 || true)

FOUND_YAML_TASK=0
for line in $YAML_FENCE_LINES; do
  # Check if "Task" appears within next 5 lines
  if sed -n "${line},$((line + 5))p" "$COMMAND_FILE" | grep -q "Task"; then
    echo "  ❌ VIOLATION: Code fence wrapper found around Task invocation (line $line)"
    FOUND_YAML_TASK=1
  fi
done

FOUND_MD_TASK=0
for line in $MD_FENCE_LINES; do
  if sed -n "${line},$((line + 5))p" "$COMMAND_FILE" | grep -q "Task"; then
    echo "  ❌ VIOLATION: Markdown fence wrapper found around Task invocation (line $line)"
    FOUND_MD_TASK=1
  fi
done

if [[ $FOUND_YAML_TASK -eq 1 ]] || [[ $FOUND_MD_TASK -eq 1 ]]; then
  echo "     Task invocations should NOT be wrapped in code fences"
  echo "     Code fences make instructions appear as documentation"
  echo ""
  VIOLATIONS_FOUND=1
  ((VIOLATION_COUNT++))
else
  echo "  ✓ No code fence wrappers found around Task invocations"
fi
echo ""

# Check 3: Detect template variables in agent prompts
echo "[Check 3] Detecting template variables in command file..."
TEMPLATE_VARS=$(grep -n '\${[A-Z_]*}' "$COMMAND_FILE" 2>/dev/null || true)
if [[ -n "$TEMPLATE_VARS" ]]; then
  echo "  ❌ VIOLATION: Template variables found (will never be substituted)"
  echo "$TEMPLATE_VARS"
  echo "     Replace template variables with instructions to insert actual values"
  echo "     Example: Instead of \${TOPIC_NAME}, use: [insert topic name from user input]"
  echo ""
  VIOLATIONS_FOUND=1
  ((VIOLATION_COUNT++))
else
  echo "  ✓ No template variables found"
fi
echo ""

# Check 4: Detect bash code blocks that should be Bash tool invocations
echo "[Check 4] Detecting bash code blocks without EXECUTE NOW prefix..."
# Look for ```bash blocks that don't have "EXECUTE NOW" or "USE the Bash tool" within 3 lines before
BASH_BLOCKS=$(grep -n '```bash' "$COMMAND_FILE" 2>/dev/null | cut -d: -f1 || true)
MISSING_EXECUTE=0

for line in $BASH_BLOCKS; do
  # Check if "EXECUTE NOW" or "USE the Bash tool" appears in previous 3 lines
  START_LINE=$((line > 3 ? line - 3 : 1))
  if ! sed -n "${START_LINE},$((line - 1))p" "$COMMAND_FILE" | grep -q -E "(EXECUTE NOW|USE the Bash tool)"; then
    # Skip if this is a code example (within an example section or fenced in another code block)
    # This is a heuristic check - look for "Example:" or "```" in previous lines
    if ! sed -n "${START_LINE},$((line - 1))p" "$COMMAND_FILE" | grep -q -E "(Example:|example:|```|For example)"; then
      echo "  ⚠️  WARNING: Bash code block at line $line may lack EXECUTE NOW directive"
      MISSING_EXECUTE=1
    fi
  fi
done

if [[ $MISSING_EXECUTE -eq 1 ]]; then
  echo "     Bash code blocks should have explicit execution directives"
  echo "     Add: **EXECUTE NOW**: USE the Bash tool to [description]"
  echo "     Note: This is a warning, not a hard failure"
  echo ""
  # Don't count as violation for exit code, just warn
else
  echo "  ✓ Bash code blocks have execution directives"
fi
echo ""

# Check 5: Verify imperative phrasing for Task invocations
echo "[Check 5] Verifying imperative phrasing patterns..."
# Look for "USE the Task tool" pattern which indicates imperative style
IMPERATIVE_COUNT=$(grep -c "USE the Task tool" "$COMMAND_FILE" 2>/dev/null || echo "0")
TASK_COUNT=$(grep -c "subagent_type:" "$COMMAND_FILE" 2>/dev/null || echo "0")

if [[ $TASK_COUNT -gt 0 ]]; then
  if [[ $IMPERATIVE_COUNT -eq 0 ]]; then
    echo "  ❌ VIOLATION: Task invocations found but no imperative phrasing detected"
    echo "     Expected: 'USE the Task tool NOW' or similar imperative directive"
    echo "     Found $TASK_COUNT subagent_type references but 0 imperative directives"
    echo ""
    VIOLATIONS_FOUND=1
    ((VIOLATION_COUNT++))
  elif [[ $IMPERATIVE_COUNT -lt $TASK_COUNT ]]; then
    echo "  ⚠️  WARNING: Some Task invocations may lack imperative phrasing"
    echo "     Found $TASK_COUNT subagent_type references but only $IMPERATIVE_COUNT imperative directives"
    echo ""
  else
    echo "  ✓ Imperative phrasing pattern detected ($IMPERATIVE_COUNT occurrences)"
  fi
else
  echo "  ℹ️  No Task invocations found in this file"
fi
echo ""

# Summary
echo "========================================================"
echo "Validation Summary"
echo "========================================================"
if [[ $VIOLATIONS_FOUND -eq 0 ]]; then
  echo "✓ PASS: No violations detected"
  echo ""
  exit 0
else
  echo "❌ FAIL: $VIOLATION_COUNT violation(s) detected"
  echo ""
  echo "Next steps:"
  echo "1. Review violations listed above"
  echo "2. Apply imperative bullet-point pattern transformation"
  echo "3. Reference: .claude/commands/supervise.md (proven working pattern)"
  echo "4. Re-run validation after fixes"
  echo ""
  exit 1
fi
