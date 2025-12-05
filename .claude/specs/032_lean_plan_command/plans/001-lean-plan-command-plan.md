# Lean Plan Command Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Create /lean:plan command for Lean theorem proving implementation plans
- **Scope**: Implement a Lean-specific planning workflow that generates structured implementation plans with theorem-level granularity, Mathlib research, proof strategies, and dependency tracking for the /lean command execution
- **Estimated Phases**: 5
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 78.0
- **Structure Level**: 0
- **Research Reports**:
  - [Lean Infrastructure Research](../reports/001-lean-infrastructure-research.md)
  - [Lean Planning Best Practices](../reports/002-lean-planning-best-practices.md)

---

## Overview

This plan implements a `/lean:plan` command that creates Lean-specific implementation plans for theorem proving projects. The command follows the existing `/plan` pattern but specializes in formalization planning with theorem-level granularity, Mathlib discovery, proof strategy formulation, and dependency graph generation.

The implementation extends the existing planning infrastructure with two new agents (lean-research-specialist and lean-plan-architect) and a command that integrates seamlessly with the existing `/lean` execution workflow.

**Key Innovations**:
1. **Theorem-Level Granularity**: Plans track individual theorems as atomic units (following blueprint methodology)
2. **Mathlib Integration**: Automated discovery of reusable lemmas from Mathlib during research phase
3. **Proof Strategy Metadata**: Each theorem includes goal specification, proof approach, and complexity estimate
4. **Dependency Tracking**: Theorem dependencies enable wave-based parallel proving via existing /lean coordinator
5. **Lean Project Detection**: Automatic validation of Lean project structure (lakefile.toml)

---

## Research Summary

Based on the research reports, the following key findings inform this implementation:

**From Infrastructure Research (Report 001)**:
- The `/lean` command already supports plan-based execution with 3-tier Lean file discovery
- Wave-based parallel execution via lean-coordinator provides 40-60% time savings
- lean-lsp-mcp provides 17 MCP tools including `lean_local_search` (no rate limits)
- Plan metadata field `**Lean File**` enables Tier 1 discovery
- Progress tracking via plan markers `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`

**From Best Practices Research (Report 002)**:
- Blueprint methodology works at theorem-level granularity (proven in PFR formalization, Liquid Tensor Experiment)
- AI provers require rich context (up to 163K tokens for DeepSeek-Prover-V2)
- Dependency graphs enable parallel proof attempts
- Mathlib survey during planning prevents reinventing 210,000+ proven theorems
- Iteration metadata helps track proof complexity and strategy evolution

**Recommended Approach**:
Create `/lean:plan` as a separate command (not extending `/plan`) to provide Lean-specific features (`--project` flag, theorem validation, dependency acyclicity checks) while maintaining explicit naming and specialized agent delegation.

---

## Success Criteria
- [ ] `/lean:plan` command creates valid Lean implementation plans with theorem specifications
- [ ] Plans include Mathlib research identifying reusable lemmas
- [ ] Each theorem has goal specification, proof strategy, and complexity estimate
- [ ] Dependency validation ensures acyclic theorem dependencies
- [ ] Plans execute successfully with `/lean` command in plan-based mode
- [ ] Documentation provides clear usage examples and integration workflow
- [ ] Lean project detection validates lakefile.toml presence

---

## Technical Design

### Architecture Overview

The `/lean:plan` command follows the standard research-and-plan workflow with Lean-specific extensions:

```
/lean:plan "<description>" [--file <path>] [--complexity 1-4] [--project <path>]

Block 1a: Setup & State Initialization
├─ Argument parsing (description, --file, --complexity, --project)
├─ Lean project detection (lakefile.toml validation)
├─ Project directory detection (.claude/)
├─ Library sourcing (error-handling, state-persistence, workflow-state-machine)
└─ Workflow state initialization

Block 1b: Topic Name Pre-Calculation
├─ Pre-calculate TOPIC_NAME_FILE path
└─ Persist for Block 1b-exec validation

Block 1b-exec: Topic Name Generation [HARD BARRIER]
└─ Invoke topic-naming-agent via Task tool

Block 1c: Hard Barrier Validation
└─ Validate topic name file exists

Block 1d: Topic Path Initialization
├─ Read topic name from file
├─ Initialize workflow paths with topic name
├─ Archive prompt file (if --file used)
└─ Persist Lean project path

Block 1e: Research Initiation [HARD BARRIER]
└─ Invoke lean-research-specialist agent via Task tool
    ├─ Mathlib theorem discovery
    ├─ Proof pattern analysis
    ├─ Project architecture review
    └─ Research report creation

Block 2: Research Verification and Planning Setup
├─ Verify research artifacts (reports/ directory, file count)
├─ Transition to PLAN state
├─ Prepare plan path
├─ Extract project standards
├─ Extract Lean project standards (LEAN_STYLE_GUIDE.md if exists)
└─ Invoke lean-plan-architect agent via Task tool

Block 3: Plan Verification and Completion
├─ Verify plan artifacts (file exists, size >= 500 bytes)
├─ Lean-specific validation:
│   ├─ Theorem count > 0
│   ├─ Goal specifications present
│   └─ Dependency acyclicity check (via dependency-analyzer)
├─ Transition to COMPLETE state
├─ Display console summary
└─ Emit PLAN_CREATED signal
```

