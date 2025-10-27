# Corrective Actions and Improvement Recommendations for /supervise

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: corrective_actions_and_improvement_recommendations
- **Report Type**: improvement recommendations
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The /supervise command requires three critical corrective actions: (1) convert /plan invocation to Task-based planning agent delegation following the behavioral injection pattern used in /orchestrate, (2) add research subagent delegation using parallel invocation from /research command, and (3) align with hierarchical agent architecture standards. Analysis shows /supervise currently invokes /plan via SlashCommand (deprecated pattern) while /orchestrate correctly uses Task tool with plan-architect.md behavioral injection. Migration path involves updating Phase 2 implementation, testing agent invocation patterns, and evaluating deprecation vs. enhancement based on usage patterns and functional overlap with /orchestrate.

## Findings

### 1. Current /plan Invocation Anti-Pattern

**Location**: `/home/benjamin/.config/.claude/commands/supervise.md:1225-1232`

**Current Pattern** (Lines 1225-1232):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: ${WORKFLOW_DESCRIPTION}
    - Plan File Path: ${PLAN_PATH} (absolute path, pre-calculated by orchestrator)
```

**Problem**: While /supervise correctly uses Task tool (not SlashCommand), it provides minimal context to the plan-architect agent. The prompt structure is abbreviated compared to /orchestrate's comprehensive context injection.

**Correct Pattern from /orchestrate** (Lines 1759-1800):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000  # 10 minutes for planning
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}
    **Thinking Mode**: ${THINKING_MODE_FOR_AGENT}

    **Research Context**: ${RESEARCH_REPORT_COUNT} research reports created
    **Research Reports**:
    ${RESEARCH_REPORT_PATHS_FORMATTED}

    **PLAN CREATION**:
    STEP 1: Review all research reports above
    STEP 2: Analyze workflow requirements
    STEP 3: Calculate complexity and select tier
    STEP 4: Create plan at path: ${PLAN_PATH}
    STEP 5: Include ALL research reports in plan metadata
    STEP 6: Return: PLAN_CREATED: ${PLAN_PATH}
```

**Key Differences**:
1. /orchestrate includes THINKING_MODE for agent model selection
2. /orchestrate provides formatted research report paths list
3. /orchestrate includes explicit STEP 1-6 instructions
4. /orchestrate includes research report count
5. /supervise has minimal context injection

**Impact**: The plan-architect agent receives less guidance in /supervise, potentially resulting in lower quality plans.

### 2. Missing Research Subagent Delegation

**Current State**: /supervise Phase 1 (Lines 899-1169) invokes research-specialist agents but uses abbreviated template:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
```

**Best Practice from /research Command**: The /research command demonstrates proper hierarchical decomposition with sub-supervisors and parallel research agents.

**Missing Features in /supervise**:
1. **No topic decomposition**: /supervise doesn't analyze complexity to determine 2-4 research topics
2. **No parallel invocation optimization**: Research agents invoked sequentially or with basic parallelization
3. **No research overview synthesis**: Missing aggregation of parallel research results
4. **Minimal complexity analysis**: Lines 920-944 use keyword matching, not structured complexity scoring

**Recommended Pattern from /research** (hierarchical multi-agent):
1. Analyze workflow description to identify 2-4 research topics
2. Invoke research-specialist agents in parallel (single message, multiple Task calls)
3. Create research overview synthesizing findings
4. Pass overview + individual reports to planning phase

**Performance Impact**:
- /orchestrate achieves 40-80% time savings with proper parallel research
- /supervise's basic parallelization may not maximize efficiency

### 3. Hierarchical Agent Architecture Alignment

**Documentation Reference**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md`

**Key Standards** (Lines 29-62):
1. **Metadata-Only Passing**: Extract title + 50-word summary (99% context reduction)
2. **Forward Message Pattern**: Pass subagent responses directly without re-summarization
3. **Recursive Supervision**: Supervisors delegate to sub-supervisors for 10+ parallel agents
4. **Aggressive Context Pruning**: Prune full content after phase completion (80-90% reduction)

**Current /supervise Alignment Status**:

| Standard | /supervise Implementation | Compliance |
|----------|---------------------------|------------|
| Metadata-Only Passing | ✓ Uses path-based context (Lines 1161-1168) | **COMPLIANT** |
| Forward Message Pattern | ✓ Extracts metadata from agent output (Lines 1949-1959) | **COMPLIANT** |
| Recursive Supervision | ✗ No sub-supervisor delegation | **NON-COMPLIANT** |
| Context Pruning | ✗ No explicit pruning implementation | **PARTIAL** |

