# Phase 3: Skills Expansion - Detailed Implementation

## Metadata
- **Phase Number**: 3
- **Phase Name**: Skills Expansion
- **Dependencies**: [Phase 1, Phase 2]
- **Status**: [NOT STARTED]
- **Estimated Duration**: 20-26 hours
- **Complexity**: Medium-High
- **Parent Plan**: [Three-Tier Agent Improvements Plan](../001-three-tier-agent-improvements-plan.md)

## Overview

This phase extracts three high-priority capabilities as autonomous skills: research-specialist, plan-generator, and test-orchestrator. Skills enable broader applicability through autonomous composition and model-invoked usage, while maintaining backward compatibility with existing Task invocation paths.

**Key Objectives**:
1. Extract research-specialist skill from research-specialist.md agent (lines 1-400)
2. Extract plan-generator skill with delegation to plan-architect agent
3. Create test-orchestrator skill with auto-trigger after implementation phases
4. Update skills catalog and documentation
5. Maintain Task invocation backward compatibility for coordinators

**Expected Benefits**:
- Autonomous research across all workflows (not just /research command)
- Reusable planning logic across /create-plan, /repair, /debug commands
- Auto-triggered testing after implementation (no manual /test invocation)
- Skills catalog expanded from 1 skill to 4 skills

## Stage 1: Research-Specialist Skill Extraction [NOT STARTED]

**Objective**: Extract research-specialist capability as autonomous skill for use across all workflows requiring research

### Implementation Steps

#### Step 1.1: Create Skill Directory Structure

**Tasks**:
- [ ] Create skill directory: `.claude/skills/research-specialist/`
- [ ] Create subdirectories: `scripts/`, `templates/`
- [ ] Create README.md stub for skill documentation
- [ ] Verify directory structure matches skills convention

**Commands**:
```bash
# Create skill directory structure
mkdir -p /home/benjamin/.config/.claude/skills/research-specialist/{scripts,templates}

# Create README stub
cat > /home/benjamin/.config/.claude/skills/research-specialist/README.md <<'EOF'
# Research Specialist Skill

**Status**: In Development

See [SKILL.md](./SKILL.md) for skill definition and usage.
EOF

# Verify structure
ls -la /home/benjamin/.config/.claude/skills/research-specialist/
```

**Validation**:
```bash
# Verify directory exists
test -d /home/benjamin/.config/.claude/skills/research-specialist
test -d /home/benjamin/.config/.claude/skills/research-specialist/scripts
test -d /home/benjamin/.config/.claude/skills/research-specialist/templates
```

**Expected Duration**: 0.5 hours

---

#### Step 1.2: Extract Research Protocol to SKILL.md

**Tasks**:
- [ ] Read research-specialist.md agent (file: `/home/benjamin/.config/.claude/agents/research-specialist.md`)
- [ ] Extract research protocol from lines 1-400 (core research workflow)
- [ ] Convert agent frontmatter to skill frontmatter format
- [ ] Add autonomous invocation detection patterns
- [ ] Keep SKILL.md under 500 lines for token efficiency
- [ ] Write SKILL.md to research-specialist/ directory

**SKILL.md Structure** (based on document-converter template):
```markdown
---
name: research-specialist
description: Codebase research, best practice investigation, and comprehensive report generation. Use when researching existing patterns, analyzing codebases, investigating best practices, or generating detailed research reports.
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
dependencies: []
model: sonnet-4.5
model-justification: Codebase research requires comprehensive analysis, pattern synthesis, and report generation with 28 completion criteria
fallback-model: sonnet-4.5
---

# Research Specialist Skill

Conduct comprehensive codebase research and generate detailed research reports. This skill automatically detects research needs and creates structured reports with findings, recommendations, and implementation guidance.

## Core Capabilities

### Research Modes

**Codebase Analysis**: Analyze existing code patterns, architecture decisions, and implementation approaches.

**Best Practices Investigation**: Research industry best practices, framework conventions, and optimization opportunities.

**Pattern Recognition**: Identify recurring patterns, anti-patterns, and design decisions across codebase.

### Report Generation

- Structured report creation (Metadata, Executive Summary, Findings, Recommendations, Next Steps)
- File path collection with line-level references
- Implementation status tracking
- Cross-reference integration

## Research Protocol

[Include core research workflow from research-specialist.md]

### Phase 1: Topic Analysis
- Parse research topics from prompt
- Identify research scope and boundaries
- Define success criteria

### Phase 2: Codebase Exploration
- Use Grep and Glob for pattern discovery
- Read relevant files for context
- Document findings with file paths and line numbers

### Phase 3: Web Research (Optional)
- WebSearch for best practices when needed
- WebFetch for documentation analysis
- Synthesize external findings with codebase context

### Phase 4: Report Creation
- Create report file at provided REPORT_PATH
- Populate Findings section (minimum 3 findings)
- Add Recommendations section
- Include file path references

### Phase 5: Validation
- Verify report file exists
- Check required sections present
- Validate file path references

## Autonomous Invocation Detection

This skill triggers when Claude detects:
- Keywords: "research", "investigate", "analyze patterns", "best practices", "codebase analysis"
- Questions about existing code patterns
- Requests for architecture analysis
- Comparative analysis of implementation approaches

## Task Invocation Path (Backward Compatibility)

Coordinators can still invoke via Task tool:
```
Task {
  subagent_type: "general-purpose"
  description: "Research [topic] using research-specialist protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as Research Specialist with the tools and constraints
    defined in that file.

    Research topic: [topic description]
    REPORT_PATH: [absolute path to report file]
}
```

## Integration Examples

### Autonomous Invocation
```
User: "Analyze existing authentication patterns in the codebase"
→ Skill auto-invokes: research-specialist
→ Performs codebase analysis
→ Generates research report
→ Returns findings
```

### From Coordinators
```yaml
# research-coordinator agent
skills: research-specialist  # Auto-loads skill
```

### From Commands
```bash
# /research command delegates to research-coordinator
# research-coordinator has skills: research-specialist in frontmatter
# research-coordinator invokes specialists (which may use skill)
```

## Error Handling

### Structured Error Return
When encountering errors, return structured signals:
```
ERROR_CONTEXT: {
  "error_type": "file_error|validation_error|agent_error",
  "message": "Human-readable description",
  "details": {"key": "value"}
}

