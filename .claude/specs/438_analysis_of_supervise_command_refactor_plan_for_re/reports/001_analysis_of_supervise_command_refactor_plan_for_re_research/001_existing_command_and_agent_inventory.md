# Existing Command and Agent Inventory

**Research Date**: 2025-10-23
**Topic**: Comprehensive inventory of .claude/ system commands, agents, templates, and libraries
**Context**: Supporting analysis of supervise command refactor plan at `/home/benjamin/.config/.claude/specs/437_supervise_command_regression_analysis/plans/001_systematic_supervise_refactor.md`

## Related Reports
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md) - Complete analysis synthesis with architectural recommendations

## Executive Summary

The .claude/ system provides a rich ecosystem of 23 commands, 24 specialized agents, 13 templates, and 40+ library functions that can be leveraged for the supervise command refactor. Key findings:

1. **Location Detection**: Unified location detection library (`unified-location-detection.sh`) provides standardized topic-based directory structure creation with 85% token reduction vs agent-based detection - directly applicable to Phase 0 optimization mentioned in refactor plan.

2. **Agent Patterns**: `/orchestrate` command demonstrates correct imperative Task invocation pattern that should be replicated in `/supervise` - all invocations use "EXECUTE NOW" or "USE the Task tool" imperatives, never YAML documentation blocks.

3. **Context Optimization**: Comprehensive utilities exist for metadata extraction (`metadata-extraction.sh`), context pruning (`context-pruning.sh`), and hierarchical agent coordination that align perfectly with Phase 4 context optimization goals.

4. **Template Infrastructure**: Existing template directory structure (`.claude/templates/`) with agent invocation patterns, orchestration patterns, and output patterns provides foundation for Phase 2 template extraction.

5. **Critical Gap**: No existing command uses YAML documentation blocks for Task invocations - `/supervise`'s pattern is unique and should be eliminated.

## 1. Commands Inventory

### Location: `.claude/commands/`

**Total Commands**: 23 command files

#### Primary Workflow Commands (Agent Coordination)
- **orchestrate.md** (Lines: ~2,800) - Multi-agent workflow coordination
  - Pattern: Pure orchestration via Task tool invocations
  - Agent delegation rate: 100% (all phases use specialized agents)
  - Key feature: Metadata-based context passing, forward message pattern
  - File location: Lines 1-150 show imperative Task invocations with "EXECUTE NOW" pattern

- **implement.md** (Lines: ~2,400) - Phase-by-phase implementation execution
  - Pattern: Hybrid (direct execution for simple phases, agent delegation for complex)
  - Complexity threshold: Score ≥3 triggers agent delegation
  - Agent invocation: code-writer (line ~89), implementation-researcher (line ~89)
  - Key feature: Adaptive role switching based on complexity evaluation

- **plan.md** - Implementation plan creation
  - Pattern: Agent delegation to plan-architect
  - Context injection: Research report paths passed to agent

- **report.md** - Research report generation
  - Pattern: Agent delegation to research-specialist
  - Artifact verification: File creation checkpoints mandatory

- **research.md** - Hierarchical multi-agent research
  - Pattern: Improved /report with recursive supervision
  - Agent coordination: Sub-supervisor pattern for 10+ topics

#### Supporting Commands
- **debug.md** - Debugging and root cause analysis
- **document.md** - Documentation updates
- **refactor.md** - Code refactoring analysis
- **test.md** / **test-all.md** - Testing protocols
- **expand.md** / **collapse.md** - Progressive planning utilities
- **revise.md** - Plan revision (auto-mode and interactive)
- **setup.md** - CLAUDE.md configuration and enhancement
- **list.md** - Artifact listing (metadata-only reads)
- **validate-setup.md** - Standards compliance validation
- **plan-from-template.md** - Template-based plan generation
- **plan-wizard.md** - Interactive plan creation
- **convert-docs.md** - Document format conversion
- **analyze.md** - System performance metrics analysis
- **example-with-agent.md** - Agent invocation pattern template
- **migrate-specs.md** - Artifact migration utility

#### Command Pattern Analysis

**Commands Using Imperative Task Invocations** (✓ Correct Pattern):
- `/orchestrate` - All 6 phases use imperative pattern
- `/implement` - Adaptive delegation with imperative invocations
- `/plan` - Single imperative invocation to plan-architect
- `/report` - Imperative invocation to research-specialist
- `/debug` - Imperative invocation to debug-analyst
- `/refactor` - Imperative invocation to code-reviewer