### Component Interactions

```
/lean:plan command
    │
    ├──> topic-naming-agent (reused)
    │      └─ Generates semantic topic name
    │
    ├──> lean-research-specialist (new)
    │      ├─ Mathlib theorem search
    │      ├─ Proof pattern analysis
    │      ├─ Project architecture review
    │      └─ Research report creation
    │
    └──> lean-plan-architect (new)
           ├─ Theorem dependency analysis
           ├─ Wave structure generation
           ├─ Proof strategy formulation
           └─ Plan file creation

/lean command (existing)
    │
    └──> Executes plan created by /lean:plan
         ├─ 3-tier Lean file discovery (Tier 1: **Lean File** metadata)
         ├─ lean-coordinator for wave orchestration
         └─ lean-implementer for theorem proving
```

### Lean-Specific Metadata Extensions

Plans created by `/lean:plan` include standard metadata plus Lean-specific fields:

```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: Brief description
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /absolute/path/to/CLAUDE.md
- **Research Reports**: [Report 1](../reports/001-name.md), [Report 2](../reports/002-name.md)
- **Lean File**: /absolute/path/to/ProofChecker/Module/File.lean  # Tier 1 discovery
- **Lean Project**: /absolute/path/to/project/  # lakefile.toml location
```

### Theorem Phase Format

Each phase represents one or more related theorems with explicit specifications:

```markdown
### Phase 1: Basic Commutativity Properties [COMPLETE]
dependencies: []

**Objective**: Prove commutativity for addition and multiplication

**Complexity**: Low

**Theorems**:
- [x] `theorem_add_comm`: Prove addition commutativity
  - Goal: `∀ a b : Nat, a + b = b + a`
  - Strategy: Use `Nat.add_comm` from Mathlib via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours

- [x] `theorem_mul_comm`: Prove multiplication commutativity
  - Goal: `∀ a b : Nat, a * b = b * a`
  - Strategy: Use `Nat.mul_comm` from Mathlib via `exact` tactic
  - Complexity: Simple (direct application)
  - Estimated: 0.5 hours

**Testing**:
```bash
# Verify compilation
lake build

# Check no sorry markers
grep -c "sorry" ProofChecker/Module/File.lean

# Verify no diagnostics
# (via lean-implementer using lean_diagnostic_messages)
```

**Expected Duration**: 1 hour

---

### Phase 2: Derived Ring Properties [COMPLETE]
dependencies: [1]

**Objective**: Prove distributivity using Phase 1 theorems

**Complexity**: Medium

**Theorems**:
- [x] `theorem_distributivity`: Prove left distributivity
  - Goal: `∀ a b c : Nat, (a + b) * c = a * c + b * c`
  - Strategy: Apply Phase 1 theorems + `ring` tactic
  - Complexity: Medium (tactic combination)
  - Prerequisites: `theorem_add_comm`, `theorem_mul_comm`
  - Estimated: 2 hours

**Testing**:
```bash
lake build
# Run tests if test suite exists
```

**Expected Duration**: 2 hours
```

### Validation Requirements

Block 3 includes Lean-specific validation beyond standard plan verification:

```bash
# 1. Theorem count validation
THEOREM_COUNT=$(grep -c "^- \[ \] \`theorem_" "$PLAN_PATH" || echo "0")
if [ "$THEOREM_COUNT" -eq 0 ]; then
  log_command_error "validation_error" "Plan has no theorem specifications" "path=$PLAN_PATH"
  exit 1
fi

# 2. Goal specification validation
GOAL_COUNT=$(grep -c "  - Goal:" "$PLAN_PATH" || echo "0")
if [ "$GOAL_COUNT" -lt "$THEOREM_COUNT" ]; then
  echo "WARNING: Not all theorems have goal specifications ($GOAL_COUNT/$THEOREM_COUNT)"
fi

# 3. Dependency acyclicity check
bash "$CLAUDE_LIB/util/dependency-analyzer.sh" "$PLAN_PATH" > /tmp/lean_plan_deps.json
CYCLE_CHECK=$(jq -r '.errors[] | select(.type == "circular_dependency")' /tmp/lean_plan_deps.json)
if [ -n "$CYCLE_CHECK" ]; then
  log_command_error "validation_error" "Circular theorem dependencies detected" "$CYCLE_CHECK"
  exit 1
fi

# 4. Lean file metadata validation
if ! grep -q "^\- \*\*Lean File\*\*:" "$PLAN_PATH"; then
  echo "WARNING: Plan missing **Lean File** metadata (Tier 1 discovery will fail)"
fi
```

---

## Implementation Phases

### Phase 1: Command File Creation [COMPLETE]
dependencies: []

**Objective**: Create `/lean:plan` command following `/plan` pattern with Lean-specific argument parsing and validation

**Complexity**: Medium

**Tasks**:
- [x] Create `.claude/commands/lean_plan.md` file
- [x] Copy structure from `.claude/commands/plan.md` as template
- [x] Add frontmatter metadata (description, allowed-tools, model)
- [x] Implement Block 1a: Argument parsing
  - [x] Parse feature description (required)
  - [x] Parse `--file <path>` flag (optional, for long prompts)
  - [x] Parse `--complexity 1-4` flag (default: 3)
  - [x] Parse `--project <path>` flag (optional, auto-detect if omitted)
- [x] Implement Lean project detection
  - [x] Search for `lakefile.toml` in provided path or cwd
  - [x] Validate project structure
  - [x] Set `LEAN_PROJECT_PATH` variable
- [x] Implement project directory detection (`.claude/` location)
- [x] Source required libraries (error-handling, state-persistence, workflow-state-machine)
- [x] Initialize error logging with `ensure_error_log_exists`
- [x] Set workflow metadata (`COMMAND_NAME="/lean:plan"`, `WORKFLOW_ID`, `USER_ARGS`)
- [x] Initialize workflow state machine

**Affected Files**:
- New: `.claude/commands/lean_plan.md`

**Testing**:
```bash
# Test argument parsing
/lean:plan "test formalization" --complexity 2

# Test --file flag
echo "Formalize group homomorphism theorems" > /tmp/prompt.txt
/lean:plan --file /tmp/prompt.txt

# Test --project flag
/lean:plan "test" --project ~/ProofChecker

# Test Lean project detection failure
cd /tmp
/lean:plan "test"  # Should fail with "No Lean project found" error
```

**Expected Duration**: 2 hours

---

### Phase 2: Agent Creation - lean-research-specialist [COMPLETE]
dependencies: []

**Objective**: Create Lean-specific research agent for Mathlib discovery and proof pattern analysis

**Complexity**: High

**Tasks**:
- [x] Create `.claude/agents/lean-research-specialist.md` file
- [x] Add frontmatter:
  - [x] `allowed-tools: Read, Grep, Glob, Bash, WebSearch`
  - [x] `description: Lean 4 formalization research specialist for Mathlib and proof pattern analysis`
  - [x] `model: sonnet-4.5`
  - [x] `model-justification: Deep Mathlib analysis, proof pattern recognition, formalization strategy`
- [x] Write behavioral guidelines section:
  - [x] Mathlib theorem discovery workflow
    - [x] Use `grep` to search Lean project for existing formalizations
    - [x] Use `WebSearch` for Mathlib documentation
    - [x] Document theorem names, types, locations, usage patterns
  - [x] Proof pattern analysis workflow
    - [x] Identify common tactic sequences for goal types
    - [x] Note difficult proofs requiring custom lemmas
    - [x] Document alternative formalization approaches
  - [x] Project architecture review workflow
    - [x] Read existing module structure
    - [x] Extract naming conventions from style guide (if exists)
    - [x] Document import patterns
  - [x] Documentation survey workflow
    - [x] Read LEAN_STYLE_GUIDE.md (if exists)
    - [x] Read TESTING_STANDARDS.md (if exists)
    - [x] Extract quality metrics
