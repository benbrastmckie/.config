# Workflow Efficiency Guide

**Path**: docs → guides → efficiency-guide.md

This guide documents the efficiency enhancements implemented in Phase 4 of the agentic workflow system, including dynamic agent selection, progress streaming, intelligent parallelization, and the interactive plan wizard.

## Overview

The efficiency enhancements provide:

- **Dynamic Agent Selection**: Automatic selection of optimal agents based on phase complexity
- **Progress Streaming**: Real-time progress updates during long operations
- **Intelligent Parallelization**: Parallel phase execution with dependency management
- **Plan Wizard**: Interactive guided plan creation

**Expected Impact**:
- 15-30% faster execution from optimal agent selection
- Better user experience with real-time progress feedback
- 30-50% faster complex workflows from parallelization
- Lower barrier to entry with plan wizard

## Dynamic Agent Selection

### Overview

The `/implement` command automatically analyzes each phase and selects the optimal agent based on complexity and type. This ensures specialized agents handle appropriate tasks while avoiding overhead for simple operations.

### Complexity Scoring Algorithm

Phases are scored on a 0-10 scale:

```
score = 0
score += count_keywords(phase_name, ["refactor", "architecture"]) * 3
score += count_keywords(phase_name, ["implement", "create"]) * 2
score += count_keywords(phase_name, ["fix", "update"]) * 1
score += count_keywords(tasks, ["test", "verify"]) * 0.5
score += estimated_file_count * 0.5
score += (task_count / 5)
```

**Keyword Weighting**:
- **High complexity** (3 points): "refactor", "architecture", "redesign", "overhaul"
- **Medium complexity** (2 points): "implement", "create", "build", "develop"
- **Low complexity** (1 point): "fix", "update", "modify", "adjust"
- **Test indicators** (0.5 points): "test", "verify", "validate", "check"

**File Count Estimation**:
- Parse task descriptions for file references
- Count explicit file paths mentioned
- Add 0.5 points per file

**Task Count Factor**:
- Divide task count by 5
- More tasks = higher complexity

### Agent Selection Logic

Based on complexity score:

```
if score 0-2:
  → Direct execution (no agent)
  → Simple tasks don't need delegation overhead

elif score 3-5:
  → code-writer agent
  → Standard complexity, basic agent sufficient

elif score 6-7:
  → code-writer agent + "think" mode
  → Moderate complexity, needs careful planning

elif score 8-9:
  → code-writer agent + "think hard" mode
  → High complexity, needs deep analysis

elif score 10+:
  → code-writer agent + "think harder" mode
  → Critical complexity, maximum reasoning
```

**Special Case Detection**:
- **"documentation" or "README" in phase name** → doc-writer agent
- **"test" in phase name** → test-specialist agent
- **"debug" or "investigate" in phase name** → debug-assistant agent

### Usage

Agent selection happens automatically during `/implement` execution:

```bash
# The command analyzes each phase before execution
/implement specs/plans/045_feature.md

# Output shows agent selection:
Phase 1: Setup (score: 2) → Direct execution
Phase 2: Core Implementation (score: 6) → code-writer + think
Phase 3: Documentation (detected) → doc-writer
Phase 4: Tests (detected) → test-specialist
```

### Configuration

The complexity scoring is implemented in `.claude/lib/analyze-phase-complexity.sh`:

```bash
# Analyze phase complexity
.claude/lib/analyze-phase-complexity.sh "Phase Name" "task1|task2|task3"

# Output: complexity score (0-10)
```

### Benefits

- **Performance**: Simple tasks execute faster without agent overhead
- **Quality**: Complex tasks get specialized agents with appropriate reasoning
- **Specialization**: Doc and test tasks handled by expert agents
- **Adaptability**: Scoring algorithm can be tuned based on experience

### Examples

**Example 1: Simple Fix (Score: 1)**
```markdown
### Phase 1: Fix typo in README
Tasks:
- [ ] Update README.md line 42 typo

Score: 1 (1 for "fix")
Action: Direct execution (no agent)
```

**Example 2: Standard Implementation (Score: 5)**
```markdown
### Phase 2: Create authentication module
Tasks:
- [ ] Create auth/login.lua
- [ ] Create auth/logout.lua
- [ ] Add session management

Score: 5 (2 for "create" + 3 files * 0.5 + 3 tasks / 5)
Action: code-writer agent
```

**Example 3: Complex Refactor (Score: 8)**
```markdown
### Phase 3: Refactor plugin loading architecture
Tasks:
- [ ] Redesign lazy loading system
- [ ] Refactor plugin manager
- [ ] Update 15+ plugin configurations
- [ ] Add comprehensive tests

Score: 8 (3 for "refactor" + 3 for "redesign" + 15 files * 0.5 / 2)
Action: code-writer + "think hard"
```

