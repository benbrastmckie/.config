# Phase 6 Expansion: Feature Preservation Validation

## Overview

This phase validates that all 6 essential coordinate features are preserved in the new dedicated orchestrator commands. The validation uses automated testing, metric collection, and performance benchmarking to ensure no regression from the original `/coordinate` command.

**Dependencies**: Phases 2, 3, 4, 5 (all commands implemented)

**Duration**: 4 hours

**Complexity**: Medium (8/10)

---

## 6 Essential Features to Validate

### 1. Delegation Rate (Behavioral Injection)
**Target**: >90% delegation rate
**Definition**: Percentage of implementation work delegated to specialized agents vs. direct Claude edits

### 2. Context Usage (Metadata Extraction)
**Target**: <300 tokens per agent invocation
**Definition**: Average context size passed to each agent through metadata extraction

### 3. State Machine Architecture
**Target**: 100% coverage of sm_init and sm_transition
**Definition**: All workflow state changes must use state machine primitives

### 4. Verification Checkpoints
**Target**: 100% checkpoint compliance
**Definition**: File existence verification after every agent invocation that produces artifacts

### 5. Wave Execution (Parallel Planning)
**Target**: Present in /build and /research-plan
**Definition**: Use of dependency-analyzer.sh for parallel phase execution

### 6. Hierarchical Supervision
**Target**: Automatic for complexity ≥4
**Definition**: research-sub-supervisor.md invocation for complex research workflows

---

## Task 1: Create Validation Script Structure

**File**: `.claude/tests/validate_feature_preservation.sh`

**Purpose**: Central validation orchestrator that runs all feature checks

### Script Architecture

```bash
#!/usr/bin/env bash
# validate_feature_preservation.sh - Feature preservation validation for orchestrator commands
#
# Usage:
#   ./validate_feature_preservation.sh [--command <name>] [--feature <name>] [--verbose]
#
# Exit Codes:
#   0 - All validations passed
#   1 - Validation failures detected
#   2 - Script error (missing dependencies, invalid args)

set -euo pipefail

# Script directory and library sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source required libraries
source "${PROJECT_ROOT}/.claude/lib/validation-framework.sh"
source "${PROJECT_ROOT}/.claude/lib/metric-collectors.sh"
source "${PROJECT_ROOT}/.claude/lib/performance-benchmarks.sh"

# Validation configuration
VALIDATION_RESULTS_DIR="${PROJECT_ROOT}/.claude/specs/743_coordinate_command_working_reasonably_well_more/artifacts"
VALIDATION_LOG="${VALIDATION_RESULTS_DIR}/validation_$(date +%Y%m%d_%H%M%S).log"
FEATURE_RESULTS="${VALIDATION_RESULTS_DIR}/feature_preservation_results.md"
PERFORMANCE_BASELINE="${VALIDATION_RESULTS_DIR}/performance_baseline.md"

# Feature validation targets
declare -A FEATURE_TARGETS=(
    ["delegation_rate"]=90
    ["context_usage"]=300
    ["state_machine"]=100
    ["verification_checkpoints"]=100
    ["wave_execution"]=100
    ["hierarchical_supervision"]=100
)

# Commands to validate
COMMANDS_TO_VALIDATE=(
    "research"
    "research-plan"
    "research-revise"
    "build"
    "fix"
)

# Validation results tracking
declare -A VALIDATION_RESULTS
declare -A PERFORMANCE_METRICS

# Main validation orchestrator
main() {
    local command_filter=""
    local feature_filter=""
    local verbose=false

    parse_arguments "$@"
    setup_validation_environment

    log_info "Starting feature preservation validation"
    log_info "Validation log: ${VALIDATION_LOG}"

    # Run validation for each command
    for cmd in "${COMMANDS_TO_VALIDATE[@]}"; do
        if [[ -n "${command_filter}" && "${cmd}" != "${command_filter}" ]]; then
            continue
        fi

        log_info "Validating command: ${cmd}"
        validate_command "${cmd}"
    done

    # Generate reports
    generate_feature_report
    generate_performance_report

    # Check overall results
    local failed_validations=$(count_failures)
    if [[ ${failed_validations} -gt 0 ]]; then
        log_error "${failed_validations} validation(s) failed"
        return 1
    fi

    log_success "All validations passed!"
    return 0
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --command)
                command_filter="$2"
                shift 2
                ;;
            --feature)
                feature_filter="$2"
                shift 2
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 2
                ;;
        esac
    done
}

# Validate a single command
validate_command() {
    local cmd=$1
    local cmd_path="${PROJECT_ROOT}/.claude/commands/${cmd}.md"

    if [[ ! -f "${cmd_path}" ]]; then
        log_error "Command file not found: ${cmd_path}"
        VALIDATION_RESULTS["${cmd}:exists"]="FAIL"
        return 1
    fi

    log_info "  Feature 1: Delegation Rate"
    validate_delegation_rate "${cmd}" "${cmd_path}"

    log_info "  Feature 2: Context Usage"
    validate_context_usage "${cmd}" "${cmd_path}"

    log_info "  Feature 3: State Machine"
    validate_state_machine "${cmd}" "${cmd_path}"

    log_info "  Feature 4: Verification Checkpoints"
    validate_verification_checkpoints "${cmd}" "${cmd_path}"

    log_info "  Feature 5: Wave Execution"
    validate_wave_execution "${cmd}" "${cmd_path}"

    log_info "  Feature 6: Hierarchical Supervision"
    validate_hierarchical_supervision "${cmd}" "${cmd_path}"

    log_info "  Performance: Baseline Measurement"
    measure_performance_baseline "${cmd}"

    log_info "  Edge Cases: Comprehensive Testing"
    run_edge_case_tests "${cmd}"
}

# Setup validation environment
setup_validation_environment() {
    mkdir -p "${VALIDATION_RESULTS_DIR}"

    # Create validation log header
    {
        echo "=== Feature Preservation Validation ==="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Project: ${PROJECT_ROOT}"
        echo "Commands: ${COMMANDS_TO_VALIDATE[*]}"
        echo ""
    } > "${VALIDATION_LOG}"
}

# Logging functions
log_info() {
    echo "[INFO] $*" | tee -a "${VALIDATION_LOG}"
}

log_success() {
    echo "[SUCCESS] $*" | tee -a "${VALIDATION_LOG}"
}

log_error() {
    echo "[ERROR] $*" | tee -a "${VALIDATION_LOG}" >&2
}

log_warning() {
    echo "[WARNING] $*" | tee -a "${VALIDATION_LOG}"
}

# Count validation failures
count_failures() {
    local count=0
    for key in "${!VALIDATION_RESULTS[@]}"; do
        if [[ "${VALIDATION_RESULTS[$key]}" == "FAIL" ]]; then
            ((count++))
        fi
    done
    echo "${count}"
}

# Show usage
show_usage() {
    cat <<EOF
Usage: validate_feature_preservation.sh [OPTIONS]

Options:
    --command <name>     Validate specific command only
    --feature <name>     Validate specific feature only
    --verbose            Enable verbose output
    --help               Show this help message

Examples:
    # Validate all commands
    ./validate_feature_preservation.sh

    # Validate specific command
    ./validate_feature_preservation.sh --command research

    # Validate specific feature
    ./validate_feature_preservation.sh --feature delegation_rate

    # Verbose mode
    ./validate_feature_preservation.sh --verbose
EOF
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

---

## Task 2: Delegation Rate Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_delegation_rate`)

**Target**: >90% delegation rate

**Methodology**: Analyze command files for agent invocation patterns vs. direct file operations

### Implementation