- [x] Define research report format template
  - [x] Mathlib theorems section (theorem name, type, location, usage)
  - [x] Proof patterns section (tactic sequences, examples)
  - [x] Project structure section (module hierarchy, conventions)
  - [x] Formalization strategy section (recommendations, complexity estimates)
- [x] Add completion criteria section
  - [x] Report file created at provided path
  - [x] All research categories covered
  - [x] Return signal: `REPORT_CREATED: /path/to/report.md`

**Affected Files**:
- New: `.claude/agents/lean-research-specialist.md`

**Testing**:
```bash
# Manually invoke agent via Task tool to test research workflow
# (Full integration testing in Phase 4)

# Verify agent creates research report with Mathlib findings
grep -l "Mathlib" /path/to/test/report.md

# Verify proof patterns documented
grep -l "Tactic Sequences" /path/to/test/report.md
```

**Expected Duration**: 3 hours

---

### Phase 3: Agent Creation - lean-plan-architect [COMPLETE]
dependencies: []

**Objective**: Create Lean-specific planning agent for theorem-level plan generation with dependency tracking

**Complexity**: High

**Tasks**:
- [x] Create `.claude/agents/lean-plan-architect.md` file
- [x] Copy structure from `.claude/agents/plan-architect.md` as base template
- [x] Update frontmatter:
  - [x] `allowed-tools: Read, Write, Edit, Bash`
  - [x] `description: Lean 4 formalization implementation plan creation specialist`
  - [x] `model: sonnet-4.5`
  - [x] `model-justification: Theorem dependency analysis, proof strategy formulation, effort estimation`
- [x] Extend behavioral guidelines with Lean-specific sections:
  - [x] Theorem dependency analysis
    - [x] Extract theorem prerequisites from research reports
    - [x] Build dependency graph (theorem → theorem edges)
    - [x] Validate acyclicity (no circular dependencies)
  - [x] Wave structure generation
    - [x] Group independent theorems into parallel waves
    - [x] Respect theorem dependencies
    - [x] Optimize for parallelization (40-60% time savings target)
  - [x] Proof strategy formulation
    - [x] Specify Mathlib theorems to use (from research reports)
    - [x] Suggest tactic sequences (`exact`, `rw`, `ring`, `simp`, etc.)
    - [x] Assess complexity (Simple/Medium/Complex)
  - [x] Effort estimation
    - [x] Simple theorems: 0.5-1 hour (exact application)
    - [x] Medium theorems: 1-3 hours (tactic combination)
    - [x] Complex theorems: 3-6 hours (custom lemmas, deep reasoning)
  - [x] Lean-specific metadata
    - [x] Include `**Lean File**` field in metadata (Tier 1 discovery)
    - [x] Include `**Lean Project**` field (lakefile.toml location)
    - [x] Add theorem count metrics to summary
- [x] Add theorem phase format template:
  - [x] Phase heading with status marker
  - [x] Theorem checkbox items with backtick-wrapped names
  - [x] Goal specification (formal Lean 4 type)
  - [x] Proof strategy (high-level approach)
  - [x] Complexity assessment (Simple/Medium/Complex)
  - [x] Estimated duration
- [x] Update completion criteria:
  - [x] All theorems have goal specifications
  - [x] All theorems have proof strategies
  - [x] Dependency graph is acyclic
  - [x] Return signal: `PLAN_CREATED: /path/to/plan.md`

**Affected Files**:
- New: `.claude/agents/lean-plan-architect.md`

**Testing**:
```bash
# Manually invoke agent via Task tool with sample research reports
# Verify plan includes theorem-level tasks

# Check theorem specifications
grep -c "- \[ \] \`theorem_" /path/to/test/plan.md

# Check goal specifications
grep -c "  - Goal:" /path/to/test/plan.md

# Verify dependency format
grep "dependencies: \[" /path/to/test/plan.md
```

**Expected Duration**: 3 hours

---

### Phase 4: Command Integration and Workflow Orchestration [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Complete command workflow blocks for agent delegation and artifact verification

**Complexity**: Medium

**Tasks**:
- [x] Implement Block 1b: Topic Name Pre-Calculation (in `.claude/commands/lean_plan.md`)
  - [x] Pre-calculate `TOPIC_NAME_FILE` path
  - [x] Validate path is absolute
  - [x] Persist for Block 1b-exec and Block 1c