**Example 4: Documentation (Detected)**
```markdown
### Phase 4: Update documentation
Tasks:
- [ ] Update README.md
- [ ] Create API documentation

Score: N/A (special case detected: "documentation")
Action: doc-writer agent
```

## Progress Streaming

### Overview

Agents emit progress markers during execution to provide real-time visibility into long-running operations. Commands detect these markers and display them to users.

### Progress Marker Format

Agents emit progress using this format:

```
PROGRESS: <brief-message>
```

**Guidelines for Messages**:
- 5-10 words maximum
- Present continuous tense ("Searching...", "Analyzing...", "Generating...")
- Milestone-based (not continuous updates)
- Actionable and informative

### Agent Implementation

All agents include progress markers at key milestones:

**research-specialist**:
```markdown
PROGRESS: Searching for existing patterns...
PROGRESS: Found 15 files, analyzing...
PROGRESS: Reviewing best practices...
PROGRESS: Generating summary report...
```

**code-writer**:
```markdown
PROGRESS: Analyzing phase requirements...
PROGRESS: Implementing module 1 of 3...
PROGRESS: Running tests...
PROGRESS: Creating git commit...
```

**test-specialist**:
```markdown
PROGRESS: Discovering test files...
PROGRESS: Running test suite...
PROGRESS: Analyzing failures...
PROGRESS: Generating report...
```

**plan-architect**:
```markdown
PROGRESS: Analyzing feature requirements...
PROGRESS: Reviewing research findings...
PROGRESS: Structuring implementation phases...
PROGRESS: Writing plan document...
```

### Command Integration

Commands monitor for progress markers and display them:

**In /implement**:
```markdown
Phase 2: Core Implementation

Delegating to code-writer agent...
└─ Analyzing phase requirements...
└─ Implementing module 1 of 3...
└─ Implementing module 2 of 3...
└─ Implementing module 3 of 3...
└─ Running tests...
└─ Creating git commit...

Phase 2 complete ✓
```

**In /orchestrate**:
```markdown
Research Phase

Launching 3 parallel agents...
├─ Agent 1: Searching for existing patterns...
├─ Agent 2: Reviewing best practices...
└─ Agent 3: Analyzing alternatives...

Research complete ✓
```

### Benefits

- **Visibility**: Users know what's happening during long operations
- **Confidence**: Progress updates confirm the system is working
- **Debugging**: Progress markers help identify where failures occur
- **UX**: Better experience than silent execution

### Implementation

Progress streaming is implemented in agent definitions (`.claude/agents/*.md`) and monitored by commands.

**No configuration needed** - works automatically when agents emit `PROGRESS:` markers.

## Intelligent Parallelization

### Overview

Implementation plans can declare phase dependencies, enabling parallel execution of independent phases while respecting dependency order. This dramatically speeds up complex workflows.

### Dependency Format

Phases declare dependencies using this syntax:

```markdown
### Phase 1: Setup
dependencies: []

### Phase 2: Module A
dependencies: [1]

### Phase 3: Module B
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]
```

**Dependency Rules**:
- `dependencies: []` - No dependencies (can run immediately)
- `dependencies: [1]` - Depends on Phase 1
- `dependencies: [1, 2]` - Depends on Phases 1 AND 2
- Missing `dependencies` field - Treated as sequential (depends on previous phase)

### Execution Waves

The `/implement` command parses dependencies and creates execution waves:

```
Wave 1: [Phase 1]           (no dependencies)
Wave 2: [Phase 2, Phase 3]  (both depend only on Phase 1 - parallel)
Wave 3: [Phase 4]           (depends on Phases 2 and 3)
```

**Execution Rules**:
- Phases in the same wave execute in parallel
- Maximum 3 concurrent phases per wave (configurable)
- Next wave starts only after current wave completes
- If any phase in a wave fails, execution stops

### Wave-Based Execution

```bash
/implement specs/plans/046_parallel_example.md

Analyzing phase dependencies...
Found 4 phases, 3 execution waves

Wave 1: Executing Phase 1...
└─ Phase 1 complete ✓

Wave 2: Executing Phases 2 and 3 in parallel...
├─ Phase 2: Module A [running]
└─ Phase 3: Module B [running]
├─ Phase 2 complete ✓
└─ Phase 3 complete ✓

Wave 3: Executing Phase 4...
└─ Phase 4 complete ✓

All phases complete ✓
Total time: 2m 15s (vs 4m 30s sequential - 50% faster)
```