**Analysis**:
- /supervise correctly passes paths instead of full content
- /supervise extracts metadata from plan output
- /supervise lacks recursive supervision (can't scale to 10+ agents)
- /supervise doesn't implement explicit context pruning utilities

**Context Pruning Gap**:
- /orchestrate sources context-pruning.sh (Lines 316-322)
- /supervise does NOT source context-pruning.sh
- Impact: /supervise may accumulate more context than necessary

### 4. Deprecation vs. Enhancement Analysis

**Functional Overlap Assessment**:

| Feature | /supervise | /orchestrate | Overlap |
|---------|-----------|--------------|---------|
| Research Phase | ✓ (Lines 899-1169) | ✓ (Lines 671-1077) | **100%** |
| Planning Phase | ✓ (Lines 1172-1401) | ✓ (Lines 1431-2082) | **100%** |
| Implementation | ✓ (Lines 1404-1527) | ✓ (Lines 2085-2427) | **100%** |
| Testing Phase | ✓ (Lines 1530-1635) | ✓ (Lines 2430-3125) | **100%** |
| Debug Loop | ✓ (Lines 1638-1961) | ✓ (Lines 3126-3758) | **100%** |
| Documentation | ✓ (Lines 1964-2052) | ✓ (Phase 6) | **100%** |
| Workflow Scope Detection | ✓ (Lines 612-673) | ✓ (Lines 118-390) | **90%** |
| Checkpoint Recovery | ✓ (Lines 593-608) | ✓ (Lines 211-223) | **100%** |
| Wave-Based Parallel Execution | ✗ | ✓ (Lines 2133-2200) | **0%** |
| PR Creation | ✗ | ✓ (Lines 4680-4820) | **0%** |

**Unique Features**:
- **Only /supervise**: Simplified workflow scope detection (4 types: research-only, research-and-plan, full-implementation, debug-only)
- **Only /orchestrate**: Wave-based parallel implementation (40-60% time savings), PR creation, dry-run mode, dashboard progress

**Usage Patterns** (from codebase analysis):
- **CLAUDE.md references**:
  - /orchestrate: 1 reference (Lines 176-182 in CLAUDE.md)
  - /supervise: 0 references in CLAUDE.md
- **Command README mentions**:
  - /orchestrate: Documented as "Multi-agent workflow coordination" (primary)
  - /supervise: Not prominently featured in README.md

**Deprecation Evaluation Criteria**:
1. **Functional redundancy**: 90-95% overlap (research, planning, implementation, testing, debugging, documentation)
2. **Performance gap**: /orchestrate has wave-based execution (40-60% faster), /supervise does not
3. **Usage evidence**: /supervise not referenced in CLAUDE.md or prominently documented
4. **Maintenance burden**: Maintaining two similar commands increases technical debt
5. **Migration complexity**: Moderate - users would need to switch from `/supervise` to `/orchestrate` syntax

**Recommendation Direction**: **DEPRECATE /supervise in favor of /orchestrate** based on:
- High functional overlap (90-95%)
- Superior /orchestrate performance (wave-based execution)
- No documented /supervise-specific use cases
- Low migration complexity

However, **migration plan MUST account for**:
- Existing workflows depending on /supervise
- Simplified scope detection in /supervise may be useful for some users
- Transition period with deprecation warnings before removal

## Recommendations

### Recommendation 1: Convert /plan Invocation to Enhanced Task-Based Pattern

**Priority**: HIGH
**Effort**: 2-3 hours
**Risk**: LOW

**Specific Changes Required**:

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Location**: Lines 1225-1250 (Phase 2: Planning section)

**Current Code** (Lines 1225-1232):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Workflow Description: ${WORKFLOW_DESCRIPTION}
    - Plan File Path: ${PLAN_PATH} (absolute path, pre-calculated by orchestrator)
```

**Replacement Code** (based on /orchestrate Lines 1759-1800):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000  # 10 minutes for planning
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}
    **Thinking Mode**: ${THINKING_MODE_FOR_AGENT}

    **Research Context**: ${SUCCESSFUL_REPORT_COUNT} research reports created
    **Research Reports**:
    ${RESEARCH_REPORTS_LIST}

    **PLAN CREATION**:
    STEP 1: Review all research reports above
    STEP 2: Analyze workflow requirements
    STEP 3: Calculate complexity and select tier
    STEP 4: Create plan file at EXACT path: ${PLAN_PATH}
            (Use Write tool with this absolute path)
    STEP 5: Include ALL research reports in plan metadata section
            Format: ## Metadata → Research Reports: [list]
    STEP 6: Verify plan created and return: PLAN_CREATED: ${PLAN_PATH}

    **CRITICAL REQUIREMENTS**:
    - Create plan at EXACT path provided (${PLAN_PATH})
    - Include all ${SUCCESSFUL_REPORT_COUNT} research reports in metadata
    - Use Write tool (not SlashCommand)
    - Return ONLY: PLAN_CREATED: [path]
  "
}
```

**Additional Variables to Define** (add before Task invocation around Line 1198):
```bash
# Format research reports for injection
RESEARCH_REPORTS_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  RESEARCH_REPORTS_LIST+="- $report\n"
done

# Set thinking mode based on complexity
if [ $SUCCESSFUL_REPORT_COUNT -ge 3 ]; then
  THINKING_MODE_FOR_AGENT="think hard"
else
  THINKING_MODE_FOR_AGENT="normal"
fi
```

**Testing Plan**:
1. Test with 2 research reports (normal thinking mode)
2. Test with 4 research reports (think hard mode)
3. Verify plan file includes all research reports in metadata
4. Verify plan quality improvement vs. current implementation
5. Measure context token usage (should be similar to /orchestrate)

**Success Criteria**:
- Plan-architect agent receives complete context (research reports, thinking mode)
- Plan metadata includes all research reports (traceability)
- No increase in context token usage
- Plan quality equivalent to /orchestrate-generated plans

### Recommendation 2: Add Research Subagent Delegation Following /research Pattern

**Priority**: MEDIUM
**Effort**: 4-6 hours
**Risk**: MEDIUM (requires understanding complexity scoring)

**Specific Changes Required**:

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Location**: Lines 920-985 (Phase 1: Research section)

**Step 1: Replace Keyword-Based Complexity with Structured Scoring**

**Current Code** (Lines 920-944):
```bash
# Simple keyword-based complexity scoring
RESEARCH_COMPLEXITY=2  # Default: 2 research topics

# Increase complexity for these keywords
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi
```

**Replacement Code** (inspired by /orchestrate's structured approach):
```bash
# Structured complexity scoring for research topics
RESEARCH_COMPLEXITY=2  # Default: 2 research topics

# Calculate base score from workflow type
BASE_SCORE=0
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "new|create|build"; then
  BASE_SCORE=10
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "enhance|update|improve"; then
  BASE_SCORE=7
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "refactor|restructure"; then
  BASE_SCORE=5
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "fix|debug|repair"; then
  BASE_SCORE=3
fi

# Add complexity multipliers
MULTIPLIERS=0
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|api" && MULTIPLIERS=$((MULTIPLIERS + 5))
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "security|auth" && MULTIPLIERS=$((MULTIPLIERS + 5))
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "migration|legacy" && MULTIPLIERS=$((MULTIPLIERS + 5))
echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi|distributed|microservice" && MULTIPLIERS=$((MULTIPLIERS + 10))

# Calculate research complexity (1-4 topics)
COMPLEXITY_SCORE=$((BASE_SCORE + MULTIPLIERS))
if [ $COMPLEXITY_SCORE -ge 30 ]; then
  RESEARCH_COMPLEXITY=4
elif [ $COMPLEXITY_SCORE -ge 20 ]; then
  RESEARCH_COMPLEXITY=3
elif [ $COMPLEXITY_SCORE -ge 10 ]; then
  RESEARCH_COMPLEXITY=2
else
  RESEARCH_COMPLEXITY=1
fi

echo "Research Complexity Score: $COMPLEXITY_SCORE → $RESEARCH_COMPLEXITY topics"
echo ""
```

**Step 2: Enhance Agent Invocation Template**

**Current Code** (Lines 959-978):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]}
```

**Replacement Code** (enhanced with topic focus):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPIC_NAME} with mandatory file creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Primary Workflow: ${WORKFLOW_DESCRIPTION}
    - Your Research Focus: ${RESEARCH_TOPIC_NAME}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
    - Project Standards: ${STANDARDS_FILE}
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    **Research Scope**:
    You are ONE of ${RESEARCH_COMPLEXITY} parallel research agents.
    Focus ONLY on: ${RESEARCH_TOPIC_NAME}

    Other agents are covering: ${OTHER_TOPICS}

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p \"\$(dirname \\\"${REPORT_PATHS[i]}\\\")\"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[i]}
  "
}
```

