# Expand/Collapse Auto-Analysis Implementation Plan

## Metadata
- **Date**: 2025-10-09
- **Feature**: Auto-analysis mode for /expand and /collapse commands
- **Plan Number**: 036
- **Structure Level**: 0
- **Scope**: Refactor /expand and /collapse commands to support automatic complexity-based analysis when no phase/stage arguments provided
- **Estimated Phases**: 7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Context**: Existing AWK-based parsing handles code blocks correctly, plan structure progressive (Level 0→1→2)
- **Agent Integration**: Follows /home/benjamin/.config/.claude/docs/agent-integration-guide.md

## Revision History

### 2025-10-09 - Revision 1
**Changes**: Replaced shell-script complexity analysis (complexity-utils.sh) with dedicated complexity_estimator subagent
**Reason**: Complexity estimation is context-dependent and cannot be reduced to magic numbers/keywords. Requires human-like understanding of broader master plan context and phase relationships.
**Modified Phases**: Phase 1 (new agent creation instead of shell utilities), Phase 3 (agent invocation), Phase 5 (agent invocation)
**Agent Integration**: All agent invocations use general-purpose agent type with behavioral injection following agent-integration-guide.md

## Overview

Refactor the `/expand` and `/collapse` commands to support two modes of operation:

1. **Explicit Mode (Current)**: User specifies `[phase|stage] <path> <number>` to expand/collapse specific element
2. **Auto-Analysis Mode (New)**: User omits phase/stage arguments, system invokes **complexity_estimator subagent** to analyze entire plan in context, intelligently expands/collapses all elements based on LLM-powered complexity assessment

This enhancement preserves backward compatibility while enabling intelligent batch operations that align with the progressive planning philosophy: expand complex work, collapse simple work.

## Success Criteria

- [ ] `/expand <path>` invokes complexity_estimator agent to analyze all phases/stages and expands those deemed sufficiently complex
- [ ] `/collapse <path>` invokes complexity_estimator agent to analyze all expanded phases/stages and collapses those deemed sufficiently simple
- [ ] Explicit mode `/expand phase <path> <number>` continues to work unchanged
- [ ] Explicit mode `/collapse stage <path> <number>` continues to work unchanged
- [ ] Agent receives parent plan context for contextual analysis
- [ ] Summary report shows which phases/stages were analyzed and actions taken with reasoning
- [ ] All existing tests pass
- [ ] New tests cover both auto-analysis and explicit modes
- [ ] Edge cases handled: no phases meet threshold, all already expanded, mixed states
- [ ] Agent integration follows agent-integration-guide.md patterns

## Technical Design

### Argument Parsing Strategy

**Current Pattern**:
```bash
TYPE="$1"  # "phase" or "stage" (required)
PATH="$2"  # path to plan/phase (required)
NUM="$3"   # number (required)
```

**New Pattern**:
```bash
# Auto-analysis mode
/expand <path>
/collapse <path>

# Explicit mode (backward compatible)
/expand [phase|stage] <path> <number>
/collapse [phase|stage] <path> <number>
```

**Detection Logic**:
```bash
if [[ $# -eq 1 ]]; then
  # Auto-analysis mode: only path provided
  MODE="auto"
  PATH="$1"
elif [[ $# -eq 3 ]]; then
  # Explicit mode: [phase|stage] <path> <number>
  MODE="explicit"
  TYPE="$1"
  PATH="$2"
  NUM="$3"
else
  echo "ERROR: Invalid arguments"
  echo "Usage: /expand <path>  OR  /expand [phase|stage] <path> <number>"
  exit 1
fi
```

### Auto-Analysis Algorithm with complexity_estimator Agent

**For /expand (auto-analysis)**:
1. Detect plan structure level (0, 1, or 2)
2. If Level 0 or 1: Analyze all inline phases
   - Extract phase content using `parse-adaptive-plan.sh`
   - **Invoke complexity_estimator agent** with:
     - All phase contents
     - Parent plan context (overview, goals, constraints)
     - Current structure level
     - Task to: "For each phase, estimate complexity and recommend expand/skip"
   - Parse agent's JSON response with decisions per phase
   - Expand phases where agent recommends expansion
