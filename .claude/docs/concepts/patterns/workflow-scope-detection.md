# Workflow Scope Detection Pattern

**Path**: docs → concepts → patterns → workflow-scope-detection.md

[Used by: /orchestrate, /coordinate, /supervise, all workflow orchestration commands]

Conditional phase execution based on workflow type, enabling orchestration commands to skip inappropriate phases and reduce cognitive load.

## Problem

Orchestration commands implement 7 phases (research → plan → implement → test → debug → document → summary), but not all workflows require all phases:

1. **Research-Only Workflows**: User wants investigation only, no implementation
   - Example: "research OAuth 2.0 best practices"
   - Should execute: Phases 0-1 (location detection, research)
   - Should skip: Phases 2-7 (planning, implementation, testing, debugging, documentation, summary)

2. **Research-and-Plan Workflows**: User wants understanding and roadmap, no code
   - Example: "research and plan authentication system"
   - Should execute: Phases 0-2 (location detection, research, planning)
   - Should skip: Phases 3-7 (implementation, testing, debugging, documentation, summary)

3. **Full-Implementation Workflows**: User wants complete feature development
   - Example: "implement JWT authentication"
   - Should execute: Phases 0-4, 6 (all phases except debugging, unless tests fail)
   - Should skip: Phase 5 (debugging) unless Phase 4 tests fail

4. **Debug-Only Workflows**: User wants investigation of existing failures
   - Example: "debug failing authentication tests"
   - Should execute: Phases 0-1, 5 (location detection, research, debugging)
   - Should skip: Phases 2-4, 6-7 (planning, implementation, testing, documentation, summary)

**Without Scope Detection**:
- Orchestration commands execute all phases regardless of workflow intent
- Users receive unwanted artifacts (e.g., implementation plan for research-only workflow)
- Wasted context budget on unnecessary phases
- Confusing user experience ("I asked for research, why did it create code?")

**With Scope Detection**:
- Commands execute only relevant phases
- Clean artifact output matching user intent
- Optimal context budget allocation
- Clear user experience matching expectations

## Solution

Analyze workflow description using keyword detection to determine scope type, then use `should_run_phase()` function to conditionally execute each phase.

### Four Scope Types

| Scope Type | Phases Executed | Detection Keywords | Use Cases |
|------------|-----------------|-------------------|-----------|
| **research-only** | 0-1 | "research", "investigate", "explore" (without "plan" or "implement") | Topic exploration, best practices research |
| **research-and-plan** | 0-2 | "research and plan", "plan", "design" (without "implement") | Roadmap creation, architecture planning |
| **full-implementation** | 0-4, 6 | "implement", "create", "build", "add feature" | Feature development, code changes |
| **debug-only** | 0, 1, 5 | "debug", "fix", "investigate failure" | Bug investigation, error analysis |

**Note**: Phase 5 (debugging) is conditionally added to full-implementation workflows if Phase 4 (testing) fails.

### Keyword Detection Logic

```bash
# Pseudo-code for scope detection
if workflow contains ("debug" OR "fix" OR "investigate failure"):
  scope = "debug-only"
elif workflow contains ("implement" OR "create" OR "build" OR "add"):
  scope = "full-implementation"
elif workflow contains ("plan" OR "design") AND NOT ("research only"):
  scope = "research-and-plan"
else:
  scope = "research-only"  # Default: safest assumption
```

## Implementation

### Library: workflow-detection.sh

Location: `.claude/lib/workflow/workflow-detection.sh`

#### Function: `detect_workflow_scope(workflow_description)`

Analyzes workflow description and returns scope type.

**Arguments**:
- `workflow_description` (string): User-provided workflow description

**Returns**: Scope type (stdout)
- `research-only`
- `research-and-plan`
- `full-implementation`
- `debug-only`

**Example**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

SCOPE=$(detect_workflow_scope "research OAuth 2.0 authentication patterns")
echo "$SCOPE"  # Output: research-only

SCOPE=$(detect_workflow_scope "research and plan authentication system")
echo "$SCOPE"  # Output: research-and-plan

SCOPE=$(detect_workflow_scope "implement JWT authentication for API")
echo "$SCOPE"  # Output: full-implementation

