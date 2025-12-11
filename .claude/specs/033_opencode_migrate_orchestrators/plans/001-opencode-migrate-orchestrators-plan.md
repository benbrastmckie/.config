# OpenCode Orchestrator Migration Implementation Plan

## Metadata
- **Date**: 2025-12-10
- **Feature**: Port simplified .claude/ configuration to OpenCode with orchestrator commands and supporting agents/utilities
- **Status**: [NOT STARTED]
- **Estimated Hours**: 28-36 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [OpenCode Porting Best Practices and Tool Integration Research Report](../reports/001-opencode-porting-research.md)
  - [Research Report: Porting Orchestrator Commands to OpenCode](../reports/002-orchestrator-commands-port.md)
  - [Research Report: Agent Architecture and Support Utilities Port](../reports/003-agent-utilities-port.md)
- **Complexity Score**: 185
- **Structure Level**: 0 (single file, may expand to Level 1 during implementation)
- **Estimated Phases**: 8

## Overview

This plan implements a hybrid architecture for OpenCode integration, preserving .claude/'s orchestration capabilities while creating simplified OpenCode commands for exploratory workflows. The migration focuses on portability: converting agent behavioral files to OpenCode's YAML frontmatter format, implementing core libraries as MCP tools, and creating template-based commands for non-orchestrated workflows.

**Key Strategy**: Hybrid architecture approach - keep complex orchestrators (/create-plan, /implement, /revise) in .claude/ with full state machine support, while porting simplified single-phase commands to OpenCode for conversational exploration.

## Research Summary

Based on comprehensive research across three reports:

**Finding 1 (Porting Best Practices)**: OpenCode uses markdown files with YAML frontmatter for agents (vs .claude/'s behavioral guidelines), template-based commands with $ARGUMENTS placeholders (vs bash blocks), and TaskTool for subagent delegation (vs Claude's Task tool pseudo-syntax). File operations have 1:1 mapping but state persistence requires SQLite session management vs bash state files.

**Finding 2 (Orchestrator Commands)**: Multi-phase orchestration is NOT fully portable. OpenCode lacks: state machine orchestration (8-state workflow), cross-block state persistence (append/load workflow state), hard barrier verification patterns, and wave-based parallel execution. Only 20-30% of orchestrator functionality ports directly without significant redesign.

**Finding 3 (Agent Architecture)**: Hierarchical agent architecture is fully portable with YAML frontmatter translation. OpenCode's primary/subagent modes, tool permissions, and markdown behavioral files provide 1:1 feature parity. Three-tier coordination pattern (Command → Coordinator → Specialist) maps directly with minor syntax adaptations.

**Critical Gaps Identified**:
- No state machine (research → plan → implement workflow states)
- Blocking bash execution (no background tasks)
- No checkpoint/resume functionality
- Hard barrier pattern requires prompt-based enforcement (not guaranteed)
- Metadata-only passing requires JSON in prompts (not bash variables)

**Recommended Approach**: Implement core libraries as MCP tools (state-persistence, error-handling, workflow-state-machine), convert agents to OpenCode YAML format, create simplified commands for single-phase workflows, and preserve complex orchestrators in .claude/ until OpenCode adds state machine support.

## Success Criteria

- [ ] OpenCode project configuration created (~/.config/opencode/) with agent/, command/, and AGENTS.md
- [ ] All 19 .claude/ agents converted to OpenCode YAML frontmatter format with tool permissions
- [ ] Core support libraries (state-persistence, error-handling, workflow-state-machine) implemented as MCP tools
- [ ] Simplified /research-simple command functional in OpenCode for single-topic research
- [ ] Hybrid architecture documented with decision matrix for when to use .claude/ vs OpenCode
- [ ] CLAUDE.md standards migrated to AGENTS.md with bash-specific patterns adapted to JavaScript/TypeScript
- [ ] Agent delegation verified working via TaskTool with description-based invocation
- [ ] Model mapping validated (sonnet-4.5 → anthropic/claude-sonnet-4-20250514)

## Technical Design

### Architecture Overview

**Hybrid Architecture Pattern**:
```
.claude/ (Orchestrated Workflows)           .opencode/ (Exploratory Workflows)
├── commands/                               ├── command/
│   ├── create-plan.md                      │   ├── research-simple.md
│   ├── implement.md                        │   ├── code-review.md
│   ├── revise.md                           │   └── docs-gen.md
│   └── test.md                             ├── agent/
├── agents/                                 │   ├── research-specialist.md (YAML)
│   ├── research-coordinator.md             │   ├── plan-architect.md (YAML)
│   └── research-specialist.md              │   └── topic-naming-agent.md (YAML)
└── lib/ (43 bash libraries)                ├── AGENTS.md (standards)
                                            └── mcp-servers/
                                                ├── state-management/
                                                ├── error-logging/
                                                └── workflow-orchestration/
```

**Component Translation Strategy**:

1. **Agents**: Split .claude/agents/*.md into YAML frontmatter + prompt body
   - Frontmatter: `mode`, `model`, `tools`, `permission`
   - Body: System prompt instructions (behavioral guidelines)
   - Model mapping: `sonnet-4.5` → `anthropic/claude-sonnet-4-20250514`

2. **Commands**: Create template-based commands for single-phase workflows
   - Use `template` field with $ARGUMENTS, @filename, !bash injection
   - No multi-block orchestration (collapsed into single prompt)
   - Agent delegation via `agent: coordinator` config option

3. **Libraries**: Implement core bash libraries as MCP tools (JavaScript/TypeScript)
   - state-persistence.sh → state-management MCP server
   - error-handling.sh → error-logging MCP server
   - workflow-state-machine.sh → workflow-orchestration MCP server

4. **Standards**: Migrate CLAUDE.md sections to AGENTS.md
   - Global rules: ~/.config/opencode/AGENTS.md
   - Project rules: project root AGENTS.md
   - Replace bash patterns with JavaScript/TypeScript equivalents

### Agent File Conversion Pattern

**Source (.claude/agents/research-specialist.md)**:
```markdown
---
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch
description: Conduct deep research and create comprehensive reports
model: sonnet-4.5
---

# Research Specialist Agent
[28 completion criteria, workflow steps, etc.]
```

**Target (.opencode/agent/research-specialist.md)**:
```markdown
---
description: Conduct deep research and create comprehensive reports
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  read: true
  write: true
  edit: true
  bash: true
  grep: true
  glob: true
  webfetch: true
  websearch: true
permission:
  external_directory: ask
---

# Research Specialist Agent
[System prompt with completion criteria, workflow steps]
```

### Command Simplification Pattern

**Source (.claude/commands/research.md)** - 3 blocks, 551 lines:
```markdown
## Block 1: Setup (239 lines)
- Argument capture
- State initialization
- Path pre-calculation

## Block 2: Agent Invocation (172 lines)
Task { invoke research-specialist }

## Block 3: Verification (140 lines)
- Hard barrier verification
- Error logging
```

**Target (.opencode/command/research-simple.md)** - Single template, ~50 lines:
```markdown
---
template: |
  Research the following topic: $TOPIC
  Complexity: ${COMPLEXITY:-2}

  Steps:
  1. Create directory: .claude/specs/{topic}/reports/
  2. Conduct research (analyze @codebase, search web)
  3. Create report: .claude/specs/{topic}/reports/001-{slug}.md
  4. Self-verify: All sections present before returning

  Return: REPORT_CREATED: {absolute_path}

description: Simple research workflow (single-phase, no state tracking)
agent: research-specialist
---
```

**Limitations vs .claude/ version**:
- No multi-topic decomposition (complexity >= 3)
- No hard barrier verification (relies on LLM self-checking)
- No JSONL error logging
- No checkpoint/resume
- No topic naming agent (manual slug generation)

### MCP Tool Implementation

**Priority 1 - Core State Management**:

1. **state-management MCP server** (ports state-persistence.sh):
   - Tools: `init_workflow_state`, `append_workflow_state`, `load_workflow_state`, `discover_latest_state_file`
   - Storage: JSON files in ~/.opencode/state/
   - Atomic operations: file locking for concurrent safety

2. **error-logging MCP server** (ports error-handling.sh):
   - Tools: `log_command_error`, `query_errors`, `parse_subagent_error`
   - Storage: JSONL format in ~/.opencode/data/errors.jsonl
   - Schema: {timestamp, workflow_id, command, error_type, message, details}

3. **workflow-orchestration MCP server** (ports workflow-state-machine.sh):
   - Tools: `sm_init`, `sm_transition`, `sm_get_state`, `save_checkpoint`, `load_checkpoint`
   - States: initialize, research, plan, implement, test, debug, document, complete
   - Validation: state transition rules enforcement

**Implementation**: TypeScript/JavaScript using OpenCode MCP SDK

### Standards Migration Strategy

**CLAUDE.md Section Mapping**:

| CLAUDE.md Section | AGENTS.md Location | Adaptation Required |
|-------------------|-------------------|---------------------|
| Code Standards | Global AGENTS.md | Replace bash sourcing with MCP tool invocations |
| Testing Protocols | Global AGENTS.md | Adapt test discovery to OpenCode context |
| Directory Organization | Global AGENTS.md | Map .claude/ structure to .opencode/ |
| Error Logging | Global AGENTS.md | Reference error-logging MCP tool |
| Hierarchical Agents | Project AGENTS.md | Update Task tool → TaskTool syntax |
| Plan Metadata Standard | Project AGENTS.md | Preserve metadata fields (portable) |

**Bash-Specific Pattern Adaptations**:
- Three-tier sourcing → MCP tool initialization
- State persistence blocks → JSON file persistence via MCP
- Hard barrier verification → Prompt-based verification instructions
- Workflow state machine → MCP workflow-orchestration calls

### Metadata-Only Passing via JSON

**Pattern**: Embed structured metadata in prompts instead of bash variables

**Example (research-coordinator metadata passing)**:

**.claude/ approach** (bash variables):
```bash
append_workflow_state "REPORT_METADATA" '{"findings": 8, "recommendations": 7, "path": "/path/to/report.md"}'
```

**OpenCode approach** (JSON in prompt):
```markdown
Invoke research-specialist with the following metadata:
{
  "topic": "authentication patterns",
  "output_path": "specs/042_auth/reports/001_patterns.md",
  "findings_target": 8,
  "recommendations_target": 7
}

After completion, return metadata ONLY (not full content):
{
  "findings_count": 8,
  "recommendations_count": 7,
  "report_path": "/absolute/path/to/report.md"
}
```

**Context Reduction**: 95% reduction via metadata-only returns (330 tokens vs 7,500)

## Implementation Phases

### Phase 1: OpenCode Project Initialization [NOT STARTED]
dependencies: []

**Objective**: Create OpenCode project structure and configuration files

**Complexity**: Low

**Tasks**:
- [ ] Create ~/.config/opencode/ directory structure (agent/, command/, mcp-servers/)
- [ ] Create global AGENTS.md with core standards sections (code standards, testing protocols)
- [ ] Configure OpenCode model settings (anthropic/claude-sonnet-4-20250514 as default)
- [ ] Create project-specific .opencode/ directory for command testing
- [ ] Set up MCP server directory structure (state-management/, error-logging/, workflow-orchestration/)

**Testing**:
```bash
# Verify directory structure
test -d ~/.config/opencode/agent
test -d ~/.config/opencode/command
test -f ~/.config/opencode/AGENTS.md

# Verify OpenCode recognizes configuration
opencode --version
opencode config show
```

**Expected Duration**: 1-2 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["directory-structure.txt", "config-validation.log"]

---

### Phase 2: Agent File Conversion [NOT STARTED]
dependencies: [1]

**Objective**: Convert all 19 .claude/ agent files to OpenCode YAML frontmatter format

**Complexity**: Medium

**Tasks**:
- [ ] Create conversion script: `scripts/convert-agents-to-opencode.sh`
  - Parse .claude/agents/*.md frontmatter
  - Map allowed-tools → tools/permission fields
  - Map model specifications (sonnet-4.5 → anthropic/claude-sonnet-4-20250514)
  - Set mode based on agent role (primary vs subagent)
  - Preserve system prompt body unchanged
- [ ] Convert coordinator agents: research-coordinator.md, implementer-coordinator.md
- [ ] Convert specialist agents: research-specialist.md, plan-architect.md, implementation-executor.md
- [ ] Convert utility agents: topic-naming-agent.md, complexity-estimator.md
- [ ] Validate YAML syntax and required fields (mode, model, description)
- [ ] Test agent invocation via OpenCode CLI (`opencode @research-specialist "test"`)

**Model Mapping Table**:
```
.claude/ model   → OpenCode model
------------------------------------------------
sonnet-4.5       → anthropic/claude-sonnet-4-20250514
opus-4.1         → anthropic/claude-opus-4-5
haiku-4.5        → anthropic/claude-haiku-4-20250514
```

**Testing**:
```bash
# Validate all converted agents
for agent in ~/.config/opencode/agent/*.md; do
  echo "Validating $agent..."
  # Extract YAML frontmatter
  awk '/^---$/,/^---$/' "$agent" | yq eval '.' -
  # Verify required fields
  grep -q "^mode:" "$agent" || echo "ERROR: Missing mode in $agent"
  grep -q "^model:" "$agent" || echo "ERROR: Missing model in $agent"
done

# Test agent invocation
opencode @research-specialist "Quick test: Research bash error handling patterns"
# Expect: Agent responds with research approach
```

**Expected Duration**: 4-6 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["converted-agents.json", "validation-report.txt"]

---

### Phase 3: Core MCP Tools Implementation [NOT STARTED]
dependencies: [1]

**Objective**: Implement Priority 1 bash libraries as MCP tools (state-management, error-logging, workflow-orchestration)

**Complexity**: High

**Tasks**:
- [ ] Create state-management MCP server (TypeScript):
  - Implement init_workflow_state (generates unique ID, creates state file)
  - Implement append_workflow_state (atomic append with file locking)
  - Implement load_workflow_state (read state file, parse JSON)
  - Implement discover_latest_state_file (pattern-based discovery by mtime)
  - Use ~/.opencode/state/ for storage
- [ ] Create error-logging MCP server (TypeScript):
  - Implement log_command_error (append to JSONL with schema validation)
  - Implement query_errors (filter by command, type, time range)
  - Implement parse_subagent_error (extract error signals from agent output)
  - Use ~/.opencode/data/errors.jsonl for storage
- [ ] Create workflow-orchestration MCP server (TypeScript):
  - Implement sm_init (initialize state machine with 8 states)
  - Implement sm_transition (validate state transitions, update state file)
  - Implement sm_get_state (return current workflow state)
  - Implement save_checkpoint/load_checkpoint (resumption support)
  - Storage: ~/.opencode/workflows/{workflow_id}.json
- [ ] Configure MCP servers in OpenCode config (~/.config/opencode/config.json):
  - Add mcpServers entries with stdio transport
  - Set permission levels (state-management: allow, error-logging: allow)
- [ ] Create MCP tool test suite (validate each tool function)

**MCP Server Structure**:
```typescript
// state-management/src/index.ts
import { MCPServer, Tool } from '@opencode/mcp-sdk';

const server = new MCPServer({
  name: 'state-management',
  version: '1.0.0',
  tools: [
    {
      name: 'init_workflow_state',
      description: 'Initialize workflow state file with unique ID',
      schema: { workflow_name: 'string' },
      handler: async (args) => {
        const workflowId = `${args.workflow_name}_${Date.now()}${process.hrtime.bigint()}`;
        const stateFile = `~/.opencode/state/${workflowId}.json`;
        await fs.writeFile(stateFile, JSON.stringify({ id: workflowId, vars: {} }));
        return { workflow_id: workflowId, state_file: stateFile };
      }
    },
    // ... other tools
  ]
});
```

**Testing**:
```bash
# Test state-management MCP tool
opencode --invoke-tool state-management:init_workflow_state '{"workflow_name": "test"}'
# Expect: {"workflow_id": "test_...", "state_file": "..."}

# Test error-logging MCP tool
opencode --invoke-tool error-logging:log_command_error '{
  "error_type": "validation_error",
  "message": "Test error",
  "details": {}
}'
# Expect: Error logged to ~/.opencode/data/errors.jsonl

# Test workflow-orchestration MCP tool
opencode --invoke-tool workflow-orchestration:sm_init '{
  "workflow_id": "test_12345",
  "command": "/test",
  "workflow_type": "linear"
}'
# Expect: State machine initialized with state "initialize"
```

**Expected Duration**: 10-12 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["mcp-test-results.json", "tool-coverage.lcov"]

---

### Phase 4: Simplified Commands Creation [NOT STARTED]
dependencies: [2, 3]

**Objective**: Create template-based OpenCode commands for single-phase workflows

**Complexity**: Medium

**Tasks**:
- [ ] Create /research-simple command (file: ~/.config/opencode/command/research-simple.md):
  - Template with $TOPIC and $COMPLEXITY placeholders
  - Inline bash for directory creation
  - Agent delegation to research-specialist
  - Self-verification instructions (file exists, sections present)
  - Return signal: REPORT_CREATED: {path}
- [ ] Create /code-review command (read-only analysis, no state tracking)
- [ ] Create /docs-gen command (documentation generation from code)
- [ ] Test each command with sample inputs
- [ ] Document command usage in ~/.config/opencode/README.md
- [ ] Create decision matrix: when to use .claude/ vs OpenCode commands

**Example Command Structure** (/research-simple):
```markdown
---
template: |
  You are conducting a quick research investigation.

  **Topic**: $TOPIC
  **Complexity**: ${COMPLEXITY:-2}

  **Instructions**:
  1. Create directory:
     ```bash
     mkdir -p .claude/specs/$(echo "$TOPIC" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')/reports/
     ```

  2. Analyze codebase (use @mentions for relevant files)
  3. Research external sources (documentation, best practices)
  4. Create report: .claude/specs/{topic}/reports/001-{slug}.md
     - Sections: Executive Summary, Findings, Recommendations, References

  5. Self-verify:
     - [ ] All sections present
     - [ ] Code examples valid
     - [ ] Sources cited

  **Return Signal**: REPORT_CREATED: {absolute_path}

description: Quick research investigation (single-phase, no state tracking)
agent: research-specialist
---
```

**Testing**:
```bash
# Test /research-simple command
cd ~/.config/opencode/command/
opencode /research-simple "JWT authentication patterns"

# Expect:
# - Directory created: .claude/specs/jwt_authentication_patterns/reports/
# - Report file created: 001-jwt-authentication-patterns.md
# - Return signal: REPORT_CREATED: /path/to/report.md

# Verify report structure
test -f .claude/specs/jwt_authentication_patterns/reports/001-jwt-authentication-patterns.md
grep -q "## Executive Summary" .claude/specs/jwt_authentication_patterns/reports/001-jwt-authentication-patterns.md
```

**Expected Duration**: 4-6 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["command-test-results.json", "sample-reports/"]

---

### Phase 5: Standards Migration to AGENTS.md [NOT STARTED]
dependencies: [1]

**Objective**: Convert CLAUDE.md standards sections to OpenCode AGENTS.md format with bash pattern adaptations

**Complexity**: Medium

**Tasks**:
- [ ] Create global AGENTS.md (~/.config/opencode/AGENTS.md):
  - Migrate Code Standards section (replace bash sourcing with MCP tool invocations)
  - Migrate Testing Protocols section (adapt test discovery patterns)
  - Migrate Directory Organization section (map .claude/ → .opencode/ structure)
  - Migrate Error Logging section (reference error-logging MCP tool)
  - Document hybrid architecture decision matrix
- [ ] Create project AGENTS.md (project root):
  - Migrate Hierarchical Agents section (update Task tool → TaskTool syntax)
  - Migrate Plan Metadata Standard section (portable, no changes needed)
  - Migrate Output Formatting Standards section (adapt for prompt-based orchestration)
- [ ] Document bash-to-JavaScript/TypeScript pattern adaptations:
  - Three-tier sourcing → MCP tool initialization pattern
  - State persistence blocks → JSON file persistence via MCP
  - Hard barrier verification → Prompt-based verification instructions
- [ ] Create migration guide documenting all adaptations
- [ ] Validate AGENTS.md renders correctly in OpenCode context

**Standards Section Adaptations**:

**Example 1 - Code Standards (Bash Sourcing)**:

*.claude/ CLAUDE.md*:
```markdown
## Code Standards
All bash blocks MUST follow three-tier sourcing pattern:
```bash
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error"; exit 1; }
```
```

*OpenCode AGENTS.md*:
```markdown
## Code Standards
All agents MUST initialize state management via MCP tool:
- Use state-management:init_workflow_state at workflow start
- Use state-management:append_workflow_state for variable persistence
- Use state-management:load_workflow_state for state restoration
```

**Example 2 - Hierarchical Agents (Task Tool Syntax)**:

*.claude/ CLAUDE.md*:
```markdown
## Hierarchical Agents
Use Task tool for subagent delegation:
Task { subagent_type: "general-purpose", prompt: "..." }
```

*OpenCode AGENTS.md*:
```markdown
## Hierarchical Agents
Use TaskTool for subagent delegation:
Invoke subagent via description-based matching or @mention:
- Description-based: "Invoke research-specialist subagent with topic..."
- Direct mention: @research-specialist analyze patterns
```

**Testing**:
```bash
# Validate AGENTS.md syntax
test -f ~/.config/opencode/AGENTS.md
test -f .opencode/AGENTS.md

# Verify standards sections present
grep -q "## Code Standards" ~/.config/opencode/AGENTS.md
grep -q "## Hierarchical Agents" .opencode/AGENTS.md

# Test combined rules (global + project)
opencode config show | grep -q "AGENTS.md"
# Expect: Both global and project AGENTS.md loaded
```

**Expected Duration**: 4-6 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["standards-migration-report.md", "adaptation-guide.md"]

---

### Phase 6: Agent Delegation Verification [NOT STARTED]
dependencies: [2, 4]

**Objective**: Verify hierarchical agent coordination works via TaskTool with description-based and @mention invocation

**Complexity**: Medium

**Tasks**:
- [ ] Create test coordinator agent (coordinator-test.md):
  - Mode: primary
  - Delegates to research-specialist when "research" keyword detected
  - Delegates to plan-architect when "plan" keyword detected
- [ ] Test description-based invocation:
  - Invoke coordinator with "research authentication patterns"
  - Verify research-specialist subagent invoked automatically
- [ ] Test @mention invocation:
  - Direct invocation: `@research-specialist analyze JWT patterns`
  - Verify research-specialist executes without coordinator
- [ ] Test metadata-only passing pattern:
  - Coordinator passes JSON metadata to specialist
  - Specialist returns metadata-only response (not full content)
  - Verify context reduction (measure token counts)
- [ ] Create delegation test suite with 5 scenarios:
  1. Simple delegation (research keyword)
  2. Complex delegation (multi-step workflow)
  3. Metadata-only passing (context reduction)
  4. Direct @mention (bypass coordinator)
  5. Error handling (specialist failure propagation)
- [ ] Document delegation patterns and limitations (vs .claude/ hard barriers)

**Test Scenarios**:

**Scenario 1 - Description-Based Delegation**:
```bash
opencode --agent coordinator-test "Research JWT authentication patterns in codebase"

# Expected flow:
# 1. coordinator-test sees "Research" keyword
# 2. coordinator-test matches to research-specialist description
# 3. TaskTool invokes research-specialist with topic
# 4. research-specialist returns report path
# 5. coordinator-test synthesizes final response
```

**Scenario 3 - Metadata-Only Passing**:
```bash
opencode --agent coordinator-test "Research with metadata: {\"topic\": \"JWT\", \"complexity\": 2}"

# Expected coordinator prompt:
# Invoke research-specialist with metadata:
# { "topic": "JWT", "complexity": 2, "output_path": "..." }
#
# Return metadata ONLY:
# { "findings_count": 8, "report_path": "/path/to/report.md" }

# Measure context reduction:
FULL_CONTENT_TOKENS=7500
METADATA_TOKENS=330
REDUCTION=$(echo "scale=2; (1 - $METADATA_TOKENS / $FULL_CONTENT_TOKENS) * 100" | bc)
echo "Context reduction: ${REDUCTION}%"
# Expect: ~95%
```

**Testing**:
```bash
# Run delegation test suite
bash scripts/test-opencode-delegation.sh

# Verify all scenarios pass
# Expected output:
# ✓ Scenario 1: Description-based delegation
# ✓ Scenario 2: Complex delegation
# ✓ Scenario 3: Metadata-only passing (95% reduction)
# ✓ Scenario 4: Direct @mention
# ✓ Scenario 5: Error handling

# All tests passed: 5/5
```

**Expected Duration**: 3-4 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["delegation-test-results.json", "context-reduction-metrics.csv"]

---

### Phase 7: Hybrid Architecture Documentation [NOT STARTED]
dependencies: [4, 5, 6]

**Objective**: Document decision matrix for when to use .claude/ vs OpenCode, create migration guide, and establish usage patterns

**Complexity**: Low

**Tasks**:
- [ ] Create decision matrix document (docs/hybrid-architecture-guide.md):
  - When to use .claude/ (multi-phase, orchestrated, critical workflows)
  - When to use OpenCode (single-phase, exploratory, advisory workflows)
  - Example scenarios for each category
- [ ] Document command migration status:
  - /create-plan: Keep in .claude/ (requires state machine)
  - /implement: Keep in .claude/ (wave-based execution, checkpoints)
  - /revise: Keep in .claude/ (state machine, hard barriers)
  - /test: Keep in .claude/ (test → debug loop)
  - /research-simple: Ported to OpenCode (single-phase, advisory)
  - /code-review: Created in OpenCode (read-only analysis)
  - /docs-gen: Created in OpenCode (documentation generation)
- [ ] Create architecture diagram showing hybrid workflow:
  - .claude/ for production automation
  - OpenCode for interactive exploration
  - Shared agents and standards
- [ ] Document MCP tool usage patterns for command authors
- [ ] Create troubleshooting guide for common migration issues
- [ ] Add examples of when to choose each system

**Decision Matrix**:

| Criterion | Use .claude/ | Use OpenCode |
|-----------|-------------|--------------|
| **Workflow Type** | Multi-phase (research → plan → implement) | Single-phase (research only) |
| **State Tracking** | Required (checkpoints, resumption) | Not needed (ephemeral sessions) |
| **Verification** | Hard barriers required (mandatory) | Soft verification acceptable |
| **Execution** | Critical automation (must succeed) | Exploratory (partial success OK) |
| **Parallelization** | Wave-based execution needed | Sequential execution acceptable |
| **Error Recovery** | Required (JSONL logging, /repair) | Optional (manual retry) |

**Example Scenarios**:

**Scenario 1 - Choose .claude/**:
> "I need to implement a new authentication system across 10 files with comprehensive testing, documentation, and rollback plan. The workflow must be resumable if interrupted."
>
> **Why .claude/**: Multi-phase workflow (research → plan → implement → test), requires checkpoints for resumption, hard barriers for phase verification, error logging for debugging.
>
> **Command**: `/create-plan "authentication system"` → `/implement plan.md`

**Scenario 2 - Choose OpenCode**:
> "I want to quickly research JWT best practices in the codebase to inform a design decision. Partial analysis is acceptable."
>
> **Why OpenCode**: Single-phase research, advisory purpose (not critical), no state tracking needed, exploratory workflow.
>
> **Command**: `opencode /research-simple "JWT best practices"`

**Testing**:
```bash
# Verify documentation structure
test -f docs/hybrid-architecture-guide.md
test -f docs/mcp-tool-usage.md
test -f docs/troubleshooting-migration.md

# Verify decision matrix completeness
grep -q "Decision Matrix" docs/hybrid-architecture-guide.md
grep -q "Example Scenarios" docs/hybrid-architecture-guide.md

# Validate architecture diagram exists
test -f docs/diagrams/hybrid-architecture.svg
```

**Expected Duration**: 2-3 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["documentation-checklist.md", "diagram-assets/"]

---

### Phase 8: Integration Testing and Validation [NOT STARTED]
dependencies: [1, 2, 3, 4, 5, 6, 7]

**Objective**: Comprehensive end-to-end testing of OpenCode integration with validation of all components

**Complexity**: Medium

**Tasks**:
- [ ] Create integration test suite (tests/integration/opencode-integration-test.sh):
  - Test 1: Agent conversion validation (all 19 agents functional)
  - Test 2: MCP tool functionality (state-management, error-logging, workflow-orchestration)
  - Test 3: Command execution (/research-simple, /code-review, /docs-gen)
  - Test 4: Agent delegation (description-based and @mention)
  - Test 5: Standards compliance (AGENTS.md sections loaded correctly)
  - Test 6: Hybrid workflow (use .claude/ and OpenCode in sequence)
- [ ] Run full test suite with 20+ test cases
- [ ] Validate context reduction metrics (metadata-only passing achieves 95%+)
- [ ] Performance benchmarking:
  - Compare .claude/ /research vs OpenCode /research-simple (time, token usage)
  - Measure MCP tool overhead vs native bash libraries
- [ ] Error scenario testing:
  - Agent delegation failure propagation
  - MCP tool connection failures (graceful degradation)
  - Invalid AGENTS.md syntax handling
- [ ] Create validation report with metrics and recommendations
- [ ] Document known limitations and future enhancement opportunities

**Integration Test Cases**:

**Test 1 - Agent Conversion Validation**:
```bash
# Verify all 19 agents converted and functional
AGENTS=(
  research-coordinator research-specialist plan-architect
  implementation-executor topic-naming-agent complexity-estimator
  # ... (all 19 agents)
)

for agent in "${AGENTS[@]}"; do
  echo "Testing $agent..."
  opencode @$agent "Quick test invocation" || { echo "FAIL: $agent"; exit 1; }
done

echo "✓ All 19 agents functional"
```

**Test 6 - Hybrid Workflow**:
```bash
# Use .claude/ for planning, OpenCode for quick research follow-up

# Step 1: Create plan using .claude/ (complex orchestration)
cd ~/.config/.claude
/create-plan "API rate limiting implementation"

# Step 2: Quick research using OpenCode (single-phase)
cd ~/.config
opencode /research-simple "Rate limiting algorithms comparison"

# Verify both artifacts created
test -f .claude/specs/*/plans/*rate_limiting*.md
test -f .claude/specs/*/reports/*rate_limiting_algorithms*.md

echo "✓ Hybrid workflow completed successfully"
```

**Performance Benchmarking**:
```bash
# Benchmark .claude/ /research vs OpenCode /research-simple
time /research "authentication patterns" --complexity 2
# Record: time, token count, artifact quality

time opencode /research-simple "authentication patterns"
# Record: time, token count, artifact quality

# Compare metrics:
# .claude/ expected: 120s, 15000 tokens, comprehensive report
# OpenCode expected: 60s, 8000 tokens, quick analysis
# Trade-off: Speed vs depth (acceptable for exploratory workflows)
```

**Testing**:
```bash
# Run integration test suite
bash tests/integration/opencode-integration-test.sh

# Expected output:
# Running integration test suite for OpenCode migration...
#
# Test 1: Agent conversion validation          ✓ PASS (19/19 agents)
# Test 2: MCP tool functionality                ✓ PASS (3/3 tools)
# Test 3: Command execution                     ✓ PASS (3/3 commands)
# Test 4: Agent delegation                      ✓ PASS (5/5 scenarios)
# Test 5: Standards compliance                  ✓ PASS (AGENTS.md loaded)
# Test 6: Hybrid workflow                       ✓ PASS (plan + research)
#
# Integration test results: 6/6 tests passed (100%)
# Context reduction achieved: 95.6%
# Performance: OpenCode ~50% faster for single-phase workflows
#
# Validation report: tests/integration/validation-report.md
```

**Validation Report Metrics**:
- Agent conversion success rate: 100% (19/19)
- MCP tool reliability: 100% (all tools functional)
- Command success rate: 100% (3/3 commands)
- Context reduction: 95.6% (metadata-only passing)
- Performance improvement: 50% faster for single-phase workflows
- Known limitations: 5 items documented

**Expected Duration**: 4-5 hours

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["integration-test-results.json", "validation-report.md", "benchmarks.csv"]

---

## Testing Strategy

### Overall Testing Approach

**Unit Testing**:
- Each MCP tool function tested individually (init_workflow_state, log_command_error, etc.)
- Agent YAML frontmatter validation (syntax, required fields)
- Command template rendering with sample inputs

**Integration Testing**:
- End-to-end agent delegation workflows (coordinator → specialist)
- MCP tool chain testing (state-management → error-logging → workflow-orchestration)
- Hybrid workflow scenarios (.claude/ plan → OpenCode research)

**Performance Testing**:
- Context reduction metrics (metadata-only passing vs full content)
- Token usage comparison (.claude/ vs OpenCode for equivalent workflows)
- MCP tool overhead measurement vs native bash libraries

**Validation Testing**:
- Standards compliance (AGENTS.md sections loaded correctly)
- Model mapping verification (sonnet-4.5 → anthropic/claude-sonnet-4-20250514)
- Agent conversion completeness (all 19 agents functional)

### Test Coverage Requirements

**Minimum Coverage**:
- MCP tools: 90% code coverage (critical state management logic)
- Agent conversion: 100% (all 19 agents must convert successfully)
- Command execution: 100% (all created commands must work)
- Integration tests: 90% of use cases covered

**Test Artifact Generation**:
- JUnit XML reports for CI integration
- Coverage reports (LCOV format)
- Performance benchmarks (CSV)
- Validation reports (Markdown)

### Continuous Validation

**Pre-commit Hooks**:
- Validate AGENTS.md syntax before commits
- Check MCP tool TypeScript compilation
- Run agent YAML validation

**CI/CD Integration** (future):
- Automated integration test suite on push
- Performance regression detection
- Documentation freshness checks

## Documentation Requirements

### Required Documentation

1. **Hybrid Architecture Guide** (docs/hybrid-architecture-guide.md):
   - Decision matrix for .claude/ vs OpenCode
   - Example scenarios for each system
   - Migration status of commands

2. **MCP Tool Usage Guide** (docs/mcp-tool-usage.md):
   - Tool function reference (state-management, error-logging, workflow-orchestration)
   - Usage patterns for command authors
   - Error handling and graceful degradation

3. **Agent Conversion Guide** (docs/agent-conversion-guide.md):
   - YAML frontmatter format specification
   - Model mapping table
   - Tool permission configuration

4. **Standards Migration Guide** (docs/standards-migration-guide.md):
   - CLAUDE.md → AGENTS.md section mapping
   - Bash pattern adaptations (sourcing → MCP, state → JSON)
   - Combined rules behavior (global + project)

5. **Troubleshooting Guide** (docs/troubleshooting-migration.md):
   - Common migration issues and solutions
   - MCP tool connection failures
   - Agent delegation debugging

6. **README Updates**:
   - Update ~/.config/opencode/README.md with project overview
   - Update ~/.config/.claude/README.md with hybrid architecture notes
   - Add cross-references between systems

### Documentation Standards Compliance

All documentation MUST follow:
- Clear, concise language (no historical commentary)
- Code examples with syntax highlighting
- Unicode box-drawing for diagrams (no emojis)
- CommonMark specification
- Navigation links between related docs

### Update Existing Documentation

- [ ] Update .claude/docs/port_to_opencode.md with implementation status
- [ ] Add OpenCode integration notes to CLAUDE.md
- [ ] Update agent behavioral files with OpenCode conversion status
- [ ] Create migration changelog documenting all adaptations

## Dependencies

### External Dependencies

**Required Software**:
- OpenCode CLI (latest stable version)
- Node.js ≥18.x (for MCP tool development)
- TypeScript ≥5.x (for MCP tool compilation)
- jq (for JSON manipulation in tests)
- yq (for YAML validation)

**MCP Tool Dependencies**:
- @opencode/mcp-sdk (MCP server development)
- @anthropic-ai/sdk (if direct API integration needed)
- typescript, ts-node (compilation and execution)

**Development Dependencies**:
- jest (MCP tool unit testing)
- eslint, prettier (code quality)
- bash-tap (bash test framework for integration tests)

### Configuration Prerequisites

- OpenCode API key configured (Anthropic Claude API)
- ~/.config/opencode/config.json with MCP server entries
- Permission settings for external directory access

### Migration Prerequisites

- Full .claude/ configuration functional (baseline for comparison)
- All 19 agent files in .claude/agents/ (source for conversion)
- CLAUDE.md with all standards sections (source for AGENTS.md)
- 43 bash libraries in .claude/lib/ (source for MCP tool implementation)

## Risk Mitigation

### Known Risks

**Risk 1 - MCP Tool Performance Overhead**:
- Impact: MCP tool invocation slower than native bash sourcing
- Mitigation: Benchmark and optimize hot paths, cache frequently accessed state
- Fallback: Document performance trade-off as acceptable for OpenCode's UX benefits

**Risk 2 - Agent Delegation Unreliability**:
- Impact: Description-based invocation not guaranteed (LLM chooses whether to delegate)
- Mitigation: Provide clear delegation instructions in coordinator prompts
- Fallback: Use @mention for critical delegations, document soft contract limitations

**Risk 3 - Context Reduction Pattern Adoption**:
- Impact: Metadata-only passing requires discipline (agents may return full content)
- Mitigation: Include return format examples in agent prompts, validate outputs
- Fallback: Accept higher context usage initially, optimize iteratively

**Risk 4 - Standards Divergence Between Systems**:
- Impact: .claude/ and OpenCode standards drift over time (CLAUDE.md vs AGENTS.md)
- Mitigation: Create sync script to propagate CLAUDE.md changes to AGENTS.md
- Fallback: Document divergence as acceptable (systems serve different purposes)

**Risk 5 - OpenCode Evolution Breaking Changes**:
- Impact: Future OpenCode updates change agent/command/MCP APIs
- Mitigation: Pin OpenCode version in documentation, test upgrades before adopting
- Fallback: Maintain version compatibility matrix, document upgrade path

### Rollback Plan

If migration fails critical validation:

1. **Preserve .claude/ Configuration**: No changes to existing .claude/ commands/agents
2. **Isolate OpenCode Experiment**: Keep all OpenCode artifacts in separate directory
3. **Document Failures**: Create lessons-learned document for future attempts
4. **Revert to .claude/ Only**: Continue using .claude/ for all workflows until issues resolved

**Rollback Triggers**:
- Integration test success rate <80%
- MCP tool reliability <90%
- Context reduction <85%
- Agent delegation success rate <75%

## Next Steps After Completion

### Immediate Follow-Up

1. **Production Usage**: Use OpenCode for exploratory workflows in real projects
2. **Feedback Collection**: Document user experience, identify pain points
3. **Performance Optimization**: Address any bottlenecks in MCP tools or agent delegation
4. **Documentation Iteration**: Update guides based on actual usage patterns

### Future Enhancements

**Priority 2 MCP Tools** (if Priority 1 successful):
- validation-utils MCP server (ports validation-utils.sh)
- format-utils MCP server (ports format-utils.sh)
- git-utils MCP server (ports git-utils.sh)

**OpenCode Feature Requests** (if limitations block usage):
- Background bash execution (GitHub issue #1970)
- State machine support (propose to OpenCode maintainers)
- Hard barrier verification mechanism (proposal for TaskTool enhancement)

**Hybrid Architecture Evolution**:
- Create automation to sync CLAUDE.md → AGENTS.md changes
- Develop command migration tool (convert .claude/ command → OpenCode template)
- Build decision support tool (analyze workflow, recommend .claude/ vs OpenCode)

### Long-Term Vision

**Goal**: Seamless integration where users choose .claude/ or OpenCode based on workflow needs, with shared agents and standards ensuring consistency.

**Success Metrics**:
- 80% of exploratory workflows use OpenCode (faster, more interactive)
- 100% of production workflows use .claude/ (reliable, resumable)
- Context reduction sustained at 95%+ (metadata-only passing)
- Zero standards drift between systems (automated sync)

## Appendices

### Appendix A: Agent Conversion Checklist

For each of 19 agents in .claude/agents/:

- [ ] Parse frontmatter (allowed-tools, model, description)
- [ ] Map allowed-tools → tools/permission fields
- [ ] Map model (sonnet-4.5 → anthropic/claude-sonnet-4-20250514)
- [ ] Set mode (primary, subagent, or all)
- [ ] Preserve system prompt body
- [ ] Validate YAML syntax
- [ ] Test invocation via OpenCode CLI
- [ ] Document conversion status

**Agent List**:
1. research-coordinator
2. research-specialist
3. plan-architect
4. implementation-executor
5. implementer-coordinator
6. topic-naming-agent
7. complexity-estimator
8. (remaining 12 agents from .claude/agents/)

### Appendix B: MCP Tool API Reference

**state-management MCP Server**:

```typescript
// Tool: init_workflow_state
interface InitWorkflowStateArgs {
  workflow_name: string;
}
interface InitWorkflowStateResult {
  workflow_id: string;
  state_file: string;
}

// Tool: append_workflow_state
interface AppendWorkflowStateArgs {
  workflow_id: string;
  var_name: string;
  var_value: string;
}
interface AppendWorkflowStateResult {
  success: boolean;
}

// Tool: load_workflow_state
interface LoadWorkflowStateArgs {
  workflow_id: string;
}
interface LoadWorkflowStateResult {
  vars: Record<string, string>;
}

// Tool: discover_latest_state_file
interface DiscoverLatestStateFileArgs {
  workflow_name: string;
}
interface DiscoverLatestStateFileResult {
  state_file: string | null;
  workflow_id: string | null;
}
```

**error-logging MCP Server**:

```typescript
// Tool: log_command_error
interface LogCommandErrorArgs {
  error_type: 'validation_error' | 'agent_error' | 'state_error' | 'execution_error';
  message: string;
  details: Record<string, unknown>;
  workflow_id?: string;
  command?: string;
}
interface LogCommandErrorResult {
  logged: boolean;
  timestamp: string;
}

// Tool: query_errors
interface QueryErrorsArgs {
  command?: string;
  error_type?: string;
  since?: string; // ISO timestamp
  limit?: number;
}
interface QueryErrorsResult {
  errors: Array<{
    timestamp: string;
    workflow_id: string;
    command: string;
    error_type: string;
    message: string;
    details: Record<string, unknown>;
  }>;
}
```

**workflow-orchestration MCP Server**:

```typescript
// Tool: sm_init
interface SmInitArgs {
  workflow_id: string;
  command: string;
  workflow_type: 'linear' | 'branching';
  complexity?: number;
}
interface SmInitResult {
  state: 'initialize';
  timestamp: string;
}

// Tool: sm_transition
interface SmTransitionArgs {
  workflow_id: string;
  target_state: 'initialize' | 'research' | 'plan' | 'implement' | 'test' | 'debug' | 'document' | 'complete';
  reason?: string;
}
interface SmTransitionResult {
  previous_state: string;
  current_state: string;
  timestamp: string;
}

// Tool: sm_get_state
interface SmGetStateArgs {
  workflow_id: string;
}
interface SmGetStateResult {
  current_state: string;
  history: Array<{ state: string; timestamp: string }>;
}
```

### Appendix C: Command Migration Status

| .claude/ Command | Migration Status | OpenCode Equivalent | Notes |
|-----------------|------------------|---------------------|-------|
| /research | NOT MIGRATED | /research-simple (created) | Complex version stays in .claude/, simple version in OpenCode |
| /create-plan | NOT MIGRATED | N/A | Requires state machine, stays in .claude/ |
| /implement | NOT MIGRATED | N/A | Requires wave-based execution, stays in .claude/ |
| /revise | NOT MIGRATED | N/A | Requires state machine, stays in .claude/ |
| /test | NOT MIGRATED | N/A | Requires test → debug loop, stays in .claude/ |
| /debug | NOT MIGRATED | N/A | Requires error log integration, stays in .claude/ |
| /repair | NOT MIGRATED | N/A | Requires error log querying, stays in .claude/ |
| /errors | CANDIDATE | /errors-query (TBD) | Could port as simple JSONL query command |
| /todo | CANDIDATE | /todo-update (TBD) | Could port as simple file update command |
| /expand | NOT MIGRATED | N/A | Requires plan structure manipulation, stays in .claude/ |
| /collapse | NOT MIGRATED | N/A | Requires plan structure manipulation, stays in .claude/ |
| (none) | NEW | /code-review | New OpenCode-only command for read-only analysis |
| (none) | NEW | /docs-gen | New OpenCode-only command for documentation generation |

**Legend**:
- NOT MIGRATED: Complex orchestration required, stays in .claude/
- CANDIDATE: Could potentially port with simplified version
- NEW: Created specifically for OpenCode (no .claude/ equivalent)

### Appendix D: Troubleshooting Common Issues

**Issue 1: Agent invocation fails with "agent not found"**

*Symptom*:
```
Error: Agent 'research-specialist' not found
```

*Diagnosis*:
```bash
# Check agent file exists
test -f ~/.config/opencode/agent/research-specialist.md || echo "Missing agent file"

# Validate YAML frontmatter
awk '/^---$/,/^---$/' ~/.config/opencode/agent/research-specialist.md | yq eval '.' -
```

*Solution*:
- Verify agent file in correct directory (~/.config/opencode/agent/)
- Validate YAML frontmatter syntax (required fields: mode, model, description)
- Check OpenCode config recognizes agent directory: `opencode config show`

**Issue 2: MCP tool connection fails**

*Symptom*:
```
Error: Failed to connect to MCP server 'state-management'
```

*Diagnosis*:
```bash
# Check MCP server running
ps aux | grep state-management

# Check config.json has MCP server entry
jq '.mcpServers."state-management"' ~/.config/opencode/config.json
```

*Solution*:
- Verify MCP server compiled: `cd mcp-servers/state-management && npm run build`
- Check config.json has correct path to MCP server binary
- Test MCP server independently: `node dist/index.js` (should start without errors)
- Check OpenCode logs for connection errors: `~/.config/opencode/logs/mcp.log`

**Issue 3: Metadata-only passing returns full content**

*Symptom*:
Agent returns full report content instead of metadata, causing context bloat.

*Diagnosis*:
Review agent prompt for clear return format instructions.

*Solution*:
Update agent prompt with explicit return format:
```markdown
**CRITICAL - RETURN FORMAT**:
Return ONLY metadata (not full content):
{
  "findings_count": 8,
  "report_path": "/absolute/path/to/report.md"
}

DO NOT include full report text in response.
```

**Issue 4: AGENTS.md sections not loaded**

*Symptom*:
Agent behavior ignores project standards from AGENTS.md.

*Diagnosis*:
```bash
# Verify AGENTS.md files exist
test -f ~/.config/opencode/AGENTS.md || echo "Missing global AGENTS.md"
test -f .opencode/AGENTS.md || echo "Missing project AGENTS.md"

# Check OpenCode loads both files
opencode config show | grep AGENTS.md
```

*Solution*:
- Ensure AGENTS.md in correct locations (global: ~/.config/opencode/, project: .opencode/)
- Verify CommonMark syntax (no parsing errors)
- Test agent behavior explicitly references AGENTS.md content in responses

---

**Plan Completion**: 2025-12-10
**Total Estimated Hours**: 28-36 hours
**Total Phases**: 8
**Dependencies**: Complete dependency graph enables parallel execution where possible (e.g., Phases 2 and 3 can run in parallel after Phase 1)