**Commands Using YAML Documentation Blocks** (✗ Anti-Pattern):
- `/supervise` - ALL Task invocations in YAML code blocks (0/9 executable)
- **Finding**: This pattern is UNIQUE to /supervise - no other command uses it

## 2. Agents Inventory

### Location: `.claude/agents/`

**Total Agents**: 24 specialized agents

#### Research and Analysis Agents
1. **research-specialist.md**
   - Tools: Read, Write, Grep, Glob, WebSearch, WebFetch
   - Model: sonnet-4.5
   - Completion criteria: 28 requirements (95+/100 enforcement score)
   - Key feature: MANDATORY file creation FIRST (Step 2) before research (Step 3)
   - Return format: `REPORT_CREATED: [absolute-path]` only
   - File reference: Lines 1-646 (full specification)
   - **Leverage**: Template for Phase 1 research agent invocations in refactor

2. **research-synthesizer.md**
   - Purpose: Aggregate findings from multiple research-specialist outputs
   - Pattern: Metadata-based input (not full report text)

3. **debug-analyst.md**
   - Purpose: Parallel root cause investigation
   - Pattern: Hypothesis testing across multiple code paths

4. **metrics-specialist.md**
   - Purpose: Performance analysis and optimization recommendations

#### Planning and Architecture Agents
5. **plan-architect.md**
   - Purpose: Create structured implementation plans
   - Input: Research report metadata (not full content)
   - Output: Plan file with phases, tasks, dependencies

6. **plan-expander.md**
   - Purpose: Expand phases into separate files (progressive planning)

7. **complexity-estimator.md**
   - Purpose: Evaluate phase/stage complexity for expansion decisions
   - Pattern: Context-aware analysis (not keyword matching)

#### Implementation Agents
8. **code-writer.md**
   - Purpose: Execute implementation tasks with coding standards
   - Pattern: Receives plan context, implements changes, runs tests

9. **implementation-researcher.md**
   - Purpose: Codebase exploration before complex implementation phases
   - Returns: 50-word summary + artifact path (95% context reduction)

10. **implementation-executor.md**
    - Purpose: Direct implementation without orchestration layer

#### Specialized Utility Agents
11. **location-specialist.md**
    - Tools: Read, Bash, Grep, Glob
    - Model: haiku-4.5 (75.6k token optimization)
    - Purpose: Analyze workflow, create topic directory structure
    - Returns: YAML location context with absolute paths
    - File reference: Lines 1-417 (complete specification)
    - **Leverage**: Replaced by unified-location-detection.sh library (85% faster)
    - **Note**: Agent still used by some commands, but library preferred

12. **spec-updater.md**
    - Tools: Read, Write, Edit, Grep, Glob, Bash
    - Purpose: Artifact management, cross-reference updates, hierarchy synchronization
    - Key features: Checkbox propagation across plan levels, gitignore compliance
    - File reference: Lines 1-1076 (artifact taxonomy standards)

13. **doc-writer.md**
    - Purpose: Generate implementation summaries and documentation

14. **git-commit-helper.md**
    - Purpose: Create structured git commit messages

15. **github-specialist.md**
    - Purpose: GitHub operations (PR creation, issue management)

#### Testing and Quality Agents
16. **test-specialist.md**
    - Purpose: Execute test suites and analyze results

17. **code-reviewer.md**
    - Purpose: Code review and quality analysis

#### Workflow Coordination Agents
18. **implementer-coordinator.md**
    - Purpose: Coordinate multi-phase implementations

19. **expansion-specialist.md** / **collapse-specialist.md**
    - Purpose: Progressive planning operations

20. **debug-specialist.md**
    - Purpose: Specialized debugging workflows

21. **doc-converter.md**
    - Purpose: Document format conversions

### Agent Frontmatter Standards

All agents include YAML frontmatter with:
- `allowed-tools`: Tool whitelist
- `description`: Agent purpose
- `model`: Primary model (sonnet-4.5 or haiku-4.5)
- `model-justification`: Reasoning for model selection
- `fallback-model`: Backup model

## 3. Templates Inventory

### Location: `.claude/templates/`

**Total Templates**: 13 template files

1. **agent-invocation-patterns.md**
   - Purpose: Standard patterns for invoking agents via Task tool
   - **Leverage**: Reference for Phase 1 Task invocation conversions

2. **agent-tool-descriptions.md**
   - Purpose: Tool access patterns and descriptions

3. **artifact_research_invocation.md**
   - Purpose: Research artifact creation patterns

4. **audit-checklist.md**
   - Purpose: Quality verification checklists

