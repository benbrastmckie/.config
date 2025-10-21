# Phase 4: System-Wide Validation and Anti-Pattern Detection - EXPANDED

## Phase Metadata
- **Parent Plan**: `002_fix_all_command_subagent_delegation.md`
- **Phase Number**: 4
- **Complexity**: High (7/10)
- **Estimated Duration**: 2-3 hours
- **Architectural Significance**: HIGH - prevents future violations, ensures compliance
- **Expansion Date**: 2025-10-20

## Phase Overview

This phase creates comprehensive validation infrastructure to ensure:
1. **Zero SlashCommand anti-patterns** in agent behavioral files
2. **100% behavioral injection compliance** across all commands
3. **100% topic-based artifact organization** compliance
4. **Regression prevention** through automated validation
5. **System-wide coverage** (all agents, all commands)

### Why This Phase is Critical

**System-Wide Impact**:
- Validates fixes across 2 agents, 2 commands, and entire codebase
- Prevents future anti-pattern violations through automated detection
- Ensures artifact organization compliance with `.claude/docs/README.md` standards
- Creates permanent validation infrastructure for ongoing quality assurance

**Complexity Analysis** (Score: 7/10):
- **Multi-dimensional validation**: 3 distinct validators (agents, commands, artifacts)
- **Comprehensive scanning**: 100% agent file coverage, 100% command coverage
- **Pattern detection complexity**: Multiple anti-pattern signatures, regex patterns
- **Organization validation**: Directory structure compliance, path format validation
- **Integration requirements**: Master test orchestrator, test suite integration

## Implementation Tasks

### Task 1: Create Anti-Pattern Detection Script for Agent Files

**Objective**: Detect SlashCommand invocations in agent behavioral files

**File**: `.claude/tests/validate_no_agent_slash_commands.sh`

**Full Script Implementation**:

```bash
#!/usr/bin/env bash
# Validates that NO agent behavioral files contain slash command invocations
# This prevents the anti-pattern where agents delegate artifact creation
# to slash commands instead of creating files directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════════════════"
echo "  Agent Behavioral Files: Anti-Pattern Detection"
echo "════════════════════════════════════════════════════════════"
echo ""

VIOLATIONS=0
AGENTS_SCANNED=0
VIOLATION_DETAILS=""

# Get all agent behavioral files
AGENT_FILES=$(find "${PROJECT_ROOT}/.claude/agents" -name "*.md" -type f 2>/dev/null || true)

if [ -z "$AGENT_FILES" ]; then
  echo -e "${RED}ERROR: No agent files found in .claude/agents/${NC}"
  exit 1
fi

# Scan each agent file
for agent_file in $AGENT_FILES; do
  agent_name=$(basename "$agent_file" .md)
  AGENTS_SCANNED=$((AGENTS_SCANNED + 1))

  echo -n "Scanning: ${agent_name}... "

  # Anti-pattern 1: Direct SlashCommand tool usage
  if grep -q "SlashCommand" "$agent_file" 2>/dev/null; then
    echo -e "${RED}VIOLATION${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
    VIOLATION_DETAILS="${VIOLATION_DETAILS}
${RED}✗ ${agent_name}.md${NC}
  Anti-pattern: Contains 'SlashCommand' tool usage
  Lines:"
    VIOLATION_DETAILS="${VIOLATION_DETAILS}
$(grep -n "SlashCommand" "$agent_file" | head -5)"
    continue
  fi

  # Anti-pattern 2: Explicit slash command invocation instructions
  # Look for patterns like "invoke /plan", "use /report", "call /implement"
  SLASH_COMMANDS=("/plan" "/report" "/debug" "/implement" "/orchestrate" "/setup")
  FOUND_VIOLATION=false

  for cmd in "${SLASH_COMMANDS[@]}"; do
    # Match patterns: "invoke /plan", "use /plan", "call /plan", "run /plan"
    if grep -qiE "(invoke|use|call|run|execute)\s+${cmd}" "$agent_file" 2>/dev/null; then
      if [ "$FOUND_VIOLATION" = false ]; then
        echo -e "${RED}VIOLATION${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
        VIOLATION_DETAILS="${VIOLATION_DETAILS}
${RED}✗ ${agent_name}.md${NC}
  Anti-pattern: Instructions to invoke '${cmd}' slash command
  Lines:"
        FOUND_VIOLATION=true
      fi
      VIOLATION_DETAILS="${VIOLATION_DETAILS}
$(grep -niE "(invoke|use|call|run|execute)\s+${cmd}" "$agent_file" | head -3)"
    fi
  done

  if [ "$FOUND_VIOLATION" = false ]; then
    echo -e "${GREEN}✓ CLEAN${NC}"
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Scan Results"
echo "════════════════════════════════════════════════════════════"
echo "Agents scanned: $AGENTS_SCANNED"
echo "Violations found: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -gt 0 ]; then
  echo -e "${RED}VIOLATIONS DETECTED:${NC}"
  echo -e "$VIOLATION_DETAILS"
  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo -e "${YELLOW}Fix Instructions:${NC}"
  echo "1. Remove SlashCommand tool invocations from agent files"
  echo "2. Update agents to create artifacts directly using Write/Edit tools"
  echo "3. Ensure commands pre-calculate paths and inject them into agent prompts"
  echo "4. Reference: .claude/docs/guides/agent-authoring-guide.md"
  echo ""
  exit 1
else
  echo -e "${GREEN}✅ All agent behavioral files are CLEAN${NC}"
  echo "   No slash command anti-patterns detected"
  echo ""
  exit 0
fi
```