**Step 3: Add Topic Decomposition Logic** (insert before agent invocations around Line 949):
```bash
# Decompose workflow into research topics based on complexity
declare -a RESEARCH_TOPICS
case $RESEARCH_COMPLEXITY in
  1)
    RESEARCH_TOPICS=("${WORKFLOW_DESCRIPTION}")
    ;;
  2)
    # Two complementary aspects
    RESEARCH_TOPICS=(
      "existing_patterns_for_${TOPIC_NAME}"
      "best_practices_for_${TOPIC_NAME}"
    )
    ;;
  3)
    # Three specialized domains
    RESEARCH_TOPICS=(
      "existing_patterns_for_${TOPIC_NAME}"
      "best_practices_for_${TOPIC_NAME}"
      "security_considerations_for_${TOPIC_NAME}"
    )
    ;;
  4)
    # Four comprehensive domains
    RESEARCH_TOPICS=(
      "existing_patterns_for_${TOPIC_NAME}"
      "best_practices_for_${TOPIC_NAME}"
      "security_considerations_for_${TOPIC_NAME}"
      "integration_requirements_for_${TOPIC_NAME}"
    )
    ;;
esac

# Build "other topics" list for each agent
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  RESEARCH_TOPIC_NAME="${RESEARCH_TOPICS[$i-1]}"
  OTHER_TOPICS=""
  for j in $(seq 1 $RESEARCH_COMPLEXITY); do
    if [ $j -ne $i ]; then
      OTHER_TOPICS+="- ${RESEARCH_TOPICS[$j-1]}\n"
    fi
  done

  # Invoke agent with topic-specific context
  # (Task invocation here)
done
```