TASK_ERROR: error_type - Brief message
```

See [Error Handling Guidelines](../../docs/concepts/patterns/error-handling.md) for complete protocol.

## See Also
- [Research Specialist Agent](../../agents/research-specialist.md) - Full agent implementation
- [Research Coordinator](../../agents/research-coordinator.md) - Supervisor for parallel research
- [Research Command Guide](../../docs/guides/commands/research-command-guide.md)
```

**Commands**:
```bash
# Read research-specialist agent for extraction
READ_FILE=/home/benjamin/.config/.claude/agents/research-specialist.md

# Extract and adapt to SKILL.md (manual with Edit tool)
# Focus on research protocol (steps 1-5)
# Remove agent-specific orchestration logic
# Keep skill focused on research execution only
```

**Validation**:
```bash
# Verify SKILL.md exists and is under 500 lines
test -f /home/benjamin/.config/.claude/skills/research-specialist/SKILL.md
LINE_COUNT=$(wc -l < /home/benjamin/.config/.claude/skills/research-specialist/SKILL.md)
[ "$LINE_COUNT" -lt 500 ] || echo "WARNING: SKILL.md exceeds 500 lines ($LINE_COUNT)"

# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('/home/benjamin/.config/.claude/skills/research-specialist/SKILL.md').read().split('---')[1])"
```

**Expected Duration**: 4-6 hours

---

#### Step 1.3: Implement Autonomous Invocation Detection

**Tasks**:
- [ ] Add trigger keywords to SKILL.md description field
- [ ] Document autonomous invocation patterns in SKILL.md
- [ ] Test skill discoverability with sample prompts
- [ ] Verify skill doesn't conflict with explicit Task invocations

**Trigger Keywords** (in description field):
- "research", "investigate", "analyze patterns", "best practices", "codebase analysis", "pattern recognition"

**Testing Autonomous Invocation**:
```
# Test Prompt 1: Direct research request
"Research existing authentication patterns in the codebase"
→ Expected: research-specialist skill triggers

# Test Prompt 2: Best practices investigation
"What are the best practices for error handling in this project?"
→ Expected: research-specialist skill triggers

# Test Prompt 3: Architecture analysis
"Analyze the current state machine architecture"
→ Expected: research-specialist skill triggers
```

**Expected Duration**: 2-3 hours

---

#### Step 1.4: Maintain Task Invocation Backward Compatibility

**Tasks**:
- [ ] Document Task invocation pattern in SKILL.md
- [ ] Verify research-coordinator can still invoke via Task tool
- [ ] Update research-coordinator.md to note skill availability
- [ ] Test both autonomous and Task invocation paths

**Task Invocation Pattern**:
```markdown
## Task Invocation Path (Backward Compatibility)

Coordinators can still invoke research-specialist via Task tool by referencing the agent file:

```
Task {
  subagent_type: "general-purpose"
  description: "Research [topic] using research-specialist protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md
}
```

This pattern maintains backward compatibility while enabling autonomous skill usage.
```

**Validation**:
```bash
# Test Task invocation from research-coordinator
# (manual test during implementation)

# Verify research-coordinator still works after skill extraction
grep -q "research-specialist.md" /home/benjamin/.config/.claude/agents/research-coordinator.md
```

**Expected Duration**: 1-2 hours

---

#### Step 1.5: Update Research-Coordinator for Skill Auto-Loading

**Tasks**:
- [ ] Add `skills: research-specialist` to research-coordinator.md frontmatter
- [ ] Document optional skill auto-loading behavior
- [ ] Test that coordinator can use skill when available
- [ ] Verify fallback to Task invocation if skill unavailable

**Research-Coordinator Frontmatter Update**:
```yaml
---
allowed-tools: Bash, Read, Grep, Glob, WebSearch
description: Research coordinator for parallel research orchestration
model: sonnet-4.5
model-justification: Supervisor orchestration, metadata aggregation, hard barrier enforcement
fallback-model: sonnet-4.5
skills: research-specialist  # Auto-load skill for autonomous research
---
```

**Validation**:
```bash
# Verify skills field added
grep -q "skills: research-specialist" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Test coordinator with skill auto-loading
# (manual test during implementation)
```

**Expected Duration**: 1 hour

---

#### Step 1.6: Create Research-Specialist Skill Documentation

**Tasks**:
- [ ] Write comprehensive README.md (file: `/home/benjamin/.config/.claude/skills/research-specialist/README.md`)
- [ ] Document usage patterns (autonomous, Task, coordinator)
- [ ] Add troubleshooting section
- [ ] Include integration examples