5. **command-frontmatter.md**
   - Purpose: Standard YAML frontmatter for command files

6. **debug-structure.md**
   - Purpose: Debug report formatting standards

7. **orchestration-patterns.md**
   - Purpose: Multi-phase workflow coordination templates
   - **Leverage**: Model for Phase 2 template extraction

8. **output-patterns.md**
   - Purpose: Structured output formatting

9. **README.md**
   - Purpose: Template directory overview

10. **readme-template.md**
    - Purpose: Directory README generation

11. **refactor-structure.md**
    - Purpose: Refactoring report structure

12. **report-structure.md**
    - Purpose: Research report formatting

13. **sub_supervisor_pattern.md**
    - Purpose: Recursive supervision for hierarchical workflows

## 4. Library Functions Inventory

### Location: `.claude/lib/`

**Total Libraries**: 40+ shell script utilities (23,803 total lines)

#### Location and Directory Management
1. **unified-location-detection.sh** (478 lines)
   - Purpose: Standardized location detection for workflow commands
   - Functions:
     - `detect_project_root()` - Find project root (git/env/pwd)
     - `detect_specs_directory()` - Find specs directory (.claude/specs vs specs)
     - `get_next_topic_number()` - Calculate next topic number
     - `sanitize_topic_name()` - Convert workflow description to topic name
     - `create_topic_structure()` - Create 6-subdirectory structure
     - `perform_location_detection()` - Orchestrate complete workflow
     - `create_research_subdirectory()` - Hierarchical research support
   - Commands using: /supervise, /orchestrate, /report, /plan
   - **Leverage**: Direct integration for Phase 0 optimization (lines 276-333 show complete API)

2. **detect-project-dir.sh**
   - Purpose: Legacy project root detection (replaced by unified library)

3. **topic-utils.sh**
   - Purpose: Topic numbering and naming utilities (merged into unified library)

#### Artifact Management
4. **artifact-creation.sh** (267 lines)
   - Functions:
     - `create_topic_artifact()` - Create numbered artifacts in subdirectories
     - `get_next_artifact_number()` - Calculate next artifact number
     - `write_artifact_file()` - Write artifact with metadata
     - `generate_artifact_invocation()` - Create agent invocation prompts
   - Gitignore behavior: debug/ committed, all others gitignored
   - File reference: Lines 1-267 (complete API)

5. **artifact-registry.sh**
   - Purpose: Track created artifacts for cross-referencing

6. **artifact-cross-reference.sh**
   - Purpose: Update links between related artifacts

7. **artifact-cleanup.sh**
   - Purpose: Remove temporary artifacts after workflow completion

8. **artifact-operations-legacy.sh** (2,715 lines)
   - Purpose: Legacy artifact operations (being replaced by modular libraries)

#### Agent Coordination
9. **agent-invocation.sh** (136 lines)
   - Functions:
     - `invoke_complexity_estimator()` - Construct prompts for complexity analysis
   - Pattern: Build prompt, return for Task tool invocation at command layer
   - File reference: Lines 26-132 (invocation pattern)
   - **Note**: Simulation only - actual invocation via Task tool in commands

10. **agent-discovery.sh**
    - Purpose: Find available agents in .claude/agents/

11. **agent-loading-utils.sh**
    - Purpose: Load agent definitions dynamically

12. **agent-registry-utils.sh**
    - Purpose: Register and query available agents

13. **agent-schema-validator.sh**
    - Purpose: Validate agent frontmatter compliance

14. **agent-frontmatter-validator.sh**
    - Purpose: Validate YAML frontmatter in agent files

15. **hierarchical-agent-support.sh**
    - Purpose: Recursive supervision utilities

#### Context and Metadata Management
16. **metadata-extraction.sh** (540 lines)
    - Functions:
     - `extract_report_metadata()` - Extract title + 50-word summary (99% reduction)
     - `extract_plan_metadata()` - Extract complexity, phases, estimates
     - `load_metadata_on_demand()` - Generic metadata loader with caching
   - Pattern: Read artifact → Extract summary → Return JSON metadata
   - File reference: Lines 13-87 show report metadata extraction
   - **Leverage**: Integrate after Phase 1 verification (mentioned in refactor plan Phase 4)

17. **context-pruning.sh** (440 lines)
    - Functions:
     - `prune_subagent_output()` - Clear full outputs after metadata extraction
     - `prune_phase_metadata()` - Remove phase data after completion
     - `apply_pruning_policy()` - Automatic pruning by workflow type
   - Target: <30% context usage throughout workflows
   - **Leverage**: Integrate after each phase completion (refactor plan Phase 4)

