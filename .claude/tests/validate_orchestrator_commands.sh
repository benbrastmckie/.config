#!/usr/bin/env bash
# validate_orchestrator_commands.sh - Feature preservation validation
#
# Validates 5 dedicated orchestrator commands for:
# - Command structure and YAML frontmatter
# - Standard 11 imperative patterns
# - State machine integration
# - Library version requirements
# - Fail-fast verification checkpoints
#
# Usage: ./validate_orchestrator_commands.sh [--verbose]
#
# Exit Codes:
#   0 - All validations passed
#   1 - Validation failures detected

set -uo pipefail
# Note: Not using -e to allow validation to continue after failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Commands to validate
COMMANDS=(
    "research-report"
    "research-plan"
    "research-revise"
    "build"
    "fix"
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
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# ==============================================================================
# Feature 1: Command Structure Validation
# ==============================================================================

validate_command_structure() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating structure: $cmd"

    # Check file exists
    if [ ! -f "$cmd_file" ]; then
        log_fail "$cmd: Command file not found"
        return 1
    fi

    # Check YAML frontmatter
    if ! grep -q "^---$" "$cmd_file"; then
        log_fail "$cmd: Missing YAML frontmatter"
        return 1
    fi

    # Check required YAML fields
    local required_fields=("allowed-tools" "argument-hint" "description" "command-type" "dependent-agents" "library-requirements")
    for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$cmd_file"; then
            log_fail "$cmd: Missing YAML field: $field"
            return 1
        fi
    done

    log_pass "$cmd: Command structure valid"
    return 0
}

# ==============================================================================
# Feature 2: Standard 11 - Imperative Agent Invocation
# ==============================================================================

validate_standard_11_patterns() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating Standard 11 patterns: $cmd"

    local patterns_found=0
    local patterns_required=3

    # Pattern 1: "EXECUTE NOW" or "USE the Task tool"
    if grep -q "EXECUTE NOW" "$cmd_file" || grep -q "USE the Task tool" "$cmd_file"; then
        ((patterns_found++))
    else
        log_fail "$cmd: Missing imperative invocation pattern (EXECUTE NOW / USE the Task tool)"
    fi

    # Pattern 2: Behavioral file reference
    if grep -q "Read and follow.*behavioral" "$cmd_file" || grep -q "\.claude/agents/" "$cmd_file"; then
        ((patterns_found++))
    else
        log_fail "$cmd: Missing behavioral file reference"
    fi

    # Pattern 3: "YOU MUST" enforcement
    if grep -q "YOU MUST" "$cmd_file"; then
        ((patterns_found++))
    else
        log_fail "$cmd: Missing YOU MUST enforcement pattern"
    fi

    # Pattern 4: No YAML code block wrappers (anti-pattern check)
    if grep -q '```yaml' "$cmd_file"; then
        log_fail "$cmd: Contains prohibited YAML code block wrappers"
        return 1
    fi

    if [ $patterns_found -ge $patterns_required ]; then
        log_pass "$cmd: Standard 11 patterns present ($patterns_found/$patterns_required+)"
        return 0
    else
        log_fail "$cmd: Insufficient Standard 11 patterns ($patterns_found/$patterns_required)"
        return 1
    fi
}

# ==============================================================================
# Feature 3: State Machine Integration
# ==============================================================================

validate_state_machine_integration() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating state machine integration: $cmd"

    local sm_features=0

    # Check sm_init invocation
    if grep -q "sm_init" "$cmd_file"; then
        ((sm_features++))
    else
        log_fail "$cmd: Missing sm_init() invocation"
    fi

    # Check sm_transition usage
    if grep -q "sm_transition" "$cmd_file"; then
        ((sm_features++))
    else
        log_fail "$cmd: Missing sm_transition() calls"
    fi

    # Check save_completed_states_to_state persistence
    if grep -q "save_completed_states_to_state" "$cmd_file"; then
        ((sm_features++))
    else
        log_fail "$cmd: Missing save_completed_states_to_state() persistence"
    fi

    # Check hardcoded WORKFLOW_TYPE
    if grep -q 'WORKFLOW_TYPE=' "$cmd_file"; then
        ((sm_features++))
    else
        log_fail "$cmd: Missing hardcoded WORKFLOW_TYPE"
    fi

    if [ $sm_features -ge 4 ]; then
        log_pass "$cmd: State machine integration complete ($sm_features/4)"
        return 0
    else
        log_fail "$cmd: Incomplete state machine integration ($sm_features/4)"
        return 1
    fi
}