**README.md Structure**:
```markdown
# Research Specialist Skill

Autonomous research capability for codebase analysis, best practice investigation, and comprehensive report generation.

## Overview

The research-specialist skill enables Claude to autonomously conduct research when needs are detected. It creates structured research reports with findings, recommendations, and implementation guidance.

## Usage Patterns

### Autonomous Invocation
[Examples of autonomous triggers]

### Task Invocation
[Backward compatibility pattern]

### Coordinator Integration
[research-coordinator auto-loading]

## Skill Capabilities

[List of research modes and report generation features]

## Integration Examples

[Practical examples with code snippets]

## Troubleshooting

[Common issues and solutions]

## See Also

[Links to related documentation]
```

**Expected Duration**: 2 hours

---

## Stage 2: Plan-Generator Skill Extraction [NOT STARTED]

**Objective**: Extract plan-generator capability as skill with delegation to plan-architect agent

### Implementation Steps

#### Step 2.1: Create Plan-Generator Skill Directory

**Tasks**:
- [ ] Create skill directory: `.claude/skills/plan-generator/`
- [ ] Create subdirectories: `scripts/`, `templates/`
- [ ] Create README.md stub

**Commands**:
```bash
mkdir -p /home/benjamin/.config/.claude/skills/plan-generator/{scripts,templates}

cat > /home/benjamin/.config/.claude/skills/plan-generator/README.md <<'EOF'
# Plan Generator Skill

**Status**: In Development

See [SKILL.md](./SKILL.md) for skill definition and usage.
EOF
```

**Expected Duration**: 0.5 hours

---

#### Step 2.2: Define Skill Delegation Pattern

**Tasks**:
- [ ] Design skill-to-agent delegation pattern
- [ ] Define skill scope: plan creation logic, metadata validation, phase organization
- [ ] Document delegation to plan-architect for complex planning
- [ ] Implement skill as lightweight wrapper with core planning logic

**Skill Delegation Pattern**:

The plan-generator skill focuses on **plan creation logic** and delegates **complex orchestration** to plan-architect agent:

**Skill Scope** (plan-generator):
- Metadata validation (required fields, format checks)
- Phase structure organization (headings, checkboxes, dependencies)
- Complexity calculation
- Tier selection (Level 0/1/2)
- Standards integration

**Agent Scope** (plan-architect):
- Research report integration
- Technical design synthesis
- Phased task breakdown
- Testing strategy formulation
- Documentation requirements analysis

**Delegation Flow**:
```
User: "Create implementation plan for feature X"
→ plan-generator skill detects planning need
→ Validates metadata requirements
→ Delegates to plan-architect agent for detailed planning
→ Validates plan-architect output against standards
→ Returns plan path confirmation
```

**Expected Duration**: 2-3 hours

---

#### Step 2.3: Extract Planning Algorithm from Plan-Architect

**Tasks**:
- [ ] Read plan-architect.md agent (file: `/home/benjamin/.config/.claude/agents/plan-architect.md`)
- [ ] Extract metadata validation logic (lines 220-250)
- [ ] Extract phase structure validation (lines 545-565)
- [ ] Extract complexity calculation formula (lines 98-113)
- [ ] Extract tier selection logic (lines 467-502)
- [ ] Write SKILL.md with extracted logic

**SKILL.md Structure**:
```markdown
---
name: plan-generator
description: Implementation plan generation with metadata validation, phase organization, and standards integration. Use when creating implementation plans, validating plan structure, or organizing phased tasks.
allowed-tools: Read, Write, Edit, Bash
dependencies: []
model: opus-4.1
model-justification: Plan generation requires complexity calculation, metadata validation, standards integration, and architectural planning
fallback-model: sonnet-4.5
---

# Plan Generator Skill

Generate structured implementation plans with metadata validation, phase organization, and standards compliance. This skill delegates complex planning to plan-architect agent while providing core planning utilities.

## Core Capabilities

### Plan Creation Logic
- Metadata validation (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- Phase structure organization (headings, checkboxes, dependencies)
- Complexity calculation and tier selection
- Standards integration and divergence detection

### Metadata Validation
Required fields:
- **Date**: YYYY-MM-DD or YYYY-MM-DD (Revised)
- **Feature**: One-line description (50-100 chars)
- **Status**: [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED]
- **Estimated Hours**: {low}-{high} hours
- **Standards File**: Absolute path to CLAUDE.md
- **Research Reports**: Markdown links or "none"

### Phase Structure Validation
- Phase headings: `### Phase N: Name [NOT STARTED]`
- Tasks: Checkbox format `- [ ]` for /implement compatibility
- Dependencies: `dependencies: [1, 2]` syntax for parallel execution
- Testing sections required per phase

### Complexity Calculation
```
Score = Base(feature type) + Tasks/2 + Files*3 + Integrations*5

Where:
- Base: new=10, enhance=7, refactor=5, fix=3
- Tasks: estimated number of implementation tasks
- Files: estimated files to create/modify
- Integrations: external systems/APIs to integrate

Tier Selection:
- Score <50: Tier 1 (single file)
- Score 50-200: Tier 2 (phase directory)
- Score ≥200: Tier 3 (hierarchical tree)
```

## Skill Delegation Pattern

This skill provides core planning utilities and delegates complex orchestration to plan-architect agent:

```
plan-generator skill (lightweight):
  ↓ metadata validation
  ↓ complexity calculation
  ↓ delegates to plan-architect agent (complex planning)
  ↓ validates plan-architect output
  ↓ returns plan path confirmation
```

