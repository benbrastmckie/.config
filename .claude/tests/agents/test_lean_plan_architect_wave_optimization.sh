#!/usr/bin/env bash
# Test suite for lean-plan-architect wave optimization enhancements
# Tests theorem dependency mapping, phase dependency generation, and wave structure preview

set -euo pipefail

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Test configuration
COMMAND_NAME="test_lean_plan_architect_wave_optimization"
WORKFLOW_ID="test_$(date +%s)"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
declare -a FAILED_TESTS=()

# Test helper functions
print_test_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════"
}

print_test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"

    TEST_COUNT=$((TEST_COUNT + 1))

    if [[ "$result" == "PASS" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo -e "${GREEN}✓${NC} $test_name"
        [[ -n "$details" ]] && echo "  Details: $details"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}✗${NC} $test_name"
        [[ -n "$details" ]] && echo "  Error: $details"
    fi
}

# Test 1: Verify enhanced theorem dependency analysis section exists
test_theorem_dependency_mapping_instructions() {
    print_test_header "Test 1: Theorem Dependency Mapping Instructions"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for NEW - Map Theorem Dependencies to Phase Dependencies
    if grep -q "NEW - Map Theorem Dependencies to Phase Dependencies" "$agent_file"; then
        print_test_result "Theorem-to-phase mapping instructions exist" "PASS"
    else
        print_test_result "Theorem-to-phase mapping instructions exist" "FAIL" "Missing mapping instructions"
        return 1
    fi

    # Check for Data Structures for Dependency Mapping
    if grep -q "Data Structures for Dependency Mapping" "$agent_file"; then
        print_test_result "Data structures section exists" "PASS"
    else
        print_test_result "Data structures section exists" "FAIL" "Missing data structures"
        return 1
    fi

    # Check for Phase Dependency Conversion Algorithm
    if grep -q "Phase Dependency Conversion Algorithm" "$agent_file"; then
        print_test_result "Conversion algorithm section exists" "PASS"
    else
        print_test_result "Conversion algorithm section exists" "FAIL" "Missing algorithm"
        return 1
    fi

    # Check for Dependency Validation Rules
    if grep -q "Dependency Validation Rules" "$agent_file"; then
        print_test_result "Validation rules section exists" "PASS"
    else
        print_test_result "Validation rules section exists" "FAIL" "Missing validation rules"
        return 1
    fi

    # Check for theorem_dependencies map example
    if grep -q "theorem_dependencies map" "$agent_file"; then
        print_test_result "theorem_dependencies map documented" "PASS"
    else
        print_test_result "theorem_dependencies map documented" "FAIL" "Missing map documentation"
        return 1
    fi

    # Check for theorem_to_phase map example
    if grep -q "theorem_to_phase map" "$agent_file"; then
        print_test_result "theorem_to_phase map documented" "PASS"
    else
        print_test_result "theorem_to_phase map documented" "FAIL" "Missing map documentation"
        return 1
    fi

    # Check for phase_dependencies map example
    if grep -q "phase_dependencies map" "$agent_file"; then
        print_test_result "phase_dependencies map documented" "PASS"
    else
        print_test_result "phase_dependencies map documented" "FAIL" "Missing map documentation"
        return 1
    fi
}