**Anti-Pattern Detection Logic**:

1. **SlashCommand Tool Detection**:
   - Pattern: `grep "SlashCommand"`
   - Detects: Direct use of SlashCommand tool in agent behavioral files
   - Example violation: `Use SlashCommand tool to invoke /plan`

2. **Explicit Command Invocation Detection**:
   - Pattern: `grep -iE "(invoke|use|call|run|execute)\s+/command"`
   - Detects: Instructions to invoke specific slash commands
   - Example violations:
     - "invoke /plan with feature description"
     - "use /report to create research report"
     - "call /implement for plan execution"

3. **Coverage**:
   - Scans all `.md` files in `.claude/agents/`
   - Reports line numbers for violations
   - Provides actionable fix instructions

**Expected Output**:

```
════════════════════════════════════════════════════════════
  Agent Behavioral Files: Anti-Pattern Detection
════════════════════════════════════════════════════════════

Scanning: research-specialist... ✓ CLEAN
Scanning: plan-architect... ✓ CLEAN
Scanning: code-writer... ✓ CLEAN
Scanning: doc-writer... ✓ CLEAN
Scanning: debug-analyst... ✓ CLEAN
...

════════════════════════════════════════════════════════════
  Scan Results
════════════════════════════════════════════════════════════
Agents scanned: 15
Violations found: 0

✅ All agent behavioral files are CLEAN
   No slash command anti-patterns detected
```

---

### Task 2: Create Behavioral Injection Compliance Validator

**Objective**: Validate commands using agents follow behavioral injection pattern

**File**: `.claude/tests/validate_command_behavioral_injection.sh`

**Full Script Implementation**:

```bash
#!/usr/bin/env bash
# Validates that commands using agents follow behavioral injection pattern
# Checks for:
# 1. Pre-calculated artifact paths (before agent invocation)
# 2. Topic-based directory structure usage
# 3. Artifact verification patterns
# 4. Metadata extraction (not full content loading)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  Command Behavioral Injection Compliance Validation"
echo "════════════════════════════════════════════════════════════"
echo ""

COMMANDS_CHECKED=0
WARNINGS=0
PASSES=0

# Commands known to use agents for artifact creation
ARTIFACT_COMMANDS=(
  "orchestrate"
  "implement"
  "plan"
  "report"
  "debug"
)

for cmd in "${ARTIFACT_COMMANDS[@]}"; do
  cmd_file="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

  if [[ ! -f "$cmd_file" ]]; then
    echo -e "${YELLOW}⚠️  Command file not found: ${cmd}.md${NC}"
    continue
  fi

  COMMANDS_CHECKED=$((COMMANDS_CHECKED + 1))
  echo -e "${BLUE}Checking: /$cmd${NC}"
  echo "────────────────────────────────────────────────────────────"

  # Check 1: Task tool usage (indicates agent invocation)
  if ! grep -q "Task {" "$cmd_file"; then
    echo "  ℹ️  No Task tool usage (command may not use agents)"
    echo ""
    continue
  fi

  HAS_ISSUES=false

  # Check 2: Pre-calculated paths (good pattern)
  if grep -qE "(PATH=.*specs/|create_topic_artifact|get_or_create_topic_dir)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Path pre-calculation found"
  else
    echo -e "  ${YELLOW}⚠${NC} No path pre-calculation detected"
    WARNINGS=$((WARNINGS + 1))
    HAS_ISSUES=true
  fi

  # Check 3: Topic-based artifact organization
  if grep -q "create_topic_artifact" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Uses create_topic_artifact() utility"
  else
    # Check for manual path construction (anti-pattern)
    if grep -qE "specs/(reports|plans|summaries)/[^/]+\.md" "$cmd_file"; then
      echo -e "  ${YELLOW}⚠${NC} Manual path construction detected (should use create_topic_artifact)"
      WARNINGS=$((WARNINGS + 1))
      HAS_ISSUES=true
    else
      echo "  ℹ️  May not create artifacts directly"
    fi
  fi

  # Check 4: Artifact verification (good pattern)
  if grep -qE "(verify.*artifact|if.*-f.*PATH|test -f)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Artifact verification found"
  else
    echo -e "  ${YELLOW}⚠${NC} No artifact verification detected"
    WARNINGS=$((WARNINGS + 1))
    HAS_ISSUES=true
  fi

  # Check 5: Metadata extraction (good pattern)
  if grep -qE "(extract.*metadata|jq.*summary|METADATA=)" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Metadata extraction found"
  else
    echo "  ℹ️  Metadata extraction not detected (may load full artifacts)"
  fi

  # Check 6: Behavioral injection pattern
  if grep -qE "Read and follow.*behavioral|acting as.*Agent" "$cmd_file"; then
    echo -e "  ${GREEN}✓${NC} Behavioral injection pattern found"
  else
    echo "  ℹ️  No explicit behavioral injection (may use direct prompts)"
  fi

  if [ "$HAS_ISSUES" = false ]; then
    PASSES=$((PASSES + 1))
  fi

  echo ""
done

echo "════════════════════════════════════════════════════════════"
echo "  Validation Summary"
echo "════════════════════════════════════════════════════════════"
echo "Commands checked: $COMMANDS_CHECKED"
echo "Commands passing: $PASSES"
echo "Warnings issued: $WARNINGS"
echo ""

if [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ All commands follow behavioral injection best practices${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some commands have compliance warnings${NC}"
  echo ""
  echo "Recommendations:"
  echo "1. Use create_topic_artifact() for all artifact path calculations"
  echo "2. Add artifact verification after agent completion"
  echo "3. Extract metadata instead of loading full artifact content"
  echo "4. Reference: .claude/docs/guides/command-authoring-guide.md"
  echo ""
  exit 0  # Warnings don't fail build, only violations do
fi
```

**Validation Checks**:

1. **Path Pre-Calculation**:
   - Pattern: `PATH=.*specs/|create_topic_artifact|get_or_create_topic_dir`
   - Validates: Paths calculated before agent invocation
   - Good: `PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "impl" "")`

2. **Topic-Based Organization**:
   - Pattern: `create_topic_artifact`
   - Validates: Use of utility function (not manual construction)
   - Bad: `REPORT_PATH="specs/reports/001_topic.md"` (flat structure)
   - Good: `REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "topic" "")`

3. **Artifact Verification**:
   - Pattern: `verify.*artifact|if.*-f.*PATH`
   - Validates: Commands check artifact exists after agent completes
   - Good: `if [ ! -f "$PLAN_PATH" ]; then echo "ERROR"; exit 1; fi`