**When to Delegate**:
- Research report integration needed
- Technical design synthesis required
- Complex phase breakdown (>5 phases)
- Standards divergence detected

**When NOT to Delegate**:
- Simple metadata validation
- Complexity calculation only
- Plan structure validation
- Tier selection

## Autonomous Invocation Detection

This skill triggers when Claude detects:
- Keywords: "create plan", "implementation plan", "planning", "phased approach"
- Plan structure validation requests
- Metadata validation queries
- Complexity estimation needs

## Integration with Commands

### /create-plan Command
```bash
# /create-plan delegates to plan-generator skill
/create-plan "Feature description" --complexity 2
→ plan-generator validates metadata
→ calculates complexity
→ delegates to plan-architect for detailed planning
→ validates output
→ returns plan path
```

### /repair Command
```bash
# /repair uses plan-generator for fix plan creation
/repair --since 1h --type state_error
→ plan-generator validates repair plan metadata
→ delegates to plan-architect for phase breakdown
→ ensures repair-specific fields present
```

### /debug Command
```bash
# /debug uses plan-generator for investigation plan
/debug "Issue description" --complexity 1
→ plan-generator validates debug plan metadata
→ delegates to plan-architect for investigation phases
```

## Error Handling

### Validation Errors
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Invalid metadata field",
  "details": {"field": "Status", "value": "invalid"}
}

TASK_ERROR: validation_error - Invalid Status field: must be [NOT STARTED], [IN PROGRESS], [COMPLETE], or [BLOCKED]
```

## See Also
- [Plan Architect Agent](../../agents/plan-architect.md) - Full planning agent
- [Plan Metadata Standard](../../docs/reference/standards/plan-metadata-standard.md)
- [Create-Plan Command Guide](../../docs/guides/commands/create-plan-command-guide.md)
```

**Expected Duration**: 5-7 hours

---

#### Step 2.4: Update Commands for Plan-Generator Integration

**Tasks**:
- [ ] Update /create-plan command to delegate to plan-generator skill (file: `/home/benjamin/.config/.claude/commands/create-plan.md`)
- [ ] Update /repair command to use plan-generator for metadata validation (file: `/home/benjamin/.config/.claude/commands/repair.md`)
- [ ] Update /debug command to use plan-generator for plan structure (file: `/home/benjamin/.config/.claude/commands/debug.md`)
- [ ] Test command integrations with skill delegation

**Integration Pattern**:
```markdown
# In /create-plan command

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect via plan-generator skill.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-generator skill delegation"
  prompt: |
    Use the plan-generator skill to create implementation plan.

    The skill will:
    1. Validate metadata requirements
    2. Calculate complexity
    3. Delegate to plan-architect agent for detailed planning
    4. Validate output against standards

    Feature: [feature description]
    PLAN_PATH: [absolute path]
    Research Reports: [reports list if any]
}
```

**Validation**:
```bash
# Verify commands reference plan-generator skill
grep -q "plan-generator" /home/benjamin/.config/.claude/commands/create-plan.md
grep -q "plan-generator" /home/benjamin/.config/.claude/commands/repair.md
grep -q "plan-generator" /home/benjamin/.config/.claude/commands/debug.md
```

**Expected Duration**: 3-4 hours

---

#### Step 2.5: Create Plan-Generator Skill Documentation

**Tasks**:
- [ ] Write comprehensive README.md
- [ ] Document skill delegation pattern
- [ ] Add integration examples for all three commands
- [ ] Include troubleshooting section

**Expected Duration**: 2 hours

---

## Stage 3: Test-Orchestrator Skill Creation [NOT STARTED]

**Objective**: Create test-orchestrator skill with auto-trigger after implementation phases

### Implementation Steps

#### Step 3.1: Create Test-Orchestrator Skill Directory

**Tasks**:
- [ ] Create skill directory: `.claude/skills/test-orchestrator/`
- [ ] Create subdirectories: `scripts/`, `templates/`
- [ ] Create README.md stub

**Commands**:
```bash
mkdir -p /home/benjamin/.config/.claude/skills/test-orchestrator/{scripts,templates}

cat > /home/benjamin/.config/.claude/skills/test-orchestrator/README.md <<'EOF'
# Test Orchestrator Skill

**Status**: In Development

See [SKILL.md](./SKILL.md) for skill definition and usage.
EOF
```

**Expected Duration**: 0.5 hours

---

#### Step 3.2: Extract Test Discovery Logic from /test Command

**Tasks**:
- [ ] Read /test command (file: `/home/benjamin/.config/.claude/commands/test.md`)
- [ ] Extract test discovery logic (glob patterns for test files)
- [ ] Extract framework detection logic (pytest, jest, etc.)
- [ ] Document test discovery in SKILL.md

**Test Discovery Patterns**:
```bash
# From /test command - extract test file patterns
UNIT_TESTS_GLOB="**/*_test.lua,**/*_spec.lua,**/test_*.py,**/*_test.py"
INTEGRATION_TESTS_GLOB="**/integration/**/*_test.*,**/e2e/**/*_test.*"

# Framework detection
detect_test_framework() {
  if [ -f "pytest.ini" ] || grep -q "pytest" "requirements.txt" 2>/dev/null; then
    echo "pytest"
  elif [ -f "package.json" ] && grep -q "jest" "package.json"; then
    echo "jest"
  elif [ -f ".busted" ]; then
    echo "busted"
  else
    echo "unknown"
  fi
}
```