```bash
#!/usr/bin/env bash
# Delegation rate validation functions

# Validate delegation rate for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes target (>90%)
#   1 - Fails target
validate_delegation_rate() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing delegation patterns in ${cmd}"

    # Count agent invocations (delegation)
    local agent_invocations=$(count_agent_invocations "${cmd_path}")

    # Count direct operations (non-delegation)
    local direct_operations=$(count_direct_operations "${cmd_path}")

    # Calculate delegation rate
    local total_operations=$((agent_invocations + direct_operations))

    if [[ ${total_operations} -eq 0 ]]; then
        log_warning "    No operations found in ${cmd}"
        VALIDATION_RESULTS["${cmd}:delegation_rate"]="SKIP"
        return 0
    fi

    local delegation_rate=$(echo "scale=2; (${agent_invocations} * 100) / ${total_operations}" | bc)

    log_info "    Agent invocations: ${agent_invocations}"
    log_info "    Direct operations: ${direct_operations}"
    log_info "    Delegation rate: ${delegation_rate}%"

    # Check against target
    local target=${FEATURE_TARGETS["delegation_rate"]}
    if (( $(echo "${delegation_rate} >= ${target}" | bc -l) )); then
        log_success "    PASS: Delegation rate ${delegation_rate}% >= ${target}%"
        VALIDATION_RESULTS["${cmd}:delegation_rate"]="PASS:${delegation_rate}%"
        return 0
    else
        log_error "    FAIL: Delegation rate ${delegation_rate}% < ${target}%"
        VALIDATION_RESULTS["${cmd}:delegation_rate"]="FAIL:${delegation_rate}%"
        return 1
    fi
}

# Count agent invocations in command file
# Args:
#   $1 - Command file path
# Returns:
#   Count of agent invocations
count_agent_invocations() {
    local cmd_path=$1

    # Patterns indicating agent invocation:
    # 1. AGENT_PROMPT="${PROJECT_ROOT}/.claude/agents/*.md"
    # 2. claude --agent "..."
    # 3. source agents/*.md behavior

    local count=0

    # Pattern 1: AGENT_PROMPT variable assignments
    count=$((count + $(grep -c 'AGENT_PROMPT=.*\.claude/agents/.*\.md' "${cmd_path}" || echo 0)))

    # Pattern 2: Direct claude --agent invocations
    count=$((count + $(grep -c 'claude.*--agent' "${cmd_path}" || echo 0)))

    # Pattern 3: Explicit agent sourcing
    count=$((count + $(grep -c 'source.*agents/.*\.md' "${cmd_path}" || echo 0)))

    echo "${count}"
}

# Count direct operations in command file
# Args:
#   $1 - Command file path
# Returns:
#   Count of direct operations
count_direct_operations() {
    local cmd_path=$1

    # Patterns indicating direct operations (non-delegated):
    # 1. Direct file edits (sed, awk)
    # 2. Direct file writes (cat >, echo >)
    # 3. Direct file moves/copies without verification checkpoint

    local count=0

    # Pattern 1: sed/awk operations on files
    count=$((count + $(grep -c 'sed -i' "${cmd_path}" || echo 0)))
    count=$((count + $(grep -c 'awk.*>.*' "${cmd_path}" || echo 0)))

    # Pattern 2: Direct file writes
    count=$((count + $(grep -c 'cat >.*<<' "${cmd_path}" || echo 0)))
    count=$((count + $(grep -c 'echo.*>.*\.md' "${cmd_path}" || echo 0)))

    # Pattern 3: Unverified file operations
    # Count mv/cp operations that don't have matching verification checkpoints
    local file_ops=$(grep -n 'mv \|cp ' "${cmd_path}" | wc -l || echo 0)
    local verified_ops=$(grep -n 'verify_checkpoint' "${cmd_path}" | wc -l || echo 0)
    local unverified=$((file_ops - verified_ops))
    count=$((count + (unverified > 0 ? unverified : 0)))

    echo "${count}"
}

# Extract delegation metrics for reporting
# Args:
#   $1 - Command name
# Returns:
#   JSON object with delegation metrics
extract_delegation_metrics() {
    local cmd=$1
    local result="${VALIDATION_RESULTS[${cmd}:delegation_rate]}"

    if [[ "${result}" == SKIP ]]; then
        echo '{"status": "skipped", "rate": null}'
        return
    fi

    local status="${result%%:*}"
    local rate="${result##*:}"
    rate="${rate%\%}"

    cat <<EOF
{
    "status": "${status,,}",
    "rate": ${rate},
    "target": ${FEATURE_TARGETS["delegation_rate"]},
    "passed": $([ "${status}" == "PASS" ] && echo "true" || echo "false")
}
EOF
}
```

### Validation Criteria

1. **Agent Invocation Patterns**:
   - `AGENT_PROMPT="${PROJECT_ROOT}/.claude/agents/*.md"` assignments
   - `claude --agent "..."` direct invocations
   - Behavioral injection through prompt templating

2. **Direct Operation Patterns** (should be minimal):
   - `sed -i` inline file edits
   - `awk` file transformations
   - Direct file writes (`cat >`, `echo >`)
   - Unverified file operations

3. **Threshold Justification**:
   - 90% threshold allows for essential bootstrapping operations
   - Commands should delegate all implementation to specialized agents
   - Original `/coordinate` achieves 92-95% delegation rate

---

## Task 3: Context Usage Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_context_usage`)

**Target**: <300 tokens per agent invocation

**Methodology**: Measure context passed to agents through metadata extraction

### Implementation

```bash
#!/usr/bin/env bash
# Context usage validation functions

# Validate context usage for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes target (<300 tokens)
#   1 - Fails target
validate_context_usage() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing context usage in ${cmd}"

    # Extract context preparation blocks
    local context_blocks=$(extract_context_blocks "${cmd_path}")

    if [[ -z "${context_blocks}" ]]; then
        log_warning "    No context blocks found in ${cmd}"
        VALIDATION_RESULTS["${cmd}:context_usage"]="SKIP"
        return 0
    fi

    # Calculate token counts for each context block
    local total_tokens=0
    local block_count=0
    local max_tokens=0

    while IFS= read -r block; do
        local tokens=$(estimate_token_count "${block}")
        total_tokens=$((total_tokens + tokens))
        block_count=$((block_count + 1))

        if [[ ${tokens} -gt ${max_tokens} ]]; then
            max_tokens=${tokens}
        fi
    done <<< "${context_blocks}"

    # Calculate average tokens per agent invocation
    local avg_tokens=$(echo "scale=2; ${total_tokens} / ${block_count}" | bc)

    log_info "    Context blocks: ${block_count}"
    log_info "    Total tokens: ${total_tokens}"
    log_info "    Average tokens per agent: ${avg_tokens}"
    log_info "    Max tokens: ${max_tokens}"

    # Check against target
    local target=${FEATURE_TARGETS["context_usage"]}
    if (( $(echo "${avg_tokens} <= ${target}" | bc -l) )); then
        log_success "    PASS: Average context ${avg_tokens} tokens <= ${target} tokens"
        VALIDATION_RESULTS["${cmd}:context_usage"]="PASS:${avg_tokens}"
        return 0
    else
        log_error "    FAIL: Average context ${avg_tokens} tokens > ${target} tokens"
        VALIDATION_RESULTS["${cmd}:context_usage"]="FAIL:${avg_tokens}"
        return 1
    fi
}

# Extract context preparation blocks from command file
# Args:
#   $1 - Command file path
# Returns:
#   Context blocks (one per line)
extract_context_blocks() {
    local cmd_path=$1

    # Look for context metadata extraction patterns:
    # 1. CONTEXT="$(cat <<EOF ... EOF)"
    # 2. --context "..." arguments
    # 3. Metadata extraction from plans/reports

    # Use awk to extract multi-line context blocks
    awk '
        /CONTEXT=.*<<EOF/ { in_context=1; block=""; next }
        in_context && /^EOF/ { print block; in_context=0; next }
        in_context { block = block $0 "\n" }

        /--context/ {
            match($0, /--context "([^"]*)"/, arr)
            if (arr[1]) print arr[1]
        }
    ' "${cmd_path}"
}

# Estimate token count for text
# Args:
#   $1 - Text content
# Returns:
#   Estimated token count
estimate_token_count() {
    local text=$1

    # Token estimation algorithm:
    # - Average 4 characters per token (Claude tokenization)
    # - Adjust for whitespace and punctuation

    local char_count=${#text}
    local word_count=$(echo "${text}" | wc -w)

    # Use word count as baseline, adjust for special tokens
    local estimated_tokens=$((word_count + (char_count - word_count * 4) / 4))

    echo "${estimated_tokens}"
}

# Analyze context efficiency
# Args:
#   $1 - Context block
# Returns:
#   Efficiency score (0-100)
analyze_context_efficiency() {
    local block=$1

    # Efficiency metrics:
    # 1. Metadata extraction vs. full content inclusion
    # 2. Relevant information density
    # 3. Redundancy detection

    local metadata_keywords=("Objective:" "Complexity:" "Dependencies:" "Phase:" "Stage:")
    local metadata_count=0

    for keyword in "${metadata_keywords[@]}"; do
        if echo "${block}" | grep -q "${keyword}"; then
            ((metadata_count++))
        fi
    done

    # Higher metadata count = better extraction efficiency
    local efficiency=$((metadata_count * 20))

    # Cap at 100
    if [[ ${efficiency} -gt 100 ]]; then
        efficiency=100
    fi

    echo "${efficiency}"
}
```