**Step 4: Add Research Overview Synthesis** (after verification around Line 1117):
```bash
# Only create overview if multiple reports
if [ $SUCCESSFUL_REPORT_COUNT -ge 2 ]; then
  echo "Creating research overview to synthesize findings..."

  # Build report list for overview agent
  REPORT_LIST=""
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    REPORT_LIST+="- $report\n"
  done

  # Invoke overview synthesizer agent
  Task {
    subagent_type: "general-purpose"
    description: "Synthesize research findings into overview"
    timeout: 300000  # 5 minutes for synthesis
    prompt: "
      Read and follow behavioral guidelines from:
      .claude/agents/research-specialist.md

      **SYNTHESIS TASK**:
      Create research overview synthesizing all individual reports.

      **Individual Reports to Synthesize**:
      ${REPORT_LIST}

      **Overview Path**: ${OVERVIEW_PATH}

      **Synthesis Requirements**:
      STEP 1: Read all individual reports listed above
      STEP 2: Identify common themes across reports
      STEP 3: Note any conflicting findings
      STEP 4: Create prioritized recommendations
      STEP 5: Cross-reference individual reports
      STEP 6: Write 400-500 word overview to: ${OVERVIEW_PATH}
      STEP 7: Return: OVERVIEW_CREATED: ${OVERVIEW_PATH}

      **CRITICAL**: Overview should synthesize, not duplicate.
      Focus on synthesis, conflicts, and integrated recommendations.
    "
  }

  # Verify overview created
  if retry_with_backoff 2 1000 test -f "$OVERVIEW_PATH"; then
    echo "✅ Research overview created successfully"
  else
    echo "⚠️  WARNING: Overview creation failed, continuing with individual reports"
  fi
fi
```

**Testing Plan**:
1. Test with simple workflow (1 topic)
2. Test with medium workflow (2-3 topics)
3. Test with complex workflow (4 topics)
4. Verify topic decomposition logic
5. Verify overview synthesis quality
6. Measure parallel execution time savings

**Success Criteria**:
- Research topics properly decomposed (1-4 based on complexity)
- Agents receive focused research scope
- Overview synthesizes findings (if multiple reports)
- Time savings from improved parallelization (target: 20-40%)

### Recommendation 3: Implement Context Pruning Utilities Integration

**Priority**: LOW
**Effort**: 1-2 hours
**Risk**: LOW

**Specific Changes Required**:

**File**: `/home/benjamin/.config/.claude/commands/supervise.md`
**Location**: Lines 234-322 (Shared Utility Functions section)