**Expected Duration**: 3-4 hours

---

#### Step 3.3: Extract Test Execution Logic from /test Command

**Tasks**:
- [ ] Extract test running logic per framework
- [ ] Extract test result parsing
- [ ] Document test execution in SKILL.md

**Test Execution Patterns**:
```bash
# From /test command - extract execution logic
run_tests() {
  local framework="$1"
  local test_files="$2"

  case "$framework" in
    pytest)
      pytest "$test_files" --verbose --tb=short
      ;;
    jest)
      npm test "$test_files"
      ;;
    busted)
      busted "$test_files"
      ;;
    *)
      echo "ERROR: Unknown test framework: $framework"
      return 1
      ;;
  esac
}
```

**Expected Duration**: 3-4 hours

---

#### Step 3.4: Extract Coverage Analysis Logic from /test Command

**Tasks**:
- [ ] Extract coverage threshold checking
- [ ] Extract coverage report generation
- [ ] Document coverage analysis in SKILL.md

**Coverage Analysis Patterns**:
```bash
# From /test command - extract coverage logic
check_coverage() {
  local coverage_file="$1"
  local threshold="${2:-80}"

  if [ ! -f "$coverage_file" ]; then
    echo "WARNING: Coverage file not found: $coverage_file"
    return 1
  fi

  # Parse coverage percentage (framework-specific)
  local coverage_pct=$(parse_coverage "$coverage_file")

  if [ "$coverage_pct" -lt "$threshold" ]; then
    echo "ERROR: Coverage $coverage_pct% below threshold $threshold%"
    return 1
  fi

  echo "✓ Coverage: $coverage_pct% (threshold: $threshold%)"
  return 0
}
```

**Expected Duration**: 2-3 hours

---

#### Step 3.5: Implement Autonomous Auto-Trigger After Implementation

**Tasks**:
- [ ] Design auto-trigger detection pattern
- [ ] Document trigger conditions in SKILL.md
- [ ] Test auto-trigger after /implement phases
- [ ] Verify explicit invocation via /test still works

**Auto-Trigger Pattern**:

The test-orchestrator skill auto-triggers when:
1. Implementation phase completes (detected by Phase N: [COMPLETE] marker)
2. Code files modified (detected by git diff or file timestamps)
3. Test files exist in project (detected by test discovery)

**SKILL.md Auto-Trigger Section**:
```markdown
## Autonomous Auto-Trigger Detection

This skill triggers automatically after implementation phases when:

**Trigger Conditions**:
1. Implementation phase marked [COMPLETE]
2. Code files modified (detected via git status or file modification times)
3. Test files exist in project (detected via test discovery)

**Auto-Trigger Flow**:
```
/implement completes Phase 2: [COMPLETE]
→ test-orchestrator detects phase completion
→ discovers test files for modified code
→ runs test suite automatically
→ reports results
```

**Manual Override**:
Use /test command to explicitly invoke test-orchestrator without auto-trigger:
```bash
/test --file path/to/test.py
```

## Integration with /implement Command

The /implement command can check for test-orchestrator skill availability and delegate testing:

```bash
# After phase completion in /implement
if skill_available "test-orchestrator"; then
  # Skill auto-triggers based on phase completion
  echo "✓ Tests will run automatically via test-orchestrator skill"
else
  # Fallback: recommend manual /test invocation
  echo "Recommendation: Run /test to validate implementation"
fi
```
```

**Expected Duration**: 3-4 hours

---

#### Step 3.6: Update /implement Command for Test-Orchestrator Integration

**Tasks**:
- [ ] Update /implement command to support test-orchestrator auto-trigger (file: `/home/benjamin/.config/.claude/commands/implement.md`)
- [ ] Add skill availability check after phase completion
- [ ] Document auto-testing behavior in command guide
- [ ] Test integration with real implementation workflow

**Integration Pattern**:
```markdown
# In /implement command - after phase completion

**Check for Test-Orchestrator Skill**:
```bash
# After phase N marked [COMPLETE]
if command -v claude-skill &>/dev/null && claude-skill list | grep -q "test-orchestrator"; then
  echo "✓ Auto-testing enabled via test-orchestrator skill"
  # Skill will auto-trigger based on phase completion
else
  echo "Recommendation: Run /test to validate implementation"
fi
```
```

**Validation**:
```bash
# Verify /implement references test-orchestrator
grep -q "test-orchestrator" /home/benjamin/.config/.claude/commands/implement.md

# Test auto-trigger during implementation
# (manual integration test)
```

**Expected Duration**: 2-3 hours

---

#### Step 3.7: Create Test-Orchestrator Skill Documentation

**Tasks**:
- [ ] Write comprehensive README.md
- [ ] Document auto-trigger behavior
- [ ] Add integration examples with /implement and /test
- [ ] Include troubleshooting section for auto-trigger issues

**README.md Structure**:
```markdown
# Test Orchestrator Skill

Autonomous test orchestration with auto-trigger after implementation phases.

## Overview

The test-orchestrator skill enables automatic testing after implementation phases complete. It discovers tests, detects frameworks, runs test suites, and analyzes coverage.

## Auto-Trigger Behavior

[Explain trigger conditions and flow]

## Manual Invocation

[Explain /test command usage]

## Integration Examples

[Show /implement and /test integration]

## Troubleshooting

[Common auto-trigger issues and solutions]
```