3. If Level 1 or 2: Analyze all inline stages within phases
   - For each phase file, extract inline stages
   - **Invoke complexity_estimator agent** with:
     - All stage contents from the phase
     - Parent phase context (phase goals, overview)
     - Master plan context (high-level goals)
   - Expand stages where agent recommends expansion
4. Generate summary report of actions taken with agent reasoning

**For /collapse (auto-analysis)**:
1. Detect plan structure level
2. If Level 1 or 2: Analyze all expanded phases
   - Read each expanded phase file
   - **Invoke complexity_estimator agent** with:
     - All expanded phase contents
     - Parent plan context
     - Task to: "For each phase, estimate current complexity and recommend collapse/keep"
   - Collapse phases where agent recommends collapse
   - Skip phases with expanded stages (must collapse stages first)
3. If Level 2: Analyze all expanded stages
   - Read each stage file
   - **Invoke complexity_estimator agent** with stage and parent context
   - Collapse stages where agent recommends collapse
4. Generate summary report with agent reasoning

### complexity_estimator Agent Design

**Agent Specification** (`.claude/agents/complexity_estimator.md`):

```yaml
---
allowed-tools: Read, Grep, Glob
description: Estimates plan/phase/stage complexity considering broader context to recommend expansion/collapse decisions
---
```

**Agent Responsibilities**:
- Analyze phase/stage content in context of parent plan
- Consider factors beyond task counts and keywords:
  - Architectural significance
  - Cross-cutting concerns
  - Dependencies and integration complexity
  - Risk level and criticality
  - Implementation uncertainty
  - Testing complexity
- Provide JSON-structured recommendations with reasoning
- No modification operations (read-only analysis)

**Agent Invocation Pattern** (following agent-integration-guide.md):

```bash
# Invoke via general-purpose agent type with behavioral injection
claude_code_task \
  --subagent-type "general-purpose" \
  --description "Estimate complexity using complexity_estimator protocol" \
  --prompt "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/complexity_estimator.md

    You are acting as a Complexity Estimator with constraints:
    - Read-only operations (tools: Read, Grep, Glob only)
    - Context-aware analysis (not just keyword matching)
    - JSON output with structured recommendations

    Analysis Task: [Expansion or Collapse Analysis]

    Parent Plan Context:
    [Plan overview, goals, constraints from master plan]

    Content to Analyze:
    [All phases/stages with their content]

    For each item, provide:
    - item_id: phase/stage number
    - complexity_level: 1-10 scale
    - reasoning: context-aware explanation (not just task count)
    - recommendation: expand/skip or collapse/keep
    - confidence: low/medium/high

    Output Format: JSON array
  "
```

**Example Agent Output**:
```json
[
  {
    "item_id": "phase_1",
    "item_name": "Setup",
    "complexity_level": 3,
    "reasoning": "Standard setup tasks with well-established patterns, minimal architectural decisions, straightforward dependencies",
    "recommendation": "skip",
    "confidence": "high"
  },
  {
    "item_id": "phase_2",
    "item_name": "Core Architecture Refactor",
    "complexity_level": 9,
    "reasoning": "Critical architectural changes affecting multiple modules, requires careful consideration of state management patterns, high integration complexity with existing auth system, significant testing requirements",
    "recommendation": "expand",
    "confidence": "high"
  }
]
```

### Decision Reporting

Each command will output a structured report based on agent analysis:

```
Auto-Analysis Mode: Expanding Phases
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan: 025_feature.md
Structure Level: 0 → 1

Complexity Estimator Analysis:

  Phase 1: Setup (complexity: 3/10)
    Reasoning: Standard setup tasks with well-established patterns
    Action: SKIP (below expansion threshold)

  Phase 2: Core Architecture Refactor (complexity: 9/10)
    Reasoning: Critical architectural changes, high integration complexity,
               affects multiple modules, requires state management decisions
    Action: EXPAND
    → Created: phase_2_core_architecture_refactor.md

  Phase 3: Testing (complexity: 5/10)
    Reasoning: Standard test implementation, established patterns available
    Action: SKIP (moderate complexity, can remain inline)

  Phase 4: Multi-Module Integration (complexity: 8/10)
    Reasoning: Cross-cutting concerns across 5 modules, dependency orchestration,
               potential for cascading failures, needs detailed specification
    Action: EXPAND
    → Created: phase_4_multi_module_integration.md

Summary:
  Total Phases: 4
  Expanded: 2 (Phase 2, 4)
  Skipped: 2 (Phase 1, 3)
  New Structure Level: 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Backward Compatibility

Explicit mode is preserved by detecting argument count:
- 3 arguments → Explicit mode (current behavior)
- 1 argument → Auto-analysis mode (new behavior with agent)

No changes to existing utility functions in `parse-adaptive-plan.sh` are required—only integration and orchestration logic in the command files.

## Risk Assessment

### Low Risk
- Parsing utilities handle code blocks correctly (no false matches)
- Metadata management is well-established
- Agent integration pattern proven in /orchestrate and /expand-phase

### Medium Risk
- Agent invocation latency (~30-60 seconds for full plan analysis)
  - Mitigation: Show progress indicators during agent analysis
- Agent cost (API tokens for LLM complexity estimation)
  - Mitigation: Batch phases into single agent call (not one call per phase)
- Mixed expansion states (some phases expanded, some not)
  - Mitigation: Clear logic to detect and handle each state
- User confusion about when to use auto vs explicit mode
  - Mitigation: Clear error messages and usage examples

### Edge Cases to Handle

1. **Empty Plan**: No phases exist
   - Action: Report "No phases found, nothing to do"

2. **All Phases Already Expanded**: /expand in auto-mode on Level 1 plan
   - Action: Analyze inline stages, or report "All phases already expanded"

3. **Agent Recommends Nothing**: No phases meet expansion criteria
   - Action: Report "Complexity estimator recommends no expansions"

4. **Mixed Expansion State**: Some phases expanded, some inline
   - Action: Analyze only inline phases for expansion

5. **Phase with Stages Cannot Collapse**: Level 2 structure
   - Action: Skip phase, report "Phase 3 has expanded stages, collapse stages first"

6. **Agent Timeout**: Analysis takes too long
   - Action: Retry with reduced context or escalate to user

7. **Agent Invalid Output**: Malformed JSON
   - Action: Log error, fall back to conservative behavior (no changes)

## Implementation Phases

### Phase 1: Create complexity_estimator Agent
**Objective**: Build specialized agent for context-aware complexity estimation
**Complexity**: Medium

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/agents/complexity_estimator.md`
- [ ] Define agent frontmatter with allowed-tools: `Read, Grep, Glob`
- [ ] Document agent purpose: Context-aware complexity estimation for expansion/collapse decisions
- [ ] Define behavioral guidelines:
  - Analyze content in context of parent plan/phase
  - Consider architectural significance, not just task counts
  - Assess dependencies, integration complexity, risk, testing needs
  - Provide structured JSON recommendations
  - No modification operations (read-only)
- [ ] Document input format:
  - Parent plan context (overview, goals, constraints)
  - Content to analyze (phases or stages)
  - Analysis mode (expansion or collapse)
- [ ] Document output format:
  - JSON array with per-item analysis
  - Fields: item_id, item_name, complexity_level (1-10), reasoning, recommendation, confidence
- [ ] Add example usage section showing invocation pattern
- [ ] Follow agent-integration-guide.md patterns

Testing:
```bash
# Test agent invocation pattern
# (Manual validation - no automated test yet)
# Verify agent file has valid frontmatter
# Verify description field present
# Verify allowed-tools correct
```

Validation:
- [ ] Agent file follows agent-integration-guide.md format
- [ ] Frontmatter is valid YAML
- [ ] Allowed-tools list includes only: Read, Grep, Glob
- [ ] Behavioral guidelines are clear and comprehensive
- [ ] Example usage demonstrates general-purpose agent invocation