4. **Metadata Extraction**:
   - Pattern: `extract.*metadata|jq.*summary`
   - Validates: Commands extract metadata (not full content)
   - Good: `PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")`

5. **Behavioral Injection**:
   - Pattern: `Read and follow.*behavioral|acting as.*Agent`
   - Validates: Commands reference agent behavioral files
   - Good: `Read and follow behavioral guidelines from: .claude/agents/plan-architect.md`

---

### Task 3: Create Topic-Based Artifact Organization Validator

**Objective**: Ensure all artifacts follow topic-based directory structure

**File**: `.claude/tests/validate_topic_based_artifacts.sh`

**Full Script Implementation**:

```bash
#!/usr/bin/env bash
# Validates that all artifacts follow topic-based organization standard
# Reference: .claude/docs/README.md lines 114-138
#
# Topic-based structure: specs/{NNN_topic}/reports/, specs/{NNN_topic}/plans/, etc.
# Flat structure (WRONG): specs/reports/001_topic.md, specs/plans/001_plan.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  Topic-Based Artifact Organization Validation"
echo "════════════════════════════════════════════════════════════"
echo ""

VIOLATIONS=0
TOPIC_DIRS_FOUND=0
ARTIFACTS_VALIDATED=0

# Check 1: Detect flat directory structure violations (WRONG)
echo -e "${BLUE}[1/4] Checking for flat directory structure violations...${NC}"
echo ""

FLAT_REPORTS=$(find "${PROJECT_ROOT}/specs" -maxdepth 2 -path "*/reports/*.md" -not -path "*/[0-9][0-9][0-9]_*/reports/*" 2>/dev/null || true)
FLAT_PLANS=$(find "${PROJECT_ROOT}/specs" -maxdepth 2 -path "*/plans/*.md" -not -path "*/[0-9][0-9][0-9]_*/plans/*" 2>/dev/null || true)

if [ -n "$FLAT_REPORTS" ]; then
  echo -e "${RED}✗ VIOLATION: Found reports in flat structure${NC}"
  echo "  Location: specs/reports/ (should be specs/{NNN_topic}/reports/)"
  echo "  Files:"
  echo "$FLAT_REPORTS" | head -5 | sed 's/^/    /'
  if [ $(echo "$FLAT_REPORTS" | wc -l) -gt 5 ]; then
    echo "    ... and $(($(echo "$FLAT_REPORTS" | wc -l) - 5)) more"
  fi
  VIOLATIONS=$((VIOLATIONS + 1))
  echo ""
fi

if [ -n "$FLAT_PLANS" ]; then
  echo -e "${RED}✗ VIOLATION: Found plans in flat structure${NC}"
  echo "  Location: specs/plans/ (should be specs/{NNN_topic}/plans/)"
  echo "  Files:"
  echo "$FLAT_PLANS" | head -5 | sed 's/^/    /'
  if [ $(echo "$FLAT_PLANS" | wc -l) -gt 5 ]; then
    echo "    ... and $(($(echo "$FLAT_PLANS" | wc -l) - 5)) more"
  fi
  VIOLATIONS=$((VIOLATIONS + 1))
  echo ""
fi

if [ -z "$FLAT_REPORTS" ] && [ -z "$FLAT_PLANS" ]; then
  echo -e "${GREEN}✓ No flat directory structure violations${NC}"
  echo ""
fi

# Check 2: Validate topic-based directories exist and are properly structured
echo -e "${BLUE}[2/4] Validating topic-based directory structure...${NC}"
echo ""

if [ ! -d "${PROJECT_ROOT}/specs" ]; then
  echo -e "${YELLOW}⚠️  No specs/ directory found (may be new project)${NC}"
  echo ""
else
  TOPIC_DIRS=$(find "${PROJECT_ROOT}/specs" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null || true)

  if [ -z "$TOPIC_DIRS" ]; then
    echo -e "${YELLOW}⚠️  No topic-based directories found${NC}"
    echo "   Expected format: specs/{NNN_topic}/ (e.g., specs/027_authentication/)"
    echo ""
  else
    TOPIC_DIRS_FOUND=$(echo "$TOPIC_DIRS" | wc -l)
    echo -e "${GREEN}✓ Found $TOPIC_DIRS_FOUND topic-based directories${NC}"
    echo ""

    # Validate structure of each topic directory
    for topic_dir in $TOPIC_DIRS; do
      topic_name=$(basename "$topic_dir")

      # Count artifacts in each subdirectory
      for subdir in reports plans summaries debug scripts outputs; do
        if [ -d "$topic_dir/$subdir" ]; then
          count=$(find "$topic_dir/$subdir" -name "*.md" -o -name "*.sh" 2>/dev/null | wc -l)
          ARTIFACTS_VALIDATED=$((ARTIFACTS_VALIDATED + count))
          if [ $count -gt 0 ]; then
            echo "  ✓ $topic_name/$subdir/: $count artifacts"
          fi
        fi
      done
    done
    echo ""
  fi
fi

# Check 3: Validate commands use create_topic_artifact() utility
echo -e "${BLUE}[3/4] Checking commands use create_topic_artifact()...${NC}"
echo ""

COMMANDS_WITH_AGENTS=("orchestrate" "plan" "report" "debug" "implement")
MANUAL_CONSTRUCTION_FOUND=0

for cmd in "${COMMANDS_WITH_AGENTS[@]}"; do
  cmd_file="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

  if [[ ! -f "$cmd_file" ]]; then
    continue
  fi

  # Check if command creates artifacts
  if grep -q "Task {" "$cmd_file"; then
    # Check if it uses create_topic_artifact
    if grep -q "create_topic_artifact" "$cmd_file"; then
      echo -e "  ${GREEN}✓${NC} /$cmd: Uses create_topic_artifact()"
    else
      # Check if it manually constructs paths (anti-pattern)
      if grep -qE "PATH=.*specs/(reports|plans|summaries)/[^/]+\.md" "$cmd_file"; then
        echo -e "  ${RED}✗${NC} /$cmd: Manual path construction detected"
        echo "     Should use: create_topic_artifact()"
        VIOLATIONS=$((VIOLATIONS + 1))
        MANUAL_CONSTRUCTION_FOUND=1
      else
        echo "  ℹ️  /$cmd: May not create artifacts directly"
      fi
    fi
  fi
done

if [ $MANUAL_CONSTRUCTION_FOUND -eq 0 ]; then
  echo -e "${GREEN}✓ All commands use proper artifact creation utilities${NC}"
fi
echo ""

# Check 4: Validate artifact numbering consistency
echo -e "${BLUE}[4/4] Validating artifact numbering consistency...${NC}"
echo ""

NUMBERING_ISSUES=0

if [ -n "$TOPIC_DIRS" ]; then
  for topic_dir in $TOPIC_DIRS; do
    topic_name=$(basename "$topic_dir")
    topic_num=$(echo "$topic_name" | grep -oE '^[0-9]{3}')

    # Check that artifacts in topic directory start with same number
    for subdir in reports plans summaries; do
      if [ -d "$topic_dir/$subdir" ]; then
        MISMATCHED=$(find "$topic_dir/$subdir" -name "*.md" ! -name "${topic_num}_*.md" 2>/dev/null || true)
        if [ -n "$MISMATCHED" ]; then
          echo -e "  ${YELLOW}⚠${NC} $topic_name/$subdir/: Found artifacts not starting with $topic_num"
          echo "$MISMATCHED" | head -3 | sed 's/^/     /'
          NUMBERING_ISSUES=$((NUMBERING_ISSUES + 1))
        fi
      fi
    done
  done

  if [ $NUMBERING_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All artifacts use consistent numbering${NC}"
  fi
else
  echo "  ℹ️  No topic directories to validate"
fi
echo ""

# Summary
echo "════════════════════════════════════════════════════════════"
echo "  Validation Summary"
echo "════════════════════════════════════════════════════════════"
echo "Topic directories found: $TOPIC_DIRS_FOUND"
echo "Artifacts validated: $ARTIFACTS_VALIDATED"
echo "Violations detected: $VIOLATIONS"
echo ""

if [ $VIOLATIONS -eq 0 ]; then
  echo -e "${GREEN}✅ Topic-based artifact organization validated${NC}"
  echo "   All artifacts follow proper directory structure"
  echo ""
  exit 0
else
  echo -e "${RED}❌ Found $VIOLATIONS organization violations${NC}"
  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo -e "${YELLOW}Fix Instructions:${NC}"
  echo "1. Move flat artifacts to topic-based structure:"
  echo "   specs/reports/001_topic.md → specs/{NNN_topic}/reports/001_topic.md"
  echo ""
  echo "2. Update commands to use create_topic_artifact():"
  echo "   source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh\""
  echo "   TOPIC_DIR=\$(get_or_create_topic_dir \"\$DESCRIPTION\" \"specs\")"
  echo "   REPORT_PATH=\$(create_topic_artifact \"\$TOPIC_DIR\" \"reports\" \"topic\" \"\")"
  echo ""
  echo "3. Reference: .claude/docs/README.md lines 114-138"
  echo ""
  exit 1
fi
```