# Test 2: Verify phase dependency array generation instructions
test_phase_dependency_array_generation() {
    print_test_header "Test 2: Phase Dependency Array Generation Instructions"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for CRITICAL - Dependency Array Generation from STEP 1 Analysis
    if grep -q "CRITICAL - Dependency Array Generation from STEP 1 Analysis" "$agent_file"; then
        print_test_result "Dependency array generation section exists" "PASS"
    else
        print_test_result "Dependency array generation section exists" "FAIL" "Missing section"
        return 1
    fi

    # Check for deprecation of sequential pattern
    if grep -q "Current Pattern (DEPRECATED - DO NOT USE)" "$agent_file"; then
        print_test_result "Sequential pattern deprecated" "PASS"
    else
        print_test_result "Sequential pattern deprecated" "FAIL" "Missing deprecation notice"
        return 1
    fi

    # Check for new pattern emphasis
    if grep -q "New Pattern (MANDATORY - Use phase_dependencies map from STEP 1)" "$agent_file"; then
        print_test_result "New pattern emphasized as mandatory" "PASS"
    else
        print_test_result "New pattern emphasized as mandatory" "FAIL" "Missing mandatory emphasis"
        return 1
    fi

    # Check for Dependency Generation Algorithm
    if grep -q "Dependency Generation Algorithm" "$agent_file"; then
        print_test_result "Dependency generation algorithm documented" "PASS"
    else
        print_test_result "Dependency generation algorithm documented" "FAIL" "Missing algorithm"
        return 1
    fi

    # Check for Dependency Array Formatting
    if grep -q "Dependency Array Formatting" "$agent_file"; then
        print_test_result "Array formatting rules documented" "PASS"
    else
        print_test_result "Array formatting rules documented" "FAIL" "Missing formatting rules"
        return 1
    fi

    # Check for Phase Granularity Optimization
    if grep -q "Phase Granularity Optimization" "$agent_file"; then
        print_test_result "Granularity optimization documented" "PASS"
    else
        print_test_result "Granularity optimization documented" "FAIL" "Missing optimization guide"
        return 1
    fi

    # Check for one theorem per phase default
    if grep -q "One theorem per phase" "$agent_file"; then
        print_test_result "One-theorem-per-phase default strategy documented" "PASS"
    else
        print_test_result "One-theorem-per-phase default strategy documented" "FAIL" "Missing strategy"
        return 1
    fi

    # Check for Dependency Validation Checkpoint
    if grep -q "Dependency Validation Checkpoint" "$agent_file"; then
        print_test_result "Validation checkpoint documented" "PASS"
    else
        print_test_result "Validation checkpoint documented" "FAIL" "Missing checkpoint"
        return 1
    fi
}

# Test 3: Verify wave structure preview instructions
test_wave_structure_preview_instructions() {
    print_test_header "Test 3: Wave Structure Preview Instructions"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for Generate Wave Structure Preview section
    if grep -q "Generate Wave Structure Preview" "$agent_file"; then
        print_test_result "Wave structure preview section exists" "PASS"
    else
        print_test_result "Wave structure preview section exists" "FAIL" "Missing section"
        return 1
    fi

    # Check for Kahn's Algorithm
    if grep -q "Kahn's Algorithm" "$agent_file"; then
        print_test_result "Kahn's algorithm documented" "PASS"
    else
        print_test_result "Kahn's algorithm documented" "FAIL" "Missing algorithm"
        return 1
    fi

    # Check for in-degree map
    if grep -q "in-degree map" "$agent_file"; then
        print_test_result "In-degree map concept documented" "PASS"
    else
        print_test_result "In-degree map concept documented" "FAIL" "Missing concept"
        return 1
    fi

    # Check for Parallelization Metrics Calculation
    if grep -q "Parallelization Metrics Calculation" "$agent_file"; then
        print_test_result "Metrics calculation documented" "PASS"
    else
        print_test_result "Metrics calculation documented" "FAIL" "Missing metrics"
        return 1
    fi

    # Check for Wave Structure Preview Format
    if grep -q "Wave Structure Preview Format" "$agent_file"; then
        print_test_result "Preview format documented" "PASS"
    else
        print_test_result "Preview format documented" "FAIL" "Missing format"
        return 1
    fi

    # Check for console output format with Unicode box-drawing
    if grep -q "═══════════════════════════════════════════════════════════" "$agent_file"; then
        print_test_result "Console output format with box-drawing exists" "PASS"
    else
        print_test_result "Console output format with box-drawing exists" "FAIL" "Missing format"
        return 1
    fi

    # Check for Wave Structure as Markdown Comment in Plan
    if grep -q "Wave Structure as Markdown Comment in Plan" "$agent_file"; then
        print_test_result "Markdown comment format documented" "PASS"
    else
        print_test_result "Markdown comment format documented" "FAIL" "Missing format"
        return 1
    fi

    # Check for edge cases
    if grep -q "Edge Cases to Handle" "$agent_file"; then
        print_test_result "Edge cases documented" "PASS"
    else
        print_test_result "Edge cases documented" "FAIL" "Missing edge cases"
        return 1
    fi

    # Check for single phase edge case
    if grep -q "Single Phase Plan" "$agent_file"; then
        print_test_result "Single phase edge case documented" "PASS"
    else
        print_test_result "Single phase edge case documented" "FAIL" "Missing edge case"
        return 1
    fi

    # Check for all sequential edge case
    if grep -q "All Sequential Plan" "$agent_file"; then
        print_test_result "All sequential edge case documented" "PASS"
    else
        print_test_result "All sequential edge case documented" "FAIL" "Missing edge case"
        return 1
    fi

    # Check for all parallel edge case
    if grep -q "All Parallel Plan" "$agent_file"; then
        print_test_result "All parallel edge case documented" "PASS"
    else
        print_test_result "All parallel edge case documented" "FAIL" "Missing edge case"
        return 1
    fi

    # Check for Return Signal Enhancement
    if grep -q "Return Signal Enhancement" "$agent_file"; then
        print_test_result "Return signal enhancement documented" "PASS"
    else
        print_test_result "Return signal enhancement documented" "FAIL" "Missing enhancement"
        return 1
    fi

    # Check for WAVES field in signal
    if grep -q "WAVES:" "$agent_file"; then
        print_test_result "WAVES field in return signal documented" "PASS"
    else
        print_test_result "WAVES field in return signal documented" "FAIL" "Missing field"
        return 1
    fi

    # Check for PARALLELIZATION field in signal
    if grep -q "PARALLELIZATION:" "$agent_file"; then
        print_test_result "PARALLELIZATION field in return signal documented" "PASS"
    else
        print_test_result "PARALLELIZATION field in return signal documented" "FAIL" "Missing field"
        return 1
    fi
}