**Expected Duration**: 2 hours

---

## Stage 4: Skills Catalog Update [NOT STARTED]

**Objective**: Update skills README with all three new skills and update CLAUDE.md

### Implementation Steps

#### Step 4.1: Update Skills README.md

**Tasks**:
- [ ] Add research-specialist to skills catalog (file: `/home/benjamin/.config/.claude/skills/README.md`)
- [ ] Add plan-generator to skills catalog
- [ ] Add test-orchestrator to skills catalog
- [ ] Update skills count from 1 to 4
- [ ] Add usage examples for each skill
- [ ] Update "Available Skills" section

**Skills Catalog Update**:
```markdown
## Available Skills

### [document-converter](document-converter/README.md)
[Existing description]

### [research-specialist](research-specialist/README.md)

**Description**: Codebase research, best practice investigation, and comprehensive report generation.

**Use When**: Researching existing patterns, analyzing codebases, investigating best practices, generating research reports.

**Capabilities**:
- Codebase analysis (patterns, architecture, implementation approaches)
- Best practices investigation (industry standards, framework conventions)
- Pattern recognition (recurring patterns, anti-patterns, design decisions)
- Structured report generation (Metadata, Findings, Recommendations)
- File path collection with line-level references

**Documentation**:
- [SKILL.md](./research-specialist/SKILL.md) - Core skill definition
- [README.md](./research-specialist/README.md) - Usage guide

**Integration**:
- Autonomous: Claude auto-invokes when analyzing codebases or researching patterns
- Coordinator: research-coordinator auto-loads skill via `skills:` field
- Agent: research-specialist agent provides Task invocation compatibility

**Example Usage**:
```
User: "Analyze existing authentication patterns in the codebase"
→ Claude detects research need
→ Invokes research-specialist skill automatically
→ Performs codebase analysis
→ Generates research report
```

### [plan-generator](plan-generator/README.md)

**Description**: Implementation plan generation with metadata validation, phase organization, and standards integration.

**Use When**: Creating implementation plans, validating plan structure, organizing phased tasks.

**Capabilities**:
- Metadata validation (Date, Feature, Status, Estimated Hours)
- Phase structure organization (headings, checkboxes, dependencies)
- Complexity calculation and tier selection
- Standards integration and divergence detection
- Delegation to plan-architect for complex planning

**Documentation**:
- [SKILL.md](./plan-generator/SKILL.md) - Core skill definition
- [README.md](./plan-generator/README.md) - Usage guide

**Integration**:
- Autonomous: Claude auto-invokes when creating implementation plans
- Commands: /create-plan, /repair, /debug delegate to skill
- Agent: plan-architect agent provides detailed planning via delegation

**Example Usage**:
```
User: "Create implementation plan for user authentication"
→ Claude detects planning need
→ Invokes plan-generator skill automatically
→ Validates metadata
→ Delegates to plan-architect
→ Returns plan path
```

### [test-orchestrator](test-orchestrator/README.md)

**Description**: Autonomous test orchestration with auto-trigger after implementation phases.

**Use When**: Running tests after implementation, validating code changes, analyzing test coverage.

**Capabilities**:
- Test discovery (glob patterns, framework detection)
- Test execution (pytest, jest, busted support)
- Coverage analysis (threshold checking, report generation)
- Auto-trigger after implementation phases
- Explicit invocation via /test command

**Documentation**:
- [SKILL.md](./test-orchestrator/SKILL.md) - Core skill definition
- [README.md](./test-orchestrator/README.md) - Usage guide

**Integration**:
- Autonomous: Auto-triggers after /implement phase completion
- Command: /test explicitly invokes skill
- /implement: Checks skill availability for auto-testing

**Example Usage**:
```
/implement completes Phase 2: [COMPLETE]
→ test-orchestrator detects phase completion
→ discovers test files for modified code
→ runs test suite automatically
→ reports results
```
```

**Validation**:
```bash
# Verify all three skills documented
grep -q "research-specialist" /home/benjamin/.config/.claude/skills/README.md
grep -q "plan-generator" /home/benjamin/.config/.claude/skills/README.md
grep -q "test-orchestrator" /home/benjamin/.config/.claude/skills/README.md

# Verify skills count updated
grep -q "4 skills" /home/benjamin/.config/.claude/skills/README.md || \
  (grep -q "research-specialist, plan-generator, test-orchestrator, document-converter" /home/benjamin/.config/.claude/skills/README.md)
```

**Expected Duration**: 2 hours

---

#### Step 4.2: Update CLAUDE.md Skills Architecture Section

**Tasks**:
- [ ] Update CLAUDE.md skills_architecture section (file: `/home/benjamin/.config/CLAUDE.md`)
- [ ] Add all three new skills to "Available Skills" list
- [ ] Update skills count in description
- [ ] Add integration patterns for new skills