SCOPE=$(detect_workflow_scope "debug failing authentication tests")
echo "$SCOPE"  # Output: debug-only
```

#### Function: `should_run_phase(workflow_description, phase_name)`

Determines if a specific phase should execute for given workflow scope.

**Arguments**:
- `workflow_description` (string): User-provided workflow description
- `phase_name` (string): Phase to check (e.g., "testing", "implementation", "planning")

**Returns**: Boolean (stdout)
- `true`: Phase should execute
- `false`: Phase should be skipped

**Phase Name Mapping**:
- `location` → Phase 0
- `research` → Phase 1
- `planning` → Phase 2
- `implementation` → Phase 3
- `testing` → Phase 4
- `debugging` → Phase 5
- `documentation` → Phase 6
- `summary` → Phase 7

**Example**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

WORKFLOW="research OAuth 2.0 patterns"

# Check if planning phase should run
if [ "$(should_run_phase "$WORKFLOW" "planning")" = "true" ]; then
  echo "Planning phase will execute"
else
  echo "Planning phase will be skipped"
fi
# Output: Planning phase will be skipped (research-only scope)

# Check if testing phase should run
WORKFLOW="implement JWT authentication"
if [ "$(should_run_phase "$WORKFLOW" "testing")" = "true" ]; then
  echo "Testing phase will execute"
else
  echo "Testing phase will be skipped"
fi
# Output: Testing phase will execute (full-implementation scope)
```

### Usage in Orchestration Commands

#### Pattern 1: Skip Entire Phase

```markdown
## Phase 4: Testing

**EXECUTE NOW**: USE the Bash tool to check workflow scope:

\`\`\`bash
# Source workflow detection library
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

# Check if testing should run
WORKFLOW_DESCRIPTION="<original user input>"
SHOULD_RUN=$(should_run_phase "$WORKFLOW_DESCRIPTION" "testing")

if [ "$SHOULD_RUN" = "false" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Phase 4 (Testing) - SKIPPED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Reason: Workflow scope does not require testing"
  echo "Scope: $(detect_workflow_scope "$WORKFLOW_DESCRIPTION")"
  echo ""
  echo "TESTING_SKIPPED"
  # Skip to next phase
  exit 0
fi

# If we reach here, testing should run
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4 (Testing) - EXECUTING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
\`\`\`

{Continue with testing phase execution...}
```

#### Pattern 2: Conditional Phase Execution

```markdown
## Phase 5: Debugging

**Conditions for Execution**:
1. Phase 4 (testing) failed, OR
2. Workflow scope is "debug-only"

**EXECUTE NOW**: USE the Bash tool to check conditions:

\`\`\`bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

WORKFLOW_DESCRIPTION="<original user input>"
TESTS_FAILED=<captured from Phase 4>

# Check if debugging should run
SHOULD_RUN="false"

# Condition 1: Tests failed
if [ "$TESTS_FAILED" = "true" ]; then
  SHOULD_RUN="true"
  echo "Debugging triggered: Phase 4 tests failed"
fi

# Condition 2: Debug-only scope
if [ "$(should_run_phase "$WORKFLOW_DESCRIPTION" "debugging")" = "true" ]; then
  SHOULD_RUN="true"
  echo "Debugging triggered: Workflow scope is debug-only"
fi

# Skip if neither condition met
if [ "$SHOULD_RUN" = "false" ]; then
  echo "DEBUGGING_SKIPPED: No test failures and scope doesn't require debugging"
  exit 0
fi
\`\`\`

{Continue with debugging phase execution...}
```

#### Pattern 3: Pre-Workflow Scope Announcement

```markdown
## Workflow Initialization

**EXECUTE NOW**: USE the Bash tool to detect and announce workflow scope:

\`\`\`bash
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

WORKFLOW_DESCRIPTION="<user input>"
SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Workflow Scope Detected: $SCOPE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$SCOPE" in
  "research-only")
    echo "Phases to execute: 0 (Location Detection), 1 (Research)"
    echo "Phases to skip: 2-7 (Planning, Implementation, Testing, Debugging, Documentation, Summary)"
    ;;
  "research-and-plan")
    echo "Phases to execute: 0-2 (Location Detection, Research, Planning)"
    echo "Phases to skip: 3-7 (Implementation, Testing, Debugging, Documentation, Summary)"
    ;;
  "full-implementation")
    echo "Phases to execute: 0-4, 6 (All except Debugging)"
    echo "Phases to skip: 5 (Debugging) unless Phase 4 tests fail"
    ;;
  "debug-only")
    echo "Phases to execute: 0-1, 5 (Location Detection, Research, Debugging)"
    echo "Phases to skip: 2-4, 6-7 (Planning, Implementation, Testing, Documentation, Summary)"
    ;;
esac

echo ""
echo "SCOPE_DETECTED: $SCOPE"
\`\`\`

{Continue with Phase 0...}
```

## Phase Execution Matrix

| Phase | research-only | research-and-plan | full-implementation | debug-only |
|-------|---------------|-------------------|---------------------|------------|
| **0: Location Detection** | ✓ | ✓ | ✓ | ✓ |
| **1: Research** | ✓ | ✓ | ✓ | ✓ |
| **2: Planning** | ✗ | ✓ | ✓ | ✗ |
| **3: Implementation** | ✗ | ✗ | ✓ | ✗ |
| **4: Testing** | ✗ | ✗ | ✓ | ✗ |
| **5: Debugging** | ✗ | ✗ | ✓ (if tests fail) | ✓ |
| **6: Documentation** | ✗ | ✗ | ✓ | ✗ |
| **7: Summary** | ✗ | ✗ | ✓ | ✗ |