# Test 4: Verify STEP 1 checkpoint updated
test_step1_checkpoint_updated() {
    print_test_header "Test 4: STEP 1 Checkpoint Updated"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for REQUIRED OUTPUTS FROM STEP 1
    if grep -q "REQUIRED OUTPUTS FROM STEP 1" "$agent_file"; then
        print_test_result "STEP 1 outputs section exists" "PASS"
    else
        print_test_result "STEP 1 outputs section exists" "FAIL" "Missing section"
        return 1
    fi

    # Check for theorem_dependencies map in outputs
    if grep -A 10 "REQUIRED OUTPUTS FROM STEP 1" "$agent_file" | grep -q "theorem_dependencies map"; then
        print_test_result "theorem_dependencies map in outputs" "PASS"
    else
        print_test_result "theorem_dependencies map in outputs" "FAIL" "Missing output"
        return 1
    fi

    # Check for theorem_to_phase map in outputs
    if grep -A 10 "REQUIRED OUTPUTS FROM STEP 1" "$agent_file" | grep -q "theorem_to_phase map"; then
        print_test_result "theorem_to_phase map in outputs" "PASS"
    else
        print_test_result "theorem_to_phase map in outputs" "FAIL" "Missing output"
        return 1
    fi

    # Check for phase_dependencies map in outputs
    if grep -A 10 "REQUIRED OUTPUTS FROM STEP 1" "$agent_file" | grep -q "phase_dependencies map"; then
        print_test_result "phase_dependencies map in outputs" "PASS"
    else
        print_test_result "phase_dependencies map in outputs" "FAIL" "Missing output"
        return 1
    fi

    # Check for dependency validation in outputs
    if grep -A 10 "REQUIRED OUTPUTS FROM STEP 1" "$agent_file" | grep -q "Dependency validation completed"; then
        print_test_result "Dependency validation in outputs" "PASS"
    else
        print_test_result "Dependency validation in outputs" "FAIL" "Missing output"
        return 1
    fi

    # Check for wave structure in outputs
    if grep -A 10 "REQUIRED OUTPUTS FROM STEP 1" "$agent_file" | grep -q "Wave structure calculated"; then
        print_test_result "Wave structure in outputs" "PASS"
    else
        print_test_result "Wave structure in outputs" "FAIL" "Missing output"
        return 1
    fi
}