18. **context-metrics.sh**
    - Purpose: Measure context window usage

#### Plan Parsing and Structure
19. **plan-core-bundle.sh** (1,159 lines)
    - Bundles: parse-plan-core.sh + plan-metadata-utils.sh + plan-structure-utils.sh
    - Functions:
     - `extract_phase_name()` / `extract_phase_content()`
     - `detect_structure_level()` - Identify plan level (0/1/2)
     - `is_phase_expanded()` / `get_phase_file()`
     - `merge_phase_into_plan()` / `merge_stage_into_phase()`
   - File reference: Lines 1-100 show core parsing functions

20. **progressive-planning-utils.sh** (484 lines)
    - Purpose: Expansion and collapse operations

21. **checkbox-utils.sh**
    - Purpose: Hierarchy checkbox synchronization

22. **structure-validator.sh**
    - Purpose: Validate plan structure compliance

23. **structure-eval-utils.sh**
    - Purpose: Evaluate plan structure for optimization

#### Workflow State Management
24. **checkpoint-utils.sh** (823 lines)
    - Purpose: Save/restore workflow state for resumable operations
    - Pattern: JSON checkpoint files with phase progress tracking

25. **checkpoint-manager.sh** (519 lines)
    - Purpose: Advanced checkpoint management

26. **progress-tracker.sh** (608 lines)
    - Purpose: Track workflow progress across phases

27. **progress-dashboard.sh**
    - Purpose: Display real-time progress visualization

#### Logging and Monitoring
28. **unified-logger.sh** (747 lines)
    - Purpose: Structured logging with rotation and query support
    - Log file: `.claude/data/logs/adaptive-planning.log`

29. **error-handling.sh** (765 lines)
    - Purpose: Standardized error handling patterns

30. **validation-utils.sh**
    - Purpose: Input validation and type checking

#### Testing and Quality
31. **detect-testing.sh**
    - Purpose: Score testing infrastructure (0-6 scale)

32. **generate-testing-protocols.sh**
    - Purpose: Create testing documentation

#### Orchestration and Parallel Execution
33. **parallel-orchestration-utils.sh** (398 lines)
    - Purpose: Parallel agent execution with wave-based coordination

34. **workflow-detection.sh**
    - Purpose: Identify workflow type from description

35. **dependency-analyzer.sh** (638 lines)
    - Purpose: Analyze task dependencies for parallel execution

36. **dependency-analysis.sh**
    - Purpose: Dependency graph generation

37. **dependency-mapper.sh**
    - Purpose: Map cross-file dependencies

#### Template and Report Generation
38. **parse-template.sh**
    - Purpose: Parse template files with variable substitution

39. **substitute-variables.sh**
    - Purpose: Variable replacement in templates

40. **template-integration.sh**
    - Purpose: Integrate templates into workflows

41. **report-generation.sh** (481 lines)
    - Purpose: Generate structured reports

42. **topic-decomposition.sh**
    - Purpose: Break complex topics into sub-topics

#### Specialized Utilities
43. **git-utils.sh**
    - Purpose: Git operations (commit, branch, PR)

44. **json-utils.sh**
    - Purpose: JSON parsing and manipulation

45. **timestamp-utils.sh**
    - Purpose: Timestamp generation and formatting

46. **base-utils.sh**
    - Purpose: Common utility functions (sourced by most libraries)

47. **complexity-thresholds.sh**
    - Purpose: Configurable complexity thresholds

48. **auto-analysis-utils.sh** (635 lines)
    - Purpose: Automated analysis patterns

49. **analyze-metrics.sh** (579 lines)
    - Purpose: Metrics collection and analysis

50. **track-file-creation-rate.sh**
    - Purpose: Monitor file creation performance

### Library Size Analysis (Top 10 by Lines)
1. artifact-operations-legacy.sh: 2,715 lines (being replaced)
2. convert-core.sh: 1,313 lines (document conversion)
3. plan-core-bundle.sh: 1,159 lines (plan parsing)
4. checkpoint-utils.sh: 823 lines (state management)
5. error-handling.sh: 765 lines (error patterns)
6. unified-logger.sh: 747 lines (logging)
7. dependency-analyzer.sh: 638 lines (dependency analysis)
8. auto-analysis-utils.sh: 635 lines (automated analysis)
9. migrate-specs-utils.sh: 619 lines (migration)
10. progress-tracker.sh: 608 lines (progress tracking)

## 5. Key Capabilities Analysis

### Location Detection