**Current Code** (Lines 299-322):
```bash
# Source metadata extraction utilities (95% context reduction per artifact)
if [ -f "$SCRIPT_DIR/../lib/metadata-extraction.sh" ]; then
  source "$SCRIPT_DIR/../lib/metadata-extraction.sh"
else
  echo "ERROR: metadata-extraction.sh not found"
  exit 1
fi

# Source context pruning utilities (<30% context usage target)
if [ -f "$SCRIPT_DIR/../lib/context-pruning.sh" ]; then
  source "$SCRIPT_DIR/../lib/context-pruning.sh"
else
  echo "ERROR: context-pruning.sh not found"
  exit 1
fi
```

**Observation**: /supervise already sources context-pruning.sh but doesn't use the utilities.

**Add Pruning After Each Phase** (insert after checkpoint saves):

**After Phase 1** (around Line 1168):
```bash
# Prune research phase context
if command -v prune_subagent_output >/dev/null 2>&1; then
  for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    prune_subagent_output "$report"
  done
  echo "✓ Research context pruned (metadata retained)"
fi
```

**After Phase 2** (around Line 1366):
```bash
# Prune planning phase context
if command -v prune_phase_metadata >/dev/null 2>&1; then
  prune_phase_metadata "planning" "$PLAN_PATH"
  echo "✓ Planning context pruned (metadata retained)"
fi
```

**After Phase 3** (around Line 1526):
```bash
# Prune implementation phase context
if command -v prune_phase_metadata >/dev/null 2>&1; then
  prune_phase_metadata "implementation" "$IMPL_ARTIFACTS"
  echo "✓ Implementation context pruned (metadata retained)"
fi
```

**After Phase 4** (around Line 1634):
```bash
# Prune testing phase context
if command -v prune_phase_metadata >/dev/null 2>&1; then
  prune_phase_metadata "testing" "${TOPIC_PATH}/outputs/test_results.md"
  echo "✓ Testing context pruned (metadata retained)"
fi
```

**Testing Plan**:
1. Verify context-pruning.sh functions available
2. Monitor context window usage across phases
3. Verify metadata retained after pruning
4. Confirm no functionality degradation
5. Measure context reduction (target: 80-90% for completed phases)

**Success Criteria**:
- Context pruning utilities successfully invoked after each phase
- Context window usage reduced by 80-90% for completed phases
- Metadata retained and accessible for subsequent phases
- No errors from missing pruned content

### Recommendation 4: Evaluate Deprecation and Create Migration Plan

**Priority**: HIGH (Strategic Decision)
**Effort**: 8-12 hours (comprehensive migration)
**Risk**: HIGH (impacts existing users)

**Decision Framework**:

**Option A: Deprecate /supervise in Favor of /orchestrate**

**Rationale**:
- 90-95% functional overlap
- /orchestrate has superior performance (wave-based execution)
- /orchestrate has more features (PR creation, dry-run, dashboard)
- No documented /supervise-specific use cases
- Reduces maintenance burden (single command to maintain)

**Migration Plan** (if Option A chosen):

**Phase 1: Deprecation Warning (2-4 weeks)**
1. Add deprecation notice to /supervise command documentation
2. Update CLAUDE.md to recommend /orchestrate
3. Add console warning when /supervise invoked:
   ```
   ⚠️  WARNING: /supervise is deprecated. Use /orchestrate instead.
   Migration guide: .claude/docs/migrations/supervise-to-orchestrate.md
   /supervise will be removed in: [target date]
   ```

**Phase 2: Migration Guide Creation**
Create `.claude/docs/migrations/supervise-to-orchestrate.md`:
```markdown
# Migration Guide: /supervise → /orchestrate

## Why Migrate?

/orchestrate provides all /supervise functionality plus:
- Wave-based parallel implementation (40-60% faster)
- PR creation automation
- Dry-run mode for workflow preview
- Dashboard progress tracking

## Syntax Migration

### Research-Only Workflow
**Before**: `/supervise "research API authentication patterns"`
**After**: `/orchestrate "research API authentication patterns"`

### Research-and-Plan Workflow
**Before**: `/supervise "research auth module to create refactor plan"`
**After**: `/orchestrate "research auth module to create refactor plan"`

### Full Implementation
**Before**: `/supervise "implement OAuth2 authentication"`
**After**: `/orchestrate "implement OAuth2 authentication --create-pr"`

### Debug Workflow
**Before**: `/supervise "fix token refresh bug"`
**After**: `/orchestrate "debug token refresh issue"`

## Feature Parity

All /supervise features available in /orchestrate:
- Workflow scope detection ✓
- Parallel research ✓
- Planning with research integration ✓
- Implementation with testing ✓
- Debug loop (max 3 iterations) ✓
- Documentation generation ✓
- Checkpoint recovery ✓
```