**CLAUDE.md Update**:
```markdown
<!-- SECTION: skills_architecture -->
## Skills Architecture
[Used by: all commands, all agents]

Skills are model-invoked autonomous capabilities that Claude automatically uses when relevant needs are detected. Unlike commands (user-invoked) or agents (task delegation), skills enable autonomous composition and progressive discovery.

**Available Skills**:
- `document-converter` - Bidirectional document conversion (Markdown, DOCX, PDF)
- `research-specialist` - Codebase research and best practice investigation
- `plan-generator` - Implementation plan generation with metadata validation
- `test-orchestrator` - Autonomous test orchestration with auto-trigger after implementation

**Integration Patterns**:
1. **Autonomous**: Claude detects need and loads skill automatically
2. **Agent Auto-Loading**: Agents use `skills:` frontmatter field for auto-loading
3. **Command Delegation**: Commands delegate to agents which auto-load skills

**Command-to-Agent-to-Skill Pattern** (preferred):
```markdown
# Commands invoke agents via Task tool
# Agents have skills: field in frontmatter
# Agents automatically receive skill context
```

Example: `/research` invokes `research-coordinator` agent which has `skills: research-specialist` in frontmatter.

See [Skills README](.claude/skills/README.md) for complete skills guide, and [Skills Authoring Standards](.claude/docs/reference/standards/skills-authoring.md) for compliance requirements.
<!-- END_SECTION: skills_architecture -->
```

**Validation**:
```bash
# Verify CLAUDE.md updated
grep -q "research-specialist" /home/benjamin/.config/CLAUDE.md
grep -q "plan-generator" /home/benjamin/.config/CLAUDE.md
grep -q "test-orchestrator" /home/benjamin/.config/CLAUDE.md
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Testing

**Research-Specialist Skill**:
```bash
# Test autonomous invocation detection
# Test prompt: "Research existing authentication patterns"
# Expected: research-specialist skill triggers

# Test Task invocation compatibility
# Invoke via research-coordinator
# Expected: research report created at REPORT_PATH
```

**Plan-Generator Skill**:
```bash
# Test metadata validation
# Test prompt: "Create plan with invalid metadata"
# Expected: validation_error returned

# Test complexity calculation
# Test prompt: "Calculate complexity for feature with 20 tasks, 10 files, 2 integrations"
# Expected: Score = 10 + 20/2 + 10*3 + 2*5 = 60 (Tier 2)

# Test delegation to plan-architect
# Test prompt: "Create complex implementation plan with research integration"
# Expected: plan-generator delegates to plan-architect, validates output
```

**Test-Orchestrator Skill**:
```bash
# Test test discovery
# Test prompt: "Discover all test files in project"
# Expected: Glob patterns return test file list

# Test framework detection
# Test prompt: "Detect test framework for Python project with pytest.ini"
# Expected: Framework = "pytest"

# Test coverage analysis
# Test prompt: "Check coverage for 75% with 80% threshold"
# Expected: ERROR - Coverage below threshold
```

### Integration Testing

**End-to-End Workflows**:

**Research Workflow**:
```bash
# Test /research command with research-specialist skill
/research "Analyze authentication patterns"
→ research-coordinator invokes research-specialist (skill or agent)
→ research-specialist generates report
→ coordinator aggregates metadata
→ command validates report exists
```

**Planning Workflow**:
```bash
# Test /create-plan command with plan-generator skill
/create-plan "Implement user authentication" --complexity 2
→ plan-generator validates metadata
→ calculates complexity
→ delegates to plan-architect
→ validates output
→ returns plan path
```

**Testing Workflow**:
```bash
# Test /implement auto-trigger with test-orchestrator skill
/implement plan.md --phase 1
→ phase 1 completes [COMPLETE]
→ test-orchestrator auto-triggers
→ discovers tests for modified code
→ runs test suite
→ reports results
```

### Validation Testing

**Skills Catalog Validation**:
```bash
# Verify all skills documented in README
bash .claude/scripts/validate-skills-catalog.sh

# Verify SKILL.md YAML frontmatter valid
for skill in research-specialist plan-generator test-orchestrator; do
  python3 -c "import yaml; yaml.safe_load(open('.claude/skills/$skill/SKILL.md').read().split('---')[1])"
done

# Verify SKILL.md under 500 lines
for skill in research-specialist plan-generator test-orchestrator; do
  LINE_COUNT=$(wc -l < .claude/skills/$skill/SKILL.md)
  [ "$LINE_COUNT" -lt 500 ] || echo "WARNING: $skill SKILL.md exceeds 500 lines"