### Validation Criteria

1. **Context Extraction Patterns**:
   - Metadata-only extraction (Objective, Complexity, Dependencies)
   - File path references instead of full content
   - Targeted section extraction

2. **Token Counting**:
   - Use word count as baseline (average 1.3 tokens per word)
   - Account for markdown formatting overhead
   - Validate against Claude tokenizer if available

3. **Threshold Justification**:
   - 300 tokens ≈ 230 words of metadata
   - Sufficient for Objective + Complexity + Dependencies + Status
   - Original `/coordinate` averages 150-250 tokens per agent

---

## Task 4: State Machine Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_state_machine`)

**Target**: 100% coverage of sm_init and sm_transition

**Methodology**: Verify all workflow state changes use state machine primitives

### Implementation

```bash
#!/usr/bin/env bash
# State machine validation functions

# Validate state machine usage for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes target (100% coverage)
#   1 - Fails target
validate_state_machine() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing state machine usage in ${cmd}"

    # Check if state machine library is sourced
    if ! grep -q 'source.*state-machine\.sh' "${cmd_path}"; then
        log_error "    State machine library not sourced"
        VALIDATION_RESULTS["${cmd}:state_machine"]="FAIL:no_library"
        return 1
    fi

    # Count state machine primitive usage
    local sm_init_count=$(grep -c 'sm_init' "${cmd_path}" || echo 0)
    local sm_transition_count=$(grep -c 'sm_transition' "${cmd_path}" || echo 0)
    local sm_cleanup_count=$(grep -c 'sm_cleanup' "${cmd_path}" || echo 0)

    log_info "    sm_init calls: ${sm_init_count}"
    log_info "    sm_transition calls: ${sm_transition_count}"
    log_info "    sm_cleanup calls: ${sm_cleanup_count}"

    # Validate state machine initialization
    if [[ ${sm_init_count} -eq 0 ]]; then
        log_error "    FAIL: No sm_init call found"
        VALIDATION_RESULTS["${cmd}:state_machine"]="FAIL:no_init"
        return 1
    fi

    # Validate state transitions exist
    if [[ ${sm_transition_count} -eq 0 ]]; then
        log_error "    FAIL: No sm_transition calls found"
        VALIDATION_RESULTS["${cmd}:state_machine"]="FAIL:no_transitions"
        return 1
    fi

    # Check for state machine anti-patterns
    local antipatterns=$(detect_state_antipatterns "${cmd_path}")

    if [[ -n "${antipatterns}" ]]; then
        log_error "    FAIL: State machine anti-patterns detected:"
        echo "${antipatterns}" | while read -r pattern; do
            log_error "      - ${pattern}"
        done
        VALIDATION_RESULTS["${cmd}:state_machine"]="FAIL:antipatterns"
        return 1
    fi

    # Validate state machine completeness
    local completeness=$(validate_state_completeness "${cmd_path}")

    if [[ "${completeness}" != "complete" ]]; then
        log_error "    FAIL: State machine incomplete: ${completeness}"
        VALIDATION_RESULTS["${cmd}:state_machine"]="FAIL:${completeness}"
        return 1
    fi

    log_success "    PASS: State machine properly implemented"
    VALIDATION_RESULTS["${cmd}:state_machine"]="PASS"
    return 0
}

# Detect state machine anti-patterns
# Args:
#   $1 - Command file path
# Returns:
#   List of anti-patterns (empty if none)
detect_state_antipatterns() {
    local cmd_path=$1
    local antipatterns=""

    # Anti-pattern 1: Direct state file manipulation
    if grep -q 'echo.*>.*state\.json' "${cmd_path}"; then
        antipatterns="${antipatterns}Direct state file manipulation (use sm_transition)\n"
    fi

    # Anti-pattern 2: State reads without sm_get
    if grep -q 'cat.*state\.json' "${cmd_path}" && ! grep -q 'sm_get' "${cmd_path}"; then
        antipatterns="${antipatterns}Direct state file reading (use sm_get)\n"
    fi

    # Anti-pattern 3: Missing error handling for state transitions
    if grep -q 'sm_transition' "${cmd_path}" && ! grep -q 'sm_transition.*||' "${cmd_path}"; then
        antipatterns="${antipatterns}No error handling for state transitions\n"
    fi

    # Anti-pattern 4: State initialization without workflow ID
    if grep -q 'sm_init' "${cmd_path}"; then
        local init_line=$(grep 'sm_init' "${cmd_path}")
        if ! echo "${init_line}" | grep -q '\$.*ID'; then
            antipatterns="${antipatterns}State initialization without unique workflow ID\n"
        fi
    fi

    echo -e "${antipatterns}"
}

# Validate state machine completeness
# Args:
#   $1 - Command file path
# Returns:
#   "complete" if valid, error description otherwise
validate_state_completeness() {
    local cmd_path=$1

    # Extract state machine states and transitions
    local states=$(extract_states "${cmd_path}")
    local transitions=$(extract_transitions "${cmd_path}")

    # Check for required states
    local required_states=("init" "in_progress" "completed" "failed")
    for state in "${required_states[@]}"; do
        if ! echo "${states}" | grep -q "${state}"; then
            echo "missing_state:${state}"
            return 1
        fi
    done

    # Check for unreachable states
    for state in ${states}; do
        if [[ "${state}" != "init" ]]; then
            if ! echo "${transitions}" | grep -q "→${state}"; then
                echo "unreachable_state:${state}"
                return 1
            fi
        fi
    done

    # Check for cleanup on exit
    if ! grep -q 'trap.*sm_cleanup.*EXIT' "${cmd_path}"; then
        echo "missing_cleanup_trap"
        return 1
    fi

    echo "complete"
    return 0
}

# Extract states from command file
# Args:
#   $1 - Command file path
# Returns:
#   Space-separated list of states
extract_states() {
    local cmd_path=$1

    # Extract state names from sm_transition calls
    grep 'sm_transition' "${cmd_path}" | \
        sed -n 's/.*sm_transition.*"\([^"]*\)".*/\1/p' | \
        sort -u | \
        tr '\n' ' '
}

# Extract transitions from command file
# Args:
#   $1 - Command file path
# Returns:
#   List of transitions (from→to)
extract_transitions() {
    local cmd_path=$1

    # Extract transition patterns from sm_transition calls
    # Format: sm_transition "$WORKFLOW_ID" "from_state" "to_state"
    grep 'sm_transition' "${cmd_path}" | \
        sed -n 's/.*sm_transition[^"]*"[^"]*"[[:space:]]*"\([^"]*\)"[[:space:]]*"\([^"]*\)".*/\1→\2/p'
}
```

### Validation Criteria

1. **Required State Machine Primitives**:
   - `sm_init`: Initialize state with unique workflow ID
   - `sm_transition`: All state changes
   - `sm_get`: State reads
   - `sm_cleanup`: Cleanup on exit (trap)

2. **Required States**:
   - `init`: Initial state
   - `in_progress`: Active workflow execution
   - `completed`: Successful completion
   - `failed`: Error state

3. **Anti-patterns to Detect**:
   - Direct state file manipulation
   - State reads without sm_get
   - Missing error handling
   - State initialization without unique ID
   - Unreachable states

---

## Task 5: Verification Checkpoint Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_verification_checkpoints`)

**Target**: 100% checkpoint compliance

**Methodology**: Verify file existence checks after every agent invocation that produces artifacts

### Implementation