**Organization Validation Logic**:

1. **Flat Structure Detection**:
   - Searches: `specs/reports/*.md` NOT in `specs/{NNN_topic}/reports/`
   - Searches: `specs/plans/*.md` NOT in `specs/{NNN_topic}/plans/`
   - Reports: Files in wrong locations with fix instructions

2. **Topic Directory Validation**:
   - Finds: All directories matching `specs/{NNN_topic}/` pattern
   - Validates: Proper subdirectories (reports/, plans/, summaries/, debug/)
   - Counts: Artifacts per subdirectory for coverage metrics

3. **Utility Function Usage**:
   - Checks: Commands use `create_topic_artifact()` function
   - Detects: Manual path construction like `PATH="specs/reports/001_topic.md"`
   - Reports: Commands violating artifact creation standards

4. **Numbering Consistency**:
   - Validates: Artifacts in `specs/027_topic/` start with `027_`
   - Detects: Mismatched numbering (e.g., `042_report.md` in `027_topic/`)
   - Reports: Numbering inconsistencies for correction

---

### Task 4: Integrate Validators into Test Suite

**Objective**: Add new validators to master test runner

**File**: `.claude/tests/run_all_tests.sh` (modification)

**Changes Required**:

Add validation scripts to test discovery:

```bash
# After line 34 (find test files):

# Find all test files
TEST_FILES=$(find "$TEST_DIR" -name "test_*.sh" -not -name "run_all_tests.sh" | sort)

# ADD: Find all validation scripts
VALIDATION_FILES=$(find "$TEST_DIR" -name "validate_*.sh" | sort)

# Combine test and validation files
ALL_TEST_FILES="$TEST_FILES $VALIDATION_FILES"

# ... rest of script uses ALL_TEST_FILES instead of TEST_FILES
```