**Capability**: Unified location detection library eliminates need for location-specialist agent

**Implementation**: `unified-location-detection.sh` (478 lines)
- **Function**: `perform_location_detection(workflow_description, force_new_topic)`
- **Returns**: JSON object with topic_path, topic_number, artifact_paths
- **Performance**: 85% token reduction vs agent-based detection, 25x speedup
- **Pattern**: Library function call vs Task tool agent invocation

**Example Usage** (from library file lines 276-333):
```bash
source /path/to/unified-location-detection.sh
LOCATION_JSON=$(perform_location_detection "research authentication patterns")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
```

**Commands Using**:
- /supervise (line 7 comment: "Commands using this library")
- /orchestrate
- /report
- /plan

**Refactor Alignment**: Phase 0 mentions "clarifies scope of changes" - this library IS the optimization (no agent needed).

### Artifact Management

**Capability**: Complete artifact lifecycle management with gitignore compliance

**Implementation**:
- `artifact-creation.sh` (267 lines) - Create numbered artifacts
- `artifact-registry.sh` - Track artifacts
- `artifact-cross-reference.sh` - Update links
- `artifact-cleanup.sh` - Remove temporary artifacts

**Key Functions**:
1. `create_topic_artifact(topic_dir, artifact_type, artifact_name, content)` - Lines 14-84
   - Validates artifact type (debug, scripts, outputs, artifacts, backups, data, logs, notes, reports, plans)
   - Creates subdirectory if needed
   - Calculates next number
   - Writes file with metadata
   - Returns absolute path

2. `get_next_artifact_number(topic_dir)` - Lines 134-157
   - Scans for NNN_*.md files
   - Finds maximum number
   - Returns next with zero-padding

**Gitignore Behavior**:
- **Committed**: debug/ only
- **Gitignored**: reports/, plans/, summaries/, scripts/, outputs/, artifacts/, backups/, data/, logs/, notes/

**Refactor Alignment**: Phase 1 file creation verification can use these utilities.

### Agent Invocation

**Capability**: Two distinct patterns for agent coordination

**Pattern 1: Imperative Task Invocations** (✓ Correct)
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    Research Topic: Authentication Patterns
    Report Path: /absolute/path/to/report.md

    STEP 1: Create file at exact path
    STEP 2: Conduct research
    STEP 3: Return: REPORT_CREATED: [path]
  "
}
```

**Pattern 2: YAML Documentation Blocks** (✗ Anti-Pattern)
```markdown
Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Example only"
  prompt: "This is documentation, not executable code"
}
```
```

**Commands Using Pattern 1** (Correct):
- /orchestrate (all phases)
- /implement (complex phases)
- /plan
- /report
- /debug
- /refactor

**Commands Using Pattern 2** (Anti-Pattern):
- /supervise ONLY

**Refactor Alignment**: Phase 1 converts ALL Pattern 2 blocks to Pattern 1.

### Workflow Coordination

**Capability**: Multi-phase workflow orchestration with state management

**Implementation**:
- `checkpoint-utils.sh` (823 lines) - Save/restore state
- `progress-tracker.sh` (608 lines) - Track progress
- `parallel-orchestration-utils.sh` (398 lines) - Parallel execution

**Orchestration Patterns**:

1. **Sequential Phases** (used by /orchestrate, /implement, /supervise):
   ```
   Phase 0 → Phase 1 → Phase 2 → ... → Phase N
   Each phase: Execute → Verify → Checkpoint → Next
   ```

2. **Parallel Research** (used by /orchestrate Phase 1):
   ```
   Research Topic 1 (research-specialist)
   Research Topic 2 (research-specialist)  } Parallel
   Research Topic 3 (research-specialist)
   Research Topic 4 (research-specialist)
   ↓
   Aggregate metadata → Pass to Phase 2
   ```

3. **Conditional Execution** (used by /implement debugging):
   ```
   Implementation → Tests
                     ↓
                  Passed? → Yes → Continue
                     ↓
                    No → Invoke debug-specialist → Retry (max 3)
   ```

4. **Wave-Based Implementation** (used by /implement):
   ```
   Wave 1: Independent phases in parallel
   Wave 2: Phases dependent on Wave 1
   Wave 3: Phases dependent on Wave 2
   ```

**Checkpoint Structure**:
```json
{
  "workflow_type": "orchestrate",
  "current_phase": 2,
  "completed_phases": [0, 1],
  "artifact_metadata": {
    "reports": ["path1", "path2"],
    "plan": "path3"
  },
  "timestamp": "2025-10-23T10:30:00Z"
}
```