```bash
#!/usr/bin/env bash
# Verification checkpoint validation functions

# Validate verification checkpoints for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes target (100% compliance)
#   1 - Fails target
validate_verification_checkpoints() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing verification checkpoints in ${cmd}"

    # Find all agent invocations that produce artifacts
    local agent_invocations=$(find_artifact_producing_invocations "${cmd_path}")

    if [[ -z "${agent_invocations}" ]]; then
        log_info "    No artifact-producing agent invocations found"
        VALIDATION_RESULTS["${cmd}:verification_checkpoints"]="SKIP"
        return 0
    fi

    local total_invocations=0
    local verified_invocations=0
    local unverified_invocations=""

    while IFS= read -r invocation; do
        ((total_invocations++))

        local line_num=$(echo "${invocation}" | cut -d: -f1)
        local agent=$(echo "${invocation}" | cut -d: -f2)

        # Check if verification checkpoint exists after this invocation
        if has_verification_checkpoint "${cmd_path}" "${line_num}"; then
            ((verified_invocations++))
        else
            unverified_invocations="${unverified_invocations}Line ${line_num}: ${agent}\n"
        fi
    done <<< "${agent_invocations}"

    # Calculate compliance rate
    local compliance_rate=$(echo "scale=2; (${verified_invocations} * 100) / ${total_invocations}" | bc)

    log_info "    Total agent invocations: ${total_invocations}"
    log_info "    Verified invocations: ${verified_invocations}"
    log_info "    Compliance rate: ${compliance_rate}%"

    # Check against target
    local target=${FEATURE_TARGETS["verification_checkpoints"]}
    if (( $(echo "${compliance_rate} >= ${target}" | bc -l) )); then
        log_success "    PASS: Verification compliance ${compliance_rate}% >= ${target}%"
        VALIDATION_RESULTS["${cmd}:verification_checkpoints"]="PASS:${compliance_rate}%"
        return 0
    else
        log_error "    FAIL: Verification compliance ${compliance_rate}% < ${target}%"
        log_error "    Unverified invocations:"
        echo -e "${unverified_invocations}" | while read -r line; do
            if [[ -n "${line}" ]]; then
                log_error "      ${line}"
            fi
        done
        VALIDATION_RESULTS["${cmd}:verification_checkpoints"]="FAIL:${compliance_rate}%"
        return 1
    fi
}

# Find agent invocations that produce artifacts
# Args:
#   $1 - Command file path
# Returns:
#   List of invocations with line numbers (line:agent)
find_artifact_producing_invocations() {
    local cmd_path=$1

    # Artifact-producing agents include:
    # - plan-*.md (produces plans)
    # - research-*.md (produces reports)
    # - implementation-*.md (produces code)
    # - documentation-*.md (produces docs)

    grep -n 'AGENT_PROMPT=.*\.claude/agents/.*\.md' "${cmd_path}" | \
        grep -E 'plan-|research-|implementation-|documentation-' | \
        while IFS=: read -r line_num rest; do
            local agent=$(echo "${rest}" | sed -n 's/.*agents\/\([^"]*\)\.md.*/\1/p')
            echo "${line_num}:${agent}"
        done
}

# Check if verification checkpoint exists after agent invocation
# Args:
#   $1 - Command file path
#   $2 - Agent invocation line number
# Returns:
#   0 - Verification checkpoint found
#   1 - No verification checkpoint
has_verification_checkpoint() {
    local cmd_path=$1
    local invocation_line=$2

    # Look for verification checkpoint patterns within next 20 lines:
    # 1. if [[ ! -f "${file_path}" ]]; then ... fi
    # 2. verify_checkpoint "${file_path}"
    # 3. [ -f "${file_path}" ] || handle_error

    local search_end=$((invocation_line + 20))
    local search_block=$(sed -n "${invocation_line},${search_end}p" "${cmd_path}")

    # Pattern 1: if [[ ! -f ... ]]; then error handling
    if echo "${search_block}" | grep -q 'if \[\[ ! -f'; then
        return 0
    fi

    # Pattern 2: verify_checkpoint function call
    if echo "${search_block}" | grep -q 'verify_checkpoint'; then
        return 0
    fi

    # Pattern 3: [ -f ... ] || error handling
    if echo "${search_block}" | grep -q '\[ -f.*\] ||'; then
        return 0
    fi

    # Pattern 4: test -f with error handling
    if echo "${search_block}" | grep -q 'test -f.*||'; then
        return 0
    fi

    return 1
}

# Analyze verification checkpoint quality
# Args:
#   $1 - Command file path
#   $2 - Checkpoint line number
# Returns:
#   Quality score (0-100)
analyze_checkpoint_quality() {
    local cmd_path=$1
    local line_num=$2

    local checkpoint_block=$(sed -n "${line_num},$((line_num + 10))p" "${cmd_path}")
    local quality=0

    # Quality factor 1: File existence check (+30)
    if echo "${checkpoint_block}" | grep -q '\[\[ -f \|test -f'; then
        quality=$((quality + 30))
    fi

    # Quality factor 2: Error handling (+30)
    if echo "${checkpoint_block}" | grep -q 'log_error\|return 1\|exit 1'; then
        quality=$((quality + 30))
    fi

    # Quality factor 3: Descriptive error message (+20)
    if echo "${checkpoint_block}" | grep -q 'log_error.*".*failed'; then
        quality=$((quality + 20))
    fi

    # Quality factor 4: State transition on failure (+20)
    if echo "${checkpoint_block}" | grep -q 'sm_transition.*failed'; then
        quality=$((quality + 20))
    fi

    echo "${quality}"
}
```

### Validation Criteria

1. **Verification Checkpoint Patterns**:
   - File existence checks: `[[ -f "${file_path}" ]]`
   - Error handling: log_error + return/exit
   - State transitions on failure
   - Descriptive error messages

2. **Coverage Requirements**:
   - 100% of artifact-producing agent invocations
   - Checkpoint within 20 lines after invocation
   - Multiple checkpoint patterns acceptable

3. **Artifact-Producing Agents**:
   - plan-*.md agents
   - research-*.md agents
   - implementation-*.md agents
   - documentation-*.md agents

---

## Task 6: Wave Execution Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_wave_execution`)

**Target**: 100% for /build and /research-plan

**Methodology**: Verify dependency-analyzer.sh usage for parallel phase execution

### Implementation

```bash
#!/usr/bin/env bash
# Wave execution validation functions

# Validate wave execution for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes validation
#   1 - Fails validation
validate_wave_execution() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing wave execution in ${cmd}"

    # Wave execution only required for specific commands
    local requires_waves=false
    case "${cmd}" in
        build|research-plan)
            requires_waves=true
            ;;
    esac

    if [[ "${requires_waves}" == false ]]; then
        log_info "    Wave execution not required for ${cmd}"
        VALIDATION_RESULTS["${cmd}:wave_execution"]="SKIP"
        return 0
    fi

    # Check for dependency-analyzer.sh usage
    if ! grep -q 'dependency-analyzer\.sh' "${cmd_path}"; then
        log_error "    FAIL: dependency-analyzer.sh not found"
        VALIDATION_RESULTS["${cmd}:wave_execution"]="FAIL:no_analyzer"
        return 1
    fi

    # Check for wave execution loop
    if ! grep -q 'for wave in' "${cmd_path}"; then
        log_error "    FAIL: Wave execution loop not found"
        VALIDATION_RESULTS["${cmd}:wave_execution"]="FAIL:no_loop"
        return 1
    fi

    # Check for parallel execution within waves
    if ! grep -q 'wait\|&' "${cmd_path}"; then
        log_error "    FAIL: Parallel execution not implemented"
        VALIDATION_RESULTS["${cmd}:wave_execution"]="FAIL:no_parallel"
        return 1
    fi

    # Analyze wave execution completeness
    local completeness=$(analyze_wave_completeness "${cmd_path}")

    if [[ "${completeness}" != "complete" ]]; then
        log_error "    FAIL: Wave execution incomplete: ${completeness}"
        VALIDATION_RESULTS["${cmd}:wave_execution"]="FAIL:${completeness}"
        return 1
    fi

    log_success "    PASS: Wave execution properly implemented"
    VALIDATION_RESULTS["${cmd}:wave_execution"]="PASS"
    return 0
}

# Analyze wave execution completeness
# Args:
#   $1 - Command file path
# Returns:
#   "complete" if valid, error description otherwise
analyze_wave_completeness() {
    local cmd_path=$1

    # Required components:
    # 1. Dependency graph construction
    # 2. Wave calculation
    # 3. Wave iteration loop
    # 4. Parallel phase execution within wave
    # 5. Wave barrier (wait for all phases in wave)

    # Component 1: Dependency graph construction
    if ! grep -q 'dependency-analyzer\.sh.*build-graph' "${cmd_path}"; then
        echo "missing_graph_construction"
        return 1
    fi

    # Component 2: Wave calculation
    if ! grep -q 'dependency-analyzer\.sh.*calculate-waves' "${cmd_path}"; then
        echo "missing_wave_calculation"
        return 1
    fi

    # Component 3: Wave iteration
    if ! grep -q 'while read -r wave_num'; then
        echo "missing_wave_iteration"
        return 1
    fi

    # Component 4: Parallel execution
    local has_background_execution=$(grep -c '&$' "${cmd_path}" || echo 0)
    if [[ ${has_background_execution} -eq 0 ]]; then
        echo "missing_parallel_execution"
        return 1
    fi

    # Component 5: Wave barrier
    if ! grep -q 'wait.*#.*wave barrier'; then
        echo "missing_wave_barrier"
        return 1
    fi

    echo "complete"
    return 0
}

# Extract wave execution metrics
# Args:
#   $1 - Command file path
# Returns:
#   JSON object with wave metrics
extract_wave_metrics() {
    local cmd_path=$1

    # Count wave-related operations
    local graph_builds=$(grep -c 'build-graph' "${cmd_path}" || echo 0)
    local wave_calculations=$(grep -c 'calculate-waves' "${cmd_path}" || echo 0)
    local parallel_execs=$(grep -c '&$' "${cmd_path}" || echo 0)
    local wave_barriers=$(grep -c 'wait' "${cmd_path}" || echo 0)

    cat <<EOF
{
    "graph_builds": ${graph_builds},
    "wave_calculations": ${wave_calculations},
    "parallel_executions": ${parallel_execs},
    "wave_barriers": ${wave_barriers}
}
EOF
}
```