# ==============================================================================
# Feature 4: Library Version Requirements
# ==============================================================================

validate_library_requirements() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating library requirements: $cmd"

    # Check library-requirements section in YAML
    if ! grep -q "library-requirements:" "$cmd_file"; then
        log_fail "$cmd: Missing library-requirements in YAML frontmatter"
        return 1
    fi

    # Check for workflow-state-machine.sh requirement
    if ! grep -q "workflow-state-machine.sh.*>=2.0.0" "$cmd_file"; then
        log_fail "$cmd: Missing or incorrect workflow-state-machine.sh version requirement"
        return 1
    fi

    # Check for state-persistence.sh requirement
    if ! grep -q "state-persistence.sh.*>=1.5.0" "$cmd_file"; then
        log_fail "$cmd: Missing or incorrect state-persistence.sh version requirement"
        return 1
    fi

    # Check library sourcing
    if ! grep -q "source.*workflow-state-machine.sh" "$cmd_file"; then
        log_fail "$cmd: Missing workflow-state-machine.sh sourcing"
        return 1
    fi

    log_pass "$cmd: Library requirements valid"
    return 0
}

# ==============================================================================
# Feature 5: Fail-Fast Verification Checkpoints
# ==============================================================================

validate_verification_checkpoints() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating verification checkpoints: $cmd"

    local checkpoint_features=0

    # Check for "Verifying" or "FAIL-FAST" keywords
    if grep -qi "verifying.*artifacts" "$cmd_file" || grep -q "FAIL-FAST" "$cmd_file"; then
        ((checkpoint_features++))
    else
        log_fail "$cmd: Missing artifact verification"
    fi

    # Check for file existence checks
    if grep -q 'if \[ ! -f' "$cmd_file" || grep -q 'if \[ ! -d' "$cmd_file"; then
        ((checkpoint_features++))
    else
        log_fail "$cmd: Missing file/directory existence checks"
    fi

    # Check for exit 1 on failure
    if grep -q "exit 1" "$cmd_file"; then
        ((checkpoint_features++))
    else
        log_fail "$cmd: Missing exit 1 fail-fast behavior"
    fi

    # Check for diagnostic error messages
    if grep -q "ERROR:" "$cmd_file" && grep -q "DIAGNOSTIC:" "$cmd_file"; then
        ((checkpoint_features++))
    else
        log_fail "$cmd: Missing diagnostic error messages"
    fi

    if [ $checkpoint_features -ge 3 ]; then
        log_pass "$cmd: Verification checkpoints present ($checkpoint_features/4)"
        return 0
    else
        log_fail "$cmd: Insufficient verification checkpoints ($checkpoint_features/4)"
        return 1
    fi
}

# ==============================================================================
# Feature 6: Workflow-Specific Patterns
# ==============================================================================

validate_workflow_specific_patterns() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating workflow-specific patterns: $cmd"

    case "$cmd" in
        "research-report")
            # Should have research phase only
            if grep -q "STATE_RESEARCH" "$cmd_file" && ! grep -q "STATE_PLAN" "$cmd_file"; then
                log_pass "$cmd: Correct workflow (research-only)"
                return 0
            else
                log_fail "$cmd: Incorrect workflow sequence"
                return 1
            fi
            ;;
        "research-plan")
            # Should have research + plan phases
            if grep -q "STATE_RESEARCH" "$cmd_file" && grep -q "STATE_PLAN" "$cmd_file"; then
                log_pass "$cmd: Correct workflow (research + plan)"
                return 0
            else
                log_fail "$cmd: Missing required phases"
                return 1
            fi
            ;;
        "research-revise")
            # Should have backup logic
            if grep -q "BACKUP" "$cmd_file" || grep -q "backup" "$cmd_file"; then
                log_pass "$cmd: Backup logic present"
                return 0
            else
                log_fail "$cmd: Missing backup logic for revision"
                return 1
            fi
            ;;
        "build")
            # Should have implement + test phases
            if grep -q "STATE_IMPLEMENT" "$cmd_file" && grep -q "STATE_TEST" "$cmd_file"; then
                log_pass "$cmd: Correct workflow (build)"
                return 0
            else
                log_fail "$cmd: Missing required build phases"
                return 1
            fi
            ;;
        "fix")
            # Should have debug phase
            if grep -q "STATE_DEBUG" "$cmd_file" || grep -q "debug" "$cmd_file"; then
                log_pass "$cmd: Debug workflow present"
                return 0
            else
                log_fail "$cmd: Missing debug workflow"
                return 1
            fi
            ;;
    esac
}

