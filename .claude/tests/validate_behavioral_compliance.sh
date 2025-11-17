#!/usr/bin/env bash
# validate_behavioral_compliance.sh - Behavioral compliance validation
#
# Validates all orchestrator commands for behavioral compliance patterns:
# - File creation compliance
# - Completion signal format
# - Agent delegation rate
# - Context reduction validation
# - Verification checkpoint presence
# - Return code verification
#
# Usage: ./validate_behavioral_compliance.sh [--verbose]
#
# Exit Codes:
#   0 - All validations passed
#   1 - Validation failures detected

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Commands to validate (all orchestrator commands)
COMMANDS=(
    "coordinate"
    "research-report"
    "research-plan"
    "research-revise"
    "build"
    "fix"
    "debug"
    "plan"
    "implement"
    "expand"
    "collapse"
    "revise"
    "convert-docs"
    "setup"
)

# Verbose mode
VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Helper functions
log_test() {
    ((TESTS_RUN++))
    if $VERBOSE; then
        echo -e "${YELLOW}[TEST]${NC} $1"
    fi
}

log_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# ==============================================================================
# Pattern 1: File Creation Compliance
# ==============================================================================

validate_file_creation_compliance() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "File creation compliance: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    local compliance_checks=0

    # Check 1: Pre-calculated artifact paths (file-level or directory-level)
    if grep -q "_PATH=" "$cmd_file" || grep -q "REPORT_PATH=" "$cmd_file" || grep -q "PLAN_PATH=" "$cmd_file" || grep -q "_DIR=" "$cmd_file"; then
        ((compliance_checks++))
    else
        log_fail "$cmd: Missing pre-calculated artifact paths"
    fi

    # Check 2: Path injection into agent prompts (accepts both "Path:" and "Directory:" patterns)
    if grep -q "Report Path:\|Plan Path:\|Output Path:\|Output Directory:" "$cmd_file"; then
        ((compliance_checks++))
    else
        log_fail "$cmd: Missing path injection into agent prompts"
    fi

    # Check 3: File existence verification after agent invocation (accepts both file and directory checks)
    if grep -q 'if \[ ! -f' "$cmd_file" 2>/dev/null || grep -q 'if \[ ! -d' "$cmd_file" 2>/dev/null; then
        ((compliance_checks++))
    else
        log_fail "$cmd: Missing file existence verification checkpoints"
    fi

    # Check 4: File size validation (minimum bytes check)
    if grep -q "stat.*-c.*%s" "$cmd_file" 2>/dev/null || grep -q "wc -c" "$cmd_file" 2>/dev/null || grep -qE -- '-s \$' "$cmd_file" 2>/dev/null; then
        ((compliance_checks++))
    fi

    if [ $compliance_checks -ge 3 ]; then
        log_pass "$cmd: File creation compliance ($compliance_checks/4 checks)"
        return 0
    else
        log_fail "$cmd: Insufficient file creation compliance ($compliance_checks/4 checks)"
        return 1
    fi
}

# ==============================================================================
# Pattern 2: Completion Signal Format
# ==============================================================================

validate_completion_signal_format() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Completion signal format: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    local signal_checks=0

    # Check 1: Commands expect completion signals from agents
    if grep -q "REPORT_CREATED:" "$cmd_file" || grep -q "PLAN_CREATED:" "$cmd_file" || grep -q "COMPLETION:" "$cmd_file"; then
        ((signal_checks++))
    fi

    # Check 2: Commands verify signal format
    if grep -q "grep.*CREATED:" "$cmd_file" || grep -q "COMPLETION" "$cmd_file"; then
        ((signal_checks++))
    fi

    # Note: Not all commands require completion signals
    if [ $signal_checks -ge 1 ]; then
        log_pass "$cmd: Completion signal handling present"
        return 0
    else
        log_info "$cmd: No completion signal validation (may not be required)"
        return 0
    fi
}

# ==============================================================================
# Pattern 3: Agent Delegation Rate
# ==============================================================================

validate_agent_delegation_rate() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Agent delegation rate: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    # Count agent invocations
    local agent_invocations=$(grep -c "Task {" "$cmd_file" 2>/dev/null || echo 0)
    local total_lines=$(wc -l < "$cmd_file")
    local code_blocks=$(grep -c '```bash' "$cmd_file" 2>/dev/null || echo 1)

    # Strip whitespace/newlines
    agent_invocations=$(echo "$agent_invocations" | tr -d '\n' | tr -d ' ')
    code_blocks=$(echo "$code_blocks" | tr -d '\n' | tr -d ' ')

    # Set defaults if empty
    agent_invocations=${agent_invocations:-0}
    code_blocks=${code_blocks:-1}

    # Calculate delegation rate
    local expected_min_delegations=1
    if [ "$code_blocks" -gt 0 ]; then
        expected_min_delegations=$code_blocks
    fi

    if [ "$agent_invocations" -ge "$expected_min_delegations" ]; then
        log_pass "$cmd: Agent delegation rate adequate ($agent_invocations invocations)"
        return 0
    else
        log_info "$cmd: Low agent delegation rate ($agent_invocations invocations for $code_blocks blocks)"
        return 0
    fi
}

# ==============================================================================
# Pattern 4: Context Reduction Validation
# ==============================================================================