# Test 5: Verify STEP 2 checkpoint updated
test_step2_checkpoint_updated() {
    print_test_header "Test 5: STEP 2 Checkpoint Updated"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for wave structure preview checkpoint
    if grep -q "Wave structure preview displayed and added to plan file" "$agent_file"; then
        print_test_result "Wave structure preview checkpoint exists" "PASS"
    else
        print_test_result "Wave structure preview checkpoint exists" "FAIL" "Missing checkpoint"
        return 1
    fi
}

# Test 6: Verify validation examples present
test_validation_examples() {
    print_test_header "Test 6: Validation Examples"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for forward reference example
    if grep -q "INVALID: Forward reference" "$agent_file"; then
        print_test_result "Forward reference example exists" "PASS"
    else
        print_test_result "Forward reference example exists" "FAIL" "Missing example"
        return 1
    fi

    # Check for self-dependency example
    if grep -q "INVALID: Self-dependency" "$agent_file"; then
        print_test_result "Self-dependency example exists" "PASS"
    else
        print_test_result "Self-dependency example exists" "FAIL" "Missing example"
        return 1
    fi

    # Check for circular dependency example
    if grep -q "INVALID: Circular dependency" "$agent_file"; then
        print_test_result "Circular dependency example exists" "PASS"
    else
        print_test_result "Circular dependency example exists" "FAIL" "Missing example"
        return 1
    fi

    # Check for valid dependency chain example
    if grep -q "VALID: Proper dependency chain" "$agent_file"; then
        print_test_result "Valid dependency chain example exists" "PASS"
    else
        print_test_result "Valid dependency chain example exists" "FAIL" "Missing example"
        return 1
    fi
}

# Test 7: Verify parallelization optimization guidance
test_parallelization_optimization() {
    print_test_header "Test 7: Parallelization Optimization Guidance"

    local agent_file="$CLAUDE_PROJECT_DIR/agents/lean-plan-architect.md"

    # Check for optimize for parallelization section
    if grep -q "Optimize for Parallelization" "$agent_file"; then
        print_test_result "Parallelization optimization section exists" "PASS"
    else
        print_test_result "Parallelization optimization section exists" "FAIL" "Missing section"
        return 1
    fi

    # Check for minimize sequential chains guidance
    if grep -q "Minimize sequential chains" "$agent_file"; then
        print_test_result "Sequential chain minimization documented" "PASS"
    else
        print_test_result "Sequential chain minimization documented" "FAIL" "Missing guidance"
        return 1
    fi

    # Check for balance phase complexity guidance
    if grep -q "Balance phase complexity" "$agent_file"; then
        print_test_result "Phase complexity balancing documented" "PASS"
    else
        print_test_result "Phase complexity balancing documented" "FAIL" "Missing guidance"
        return 1
    fi

    # Check for maximum parallelization default
    if grep -q "maximum parallelization" "$agent_file"; then
        print_test_result "Maximum parallelization default documented" "PASS"
    else
        print_test_result "Maximum parallelization default documented" "FAIL" "Missing default"
        return 1
    fi
}

# Main test execution
main() {
    print_test_header "Lean Plan Architect Wave Optimization Test Suite"
    echo "Testing enhanced theorem dependency mapping and wave structure preview"
    echo ""

    # Run all tests
    test_theorem_dependency_mapping_instructions || true
    test_phase_dependency_array_generation || true
    test_wave_structure_preview_instructions || true
    test_step1_checkpoint_updated || true
    test_step2_checkpoint_updated || true
    test_validation_examples || true
    test_parallelization_optimization || true

    # Print summary
    echo ""
    print_test_header "Test Summary"
    echo "Total Tests: $TEST_COUNT"
    echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
    echo -e "Failed: ${RED}$FAIL_COUNT${NC}"

    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        echo ""
        exit 1
    else
        echo ""
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        exit 0
    fi
}

# Run main function
main "$@"