- [x] Implement Block 1b-exec: Topic Name Generation [HARD BARRIER]
  - [x] Invoke topic-naming-agent via Task tool
  - [x] Pass feature description or prompt file content
  - [x] Wait for completion
- [x] Implement Block 1c: Hard Barrier Validation
  - [x] Verify topic name file exists at pre-calculated path
  - [x] Handle fallback naming if agent failed
- [x] Implement Block 1d: Topic Path Initialization
  - [x] Read topic name from file
  - [x] Create classification JSON for `initialize_workflow_paths`
  - [x] Initialize workflow paths
  - [x] Archive prompt file (if `--file` was used)
  - [x] Persist `LEAN_PROJECT_PATH` and `LEAN_FILE_PATH` (if discoverable)
- [x] Implement Block 1e: Research Initiation [HARD BARRIER]
  - [x] Prepare research prompt with Lean project context
  - [x] Invoke lean-research-specialist via Task tool
  - [x] Pass feature description, Lean project path, complexity level
  - [x] Wait for completion
- [x] Implement Block 2: Research Verification and Planning Setup
  - [x] Verify research artifacts (reports/ directory exists, file count > 0)
  - [x] Transition workflow state to PLAN
  - [x] Prepare plan path using `create_topic_artifact`
  - [x] Extract project standards using `format_standards_for_prompt`
  - [x] Extract Lean project standards (search for LEAN_STYLE_GUIDE.md, TESTING_STANDARDS.md)
  - [x] Invoke lean-plan-architect via Task tool with all context
  - [x] Wait for completion
- [x] Implement Block 3: Plan Verification and Completion
  - [x] Verify plan file exists and size >= 500 bytes
  - [x] Run Lean-specific validation (theorem count, goals, acyclicity)
  - [x] Detect Phase 0 (Standards Divergence) if present
  - [x] Transition workflow state to COMPLETE
  - [x] Display console summary with Lean-specific metrics
  - [x] Emit `PLAN_CREATED` signal

**Affected Files**:
- Modified: `.claude/commands/lean_plan.md`

**Testing**:
```bash
# End-to-end workflow test
/lean:plan "Formalize basic arithmetic commutativity theorems" --project ~/ProofChecker

# Verify topic directory created
ls -la .claude/specs/ | grep lean

# Verify research report created
ls -la .claude/specs/*/reports/

# Verify plan created
ls -la .claude/specs/*/plans/

# Verify plan has theorem specifications
grep -c "theorem_" .claude/specs/*/plans/*.md

# Test plan execution with /lean command
/lean .claude/specs/*/plans/*.md --prove-all
```

**Expected Duration**: 2 hours

---

### Phase 5: Documentation and Command Reference [COMPLETE]
dependencies: [4]

**Objective**: Create comprehensive documentation for `/lean:plan` command usage and integration

**Complexity**: Low

**Tasks**:
- [x] Create command guide file: `.claude/docs/guides/commands/lean-plan-command-guide.md`
- [x] Write command guide sections:
  - [x] Overview (purpose, when to use)
  - [x] Syntax and arguments
  - [x] Usage examples:
    - [x] Basic usage (simple formalization)
    - [x] Using `--file` flag (long prompt)
    - [x] Using `--project` flag (explicit project)
    - [x] Using `--complexity` flag (research depth)
  - [x] Integration with /lean workflow
    - [x] Planning phase: `/lean:plan`
    - [x] Execution phase: `/lean plan.md --prove-all`
    - [x] Iteration phase: `/lean plan.md --max-iterations=5`
  - [x] Plan format explanation
    - [x] Metadata fields (Lean File, Lean Project)
    - [x] Theorem phase structure
    - [x] Goal specifications
    - [x] Proof strategies
    - [x] Dependency syntax
  - [x] Troubleshooting section
    - [x] Lean project not found
    - [x] Circular dependencies detected
    - [x] No theorems in plan
    - [x] Research phase failures
- [x] Update command reference: `.claude/docs/reference/standards/command-reference.md`
  - [x] Add `/lean:plan` entry with syntax
  - [x] Link to command guide
- [x] Update CLAUDE.md (if needed)
  - [x] Add reference to Lean planning workflow in relevant section
- [x] Create example plan in documentation
  - [x] Sample formalization project
  - [x] Annotated plan showing all features