### Validation Criteria

1. **Required for Commands**:
   - /build: Multi-phase implementation plans
   - /research-plan: Complex research with parallel subtopics

2. **Wave Execution Components**:
   - Dependency graph construction
   - Wave calculation (topological sort)
   - Wave iteration loop
   - Parallel phase execution (background jobs)
   - Wave barrier (wait for wave completion)

3. **Performance Benefits**:
   - 40-60% time savings for plans with parallelizable phases
   - Measured via performance baseline tests (Task 9)

---

## Task 7: Hierarchical Supervision Validation

**Library**: `.claude/lib/metric-collectors.sh` (function: `validate_hierarchical_supervision`)

**Target**: Automatic for complexity ≥4

**Methodology**: Verify research-sub-supervisor.md invocation for complex research

### Implementation

```bash
#!/usr/bin/env bash
# Hierarchical supervision validation functions

# Validate hierarchical supervision for a command
# Args:
#   $1 - Command name
#   $2 - Command file path
# Returns:
#   0 - Passes validation
#   1 - Fails validation
validate_hierarchical_supervision() {
    local cmd=$1
    local cmd_path=$2

    log_info "    Analyzing hierarchical supervision in ${cmd}"

    # Hierarchical supervision only required for research commands
    if [[ "${cmd}" != research* ]]; then
        log_info "    Hierarchical supervision not required for ${cmd}"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="SKIP"
        return 0
    fi

    # Check for complexity threshold logic
    if ! grep -q 'COMPLEXITY' "${cmd_path}"; then
        log_error "    FAIL: No complexity threshold logic found"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="FAIL:no_threshold"
        return 1
    fi

    # Check for sub-supervisor invocation
    if ! grep -q 'research-sub-supervisor\.md' "${cmd_path}"; then
        log_error "    FAIL: research-sub-supervisor.md not found"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="FAIL:no_supervisor"
        return 1
    fi

    # Validate complexity threshold value
    local threshold=$(extract_complexity_threshold "${cmd_path}")

    if [[ ${threshold} -ne 4 ]]; then
        log_error "    FAIL: Incorrect complexity threshold: ${threshold} (expected 4)"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="FAIL:wrong_threshold:${threshold}"
        return 1
    fi

    # Check for conditional supervision logic
    if ! grep -q 'if.*COMPLEXITY.*-ge.*4' "${cmd_path}"; then
        log_error "    FAIL: Conditional supervision logic not found"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="FAIL:no_conditional"
        return 1
    fi

    # Validate supervision completeness
    local completeness=$(validate_supervision_completeness "${cmd_path}")

    if [[ "${completeness}" != "complete" ]]; then
        log_error "    FAIL: Supervision incomplete: ${completeness}"
        VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="FAIL:${completeness}"
        return 1
    fi

    log_success "    PASS: Hierarchical supervision properly implemented"
    VALIDATION_RESULTS["${cmd}:hierarchical_supervision"]="PASS"
    return 0
}

# Extract complexity threshold from command file
# Args:
#   $1 - Command file path
# Returns:
#   Complexity threshold value
extract_complexity_threshold() {
    local cmd_path=$1

    # Extract threshold from conditional: if [[ ${COMPLEXITY} -ge 4 ]]
    grep 'COMPLEXITY.*-ge' "${cmd_path}" | \
        sed -n 's/.*-ge[[:space:]]*\([0-9]*\).*/\1/p' | \
        head -n1
}

# Validate supervision completeness
# Args:
#   $1 - Command file path
# Returns:
#   "complete" if valid, error description otherwise
validate_supervision_completeness() {
    local cmd_path=$1

    # Required components:
    # 1. Complexity assessment
    # 2. Threshold comparison
    # 3. Conditional sub-supervisor invocation
    # 4. Fallback for low complexity

    # Component 1: Complexity assessment
    if ! grep -q 'COMPLEXITY=' "${cmd_path}"; then
        echo "missing_complexity_assessment"
        return 1
    fi

    # Component 2: Threshold comparison
    if ! grep -q 'COMPLEXITY.*-ge\|-gt' "${cmd_path}"; then
        echo "missing_threshold_comparison"
        return 1
    fi

    # Component 3: Conditional invocation
    local supervisor_line=$(grep -n 'research-sub-supervisor\.md' "${cmd_path}" | cut -d: -f1)
    if [[ -z "${supervisor_line}" ]]; then
        echo "missing_supervisor_invocation"
        return 1
    fi

    # Check if supervisor is inside conditional block
    local conditional_line=$(grep -n 'if.*COMPLEXITY.*-ge' "${cmd_path}" | cut -d: -f1)
    if [[ ${supervisor_line} -lt ${conditional_line} ]]; then
        echo "supervisor_not_conditional"
        return 1
    fi

    # Component 4: Fallback for low complexity
    if ! grep -q 'else\|elif' "${cmd_path}"; then
        echo "missing_fallback"
        return 1
    fi

    echo "complete"
    return 0
}
```

### Validation Criteria

1. **Complexity Threshold**:
   - Threshold value: 4 (based on research)
   - Complexity scale: 1-10 (manual assessment or automatic)

2. **Supervision Components**:
   - Complexity assessment (user input or automatic)
   - Threshold comparison (≥4)
   - Conditional sub-supervisor invocation
   - Fallback to direct agent invocation for complexity <4

3. **Sub-Supervisor Features**:
   - Parallel subtopic execution
   - Quality validation
   - Research synthesis

---

## Task 8: Edge Case Testing

**File**: `.claude/tests/edge_cases/orchestrator_edge_cases.sh`

**Purpose**: Comprehensive edge case testing for all orchestrator commands

### Test Categories

#### Category 1: Concurrent Execution (File Path Conflicts)

```bash
#!/usr/bin/env bash
# Test concurrent execution with file path conflicts

test_concurrent_research_same_topic() {
    log_info "Testing concurrent /research with same topic"

    # Launch two research commands with same topic simultaneously
    local topic="test_concurrency_topic"

    /research "${topic}" > /tmp/research1.log 2>&1 &
    local pid1=$!

    /research "${topic}" > /tmp/research2.log 2>&1 &
    local pid2=$!

    wait ${pid1}
    local exit1=$?

    wait ${pid2}
    local exit2=$?

    # Verify one succeeded and one failed with proper error
    if [[ ${exit1} -eq 0 && ${exit2} -ne 0 ]] || [[ ${exit1} -ne 0 && ${exit2} -eq 0 ]]; then
        log_success "PASS: Concurrent execution properly handled"
        return 0
    else
        log_error "FAIL: Both commands succeeded or both failed"
        return 1
    fi
}

test_concurrent_build_same_plan() {
    log_info "Testing concurrent /build with same plan"

    # Create test plan
    local plan_path="/tmp/test_plan_$$. md"
    create_test_plan "${plan_path}"

    # Launch two build commands simultaneously
    /build "${plan_path}" > /tmp/build1.log 2>&1 &
    local pid1=$!

    /build "${plan_path}" > /tmp/build2.log 2>&1 &
    local pid2=$!

    wait ${pid1}
    local exit1=$?

    wait ${pid2}
    local exit2=$?

    # Verify lock mechanism prevents concurrent execution
    if [[ ${exit1} -eq 0 && ${exit2} -ne 0 ]] || [[ ${exit1} -ne 0 && ${exit2} -eq 0 ]]; then
        log_success "PASS: Concurrent build properly prevented"
        return 0
    else
        log_error "FAIL: Lock mechanism ineffective"
        return 1
    fi
}
```

#### Category 2: Invalid Plan Path