**Legend**: ✓ = Execute, ✗ = Skip

## Benefits

### 1. Context Budget Savings

**Example: Research-Only Workflow**

Without scope detection:
```
Phase 0: 500 tokens
Phase 1: 900 tokens (3 research reports)
Phase 2: 800 tokens (unnecessary plan)
Phase 3: 2,000 tokens (unnecessary implementation)
Phase 4: 400 tokens (unnecessary testing)
Phase 6: 300 tokens (unnecessary documentation)
───────────────────────────────────────────────────
Total: 4,900 tokens (19.6% of budget)
```

With scope detection:
```
Phase 0: 500 tokens
Phase 1: 900 tokens (3 research reports)
───────────────────────────────────────────────────
Total: 1,400 tokens (5.6% of budget)
Savings: 3,500 tokens (71% reduction)
```

### 2. Clear User Experience

**User Request**: "research OAuth 2.0 patterns"

Without scope detection:
```
✓ Research reports created
✓ Implementation plan created (UNEXPECTED)
✗ Code changes made (UNEXPECTED)
✗ Tests run (UNEXPECTED)

User confusion: "I only wanted research, why did it create code?"
```

With scope detection:
```
✓ Research reports created
✗ Implementation plan skipped (scope: research-only)
✗ Code changes skipped
✗ Tests skipped

User satisfaction: "Perfect, exactly what I asked for"
```

### 3. Reduced Execution Time

| Workflow Type | Phases Executed | Estimated Time (Sequential) | Time Savings |
|---------------|-----------------|----------------------------|--------------|
| **research-only** | 2 phases | 5-10 minutes | 75% faster than full workflow |
| **research-and-plan** | 3 phases | 10-15 minutes | 60% faster than full workflow |
| **full-implementation** | 6 phases | 25-40 minutes | Baseline |
| **debug-only** | 3 phases | 10-20 minutes | 50% faster than full workflow |

## Real-World Examples

### Example 1: Research-Only Workflow

**User Request**: "/coordinate research API authentication best practices"

**Scope Detection**:
```bash
SCOPE=$(detect_workflow_scope "research API authentication best practices")
echo "$SCOPE"  # Output: research-only
```

**Execution**:
```
✓ Phase 0: Location Detection (create specs/082_api_auth_research/)
✓ Phase 1: Research (3 parallel research agents)
✗ Phase 2: Planning (skipped - research-only scope)
✗ Phase 3-7: All skipped

Artifacts created:
- specs/082_api_auth_research/reports/001_oauth_patterns.md
- specs/082_api_auth_research/reports/002_jwt_strategies.md
- specs/082_api_auth_research/reports/003_security_considerations.md

Context usage: 1,400 tokens (5.6%)
Execution time: 8 minutes
```

### Example 2: Research-and-Plan Workflow

**User Request**: "/orchestrate research and plan user authentication system"

**Scope Detection**:
```bash
SCOPE=$(detect_workflow_scope "research and plan user authentication system")
echo "$SCOPE"  # Output: research-and-plan
```

**Execution**:
```
✓ Phase 0: Location Detection
✓ Phase 1: Research (2 research agents)
✓ Phase 2: Planning (plan-architect creates implementation plan)
✗ Phase 3: Implementation (skipped - research-and-plan scope)
✗ Phase 4-7: All skipped

Artifacts created:
- specs/083_auth_system/reports/001_auth_patterns.md
- specs/083_auth_system/reports/002_user_management.md
- specs/083_auth_system/plans/001_auth_implementation_plan.md

Context usage: 2,200 tokens (8.8%)
Execution time: 15 minutes
```

### Example 3: Full-Implementation Workflow

**User Request**: "/supervise implement JWT authentication for API endpoints"

**Scope Detection**:
```bash
SCOPE=$(detect_workflow_scope "implement JWT authentication for API endpoints")
echo "$SCOPE"  # Output: full-implementation
```

**Execution**:
```
✓ Phase 0: Location Detection
✓ Phase 1: Research (1 research agent - focused investigation)
✓ Phase 2: Planning (implementation plan with 5 phases)
✓ Phase 3: Implementation (wave-based execution)
✓ Phase 4: Testing (tests passed)
✗ Phase 5: Debugging (skipped - tests passed)
✓ Phase 6: Documentation (implementation summary)

Artifacts created:
- specs/084_jwt_auth/reports/001_jwt_implementation_guide.md
- specs/084_jwt_auth/plans/001_jwt_implementation_plan.md
- specs/084_jwt_auth/summaries/001_jwt_implementation_summary.md
- Code changes in src/auth/ (implementation artifacts)

Context usage: 4,500 tokens (18%)
Execution time: 35 minutes
```