**Phase 3: Deprecation Enforcement (4-8 weeks after warning)**
1. Remove /supervise from primary command list in README.md
2. Move /supervise.md to `.claude/commands/deprecated/supervise.md`
3. Update .gitignore to exclude deprecated commands from default globbing
4. Keep deprecated command functional but emit strong warning

**Phase 4: Final Removal (12-16 weeks after warning)**
1. Remove /supervise.md entirely
2. Update all references to use /orchestrate
3. Update tests to use /orchestrate
4. Archive migration guide to `.claude/docs/migrations/archive/`

**Option B: Enhance /supervise and Maintain Both Commands**

**Rationale**:
- Simplified workflow scope detection may be valuable for some users
- Smaller file size (2,177 lines vs 5,443 lines) may be easier to maintain
- Some users may prefer simpler orchestration command
- Avoids forcing users to migrate

**Enhancement Plan** (if Option B chosen):

1. Implement Recommendation 1 (enhance /plan invocation)
2. Implement Recommendation 2 (add research delegation)
3. Implement Recommendation 3 (integrate context pruning)
4. Document /supervise vs /orchestrate differences clearly:
   ```markdown
   ## Choosing Between /supervise and /orchestrate

   **Use /supervise when**:
   - You want simplified workflow orchestration
   - You prefer explicit workflow scope types (research-only, research-and-plan, full-implementation, debug-only)
   - You don't need wave-based parallel implementation

   **Use /orchestrate when**:
   - You need maximum performance (wave-based execution)
   - You want PR creation automation
   - You want dry-run mode for workflow preview
   - You need dashboard progress tracking
   - You're working on complex multi-phase implementations
   ```

**Testing Requirements** (either option):
1. Comprehensive integration tests for chosen path
2. User acceptance testing with sample workflows
3. Performance benchmarking
4. Documentation review and updates

**Decision Criteria**:
- **Usage metrics**: Analyze actual /supervise usage in projects
- **User feedback**: Survey users on command preferences
- **Maintenance capacity**: Assess team bandwidth for dual command maintenance
- **Strategic direction**: Align with long-term command architecture goals

**Recommendation**: **Choose Option A (Deprecate /supervise)** based on:
- High functional overlap (90-95%)
- Superior /orchestrate performance
- No unique /supervise features that can't be added to /orchestrate
- Reduced maintenance burden
- Clear migration path

However, implement **gradual deprecation with comprehensive migration support** to minimize user disruption.

## Related Reports

- **[OVERVIEW.md](./OVERVIEW.md)** - Synthesizes findings from all 4 research reports
- **[001_supervise_command_implementation_analysis.md](./001_supervise_command_implementation_analysis.md)** - Implementation analysis showing Phase 3 sequential execution gap
- **[002_standards_violations_and_pattern_deviations.md](./002_standards_violations_and_pattern_deviations.md)** - Standards compliance analysis showing 95% adherence with 3 specific violations
- **[003_root_cause_of_subagent_delegation_failures.md](./003_root_cause_of_subagent_delegation_failures.md)** - Delegation failure investigation showing historical anti-pattern resolution

## References

### Command Files
- `/home/benjamin/.config/.claude/commands/supervise.md` - Lines 1-2177
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Lines 1-5443
- `/home/benjamin/.config/.claude/commands/research.md` - Research command patterns

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Lines 1-200 (planning agent guidelines)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Lines 1-671 (research agent guidelines)

### Documentation
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md` - Lines 1-300 (architecture principles)
- `/home/benjamin/.config/CLAUDE.md` - Lines 1-400 (project configuration and command reference)

### Library Utilities
- `.claude/lib/metadata-extraction.sh` - Metadata extraction utilities
- `.claude/lib/context-pruning.sh` - Context pruning utilities
- `.claude/lib/error-handling.sh` - Error handling and retry logic
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore
- `.claude/lib/unified-logger.sh` - Progress logging

### Comparison Evidence
- /orchestrate Task invocations: Lines 749, 860, 878, 902, 1080, 1549, 1581, 1622, 1759, 2167, 2234, 3045, 4764, 5307
- /supervise Task invocations: Lines 1232 (planning), 959-978 (research)
- Behavioral injection pattern examples from /orchestrate showing comprehensive context injection