### Creating Parallel Plans

**Example: Independent Modules**

```markdown
### Phase 1: Project Setup
dependencies: []
Tasks:
- [ ] Initialize directory structure
- [ ] Configure build system

### Phase 2: Backend API
dependencies: [1]
Tasks:
- [ ] Implement REST endpoints
- [ ] Add database layer

### Phase 3: Frontend UI
dependencies: [1]
Tasks:
- [ ] Create React components
- [ ] Add state management

### Phase 4: Integration Tests
dependencies: [2, 3]
Tasks:
- [ ] Write E2E tests
- [ ] Configure CI/CD
```

**Execution**:
- Wave 1: Phase 1 (setup)
- Wave 2: Phases 2 and 3 in parallel (backend and frontend)
- Wave 3: Phase 4 (integration tests)

**Example: Diamond Pattern**

```markdown
### Phase 1: Core Module
dependencies: []

### Phase 2: Feature A
dependencies: [1]

### Phase 3: Feature B
dependencies: [1]

### Phase 4: Feature C
dependencies: [1]

### Phase 5: Integration
dependencies: [2, 3, 4]
```

**Execution**:
- Wave 1: Phase 1
- Wave 2: Phases 2, 3, 4 in parallel (max 3 concurrent)
- Wave 3: Phase 5

### Safety and Error Handling

**Concurrent Limit**:
- Maximum 3 phases execute concurrently
- Prevents resource exhaustion
- Configurable via environment variable

**Fail-Fast**:
- If any phase in a wave fails, stop execution
- Preserve checkpoints for completed phases
- Report which phase failed and why

**Checkpoint Preservation**:
- Each phase completion creates a checkpoint
- Partial work is saved even on failure
- Can resume from last successful wave

### Dependency Parser

The dependency parser is implemented in `.claude/lib/parse-phase-dependencies.sh`:

```bash
# Parse dependencies and generate execution waves
.claude/lib/parse-phase-dependencies.sh plan_file.md

# Output: execution waves in JSON format
{
  "wave_1": [1],
  "wave_2": [2, 3],
  "wave_3": [4]
}
```

**Validation**:
- Detects circular dependencies (fails with error)
- Validates dependency references (fails if referencing non-existent phase)
- Ensures DAG structure (directed acyclic graph)

### Performance Benefits

**Typical Speedups**:
- **2 parallel phases**: 40-50% faster
- **3 parallel phases**: 60-70% faster
- **Complex workflows** (5+ phases): 30-50% overall speedup

**Best for**:
- Multi-module features (backend + frontend)
- Independent component implementations
- Documentation + code + tests (when independent)

**Not beneficial for**:
- Strictly sequential workflows
- Phases with many interdependencies
- Simple 1-3 phase plans

### Example Parallel Plan

See `.claude/docs/orchestration-guide.md` for a complete example plan with dependencies and expected execution waves.

## Interactive Plan Wizard

### Overview

The `/plan-wizard` command provides an interactive, guided experience for creating implementation plans. Perfect for new users or when you want assistance breaking down a feature.

### Wizard Flow

**Step 1: Feature Description**
```
What would you like to implement?
Describe your feature in 1-2 sentences:
> Add OAuth2 authentication with Google and GitHub
```

**Step 2: Component Identification**
```
Which components will this affect?
Suggested: auth, security, user, api

Enter components (comma-separated) or [Enter] for suggestions:
> auth, security, user, api, config
```

**Step 3: Complexity Assessment**
```
What's the main complexity level?
1. Simple    - Minor changes, single file, < 2 hours
2. Medium    - Multiple files, new functionality, 2-8 hours
3. Complex   - Architecture changes, multiple modules, 8-16 hours
4. Critical  - Major refactor, system-wide impact, > 16 hours

Select (1-4):
> 3
```

**Step 4: Research Decision**
```
Should I research first? (recommended for complex features)

Research will help identify:
- Existing patterns in the codebase
- Best practices and standards
- Alternative approaches

Conduct research? (y/n) [y]:
> y
```

**Step 5: Research Topics** (if research requested)
```
Based on your feature, I suggest researching:
1. Security best practices for OAuth2 (2025)
2. Existing authentication patterns in codebase
3. OAuth2 provider integration approaches

Options: [Enter]/edit/skip
> [Enter]

Launching research agents...
[Agent 1/3] Researching: Security best practices...
[Agent 2/3] Researching: Existing patterns...
[Agent 3/3] Researching: OAuth2 integration...

Research complete ✓
```

**Step 6: Plan Generation**
```
Generating implementation plan...

✅ Plan Created!
Plan: specs/plans/046_oauth2_authentication.md
Phases: 5
Complexity: complex
Research: Yes (3 artifacts)

Next: /implement specs/plans/046_oauth2_authentication.md
```