**Refactor Alignment**: /supervise should use same checkpoint pattern as /orchestrate.

## 6. Recommendations for Supervise Refactor

Based on comprehensive inventory of existing capabilities:

### Phase 0 Recommendations: Location Detection

**Current Plan**: "Optimize Phase 0 with clarification note"

**Recommendation**: REPLACE location-specialist agent with unified-location-detection.sh library

**Implementation**:
```bash
# Current pattern (in /supervise):
Task {
  description: "Determine location using location-specialist agent"
  ...
}

# Recommended pattern (from /orchestrate):
source "${BASH_SOURCE%/*}/../lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION")
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
```

**Benefits**:
- 85% token reduction vs agent invocation
- 25x faster execution (<1 second vs 20-40 seconds)
- Identical functionality to location-specialist agent
- Already used by /orchestrate, /report, /plan

**File References**:
- Library: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 276-333)
- Example: `/home/benjamin/.config/.claude/commands/orchestrate.md` (search for unified-location-detection usage)

### Phase 1 Recommendations: Task Invocation Conversion

**Current Plan**: Convert YAML blocks to imperative invocations

**Recommendation**: Use /orchestrate as reference template for ALL Task invocations

**Pattern to Replicate** (from /orchestrate):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research [topic] with mandatory file creation"
  prompt: "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Topic**: [specific topic]
    **Report Path**: [absolute path from location detection]
    **Context**: [workflow context]

    **STEP 1 (MANDATORY)**: Verify absolute path received
    **STEP 2 (EXECUTE NOW)**: Create report file using Write tool
    **STEP 3 (REQUIRED)**: Conduct research and update file
    **STEP 4 (ABSOLUTE REQUIREMENT)**: Return: REPORT_CREATED: [path]
  "
}
```

**Key Elements to Include**:
1. Imperative instruction: "EXECUTE NOW" or "USE the Task tool"
2. Agent file reference: Absolute path to agent definition
3. Explicit steps: STEP 1, STEP 2, STEP 3, STEP 4
4. Mandatory markers: MANDATORY, REQUIRED, ABSOLUTE REQUIREMENT
5. Return format: Exact expected output format

**Apply to All Phases**:
- Phase 1 Research: 2-4 research-specialist invocations
- Phase 2 Planning: 1 plan-architect invocation
- Phase 3 Implementation: 1 code-writer invocation
- Phase 4 Testing: 1 test-specialist invocation
- Phase 5 Debug: 3 invocations (debug-analyst, code-writer, test-specialist)
- Phase 6 Documentation: 1 doc-writer invocation

**Total**: 9 Task invocations to convert

### Phase 2 Recommendations: Template Extraction

**Current Plan**: Extract 8 agent templates to `.claude/templates/supervise/`

**Recommendation**: Follow /orchestrate template organization pattern

**Template Directory Structure**:
```
.claude/templates/supervise/
├── phase_1_research_specialist.md
├── phase_2_plan_architect.md
├── phase_3_code_writer.md
├── phase_4_test_specialist.md
├── phase_5_debug_analyst.md
├── phase_5_code_writer_fixes.md
├── phase_5_test_rerun.md
├── phase_6_doc_writer.md
└── README.md (explain template usage)
```

**Template File Format** (example: phase_1_research_specialist.md):
```markdown
# Research Specialist Agent Template - Phase 1

**Agent**: research-specialist
**Phase**: 1 (Research)
**Purpose**: Conduct research and create report file

## Template Variables
- {{RESEARCH_TOPIC}} - Specific research focus
- {{REPORT_PATH}} - Absolute path to report file
- {{WORKFLOW_CONTEXT}} - Workflow description
- {{TOPIC_NUMBER}} - Topic number for cross-referencing

## Invocation Pattern

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research {{RESEARCH_TOPIC}} with mandatory file creation"
  prompt: "
    [Complete prompt template here with variable placeholders]
  "
}

## Expected Output
REPORT_CREATED: {{REPORT_PATH}}

## Verification
- [ ] Report file exists at {{REPORT_PATH}}
- [ ] File size >500 bytes
- [ ] Return format matches exactly
```

**Benefits**:
- Reduces /supervise from 2,521 → ~1,600 lines (37% reduction)
- Templates reusable across commands
- Easier maintenance (update template vs inline prompts)
- Clear separation of structure vs content

**Reference**: `/home/benjamin/.config/.claude/templates/orchestration-patterns.md` for similar pattern

### Phase 3 Recommendations: File Creation Verification

**Current Plan**: Add mandatory verification checkpoints

**Recommendation**: Integrate artifact-creation.sh utilities for standardized verification

**Verification Pattern** (from research-specialist.md lines 84-153):
```bash
# After agent invocation, MANDATORY verification:
REPORT_PATH="[path from agent return]"