### Phase 2: Create Auto-Analysis Orchestration Functions
**Objective**: Build shell functions to orchestrate complexity_estimator agent invocations
**Complexity**: High

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/lib/auto-analysis-utils.sh`
- [ ] Implement `invoke_complexity_estimator <mode> <content_json> <context_json>` function
  - Mode: "expansion" or "collapse"
  - Content JSON: array of {id, name, content} for items to analyze
  - Context JSON: {parent_plan_overview, parent_plan_goals, current_level}
  - Uses `general-purpose` agent type with behavioral injection
  - Constructs prompt following agent-integration-guide.md pattern
  - Returns agent's JSON response
  - Handles errors: timeout, invalid JSON, agent unavailable
- [ ] Implement `analyze_phases_for_expansion <plan_path>` function
  - Extracts all inline phases using `parse-adaptive-plan.sh`
  - Builds content JSON for agent
  - Reads plan overview/goals for context JSON
  - Invokes complexity_estimator agent
  - Parses response and returns array of phases to expand
- [ ] Implement `analyze_stages_for_expansion <plan_path> <phase_num>` function
  - Similar to phases but for stages within a phase file
  - Includes phase context + master plan context
- [ ] Implement `analyze_phases_for_collapse <plan_path>` function
  - Reads expanded phase files
  - Builds content JSON with phase file contents
  - Invokes agent for collapse analysis
  - Returns array of phases to collapse
- [ ] Implement `analyze_stages_for_collapse <plan_path> <phase_num>` function
  - Reads expanded stage files
  - Invokes agent with stage + phase + plan context
  - Returns array of stages to collapse
- [ ] Implement `generate_analysis_report <mode> <decisions_json>` function
  - Formats agent decisions into human-readable report
  - Includes complexity scores, reasoning, actions taken
  - Mode: "expand" or "collapse"
- [ ] Add error handling for all functions:
  - Agent timeout: retry once with reduced context
  - Invalid JSON: log error, return empty array (safe default)
  - Agent unavailable: report error to user
  - Empty content: return empty array

Testing:
```bash
# Create test script
cd /home/benjamin/.config/.claude/tests
# Test will invoke functions with mock plan content
./test_auto_analysis_orchestration.sh
```

Validation:
- [ ] Functions correctly construct agent prompts following guide
- [ ] Agent invocation uses general-purpose type with behavioral injection
- [ ] JSON parsing handles agent responses correctly
- [ ] Error handling covers timeout, invalid output, agent errors
- [ ] Context is properly extracted from parent plans
- [ ] Edge cases handled: no phases, empty content, malformed plans

### Phase 3: Update /expand Command Argument Parsing
**Objective**: Add argument detection logic to support both explicit and auto-analysis modes
**Complexity**: Low

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/commands/expand.md`
- [ ] Add argument count detection at start of Implementation section
  ```bash
  # Detect mode based on argument count
  if [[ $# -eq 1 ]]; then
    MODE="auto"
    PLAN_PATH="$1"
  elif [[ $# -eq 3 ]]; then
    MODE="explicit"
    TYPE="$1"
    PATH="$2"
    NUM="$3"
  else
    echo "ERROR: Invalid arguments"
    echo "Usage: /expand <path>  OR  /expand [phase|stage] <path> <number>"
    exit 1
  fi
  ```
- [ ] Keep existing explicit mode logic intact
- [ ] Update command-level documentation to explain both modes
- [ ] Update Examples section with auto-analysis examples
- [ ] Add note about agent invocation and expected latency

Testing:
```bash
# Test argument parsing
/expand /path/to/plan.md  # Should detect auto mode
/expand phase /path/to/plan.md 2  # Should detect explicit mode
/expand invalid  # Should show error
```

Validation:
- [ ] Explicit mode commands continue to work unchanged
- [ ] Invalid argument counts produce clear error messages
- [ ] PLAN_PATH vs PATH variable naming is consistent
- [ ] Documentation clearly explains both modes and when to use each

### Phase 4: Implement /expand Auto-Analysis Mode
**Objective**: Add auto-analysis orchestration logic to /expand command using complexity_estimator agent
**Complexity**: High

Tasks:
- [ ] Source auto-analysis utilities in expand.md
  ```bash
  source "$CLAUDE_PROJECT_DIR/.claude/lib/auto-analysis-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
  ```
- [ ] Add auto-mode orchestration after argument parsing
  ```bash
  if [[ "$MODE" == "auto" ]]; then
    # Auto-analysis mode with agent
  elif [[ "$MODE" == "explicit" ]]; then
    # Existing explicit mode (unchanged)
  fi
  ```