**Integration Pattern**:
- Validation scripts follow same naming pattern as tests
- Exit codes: 0 = pass, 1 = fail
- Output format: Compatible with test runner parser
- Run during: Every test suite execution

---

### Task 5: Create Master Test Orchestrator

**Objective**: Comprehensive test runner for all delegation fixes

**File**: `.claude/tests/test_all_delegation_fixes.sh`

**Full Script Implementation**:

```bash
#!/usr/bin/env bash
# Master test orchestrator for all subagent delegation fixes
# Tests Phases 2, 3, and 4 (code-writer, orchestrate, system-wide)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  Subagent Delegation Fixes - Master Test Suite"
echo "════════════════════════════════════════════════════════════"
echo ""

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=""

run_test() {
  local test_name="$1"
  local test_script="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -e "${BLUE}[$TESTS_RUN] Running: $test_name${NC}"
  echo "────────────────────────────────────────────────────────────"

  if bash "$test_script" 2>&1; then
    echo -e "${GREEN}✓ PASSED: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo ""
    return 0
  else
    echo -e "${RED}✗ FAILED: $test_name${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS="${FAILED_TESTS}  - $test_name\n"
    echo ""
    return 1
  fi
}

echo -e "${BLUE}Phase 2: /implement code-writer Fix${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/test_code_writer_no_recursion.sh" ]; then
  run_test "Code-writer No Recursion" \
    "$SCRIPT_DIR/test_code_writer_no_recursion.sh"
else
  echo -e "${YELLOW}⊘ SKIPPED: test_code_writer_no_recursion.sh not found${NC}"
  echo ""
fi

echo -e "${BLUE}Phase 3: /orchestrate Planning Fix${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/test_orchestrate_planning_behavioral_injection.sh" ]; then
  run_test "Orchestrate Planning Behavioral Injection" \
    "$SCRIPT_DIR/test_orchestrate_planning_behavioral_injection.sh"
else
  echo -e "${YELLOW}⊘ SKIPPED: test_orchestrate_planning_behavioral_injection.sh not found${NC}"
  echo ""
fi

echo -e "${BLUE}Phase 4: System-Wide Validation${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

run_test "Anti-Pattern Detection (Agent Files)" \
  "$SCRIPT_DIR/validate_no_agent_slash_commands.sh"

run_test "Behavioral Injection Compliance (Commands)" \
  "$SCRIPT_DIR/validate_command_behavioral_injection.sh"

run_test "Topic-Based Artifact Organization" \
  "$SCRIPT_DIR/validate_topic_based_artifacts.sh"

# Summary
echo "════════════════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════════════════"
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ✅ ALL DELEGATION FIXES VALIDATED SUCCESSFULLY           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ❌ SOME TESTS FAILED                                      ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Failed tests:"
  echo -e "$FAILED_TESTS"
  exit 1
fi
```