# ==============================================================================
# Feature 7: Actual Agent Invocation Testing (Extended)
# ==============================================================================

validate_actual_agent_invocation() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating actual agent invocation: $cmd"

    local invocation_checks=0

    # Check 1: Task tool invocation present
    if grep -q "Task {" "$cmd_file" || grep -q "USE the Task tool" "$cmd_file"; then
        ((invocation_checks++))
    else
        log_fail "$cmd: Missing Task tool invocation"
    fi

    # Check 2: subagent_type specified
    if grep -q "subagent_type:" "$cmd_file" || grep -q "general-purpose" "$cmd_file"; then
        ((invocation_checks++))
    else
        log_fail "$cmd: Missing subagent_type specification"
    fi

    # Check 3: Agent file reference
    if grep -q "\.claude/agents/" "$cmd_file"; then
        ((invocation_checks++))
    else
        log_fail "$cmd: Missing agent file reference"
    fi

    # Check 4: Behavioral file reading enforced
    if grep -q "Read and follow" "$cmd_file" || grep -q "MUST read" "$cmd_file"; then
        ((invocation_checks++))
    else
        log_fail "$cmd: Missing behavioral file reading enforcement"
    fi

    if [ $invocation_checks -ge 3 ]; then
        log_pass "$cmd: Agent invocation structure validated ($invocation_checks/4 checks)"
        return 0
    else
        log_fail "$cmd: Incomplete agent invocation structure ($invocation_checks/4 checks)"
        return 1
    fi
}

# ==============================================================================
# Feature 8: File Creation Validation (Extended)
# ==============================================================================

validate_file_creation_pattern() {
    local cmd="$1"
    local cmd_file=".claude/commands/${cmd}.md"

    log_test "Validating file creation pattern: $cmd"

    local creation_checks=0

    # Check 1: Artifact paths pre-calculated
    if grep -q "_PATH=" "$cmd_file"; then
        ((creation_checks++))
    else
        log_fail "$cmd: Missing pre-calculated artifact paths"
    fi

    # Check 2: Paths injected into agent prompts
    if grep -q "Report Path:\|Plan Path:\|Output Path:" "$cmd_file"; then
        ((creation_checks++))
    else
        log_fail "$cmd: Missing path injection into prompts"
    fi

    # Check 3: File-level verification (not directory-level)
    if grep -q 'if \[ ! -f "\$.*_PATH" \]' "$cmd_file"; then
        ((creation_checks++))
    else
        log_fail "$cmd: Missing file-level verification checkpoints"
    fi

    # Check 4: No directory-level pattern (anti-pattern)
    if ! grep -q "find.*-name '\*.md'" "$cmd_file"; then
        ((creation_checks++))
    else
        log_fail "$cmd: Contains directory-level verification (anti-pattern)"
    fi

    if [ $creation_checks -ge 3 ]; then
        log_pass "$cmd: File creation pattern validated ($creation_checks/4 checks)"
        return 0
    else
        log_fail "$cmd: Incomplete file creation pattern ($creation_checks/4 checks)"
        return 1
    fi
}

# ==============================================================================
# Main Validation Loop
# ==============================================================================

echo "========================================="
echo "Orchestrator Commands Feature Validation"
echo "========================================="
echo ""

for cmd in "${COMMANDS[@]}"; do
    echo "Validating: $cmd"
    echo "---"

    validate_command_structure "$cmd" || true
    validate_standard_11_patterns "$cmd" || true
    validate_state_machine_integration "$cmd" || true
    validate_library_requirements "$cmd" || true
    validate_verification_checkpoints "$cmd" || true
    validate_workflow_specific_patterns "$cmd" || true
    validate_actual_agent_invocation "$cmd" || true
    validate_file_creation_pattern "$cmd" || true

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
SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
echo "Success Rate: ${SUCCESS_RATE}%"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL VALIDATIONS PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ VALIDATION FAILURES DETECTED${NC}"
    exit 1
fi