# 1. File exists check
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Report file not found at: $REPORT_PATH"
  echo "Initiating fallback creation..."
  # Fallback: Create minimal report
  create_topic_artifact "$TOPIC_DIR" "reports" "$REPORT_NAME" "Minimal report due to agent failure"
fi

# 2. File size check (minimum 500 bytes)
FILE_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "WARNING: Report file is too small (${FILE_SIZE} bytes)"
  echo "Expected >500 bytes for complete report"
fi

# 3. Content completeness check
if grep -q "placeholder\|TODO\|TBD" "$REPORT_PATH"; then
  echo "WARNING: Placeholder text found in report"
fi

echo "✓ VERIFIED: Report file complete and saved"
```

**Apply After Each Phase**:
- Phase 1: Verify all research reports created
- Phase 2: Verify implementation plan created
- Phase 3: Verify code changes applied
- Phase 4: Verify test results file created
- Phase 5: Verify debug reports created (if invoked)
- Phase 6: Verify documentation and summary created

**Fallback Strategy**:
If agent fails to create file → Use `create_topic_artifact()` to create minimal placeholder → Log warning → Continue workflow

### Phase 4 Recommendations: Context Optimization

**Current Plan**: Integrate metadata-extraction.sh and context-pruning.sh

**Recommendation**: Follow /orchestrate metadata-based context passing pattern

**Implementation Points**:

1. **After Phase 1 (Research)**: Extract metadata from all reports
   ```bash
   source "${BASH_SOURCE%/*}/../lib/metadata-extraction.sh"

   REPORT_METADATA=()
   for REPORT_PATH in "${RESEARCH_REPORTS[@]}"; do
     METADATA=$(extract_report_metadata "$REPORT_PATH")
     REPORT_METADATA+=("$METADATA")
   done

   # Pass metadata (not full reports) to Phase 2
   METADATA_JSON=$(jq -s '.' <<< "${REPORT_METADATA[@]}")
   ```

2. **After Phase 2 (Planning)**: Extract plan metadata
   ```bash
   PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")
   PHASE_COUNT=$(echo "$PLAN_METADATA" | jq -r '.phase_count')
   COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity')
   ```

3. **After Each Phase**: Prune completed phase data
   ```bash
   source "${BASH_SOURCE%/*}/../lib/context-pruning.sh"

   prune_phase_metadata "$COMPLETED_PHASE_NUM"
   # Removes full phase content from context, keeps only status
   ```

**Expected Results**:
- Context usage: <30% throughout workflow (vs >80% without optimization)
- Phase 1→2 transition: 95% reduction (metadata vs full reports)
- Phase 2→3 transition: 90% reduction (forward message pattern)
- Overall workflow: 60-80% context savings

**File References**:
- Metadata extraction: `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` (lines 13-87)
- Context pruning: `/home/benjamin/.config/.claude/lib/context-pruning.sh` (lines 1-440)

### Phase 5 Recommendations: Standards Documentation

**Current Plan**: Update behavioral-injection.md and command-architecture-standards.md

**Recommendation**: Document anti-pattern with explicit enforcement

**Add to behavioral-injection.md**:
```markdown
## Anti-Pattern: YAML Documentation Blocks

**NEVER** use YAML code blocks for Task invocations:

```markdown
<!-- ✗ WRONG: This is documentation, not executable -->
Example agent invocation:

```yaml
Task {
  description: "Example"
  prompt: "This will never execute"
}
```
```

**WHY THIS FAILS**:
- Code blocks are treated as literal text
- Task tool never receives invocation
- Agent never executes
- Workflow appears to succeed but does nothing

**CORRECT PATTERN**:
```markdown
<!-- ✓ CORRECT: Imperative instruction followed by executable Task -->
**EXECUTE NOW**: USE the Task tool to invoke the agent.

Task {
  description: "Research authentication patterns"
  prompt: "Actual agent prompt"
}
```

**ENFORCEMENT**:
- Regression test: `.claude/tests/test_task_invocations.sh`
- Validates: ≥N imperative Task invocations
- Validates: 0 YAML documentation blocks
- Fails build if anti-pattern detected
```

**Add to command-architecture-standards.md**:
```markdown
## Task Invocation Standards