### Example 4: Debug-Only Workflow

**User Request**: "/coordinate debug failing authentication tests in auth.test.js"

**Scope Detection**:
```bash
SCOPE=$(detect_workflow_scope "debug failing authentication tests in auth.test.js")
echo "$SCOPE"  # Output: debug-only
```

**Execution**:
```
✓ Phase 0: Location Detection
✓ Phase 1: Research (1 research agent - investigates test failures)
✗ Phase 2: Planning (skipped - debug-only scope)
✗ Phase 3: Implementation (skipped)
✗ Phase 4: Testing (skipped)
✓ Phase 5: Debugging (2 parallel debug analysts)
✗ Phase 6-7: All skipped

Artifacts created:
- specs/085_auth_test_debug/reports/001_test_failure_analysis.md
- specs/085_auth_test_debug/debug/001_token_expiry_investigation.md
- specs/085_auth_test_debug/debug/002_mock_data_issues.md

Context usage: 1,800 tokens (7.2%)
Execution time: 12 minutes
```

## Edge Cases and Fallbacks

### Edge Case 1: Ambiguous Workflow Description

**User Request**: "OAuth authentication"

**Analysis**: No clear action verb (research? implement? debug?)

**Fallback**: Default to `research-only` (safest assumption)
```bash
SCOPE=$(detect_workflow_scope "OAuth authentication")
echo "$SCOPE"  # Output: research-only
```

**Rationale**: Better to under-execute (research only) than over-execute (unwanted implementation)

### Edge Case 2: Multiple Scope Indicators

**User Request**: "research and implement JWT authentication"

**Analysis**: Contains both "research" and "implement"

**Priority**: "implement" takes precedence (higher action commitment)
```bash
SCOPE=$(detect_workflow_scope "research and implement JWT authentication")
echo "$SCOPE"  # Output: full-implementation
```

**Rationale**: If user explicitly requests implementation, research is implicit prerequisite

### Edge Case 3: Negation Keywords

**User Request**: "research authentication patterns but don't implement"

**Analysis**: Contains "implement" but also negation "don't"

**Handling**: Keyword detection checks for negation patterns ("don't", "not", "without")
```bash
# Pseudo-code
if workflow contains "implement" AND NOT contains negation:
  scope = "full-implementation"
else:
  scope = "research-only"
```

## Testing and Validation

### Unit Tests (workflow-detection.sh)

```bash
# Test research-only detection
result=$(detect_workflow_scope "research OAuth 2.0 patterns")
assert_equals "$result" "research-only"

# Test research-and-plan detection
result=$(detect_workflow_scope "research and plan authentication system")
assert_equals "$result" "research-and-plan"

# Test full-implementation detection
result=$(detect_workflow_scope "implement JWT authentication")
assert_equals "$result" "full-implementation"

# Test debug-only detection
result=$(detect_workflow_scope "debug failing tests in auth.test.js")
assert_equals "$result" "debug-only"

# Test ambiguous fallback
result=$(detect_workflow_scope "OAuth authentication")
assert_equals "$result" "research-only"
```

### Integration Tests (Orchestration Commands)

```bash
# Test phase skipping for research-only workflow
output=$(/coordinate "research API patterns")
assert_contains "$output" "TESTING_SKIPPED"
assert_contains "$output" "IMPLEMENTATION_SKIPPED"

# Test phase execution for full-implementation workflow
output=$(/coordinate "implement feature X")
assert_contains "$output" "IMPLEMENTATION_EXECUTING"
assert_contains "$output" "TESTING_EXECUTING"
```

## Cross-References

### Related Patterns
- [Parallel Execution Pattern](parallel-execution.md) - Wave-based implementation for full-implementation scope
- [Metadata Extraction Pattern](metadata-extraction.md) - Context reduction for research-only workflows
- [Context Management Pattern](context-management.md) - Budget allocation per scope type

### Related Guides
- [Orchestration Best Practices Guide](../../guides/orchestration/orchestration-best-practices.md) - Complete 7-phase framework with scope detection
- [Orchestration Troubleshooting Guide](../../guides/orchestration/orchestration-troubleshooting.md) - Debugging scope detection issues

### Related Workflows
- [Context Budget Management Tutorial](../../workflows/context-budget-management.md) - Budget allocation strategies per scope

### Related Reference
- [Library API Reference](../../reference/library-api/overview.md) - workflow-detection.sh function signatures
- [Orchestration Reference](../../reference/workflows/orchestration-reference.md) - Command comparison by scope handling

## Changelog

### 2025-10-28: Initial Creation
- Documented four scope types (research-only, research-and-plan, full-implementation, debug-only)
- Phase execution matrix defined
- Real-world examples for all scope types
- Edge case handling documented
- Context budget savings quantified