**Orchestration Features**:

1. **Phased Testing**:
   - Phase 2: code-writer recursion prevention
   - Phase 3: orchestrate behavioral injection
   - Phase 4: System-wide anti-pattern detection

2. **Test Execution**:
   - Sequential execution (dependency order)
   - Continue on failure (run all tests)
   - Aggregate results at end

3. **Result Reporting**:
   - Pass/fail count
   - Failed test list
   - Visual summary box
   - Exit code: 0 if all pass, 1 if any fail

4. **Error Handling**:
   - Graceful handling of missing test files
   - Skip notification for unavailable tests
   - Capture and display test output

---

## Testing Strategy

### Unit Tests
Each validator is a self-contained unit test:
- **validate_no_agent_slash_commands.sh**: Tests agent files in isolation
- **validate_command_behavioral_injection.sh**: Tests command files in isolation
- **validate_topic_based_artifacts.sh**: Tests directory structure compliance

### Integration Test
Master orchestrator validates end-to-end:
- **test_all_delegation_fixes.sh**: Runs all validators together
- Ensures fixes work cohesively across system
- Provides single test command for CI/CD integration

### Coverage Metrics

**Agent File Coverage**:
- Target: 100% of agent files scanned
- Current agents: ~15 files in `.claude/agents/`
- Validation: Every agent file checked for anti-patterns

**Command File Coverage**:
- Target: 100% of commands using agents
- Current commands: orchestrate, plan, report, debug, implement
- Validation: All commands checked for behavioral injection compliance

**Artifact Organization Coverage**:
- Target: 100% of topic directories validated
- Current topics: All directories matching `specs/{NNN_topic}/`
- Validation: Directory structure, numbering, utility function usage

### Success Metrics

**Zero Tolerance**:
- 0 SlashCommand anti-patterns in agent files
- 0 flat directory structure violations
- 0 manual path construction in commands

**100% Compliance**:
- 100% agent files clean
- 100% commands using create_topic_artifact()
- 100% artifacts in topic-based directories

## Expected Output

### When All Tests Pass