- [ ] Implement auto-expand for phases:
  - Detect structure level
  - Show progress: "Analyzing plan complexity with AI estimator..."
  - Call `analyze_phases_for_expansion "$PLAN_PATH"`
  - Parse agent's recommendations
  - For each phase recommended for expansion:
    - Call existing phase expansion logic (reuse from explicit mode)
    - Track actions for report
  - Generate summary report with agent reasoning
- [ ] Implement auto-expand for stages (if applicable):
  - If Level 1, check for inline stages in expanded phases
  - Call `analyze_stages_for_expansion` for each phase
  - Expand stages recommended by agent
- [ ] Add summary report generation using `generate_analysis_report`
- [ ] Handle edge cases:
  - No phases recommended → informative message
  - All phases already expanded → check for stages
  - Empty plan → "No phases found"
  - Agent error → report to user, no changes made
- [ ] Add progress indicators during agent analysis (can take 30-60 seconds)

Testing:
```bash
# Test with various plan structures
cd /home/benjamin/.config/.claude/tests
./test_expand_auto_mode.sh
```

Validation:
- [ ] Agent is invoked correctly with proper context
- [ ] Agent recommendations are parsed and applied
- [ ] Phases recommended for expansion are expanded
- [ ] Phases not recommended are skipped
- [ ] Metadata updated correctly (Structure Level, Expanded Phases)
- [ ] Summary report includes agent reasoning
- [ ] Progress indicators keep user informed during analysis
- [ ] No false positives in code blocks (AWK parsing works correctly)