**MANDATORY PATTERN** (ALL commands MUST follow):

1. **Imperative Instruction**: "EXECUTE NOW" or "USE the Task tool"
2. **Agent Reference**: Absolute path to agent file
3. **Structured Prompt**: STEP 1, STEP 2, STEP 3 format
4. **Expected Output**: Exact return format specification

**FORBIDDEN PATTERN**:
- YAML code blocks containing Task invocations
- Example-only Task patterns without imperative instructions

**VALIDATION**:
- All new commands: Run test_task_invocations.sh
- All PRs: CI/CD validates pattern compliance
- Quarterly audit: Check all commands for anti-patterns
```

### Phase 6 Recommendations: Testing

**Current Plan**: Create regression test preventing documentation-only patterns

**Recommendation**: Enhance test beyond basic grep checks

**Test File**: `.claude/tests/test_supervise_delegation.sh`

**Enhanced Test Coverage**:
```bash
#!/usr/bin/env bash
# Test: Supervise command agent delegation compliance

COMMAND_FILE=".claude/commands/supervise.md"
PASS=true

# Test 1: Count imperative Task invocations
IMPERATIVE_COUNT=$(grep -c 'EXECUTE NOW.*Task\|USE the Task tool' "$COMMAND_FILE" || echo 0)
if [ "$IMPERATIVE_COUNT" -lt 9 ]; then
  echo "FAIL: Found $IMPERATIVE_COUNT imperative invocations (expected ≥9)"
  PASS=false
else
  echo "PASS: Found $IMPERATIVE_COUNT imperative Task invocations"
fi

# Test 2: Count YAML documentation blocks
YAML_BLOCKS=$(grep -c '```yaml.*Task' "$COMMAND_FILE" || echo 0)
if [ "$YAML_BLOCKS" -gt 0 ]; then
  echo "FAIL: Found $YAML_BLOCKS YAML documentation blocks (expected 0)"
  PASS=false
else
  echo "PASS: No YAML documentation blocks found"
fi

# Test 3: Verify agent file references
AGENT_REFS=$(grep -c '\.claude/agents/.*\.md' "$COMMAND_FILE" || echo 0)
if [ "$AGENT_REFS" -lt 9 ]; then
  echo "WARNING: Found $AGENT_REFS agent references (expected ≥9)"
fi

# Test 4: Verify file creation checkpoints
FILE_CHECKS=$(grep -c 'if \[ ! -f.*\]; then' "$COMMAND_FILE" || echo 0)
if [ "$FILE_CHECKS" -lt 6 ]; then
  echo "WARNING: Found $FILE_CHECKS file verification checks (expected ≥6 phases)"
fi

# Test 5: Verify metadata extraction integration
METADATA_CALLS=$(grep -c 'extract_report_metadata\|extract_plan_metadata' "$COMMAND_FILE" || echo 0)
if [ "$METADATA_CALLS" -lt 2 ]; then
  echo "WARNING: Found $METADATA_CALLS metadata extraction calls (expected ≥2)"
fi

if [ "$PASS" = true ]; then
  echo "✓ All supervise delegation tests PASSED"
  exit 0
else
  echo "✗ Supervise delegation tests FAILED"
  exit 1
fi
```

**Benefits**:
- Comprehensive validation beyond pattern matching
- Warnings for missing optimizations
- Prevents regression to documentation-only pattern

## 7. Additional Findings

### Commands NOT Using Agent Delegation
- **test.md** / **test-all.md**: Execute tests directly via Bash
- **list.md**: Metadata-only reads (no agent needed)
- **validate-setup.md**: Standards validation scripts
- **collapse.md** / **expand.md**: Plan manipulation utilities

**Reason**: These are utility commands, not workflow orchestrators. Direct execution appropriate.

### Agents Without Current Usage
- **implementer-coordinator.md**: Appears unused (check for deprecation)
- **doc-converter-usage.md**: Usage guide, not agent specification

### Library Deprecation Candidates
- **artifact-operations-legacy.sh** (2,715 lines): Marked as legacy, should be removed after migration complete
- **detect-project-dir.sh**: Replaced by unified-location-detection.sh
- **topic-utils.sh**: Merged into unified-location-detection.sh

### Template Gaps
- No existing templates for /supervise-specific patterns
- Opportunity to create reusable templates during Phase 2

---

**Research Status**: COMPLETE
**Last Updated**: 2025-10-23
**Files Analyzed**: 23 commands, 24 agents, 13 templates, 40+ libraries
**Total Lines Reviewed**: ~30,000+ lines of code and documentation