### Features

**Automatic Suggestions**:
- Component detection based on feature description
- Research topic identification from keywords
- Complexity-based defaults

**Flexibility**:
- Accept suggestions or provide custom inputs
- Skip research for simple features
- Edit suggested research topics

**Integration**:
- Uses `/plan` command internally
- Research agents create artifacts
- Generated plans follow project standards

### When to Use

**Use /plan-wizard when**:
- You're new to the planning system
- You want guidance on scope and components
- You're unsure what research is needed
- You prefer interactive input

**Use /plan directly when**:
- You know exactly what you want
- You have specific research reports to reference
- You want to script/automate plan creation
- You're experienced with the system

### Benefits

- **Lower barrier to entry**: Guides new users through planning
- **Better scope analysis**: Prompts for components and complexity
- **Automatic research**: Identifies and executes research topics
- **Quality plans**: Same quality as manual `/plan` with less effort

## Best Practices

### Dynamic Agent Selection

**Do**:
- Trust the algorithm for most phases
- Review agent selection in complex workflows
- Adjust keyword weighting if needed

**Don't**:
- Manually override unless necessary
- Worry about simple phase overhead (it's minimal)
- Use agent delegation for trivial tasks

### Progress Streaming

**Do**:
- Use progress markers in custom agents (5-10 word messages)
- Emit at meaningful milestones (not continuously)
- Keep messages brief and informative

**Don't**:
- Emit progress every second (too noisy)
- Use long messages (truncate display)
- Mix progress with error messages

### Intelligent Parallelization

**Do**:
- Declare dependencies for independent phases
- Use parallel execution for multi-module features
- Test dependency graph before complex plans

**Don't**:
- Create circular dependencies (will fail)
- Parallelize phases with shared file modifications
- Exceed 3 concurrent phases (resource limits)

### Plan Wizard

**Do**:
- Use for new features when you want guidance
- Accept suggestions when unsure
- Customize inputs for specific needs

**Don't**:
- Use for quick simple changes (use /plan directly)
- Skip research for complex features (wizard recommends it)
- Expect wizard to modify existing plans (use /update-plan)

## Performance Metrics

Track efficiency improvements with these metrics:

**Agent Selection**:
- Measure time saved from specialized agents
- Track accuracy of complexity scoring
- Monitor thinking mode effectiveness

**Progress Streaming**:
- User satisfaction with visibility
- Time to identify stuck operations
- Reduction in "is it working?" questions

**Parallelization**:
- Execution time: parallel vs sequential
- Speedup percentage
- Resource utilization

**Plan Wizard**:
- Time to create plan: wizard vs manual
- Plan quality comparison
- New user adoption rate

## Troubleshooting

### Agent Selection Issues

**Problem**: Wrong agent selected for phase

**Solution**:
1. Check phase name keywords
2. Verify task descriptions
3. Adjust complexity scoring weights in `.claude/lib/analyze-phase-complexity.sh`

### Progress Not Showing

**Problem**: No progress updates during long operations

**Solution**:
1. Verify agents emit `PROGRESS:` markers
2. Check command monitors for markers
3. Ensure progress messages are brief (5-10 words)

### Parallelization Failures

**Problem**: Circular dependency or execution hangs

**Solution**:
1. Validate dependency graph: `.claude/lib/parse-phase-dependencies.sh plan.md`
2. Check for circular references
3. Ensure all dependency phase numbers exist
4. Review concurrent limit (max 3)

### Wizard Not Starting

**Problem**: /plan-wizard command not recognized

**Solution**:
1. Verify file exists: `.claude/commands/plan-wizard.md`
2. Check command is listed in `.claude/commands/README.md`
3. Restart Claude Code session

## References

### Implementation Files
- `.claude/commands/implement.md` - Agent selection and parallel execution
- `.claude/commands/orchestrate.md` - Progress monitoring
- `.claude/commands/plan-wizard.md` - Interactive wizard
- `.claude/agents/*.md` - Progress streaming in agents
- `.claude/lib/analyze-phase-complexity.sh` - Complexity scoring
- `.claude/lib/parse-phase-dependencies.sh` - Dependency parser

### Documentation
- `.claude/docs/orchestration-guide.md` - Example parallel plan
- `.claude/commands/README.md` - Command reference
- Plan 022 - Workflow Efficiency Enhancements implementation plan

### Related Guides
- Agent Performance Guide (Phase 2)
- Workflow Checkpointing (Phase 3)
- Error Enhancement Guide (Phase 3)