### Phase 5: Update /collapse Command Argument Parsing
**Objective**: Add argument detection logic to /collapse command (same pattern as /expand)
**Complexity**: Low

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/commands/collapse.md`
- [ ] Add identical argument count detection as in /expand
  ```bash
  if [[ $# -eq 1 ]]; then
    MODE="auto"
    PLAN_PATH="$1"
  elif [[ $# -eq 3 ]]; then
    MODE="explicit"
    TYPE="$1"
    PATH="$2"
    NUM="$3"
  else
    echo "ERROR: Invalid arguments"
    echo "Usage: /collapse <path>  OR  /collapse [phase|stage] <path> <number>"
    exit 1
  fi
  ```
- [ ] Keep existing explicit mode logic intact
- [ ] Update command documentation to explain both modes
- [ ] Update Examples section with auto-analysis examples
- [ ] Add note about agent invocation and latency

Testing:
```bash
# Test argument parsing
/collapse /path/to/plan/  # Should detect auto mode
/collapse stage /path/to/phase/ 1  # Should detect explicit mode
```

Validation:
- [ ] Explicit mode continues working unchanged
- [ ] Error messages are clear and helpful
- [ ] Documentation matches /expand format for consistency

### Phase 6: Implement /collapse Auto-Analysis Mode
**Objective**: Add auto-analysis orchestration logic to /collapse command using complexity_estimator agent
**Complexity**: High

Tasks:
- [ ] Source auto-analysis utilities in collapse.md
  ```bash
  source "$CLAUDE_PROJECT_DIR/.claude/lib/auto-analysis-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
  ```
- [ ] Add auto-mode orchestration after argument parsing
- [ ] Implement auto-collapse for stages first (Level 2 → 1):
  - Show progress: "Analyzing expanded content complexity..."
  - Call `analyze_stages_for_collapse` for each phase
  - For stages recommended for collapse:
    - Call existing stage collapse logic
    - Track actions for report
- [ ] Implement auto-collapse for phases (Level 1 → 0):
  - Call `analyze_phases_for_collapse "$PLAN_PATH"`
  - For phases recommended for collapse:
    - Check if phase has expanded stages (skip if true)
    - Call existing phase collapse logic
    - Track actions for report
- [ ] Add summary report generation with agent reasoning
- [ ] Handle edge cases:
  - Phase has expanded stages → skip with message
  - No phases recommended for collapse → "All phases remain expanded"
  - All phases already inline → "Nothing to collapse"
  - Agent error → report to user, no changes made
- [ ] Add progress indicators during agent analysis

Testing:
```bash
# Test with various expanded structures
cd /home/benjamin/.config/.claude/tests
./test_collapse_auto_mode.sh
```

Validation:
- [ ] Agent invoked correctly with collapse context
- [ ] Stages recommended for collapse are collapsed
- [ ] Phases recommended for collapse are collapsed (if no expanded stages)
- [ ] Phases not recommended remain expanded
- [ ] Metadata updated correctly
- [ ] Structure levels decrease correctly (2→1→0)
- [ ] Directory cleanup happens when last item collapsed
- [ ] Agent reasoning displayed in summary report

### Phase 7: Comprehensive Testing and Documentation
**Objective**: Ensure both modes work correctly in all scenarios and update documentation
**Complexity**: Medium

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/tests/test_auto_analysis_orchestration.sh`
  - Test `invoke_complexity_estimator` with mock responses
  - Test `analyze_phases_for_expansion` with various plans
  - Test `analyze_phases_for_collapse` with Level 1 plans
  - Test error handling: timeout, invalid JSON, agent errors
- [ ] Create `/home/benjamin/.config/.claude/tests/test_expand_auto_mode.sh`
  - Test auto-expand on Level 0 plan (inline phases)
  - Test auto-expand on Level 1 plan (inline stages)
  - Test mixed expansion states
  - Test "nothing to expand" scenarios
  - Verify metadata updates
  - Verify agent recommendations are followed
- [ ] Create `/home/benjamin/.config/.claude/tests/test_collapse_auto_mode.sh`
  - Test auto-collapse on Level 1 plan (phases)
  - Test auto-collapse on Level 2 plan (stages then phases)
  - Test "nothing to collapse" scenarios
  - Verify directory cleanup
  - Verify agent recommendations are followed
- [ ] Update `/home/benjamin/.config/.claude/tests/test_progressive_expansion.sh`
  - Add test cases for auto-analysis mode
  - Ensure explicit mode tests still pass
- [ ] Update `/home/benjamin/.config/.claude/tests/test_progressive_collapse.sh`
  - Add test cases for auto-analysis mode
  - Ensure explicit mode tests still pass
- [ ] Run full test suite:
  ```bash
  cd /home/benjamin/.config/.claude/tests
  ./run_all_tests.sh
  ```
- [ ] Update command documentation in CLAUDE.md
  - Add auto-analysis mode to Specifications Directory section
  - Update Plan Structure Levels documentation
  - Add usage examples for both modes
  - Document complexity_estimator agent
- [ ] Update agent-integration-guide.md
  - Add complexity_estimator to Agent Directory section
  - Document invocation patterns for /expand and /collapse
- [ ] Update README if applicable
- [ ] Document expected latency (30-60 seconds for agent analysis)
- [ ] Document agent cost considerations

Testing:
```bash
# Full regression test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Expected: All tests pass, coverage >80%
```

Validation:
- [ ] All new tests pass
- [ ] All existing tests still pass (backward compatibility)
- [ ] Test coverage >80% for modified code
- [ ] Documentation is clear and includes examples
- [ ] Edge cases are documented and handled
- [ ] Error messages are helpful
- [ ] Agent integration documented in guide
- [ ] Performance characteristics documented (latency, costs)

## Testing Strategy

### Unit Tests
- Test agent invocation functions in isolation
- Mock agent responses for deterministic testing
- Test JSON parsing and error handling
- Test context extraction from plans

### Integration Tests
- Test full /expand workflow: argument parsing → agent analysis → expansion → report
- Test full /collapse workflow: argument parsing → agent analysis → collapse → report
- Test interaction between commands (expand then collapse)
- Test agent with real plans (small test cases)

### Regression Tests
- Ensure explicit mode continues to work unchanged
- Run existing test suite to verify no breakage
- Test all three structure levels (0, 1, 2)

### Edge Case Tests
- Empty plans
- Plans with no phases meeting agent's criteria
- All phases already expanded/collapsed
- Mixed expansion states
- Plans with code blocks containing "### Phase" (false positives)
- Agent timeout scenarios
- Agent invalid JSON responses
- Agent unavailable errors

### Agent Behavior Tests
- Verify agent considers context not just task counts
- Verify agent reasoning is clear and actionable
- Verify agent recommendations are consistent
- Test with diverse plan types (feature, refactor, debug)

### Manual Testing Scenarios
1. Create test plan with 4 phases: 2 simple, 2 architecturally complex
2. Run `/expand <plan>` → verify agent expands complex phases, skips simple
3. Check agent reasoning in report → should mention architecture, not just task count
4. Run `/collapse <plan>` → verify simple phases collapsed
5. Run explicit `/expand phase <plan> 1` → verify single phase expanded (explicit mode)

## Dependencies

### Internal Dependencies
- `/home/benjamin/.config/.claude/lib/parse-adaptive-plan.sh`: Phase/stage extraction and metadata management
- `/home/benjamin/.config/.claude/commands/expand.md`: Current expansion logic to preserve
- `/home/benjamin/.config/.claude/commands/collapse.md`: Current collapse logic to preserve
- `/home/benjamin/.config/.claude/agents/complexity_estimator.md`: New agent specification (created in Phase 1)

### External Dependencies
- `bash 4.0+`: For associative arrays and advanced string manipulation
- `awk`: For markdown parsing (already used in parse-adaptive-plan.sh)
- `jq`: For JSON parsing of agent responses (required, not optional)
- `grep`, `sed`, `find`: Standard Unix utilities (already required)
- **Claude Code agent system**: For invoking complexity_estimator via Task tool

### Removed Dependencies
- `complexity-utils.sh`: No longer used (replaced by agent)

## Documentation Requirements

### Command Documentation Updates
- `/home/benjamin/.config/.claude/commands/expand.md`
  - Update Syntax section with both modes
  - Add Auto-Analysis Mode section
  - Update Examples with auto-analysis usage
  - Document agent latency expectations
- `/home/benjamin/.config/.claude/commands/collapse.md`
  - Same updates as expand.md

### Agent Documentation
- `/home/benjamin/.config/.claude/agents/complexity_estimator.md`
  - Complete agent specification
  - Behavioral guidelines
  - Input/output formats
  - Example usage

### CLAUDE.md Updates
- Update Progressive Plan Structure section
- Document auto-analysis mode with agent-based analysis
- Add examples of when to use auto vs explicit mode
- Update command reference
- Document expected latency and costs

### Agent Integration Guide Updates
- Add complexity_estimator to Agent Directory
- Document invocation patterns for /expand and /collapse
- Add to Command-Agent Matrix

### Test Documentation
- Document test scenarios in test file headers
- Add comments explaining edge case handling
- Document how to test agent behavior

### Inline Documentation
- Add detailed comments in auto-analysis-utils.sh explaining algorithm
- Document JSON structure for agent input/output
- Explain agent invocation pattern

## Notes

### Progressive Organization Philosophy
This implementation aligns with the project's progressive planning philosophy:
- Expand complex work for detailed planning (agent determines complexity contextually)
- Collapse simple work to reduce noise (agent considers simplicity in context)
- Structure grows organically based on actual complexity (not magic numbers)
- Agent provides human-like judgment on what warrants expansion

### Agent-Based Analysis Benefits
- **Context-aware**: Considers parent plan goals, dependencies, architectural significance
- **No magic numbers**: Complexity isn't reduced to keywords and task counts
- **Reasoning provided**: Agent explains why expansion/collapse recommended
- **Adaptive**: Agent can learn patterns and improve over time
- **Consistent**: Same analysis approach across all plans

### Agent Performance Considerations
- **Latency**: Agent analysis takes 30-60 seconds for typical plan (acceptable for batch operations)
- **Cost**: Each auto-analysis invokes LLM (consider batching multiple phases into one call)
- **Accuracy**: Agent provides more nuanced analysis than heuristics
- **Transparency**: Agent reasoning visible in reports

### Backward Compatibility Commitment
Explicit mode must remain unchanged to avoid breaking existing workflows and scripts that depend on current behavior. Auto-analysis is strictly additive.

### Future Enhancements (Out of Scope)
- Cascading analysis: After expanding phase, auto-analyze stages
- Interactive mode: Ask user before each expansion/collapse based on agent recommendation
- Customizable agent prompts: Allow user to guide agent's analysis
- Dry-run mode: Show what agent would recommend without making changes
- Batch operations: Expand all plans in a directory
- Agent learning: Track agent decisions and outcomes to improve prompts