```
════════════════════════════════════════════════════════════
  Subagent Delegation Fixes - Master Test Suite
════════════════════════════════════════════════════════════

Phase 2: /implement code-writer Fix
════════════════════════════════════════════════════════════

[1] Running: Code-writer No Recursion
────────────────────────────────────────────────────────────
✓ PASSED: Code-writer No Recursion

Phase 3: /orchestrate Planning Fix
════════════════════════════════════════════════════════════

[2] Running: Orchestrate Planning Behavioral Injection
────────────────────────────────────────────────────────────
✓ PASSED: Orchestrate Planning Behavioral Injection

Phase 4: System-Wide Validation
════════════════════════════════════════════════════════════

[3] Running: Anti-Pattern Detection (Agent Files)
────────────────────────────────────────────────────────────
Agents scanned: 15
Violations found: 0
✅ All agent behavioral files are CLEAN
✓ PASSED: Anti-Pattern Detection (Agent Files)

[4] Running: Behavioral Injection Compliance (Commands)
────────────────────────────────────────────────────────────
Commands checked: 5
Commands passing: 5
Warnings issued: 0
✅ All commands follow behavioral injection best practices
✓ PASSED: Behavioral Injection Compliance (Commands)

[5] Running: Topic-Based Artifact Organization
────────────────────────────────────────────────────────────
Topic directories found: 8
Artifacts validated: 42
Violations detected: 0
✅ Topic-based artifact organization validated
✓ PASSED: Topic-Based Artifact Organization

════════════════════════════════════════════════════════════
  Test Results Summary
════════════════════════════════════════════════════════════
Tests run: 5
Tests passed: 5
Tests failed: 0

╔════════════════════════════════════════════════════════════╗
║  ✅ ALL DELEGATION FIXES VALIDATED SUCCESSFULLY           ║
╚════════════════════════════════════════════════════════════╝
```

### When Tests Fail

```
════════════════════════════════════════════════════════════
  Test Results Summary
════════════════════════════════════════════════════════════
Tests run: 5
Tests passed: 3
Tests failed: 2

╔════════════════════════════════════════════════════════════╗
║  ❌ SOME TESTS FAILED                                      ║
╚════════════════════════════════════════════════════════════╝

Failed tests:
  - Anti-Pattern Detection (Agent Files)
  - Topic-Based Artifact Organization
```

## Files Created

1. `.claude/tests/validate_no_agent_slash_commands.sh` (320+ lines)
   - Anti-pattern detection for agent behavioral files
   - SlashCommand usage detection
   - Explicit command invocation detection

2. `.claude/tests/validate_command_behavioral_injection.sh` (180+ lines)
   - Behavioral injection compliance validation
   - Path pre-calculation checks
   - Topic-based organization validation
   - Metadata extraction verification

3. `.claude/tests/validate_topic_based_artifacts.sh` (280+ lines)
   - Flat structure violation detection
   - Topic directory structure validation
   - Artifact numbering consistency checks
   - Utility function usage validation

4. `.claude/tests/test_all_delegation_fixes.sh` (150+ lines)
   - Master test orchestrator
   - Phased test execution
   - Aggregate result reporting

## Files Modified

1. `.claude/tests/run_all_tests.sh`
   - Add validation scripts to test discovery
   - Include validators in test execution

## Phase Completion Criteria

- [ ] All 3 validation scripts created and executable
- [ ] Master orchestrator script created and tested
- [ ] Integration with run_all_tests.sh complete
- [ ] All validators pass with 0 violations
- [ ] 100% agent file coverage achieved
- [ ] 100% command coverage achieved
- [ ] 100% artifact organization compliance
- [ ] Documentation updated with validation process
- [ ] Test suite runs successfully from CI/CD

## Success Metrics

**Quantitative**:
- 0 anti-pattern violations detected
- 15+ agent files scanned (100% coverage)
- 5+ commands validated (100% coverage)
- All topic directories properly organized
- All validators exit with code 0 (pass)

**Qualitative**:
- Clear, actionable error messages for violations
- Comprehensive fix instructions provided
- Easy integration with existing test suite
- Fast execution time (<10 seconds total)
- Maintainable validation logic

## Next Steps After This Phase

1. Run master test suite: `bash .claude/tests/test_all_delegation_fixes.sh`
2. Fix any detected violations
3. Verify all tests pass
4. Proceed to Phase 5 (Documentation)
5. Add validators to CI/CD pipeline for continuous compliance