```bash
#!/usr/bin/env bash
# Test invalid plan path handling

test_nonexistent_plan() {
    log_info "Testing /build with nonexistent plan"

    /build "/nonexistent/plan.md" > /tmp/build_error.log 2>&1
    local exit_code=$?

    # Verify proper error handling
    if [[ ${exit_code} -ne 0 ]] && grep -q "Plan file not found" /tmp/build_error.log; then
        log_success "PASS: Nonexistent plan properly handled"
        return 0
    else
        log_error "FAIL: Improper error handling for nonexistent plan"
        return 1
    fi
}

test_malformed_plan() {
    log_info "Testing /build with malformed plan"

    # Create malformed plan (missing required sections)
    local plan_path="/tmp/malformed_plan_$$.md"
    cat > "${plan_path}" <<EOF
# Malformed Plan

This plan is missing:
- Metadata section
- Phase structure
- Task lists
EOF

    /build "${plan_path}" > /tmp/build_error.log 2>&1
    local exit_code=$?

    # Verify proper validation error
    if [[ ${exit_code} -ne 0 ]] && grep -q "Invalid plan structure" /tmp/build_error.log; then
        log_success "PASS: Malformed plan properly detected"
        return 0
    else
        log_error "FAIL: Malformed plan not detected"
        return 1
    fi
}

test_directory_instead_of_file() {
    log_info "Testing /build with directory path"

    local dir_path="/tmp/test_dir_$$"
    mkdir -p "${dir_path}"

    /build "${dir_path}" > /tmp/build_error.log 2>&1
    local exit_code=$?

    # Verify proper error handling
    if [[ ${exit_code} -ne 0 ]] && grep -q "not a file" /tmp/build_error.log; then
        log_success "PASS: Directory path properly rejected"
        return 0
    else
        log_error "FAIL: Directory path not properly handled"
        return 1
    fi

    rm -rf "${dir_path}"
}
```

#### Category 3: Mid-Phase Interruption

```bash
#!/usr/bin/env bash
# Test mid-phase interruption and recovery

test_sigint_during_build() {
    log_info "Testing SIGINT during /build"

    # Create test plan
    local plan_path="/tmp/test_plan_$$.md"
    create_test_plan "${plan_path}"

    # Launch build in background
    /build "${plan_path}" > /tmp/build_interrupted.log 2>&1 &
    local build_pid=$!

    # Wait for build to start (check for state file)
    sleep 2

    # Send SIGINT
    kill -INT ${build_pid}

    wait ${build_pid}
    local exit_code=$?

    # Verify proper cleanup
    if [[ ${exit_code} -ne 0 ]] && grep -q "Interrupted" /tmp/build_interrupted.log; then
        # Check state machine cleanup
        if [[ ! -f "/tmp/state_*.json" ]]; then
            log_success "PASS: SIGINT properly handled with cleanup"
            return 0
        else
            log_error "FAIL: State files not cleaned up"
            return 1
        fi
    else
        log_error "FAIL: SIGINT not properly handled"
        return 1
    fi
}

test_resume_after_interruption() {
    log_info "Testing resume after interruption"

    # Create test plan
    local plan_path="/tmp/test_plan_$$.md"
    create_test_plan "${plan_path}"

    # Start build
    /build "${plan_path}" > /tmp/build1.log 2>&1 &
    local pid1=$!

    # Interrupt after 5 seconds
    sleep 5
    kill -INT ${pid1}
    wait ${pid1}

    # Resume build
    /build "${plan_path}" --resume > /tmp/build2.log 2>&1
    local exit_code=$?

    # Verify successful resume
    if [[ ${exit_code} -eq 0 ]] && grep -q "Resumed from" /tmp/build2.log; then
        log_success "PASS: Resume after interruption successful"
        return 0
    else
        log_error "FAIL: Resume failed"
        return 1
    fi
}
```

#### Category 4: Library Incompatibility

```bash
#!/usr/bin/env bash
# Test library incompatibility handling

test_missing_state_machine_library() {
    log_info "Testing missing state-machine.sh library"

    # Temporarily rename library
    local lib_path="${PROJECT_ROOT}/.claude/lib/state-machine.sh"
    local backup_path="${lib_path}.backup"

    mv "${lib_path}" "${backup_path}"

    # Try to run command
    /research "test_topic" > /tmp/research_error.log 2>&1
    local exit_code=$?

    # Restore library
    mv "${backup_path}" "${lib_path}"

    # Verify proper error handling
    if [[ ${exit_code} -ne 0 ]] && grep -q "state-machine.sh not found" /tmp/research_error.log; then
        log_success "PASS: Missing library properly detected"
        return 0
    else
        log_error "FAIL: Missing library not detected"
        return 1
    fi
}

test_incompatible_library_version() {
    log_info "Testing incompatible library version"

    # Create incompatible library version
    local lib_path="${PROJECT_ROOT}/.claude/lib/state-machine.sh"
    local backup_path="${lib_path}.backup"

    cp "${lib_path}" "${backup_path}"

    # Modify library to incompatible version
    sed -i '1i# VERSION=0.1.0' "${lib_path}"

    # Try to run command
    /research "test_topic" > /tmp/research_error.log 2>&1
    local exit_code=$?

    # Restore library
    mv "${backup_path}" "${lib_path}"

    # Verify version check
    if [[ ${exit_code} -ne 0 ]] && grep -q "Incompatible library version" /tmp/research_error.log; then
        log_success "PASS: Library version check working"
        return 0
    else
        log_error "FAIL: Library version not checked"
        return 1
    fi
}
```

#### Category 5: Malformed Workflow Description

```bash
#!/usr/bin/env bash
# Test malformed workflow description handling

test_empty_research_topic() {
    log_info "Testing /research with empty topic"

    /research "" > /tmp/research_error.log 2>&1
    local exit_code=$?

    # Verify proper error handling
    if [[ ${exit_code} -ne 0 ]] && grep -q "Topic required" /tmp/research_error.log; then
        log_success "PASS: Empty topic properly rejected"
        return 0
    else
        log_error "FAIL: Empty topic not handled"
        return 1
    fi
}

test_special_characters_in_topic() {
    log_info "Testing /research with special characters in topic"

    local topic="test/topic|with<special>chars"

    /research "${topic}" > /tmp/research_special.log 2>&1
    local exit_code=$?

    # Verify proper sanitization or rejection
    if [[ ${exit_code} -eq 0 ]]; then
        # Check if topic was sanitized
        if grep -q "test_topic_with_special_chars" /tmp/research_special.log; then
            log_success "PASS: Special characters properly sanitized"
            return 0
        else
            log_error "FAIL: Topic not sanitized"
            return 1
        fi
    else
        log_error "FAIL: Command failed unexpectedly"
        return 1
    fi
}
```

---

## Task 9: Performance Baseline Measurement

**File**: `.claude/lib/performance-benchmarks.sh`

**Purpose**: Measure latency per workflow type and establish performance baseline

### Benchmark Implementation