**Affected Files**:
- New: `.claude/docs/guides/commands/lean-plan-command-guide.md`
- Modified: `.claude/docs/reference/standards/command-reference.md`

**Testing**:
```bash
# Verify documentation links are valid
bash .claude/scripts/validate-all-standards.sh --links

# Verify README structure
bash .claude/scripts/validate-all-standards.sh --readme

# Manual review: Verify examples in command guide work as documented
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Unit Testing (Per Phase)

Each phase includes inline testing requirements:
- Phase 1: Argument parsing validation, Lean project detection
- Phase 2: lean-research-specialist output format validation
- Phase 3: lean-plan-architect theorem specification validation
- Phase 4: End-to-end workflow integration
- Phase 5: Documentation link validation

### Integration Testing

After Phase 4 completion, run full integration tests:

```bash
# Test 1: Simple formalization (complexity 2, few theorems)
/lean:plan "Prove basic Nat arithmetic commutativity" --complexity 2
/lean .claude/specs/*/plans/*.md --prove-all

# Test 2: Medium formalization (complexity 3, Mathlib integration)
/lean:plan "Formalize group homomorphism properties" --complexity 3 --project ~/ProofChecker
/lean .claude/specs/*/plans/*.md --prove-all

# Test 3: Complex formalization (complexity 4, deep research)
/lean:plan --file prompts/tm-perpetuity-formalization.md --complexity 4

# Test 4: Error handling (no Lean project)
cd /tmp
/lean:plan "test" 2>&1 | grep "No Lean project found"

# Test 5: Circular dependency detection
# (Create plan manually with circular deps, run validation)
bash .claude/lib/util/dependency-analyzer.sh malformed-plan.md
```

### Validation Requirements

All plans created by `/lean:plan` must pass:
1. Standard plan metadata validation (via `validate-plan-metadata.sh`)
2. Lean-specific theorem count validation (> 0 theorems)
3. Goal specification validation (goals match theorem count)
4. Dependency acyclicity validation (via `dependency-analyzer.sh`)
5. Lean file metadata validation (`**Lean File**` field present)

### Success Metrics

Implementation is successful if:
- `/lean:plan` creates valid plans that execute with `/lean`
- Plans include Mathlib research identifying reusable lemmas
- Theorem specifications include goals, strategies, complexity
- Dependency graphs are acyclic and enable parallel proving
- Documentation provides clear usage examples
- Integration with existing workflow is seamless

---

## Documentation Requirements

### Command Guide (.claude/docs/guides/commands/lean-plan-command-guide.md)

**Required Sections**:
1. Overview and Purpose
2. Syntax and Arguments
3. Usage Examples (5+ examples covering all flags)
4. Integration with /lean Workflow
5. Plan Format Explanation
6. Troubleshooting

**Cross-References**:
- Link to `/lean` command guide
- Link to plan-architect agent documentation
- Link to research-specialist agent documentation
- Link to blueprint methodology references (from research reports)

### Command Reference Update

Add `/lean:plan` entry to `.claude/docs/reference/standards/command-reference.md`:

```markdown
### /lean:plan

**Syntax**: `/lean:plan "<description>" [--file <path>] [--complexity 1-4] [--project <path>]`

**Description**: Create Lean-specific implementation plan for theorem proving projects with Mathlib research and proof strategies

**Arguments**:
- `description`: Natural language formalization goal
- `--file <path>`: Path to file with detailed prompt (optional)
- `--complexity 1-4`: Research depth (default: 3)
- `--project <path>`: Lean project root (auto-detect if omitted)

**Workflow**: research-and-plan

**Related**: `/lean`, `/plan`

**Guide**: [Lean Plan Command Guide](.claude/docs/guides/commands/lean-plan-command-guide.md)
```

### README Updates

No new README files required (commands/ directory already has README).

---

## Dependencies

### External Dependencies
- Existing `/plan` command (template)
- Existing `topic-naming-agent` (reused)
- Existing `plan-architect` agent (template for lean-plan-architect)
- Existing `research-specialist` agent (template for lean-research-specialist)
- Existing `dependency-analyzer.sh` utility (acyclicity validation)
- Existing workflow state machine library
- Existing error logging infrastructure

### Lean Project Dependencies
- Lean 4 installation (for project detection validation)
- Lean projects must have `lakefile.toml` (standard Lake project structure)
- Optional: LEAN_STYLE_GUIDE.md for project-specific standards
- Optional: TESTING_STANDARDS.md for test requirements

### Integration Points
- `/lean` command consumes plans created by `/lean:plan`
- lean-coordinator parses phase dependencies from plan
- lean-implementer proves theorems specified in plan
- Plan metadata (`**Lean File**`) enables Tier 1 discovery

---

## Risk Analysis

### High Risk Items

1. **Theorem Specification Complexity**
   - **Risk**: Incorrect goal types or proof strategies lead to unprovable theorems
   - **Mitigation**: lean-research-specialist validates goal types via Lean project inspection during research phase
   - **Fallback**: Plan includes alternative proof strategies; lean-implementer can iterate with different approaches

2. **Dependency Graph Accuracy**
   - **Risk**: Missing dependencies cause premature parallel execution; circular dependencies block execution
   - **Mitigation**: dependency-analyzer.sh validates acyclicity in Block 3; lean-plan-architect uses research findings to identify theorem prerequisites
   - **Fallback**: /lean command fails gracefully with clear error message; user revises plan manually

### Medium Risk Items

3. **Mathlib Discovery Coverage**
   - **Risk**: lean-research-specialist misses relevant Mathlib theorems, leading to reinvention
   - **Mitigation**: Multi-strategy search (grep local project, WebSearch Mathlib docs, explicit prompt to check common namespaces)
   - **Fallback**: lean-implementer has access to `lean_local_search` and other MCP tools during execution to find theorems

4. **Lean Project Detection False Negatives**
   - **Risk**: Valid Lean project not detected due to non-standard structure
   - **Mitigation**: `--project` flag allows explicit path specification; detection looks for lakefile.toml (standard)
   - **Fallback**: Clear error message guides user to use `--project` flag

### Low Risk Items

5. **Agent Delegation Failures**
   - **Risk**: lean-research-specialist or lean-plan-architect fails to produce artifacts
   - **Mitigation**: Hard barrier validation checks file existence and size; error logging tracks agent failures
   - **Fallback**: User receives clear error with agent output; can retry with different complexity level

---

## Performance Considerations

### Execution Time Estimates

- **Simple Plan** (2-5 theorems, complexity 2): 2-3 minutes
  - Research: 1 minute (limited Mathlib search)
  - Planning: 1 minute (simple dependency graph)

- **Medium Plan** (5-15 theorems, complexity 3): 5-8 minutes
  - Research: 3 minutes (comprehensive Mathlib search)
  - Planning: 2-3 minutes (theorem dependency analysis)

- **Complex Plan** (15+ theorems, complexity 4): 10-15 minutes
  - Research: 6-8 minutes (deep Mathlib survey, proof pattern analysis)
  - Planning: 4-5 minutes (complex dependency graph, wave structure optimization)

### Optimization Opportunities

1. **Parallel Research**: If multiple research categories are independent, lean-research-specialist could delegate sub-tasks in parallel
2. **Mathlib Cache**: Cache Mathlib search results locally to avoid repeated WebSearch queries
3. **Incremental Planning**: For very large projects, support multi-phase planning (create high-level plan, expand phases on-demand)

---

## Future Enhancements

### Potential Extensions (Out of Scope for This Plan)

1. **Blueprint Integration**: Generate LaTeX blueprint from plan using leanblueprint format
2. **Dependency Visualization**: Generate DOT/GraphViz dependency graph for visual review
3. **AI Prover Hints**: Include DeepSeek-Prover-V2 or COPRA-specific context in plan metadata
4. **Mathlib Contribution Path**: Flag theorems suitable for Mathlib PR with contribution checklist
5. **Interactive Planning**: Support iterative refinement via `/lean:revise` command
6. **Test Case Generation**: Automatically generate concrete examples for each theorem
7. **Proof Strategy Selection**: Use ML model to predict best proof strategy based on goal type

---

## Completion Checklist

Before marking this plan complete, verify:

- [ ] All 5 phases completed with checkboxes marked
- [ ] `/lean:plan` command creates valid plans
- [ ] Plans execute successfully with `/lean` command
- [ ] All validation checks pass (metadata, theorems, dependencies)
- [ ] Documentation complete with usage examples
- [ ] Integration tests pass (simple, medium, complex plans)
- [ ] Error handling tested (no Lean project, circular deps, etc.)
- [ ] Command added to command reference documentation
- [ ] No regressions in existing `/plan` or `/lean` commands