validate_context_reduction() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Context reduction validation: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    local context_checks=0

    # Check 1: Commands pass only context parameters (not full behavioral instructions)
    if grep -q "Workflow-Specific Context:" "$cmd_file" || grep -q "Context Parameters:" "$cmd_file"; then
        ((context_checks++))
    fi

    # Check 2: No behavioral duplication (check for "Focus on", "Follow Standard", etc.)
    if ! grep -q "Focus.*on\|Follow Standard" "$cmd_file"; then
        ((context_checks++))
    fi

    # Check 3: Agent behavioral files referenced (not inlined)
    if grep -q "\.claude/agents/" "$cmd_file"; then
        ((context_checks++))
    fi

    if [ $context_checks -ge 2 ]; then
        log_pass "$cmd: Context reduction validated ($context_checks/3 checks)"
        return 0
    else
        log_fail "$cmd: Poor context reduction ($context_checks/3 checks)"
        return 1
    fi
}

# ==============================================================================
# Pattern 5: Verification Checkpoint Density
# ==============================================================================

validate_verification_checkpoint_density() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Verification checkpoint density: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    # Count verification checkpoints
    local checkpoints=0
    local file_checks=$(grep -c 'if \[ ! -f' "$cmd_file" 2>/dev/null || echo 0)
    local dir_checks=$(grep -c 'if \[ ! -d' "$cmd_file" 2>/dev/null || echo 0)
    local diagnostic_checks=$(grep -cE 'ERROR.*DIAGNOSTIC' "$cmd_file" 2>/dev/null || echo 0)
    local exit_checks=$(grep -c 'exit 1' "$cmd_file" 2>/dev/null || echo 0)

    # Ensure all values are numeric (strip any whitespace/newlines)
    file_checks=$(echo "$file_checks" | tr -d '\n' | tr -d ' ')
    dir_checks=$(echo "$dir_checks" | tr -d '\n' | tr -d ' ')
    diagnostic_checks=$(echo "$diagnostic_checks" | tr -d '\n' | tr -d ' ')
    exit_checks=$(echo "$exit_checks" | tr -d '\n' | tr -d ' ')

    checkpoints=$((file_checks + dir_checks + diagnostic_checks + exit_checks))

    local total_lines=$(wc -l < "$cmd_file")
    local density=$((total_lines / (checkpoints > 0 ? checkpoints : 1)))

    # Target: 1 checkpoint per 50 lines (better than /coordinate's 1 per 16 lines is not required)
    if [ "$density" -le 50 ]; then
        log_pass "$cmd: Verification checkpoint density good (1 per $density lines)"
        return 0
    elif [ "$density" -le 100 ]; then
        log_info "$cmd: Verification checkpoint density adequate (1 per $density lines)"
        return 0
    else
        log_fail "$cmd: Verification checkpoint density too low (1 per $density lines)"
        return 1
    fi
}

# ==============================================================================
# Pattern 6: Return Code Verification
# ==============================================================================

validate_return_code_verification() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Return code verification: $cmd"

    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    local rc_checks=0

    # Check 1: sm_init() wrapped with error handling
    if grep -q "if ! sm_init" "$cmd_file"; then
        ((rc_checks++))
    fi

    # Check 2: sm_transition() calls verified
    if grep -q "if ! sm_transition" "$cmd_file" || ! grep -q "sm_transition" "$cmd_file"; then
        ((rc_checks++))
    fi

    # Check 3: Critical library functions verified
    if grep -q "if ! check_library_requirements" "$cmd_file" || ! grep -q "check_library_requirements" "$cmd_file"; then
        ((rc_checks++))
    fi

    # Check 4: Diagnostic output on failure
    if grep -q "ERROR:.*DIAGNOSTIC:" "$cmd_file"; then
        ((rc_checks++))
    fi

    # Note: Not all commands use state machine
    local uses_state_machine=$(grep -c "sm_init\|sm_transition" "$cmd_file" || echo "0")

    if [ "$uses_state_machine" -eq 0 ]; then
        log_info "$cmd: No state machine usage (skipping return code verification)"
        return 0
    fi

    if [ $rc_checks -ge 3 ]; then
        log_pass "$cmd: Return code verification present ($rc_checks/4 checks)"
        return 0
    else
        log_fail "$cmd: Insufficient return code verification ($rc_checks/4 checks)"
        return 1
    fi
}

# ==============================================================================
# Main Validation Loop
# ==============================================================================

echo "========================================="
echo "Behavioral Compliance Validation"
echo "========================================="
echo ""

for cmd in "${COMMANDS[@]}"; do
    if [ ! -f ".claude/commands/${cmd}.md" ]; then
        log_info "Skipping $cmd (file not found)"
        continue
    fi

    echo "Validating: $cmd"
    echo "---"

    validate_file_creation_compliance "$cmd" || true
    validate_completion_signal_format "$cmd" || true
    validate_agent_delegation_rate "$cmd" || true
    validate_context_reduction "$cmd" || true
    validate_verification_checkpoint_density "$cmd" || true
    validate_return_code_verification "$cmd" || true

    echo ""
done

# ==============================================================================
# Summary Report
# ==============================================================================

echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Total Tests Run: $TESTS_RUN"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
else
    echo "Tests Failed: $TESTS_FAILED"
fi
echo ""

# Calculate success rate
if [ $TESTS_RUN -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo "Success Rate: ${SUCCESS_RATE}%"
    echo ""
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL BEHAVIORAL COMPLIANCE VALIDATIONS PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ BEHAVIORAL COMPLIANCE FAILURES DETECTED${NC}"
    exit 1
fi