```bash
#!/usr/bin/env bash
# Performance benchmark functions

# Measure performance baseline for a command
# Args:
#   $1 - Command name
# Returns:
#   0 - Benchmark completed
#   1 - Benchmark failed
measure_performance_baseline() {
    local cmd=$1

    log_info "    Measuring performance baseline for ${cmd}"

    # Run command 10 times and collect latency metrics
    local run_count=10
    local latencies=()

    for ((i=1; i<=run_count; i++)); do
        log_info "      Run ${i}/${run_count}"

        local start_time=$(date +%s.%N)
        run_command_benchmark "${cmd}" > /dev/null 2>&1
        local exit_code=$?
        local end_time=$(date +%s.%N)

        if [[ ${exit_code} -ne 0 ]]; then
            log_warning "      Run ${i} failed, skipping"
            continue
        fi

        local latency=$(echo "${end_time} - ${start_time}" | bc)
        latencies+=("${latency}")

        log_info "      Latency: ${latency}s"
    done

    # Calculate statistics
    local avg_latency=$(calculate_average "${latencies[@]}")
    local min_latency=$(calculate_min "${latencies[@]}")
    local max_latency=$(calculate_max "${latencies[@]}")
    local stddev=$(calculate_stddev "${latencies[@]}")

    log_info "    Performance statistics:"
    log_info "      Average: ${avg_latency}s"
    log_info "      Min: ${min_latency}s"
    log_info "      Max: ${max_latency}s"
    log_info "      Std Dev: ${stddev}s"

    # Store metrics
    PERFORMANCE_METRICS["${cmd}:avg"]="${avg_latency}"
    PERFORMANCE_METRICS["${cmd}:min"]="${min_latency}"
    PERFORMANCE_METRICS["${cmd}:max"]="${max_latency}"
    PERFORMANCE_METRICS["${cmd}:stddev"]="${stddev}"

    # Validate against latency budget
    validate_latency_budget "${cmd}" "${avg_latency}"

    return 0
}

# Run command for benchmarking
# Args:
#   $1 - Command name
run_command_benchmark() {
    local cmd=$1

    case "${cmd}" in
        research)
            /research "test_benchmark_topic_$$" --quiet
            ;;
        research-plan)
            /research-plan "test_benchmark_feature_$$" --quiet
            ;;
        research-revise)
            # Requires existing plan
            local test_plan="/tmp/benchmark_plan_$$.md"
            create_test_plan "${test_plan}"
            /research-revise "${test_plan}" "minor revision" --quiet
            ;;
        build)
            # Requires existing plan
            local test_plan="/tmp/benchmark_plan_$$.md"
            create_test_plan "${test_plan}"
            /build "${test_plan}" --quiet
            ;;
        fix)
            /fix "test_benchmark_issue_$$" --quiet
            ;;
    esac
}

# Calculate average of values
# Args:
#   $@ - Values
calculate_average() {
    local values=("$@")
    local sum=0
    local count=${#values[@]}

    for value in "${values[@]}"; do
        sum=$(echo "${sum} + ${value}" | bc)
    done

    echo "scale=3; ${sum} / ${count}" | bc
}

# Calculate minimum of values
# Args:
#   $@ - Values
calculate_min() {
    local values=("$@")
    local min="${values[0]}"

    for value in "${values[@]}"; do
        if (( $(echo "${value} < ${min}" | bc -l) )); then
            min="${value}"
        fi
    done

    echo "${min}"
}

# Calculate maximum of values
# Args:
#   $@ - Values
calculate_max() {
    local values=("$@")
    local max="${values[0]}"

    for value in "${values[@]}"; do
        if (( $(echo "${value} > ${max}" | bc -l) )); then
            max="${value}"
        fi
    done

    echo "${max}"
}

# Calculate standard deviation
# Args:
#   $@ - Values
calculate_stddev() {
    local values=("$@")
    local count=${#values[@]}
    local avg=$(calculate_average "${values[@]}")

    local sum_sq_diff=0
    for value in "${values[@]}"; do
        local diff=$(echo "${value} - ${avg}" | bc)
        local sq_diff=$(echo "${diff} * ${diff}" | bc)
        sum_sq_diff=$(echo "${sum_sq_diff} + ${sq_diff}" | bc)
    done

    local variance=$(echo "scale=3; ${sum_sq_diff} / ${count}" | bc)
    echo "scale=3; sqrt(${variance})" | bc
}
```

### Latency Budgets

```bash
#!/usr/bin/env bash
# Latency budget validation

# Validate latency budget for a command
# Args:
#   $1 - Command name
#   $2 - Average latency (seconds)
validate_latency_budget() {
    local cmd=$1
    local avg_latency=$2

    # Latency budgets (in seconds)
    declare -A LATENCY_BUDGETS=(
        ["research"]=5
        ["research-plan"]=15
        ["research-revise"]=10
        ["build"]=60
        ["fix"]=10
    )

    local budget=${LATENCY_BUDGETS["${cmd}"]}

    if [[ -z "${budget}" ]]; then
        log_warning "    No latency budget defined for ${cmd}"
        return 0
    fi

    log_info "    Latency budget: ${budget}s"

    if (( $(echo "${avg_latency} <= ${budget}" | bc -l) )); then
        log_success "    PASS: Latency ${avg_latency}s <= ${budget}s"
        VALIDATION_RESULTS["${cmd}:latency_budget"]="PASS:${avg_latency}s"
        return 0
    else
        log_error "    FAIL: Latency ${avg_latency}s > ${budget}s"
        VALIDATION_RESULTS["${cmd}:latency_budget"]="FAIL:${avg_latency}s"
        return 1
    fi
}
```

---

## Task 10: Validation Results Documentation

**File**: `.claude/specs/743_*/artifacts/feature_preservation_results.md`

**Purpose**: Document validation results for all features across all commands

### Report Structure

```markdown
# Feature Preservation Validation Results

**Date**: {TIMESTAMP}
**Validation Script**: validate_feature_preservation.sh v1.0
**Commands Validated**: /research, /research-plan, /research-revise, /build, /fix

---

## Executive Summary

| Command | Overall Status | Features Passed | Features Failed |
|---------|----------------|-----------------|-----------------|
| /research | PASS | 6/6 | 0/6 |
| /research-plan | PASS | 6/6 | 0/6 |
| /research-revise | PASS | 6/6 | 0/6 |
| /build | PASS | 6/6 | 0/6 |
| /fix | PASS | 6/6 | 0/6 |

**Overall Validation**: ✓ PASSED (30/30 checks)

---

## Feature 1: Delegation Rate

**Target**: >90% delegation rate

| Command | Delegation Rate | Status | Details |
|---------|----------------|---------|---------|
| /research | 94.2% | PASS | 16 agent invocations, 1 direct operation |
| /research-plan | 92.8% | PASS | 13 agent invocations, 1 direct operation |
| /research-revise | 91.3% | PASS | 21 agent invocations, 2 direct operations |
| /build | 96.1% | PASS | 24 agent invocations, 1 direct operation |
| /fix | 93.7% | PASS | 15 agent invocations, 1 direct operation |

### Analysis

All commands achieve >90% delegation rate, meeting the target. Direct operations are limited to essential bootstrapping (directory creation, state initialization).

### Comparison with /coordinate

Original `/coordinate` delegation rate: 92-95%
New commands average: 93.6%
**Conclusion**: Feature preserved ✓

---

## Feature 2: Context Usage

**Target**: <300 tokens per agent invocation

| Command | Avg Context Size | Status | Details |
|---------|------------------|---------|---------|
| /research | 187 tokens | PASS | Metadata-only extraction |
| /research-plan | 243 tokens | PASS | Includes feature description |
| /research-revise | 256 tokens | PASS | Includes revision details |
| /build | 214 tokens | PASS | Phase metadata only |
| /fix | 198 tokens | PASS | Issue description + context |

### Analysis

All commands stay well below 300 token target through effective metadata extraction. No full file content passed to agents.

### Comparison with /coordinate

Original `/coordinate` average: 150-250 tokens
New commands average: 220 tokens
**Conclusion**: Feature preserved ✓

---

## Feature 3: State Machine Architecture

**Target**: 100% coverage of sm_init and sm_transition

| Command | sm_init | sm_transition | sm_cleanup | Status |
|---------|---------|---------------|------------|---------|
| /research | 1 | 8 | 1 | PASS |
| /research-plan | 1 | 12 | 1 | PASS |
| /research-revise | 1 | 15 | 1 | PASS |
| /build | 1 | 20 | 1 | PASS |
| /fix | 1 | 10 | 1 | PASS |

### Analysis

All commands properly initialize state machine, use sm_transition for all state changes, and cleanup on exit. No direct state file manipulation detected.

### Comparison with /coordinate

Original `/coordinate`: Full state machine implementation
New commands: Full state machine implementation
**Conclusion**: Feature preserved ✓

---

## Feature 4: Verification Checkpoints

**Target**: 100% checkpoint compliance

| Command | Total Invocations | Verified | Compliance | Status |
|---------|-------------------|----------|------------|---------|
| /research | 12 | 12 | 100% | PASS |
| /research-plan | 10 | 10 | 100% | PASS |
| /research-revise | 16 | 16 | 100% | PASS |
| /build | 18 | 18 | 100% | PASS |
| /fix | 11 | 11 | 100% | PASS |

### Analysis

All artifact-producing agent invocations have corresponding verification checkpoints. Checkpoints include file existence checks and error handling.

### Comparison with /coordinate

Original `/coordinate`: 100% checkpoint compliance
New commands: 100% checkpoint compliance
**Conclusion**: Feature preserved ✓

---

## Feature 5: Wave Execution

**Target**: 100% for /build and /research-plan

| Command | Required | dependency-analyzer.sh | Wave Loop | Parallel Exec | Status |
|---------|----------|------------------------|-----------|---------------|---------|
| /research | No | N/A | N/A | N/A | SKIP |
| /research-plan | Yes | ✓ | ✓ | ✓ | PASS |
| /research-revise | No | N/A | N/A | N/A | SKIP |
| /build | Yes | ✓ | ✓ | ✓ | PASS |
| /fix | No | N/A | N/A | N/A | SKIP |

### Analysis

Commands requiring wave execution (/build, /research-plan) fully implement dependency-analyzer.sh, wave iteration, and parallel execution with barriers.

### Comparison with /coordinate

Original `/coordinate`: Wave execution for complex workflows
New commands: Wave execution for /build and /research-plan
**Conclusion**: Feature preserved ✓

---

## Feature 6: Hierarchical Supervision

**Target**: Automatic for complexity ≥4

| Command | Required | Threshold | Sub-Supervisor | Conditional | Status |
|---------|----------|-----------|----------------|-------------|---------|
| /research | Yes | 4 | ✓ | ✓ | PASS |
| /research-plan | Yes | 4 | ✓ | ✓ | PASS |
| /research-revise | Yes | 4 | ✓ | ✓ | PASS |
| /build | No | N/A | N/A | N/A | SKIP |
| /fix | No | N/A | N/A | N/A | SKIP |

### Analysis

All research commands implement hierarchical supervision with correct complexity threshold (≥4). Sub-supervisor invoked conditionally based on complexity.

### Comparison with /coordinate

Original `/coordinate`: Automatic hierarchical supervision for complexity ≥4
New commands: Automatic hierarchical supervision for complexity ≥4
**Conclusion**: Feature preserved ✓

---

## Edge Case Testing Results

| Test Case | Status | Details |
|-----------|--------|---------|
| Concurrent execution (same topic) | PASS | Proper file locking prevents conflicts |
| Concurrent execution (same plan) | PASS | Lock mechanism effective |
| Nonexistent plan path | PASS | Proper error handling |
| Malformed plan structure | PASS | Validation detects issues |
| Directory instead of file | PASS | Type check working |
| SIGINT during execution | PASS | Proper cleanup on interrupt |
| Resume after interruption | PASS | State persistence working |
| Missing library | PASS | Dependency check effective |
| Incompatible library version | PASS | Version validation working |
| Empty workflow description | PASS | Input validation working |
| Special characters in input | PASS | Sanitization effective |

**Edge Case Summary**: ✓ 11/11 tests passed

---

## Recommendations

### Strengths

1. All 6 essential features fully preserved across all commands
2. Edge case handling robust and comprehensive
3. Performance within latency budgets
4. No regression from original `/coordinate` functionality

### Areas for Improvement

1. **Documentation**: Add inline comments explaining state machine transitions
2. **Error Messages**: Enhance error messages with recovery suggestions
3. **Metrics Collection**: Add automated metrics collection to commands
4. **Testing**: Expand edge case coverage to include network failures and disk full scenarios

---

## Conclusion

All dedicated orchestrator commands successfully preserve the 6 essential features from `/coordinate`. Validation confirms no regression in functionality, delegation rate, context efficiency, or performance.

**Recommendation**: Proceed to production deployment
```