done
```

**CLAUDE.md Integration Validation**:
```bash
# Verify CLAUDE.md references all skills
grep -q "research-specialist" CLAUDE.md
grep -q "plan-generator" CLAUDE.md
grep -q "test-orchestrator" CLAUDE.md
```

## Documentation Requirements

### New Documentation Files

**Skills Documentation**:
- `.claude/skills/research-specialist/SKILL.md` - Core skill definition (<500 lines)
- `.claude/skills/research-specialist/README.md` - Comprehensive usage guide
- `.claude/skills/plan-generator/SKILL.md` - Core skill definition (<500 lines)
- `.claude/skills/plan-generator/README.md` - Comprehensive usage guide
- `.claude/skills/test-orchestrator/SKILL.md` - Core skill definition (<500 lines)
- `.claude/skills/test-orchestrator/README.md` - Comprehensive usage guide

### Documentation Updates

**Skills README.md Updates**:
- Add research-specialist to Available Skills section
- Add plan-generator to Available Skills section
- Add test-orchestrator to Available Skills section
- Update skills count from 1 to 4
- Add integration examples for all three skills

**CLAUDE.md Updates**:
- Update skills_architecture section with all three new skills
- Update Available Skills list
- Add integration pattern examples

**Command Documentation Updates**:
- `.claude/commands/create-plan.md` - Document plan-generator skill integration
- `.claude/commands/repair.md` - Document plan-generator skill usage
- `.claude/commands/debug.md` - Document plan-generator skill usage
- `.claude/commands/implement.md` - Document test-orchestrator auto-trigger
- `.claude/commands/test.md` - Document test-orchestrator skill invocation

## Dependencies

### Library Dependencies
- `.claude/lib/core/error-handling.sh` - Error logging integration
- `.claude/lib/core/unified-location-detection.sh` - Artifact path calculation

### Agent Dependencies
- `.claude/agents/research-specialist.md` - Source for research-specialist skill extraction
- `.claude/agents/plan-architect.md` - Delegation target for plan-generator skill
- `.claude/agents/research-coordinator.md` - Updated for research-specialist skill auto-loading

### Command Dependencies
- `.claude/commands/research.md` - Integration point for research-specialist skill
- `.claude/commands/create-plan.md` - Integration point for plan-generator skill
- `.claude/commands/repair.md` - Integration point for plan-generator skill
- `.claude/commands/debug.md` - Integration point for plan-generator skill
- `.claude/commands/implement.md` - Integration point for test-orchestrator skill
- `.claude/commands/test.md` - Integration point for test-orchestrator skill

## Risk Analysis

### High-Risk Areas

**Skills Auto-Invocation Conflicts**:
- Risk: Autonomous skill invocation might conflict with explicit Task invocations or trigger unexpectedly
- Mitigation: Implement clear invocation detection logic, test both autonomous and explicit paths separately, document trigger conditions clearly
- Rollback: Disable autonomous invocation, fall back to explicit Task invocation only

**Task Invocation Backward Compatibility**:
- Risk: Skills extraction might break existing coordinator Task invocation paths
- Mitigation: Maintain agent files for Task invocation compatibility, test both skill and agent invocation paths
- Rollback: Revert to agent-only invocation if skills cause compatibility issues

### Medium-Risk Areas

**Plan-Generator Delegation Complexity**:
- Risk: Skill-to-agent delegation might add complexity and failure points
- Mitigation: Keep delegation logic simple, validate both skill and agent outputs, test error handling thoroughly
- Rollback: Simplify delegation to direct agent invocation if complexity becomes problematic

**Test-Orchestrator Auto-Trigger Reliability**:
- Risk: Auto-trigger might not detect phase completion reliably or trigger on false positives
- Mitigation: Implement clear trigger conditions, test with various implementation scenarios, allow manual override via /test
- Rollback: Disable auto-trigger, rely on manual /test invocation only

### Low-Risk Areas

**Skills README Updates**:
- Risk: Minimal risk; documentation-only changes
- Mitigation: Follow existing skills README structure, validate markdown syntax

**CLAUDE.md Updates**:
- Risk: Minimal risk; documentation-only changes
- Mitigation: Maintain CLAUDE.md section structure, validate cross-references

## Success Criteria

Phase 3 is complete when:

- [ ] Research-specialist skill created with SKILL.md under 500 lines
- [ ] Research-specialist skill autonomous invocation tested and working
- [ ] Research-specialist skill Task invocation backward compatibility verified
- [ ] Research-coordinator updated with `skills: research-specialist` frontmatter
- [ ] Plan-generator skill created with delegation to plan-architect
- [ ] Plan-generator skill metadata validation logic implemented
- [ ] /create-plan, /repair, /debug commands updated for plan-generator integration
- [ ] Test-orchestrator skill created with test discovery, execution, coverage logic
- [ ] Test-orchestrator auto-trigger after /implement phase completion working
- [ ] /implement and /test commands updated for test-orchestrator integration
- [ ] Skills README.md updated with all three new skills
- [ ] CLAUDE.md skills_architecture section updated with all three new skills
- [ ] All SKILL.md files have valid YAML frontmatter
- [ ] All SKILL.md files under 500 lines for token efficiency
- [ ] All skills documented with README.md usage guides
- [ ] Integration testing passes for all workflows

## Notes

**Progressive Implementation**: Stages can be implemented sequentially (Stage 1 → Stage 2 → Stage 3 → Stage 4). Within each stage, steps should be implemented in order to maintain dependencies.

**Backward Compatibility**: All skills maintain backward compatibility with existing Task invocation paths:
- Research-specialist: Coordinator can still invoke research-specialist.md agent via Task tool
- Plan-generator: Commands can still invoke plan-architect.md agent directly if skill unavailable
- Test-orchestrator: /test command continues to work with explicit invocation

**Skills vs Agents**: After skills extraction, agents remain available for Task invocation compatibility. Skills provide autonomous invocation layer on top of existing agent capabilities.

**Token Efficiency**: All SKILL.md files kept under 500 lines for progressive disclosure efficiency. Detailed documentation moved to README.md files.

**Testing Priority**: Integration testing is critical for Phase 3 due to autonomous invocation and auto-trigger features. Unit tests validate individual skill capabilities, but end-to-end workflows validate actual usage patterns.

## Completion Signal

When all tasks complete and success criteria met, return:

```
PHASE_EXPANDED: /home/benjamin/.config/.claude/specs/019_three_tier_agent_improvements/plans/001-three-tier-agent-improvements-plan/phase_3_skills_expansion.md

Summary:
- Stages: 4 (Research-Specialist, Plan-Generator, Test-Orchestrator, Skills Catalog Update)
- Total Steps: 17
- Estimated Duration: 20-26 hours
- Skills Created: 3 (research-specialist, plan-generator, test-orchestrator)
- Documentation Files: 9 (3 SKILL.md + 3 README.md + 2 catalog updates + 1 CLAUDE.md update)
```