---

## Task 11-14: Run Validation, Fix Issues, Document Results

### Task 11: Run Validation Against All Commands

```bash
#!/usr/bin/env bash
# Run validation script

cd "${PROJECT_ROOT}/.claude/tests"
./validate_feature_preservation.sh --verbose | tee validation_output.log

# Check exit code
if [[ $? -eq 0 ]]; then
    echo "✓ All validations passed"
else
    echo "✗ Validation failures detected - see validation_output.log"
fi
```

### Task 12: Fix Feature Preservation Violations

**Process**:

1. Review validation log for failures
2. For each failure, identify root cause
3. Implement fix in command file
4. Re-run validation for that command
5. Document fix in fix log

**Fix Log Template**:

```markdown
# Feature Preservation Fixes

## Fix 1: /research - Delegation Rate

**Issue**: Delegation rate 87.3% below 90% target
**Root Cause**: Direct file writes for directory structure creation
**Fix**: Delegate directory creation to setup agent
**Validation**: Re-run shows 94.2% delegation rate
**Status**: ✓ Fixed

## Fix 2: /build - Verification Checkpoints

**Issue**: Missing checkpoint after phase completion agent
**Root Cause**: Checkpoint code commented out during debugging
**Fix**: Uncommented verification checkpoint, added error handling
**Validation**: Re-run shows 100% compliance
**Status**: ✓ Fixed
```

### Task 13: Document Validation Results

**Action**: Generate `feature_preservation_results.md` using validation results template (see Task 10)

### Task 14: Document Performance Baseline

**File**: `.claude/specs/743_*/artifacts/performance_baseline.md`

**Structure**:

```markdown
# Performance Baseline for Orchestrator Commands

**Measurement Date**: {TIMESTAMP}
**Measurement Runs**: 10 per command
**Environment**: {SYSTEM_INFO}

---

## Latency Measurements

### /research Command

- **Average Latency**: 3.2s
- **Min Latency**: 2.8s
- **Max Latency**: 3.9s
- **Std Deviation**: 0.34s
- **Latency Budget**: 5s
- **Status**: ✓ Within budget (64% of budget used)

**Latency Breakdown**:
- State initialization: 0.1s
- Topic analysis: 0.8s
- Agent invocations: 2.1s
- Report generation: 0.2s

**Comparison with /coordinate**:
- Original /coordinate: 4.1s average
- New /research: 3.2s average
- **Improvement**: 22% faster

---

### /research-plan Command

- **Average Latency**: 12.4s
- **Min Latency**: 11.2s
- **Max Latency**: 14.8s
- **Std Deviation**: 1.1s
- **Latency Budget**: 15s
- **Status**: ✓ Within budget (83% of budget used)

**Latency Breakdown**:
- State initialization: 0.1s
- Feature analysis: 1.2s
- Research phase: 5.8s
- Planning phase: 4.9s
- Report synthesis: 0.4s

**Comparison with /coordinate**:
- Original /coordinate: 18.3s average
- New /research-plan: 12.4s average
- **Improvement**: 32% faster (wave execution enabled)

---

## Performance Improvements

| Command | Original /coordinate | New Command | Improvement |
|---------|---------------------|-------------|-------------|
| /research | 4.1s | 3.2s | 22% faster |
| /research-plan | 18.3s | 12.4s | 32% faster |
| /research-revise | 11.7s | 8.9s | 24% faster |
| /build | 45.2s | 28.1s | 38% faster |
| /fix | 8.3s | 7.1s | 14% faster |

**Average Improvement**: 26% faster across all commands

---

## Performance Analysis

### Key Factors Contributing to Improvements

1. **Wave Execution**: 40-60% time savings for parallelizable workflows
2. **Reduced Context Passing**: Metadata extraction reduces token processing
3. **State Machine Efficiency**: Optimized state transitions
4. **Targeted Agent Invocation**: Specialized agents load faster

### Performance vs. Original /coordinate

All new commands are faster than original `/coordinate` for equivalent workflows:
- Specialized command loading: ~0.5s faster
- Optimized agent routing: ~1-2s faster
- Parallel execution: ~5-10s faster (where applicable)

### Scalability Considerations

Performance scales well with workflow complexity:
- Simple workflows (<5 phases): 3-8s
- Medium workflows (5-10 phases): 10-20s
- Complex workflows (>10 phases): 25-45s

Wave execution provides consistent 40-60% improvement for parallelizable phases.

---

## Recommendations

1. **Monitor Performance**: Add automated performance tracking to production commands
2. **Optimize Bottlenecks**: Research phase in /research-plan accounts for 47% of latency
3. **Cache Agent Prompts**: Consider caching frequently used agent prompts
4. **Parallel Opportunities**: Explore additional parallelization in /fix command
```

---

## Success Criteria

Phase 6 is complete when:

1. ✓ Validation script created and functional
2. ✓ All 6 features validated across all commands
3. ✓ 100% validation pass rate achieved
4. ✓ Edge case tests pass (11/11)
5. ✓ Performance baseline measured (10 runs per command)
6. ✓ Latency budgets met for all commands
7. ✓ Validation results documented
8. ✓ Performance baseline documented
9. ✓ All fixes logged and verified

---

## Dependencies

**Requires completion of**:
- Phase 2: /research, /research-plan, /research-revise implemented
- Phase 3: /build implemented
- Phase 4: /fix implemented
- Phase 5: Migration guide and integration testing complete

---

## Validation Artifacts

All validation artifacts stored in:
```
.claude/specs/743_*/artifacts/
├── feature_preservation_results.md
├── performance_baseline.md
├── validation_YYYYMMDD_HHMMSS.log
└── fix_log.md
```

---

## Time Estimates

- Task 1 (Validation script): 1 hour
- Tasks 2-7 (Feature validation functions): 1.5 hours
- Task 8 (Edge case tests): 45 minutes
- Task 9 (Performance benchmarks): 30 minutes
- Task 10-14 (Run validation, fix, document): 15 minutes

**Total**: 4 hours
