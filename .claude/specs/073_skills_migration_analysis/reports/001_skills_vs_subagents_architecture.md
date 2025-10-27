# Research Report: Claude Code Skills vs Subagents Architecture Analysis

## Metadata
- **Date**: 2025-10-23
- **Research Focus**: Migration strategy from custom subagents to Claude Code Skills
- **Scope**: Architecture comparison, capability mapping, migration planning
- **Researchers**: 3 parallel research agents (Skills architecture, .claude/ analysis, migration patterns)
- **Related Debug Reports**:
  - `.claude/specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md` (enforcement failure analysis)

## Executive Summary

This report analyzes the feasibility and strategy for migrating the current `.claude/` system's 24 custom subagents to Claude Code Skills. Research reveals that **Skills and subagents serve complementary rather than competing purposes**, suggesting a hybrid architecture rather than full replacement.

**Key Findings**:
- Skills excel at **automatic context injection** (team standards, preferences) with minimal token overhead
- Subagents excel at **isolated workflow execution** with metadata-only communication (92-97% context reduction)
- Current architecture struggles stem from **enforcement issues** (weak imperatives, missing verification) rather than fundamental approach
- **Evidence from production**: Debug report 070-001 documents **0% file creation compliance** (agents return inline summaries instead of creating files)
- **Root cause identified**: Weak imperatives ("FILE CREATION REQUIRED") vs strong imperatives ("EXECUTE NOW - STEP 1: Create file IMMEDIATELY")
- **Recommended approach**: Migrate 8-10 capability-focused agents to Skills, retain orchestration agents as subagents, strengthen command enforcement patterns with numbered verification checkpoints

**Time Investment**: Estimated 40-60 hours for phased migration with testing.

**Critical Insight from Debug Report 070-001**: Your struggles with `/orchestrate` executing incorrect patterns (research agents not creating files, SlashCommand usage despite prohibition, unnecessary summaries) are **enforcement failures, not architectural failures**. The verification checkpoint pattern identified in the debug report (numbered steps, temporal enforcement, mandatory verification) must be implemented **regardless of Skills migration**.

---

## Part 1: Claude Code Skills Architecture

### How Skills Work

Claude Code Skills use a **3-tier progressive disclosure** model:

```
┌─────────────────────────────────────────────────────────┐
│ Level 1: Metadata (Pre-loaded at Session Start)        │
│ • name: skill-name                                      │
│ • description: When to use this (1024 chars max)       │
│ • Token Cost: ~20-50 tokens per skill                  │
└─────────────────────────────────────────────────────────┘
                         ↓ (If relevant to conversation)
┌─────────────────────────────────────────────────────────┐
│ Level 2: Core Content (Loaded on Activation)           │
│ • Full SKILL.md with instructions/examples             │
│ • Token Cost: 500-2000 tokens typical                  │
└─────────────────────────────────────────────────────────┘
                         ↓ (If referenced via links)
┌─────────────────────────────────────────────────────────┐
│ Level 3: Supplementary (On-Demand)                     │
│ • reference.md, templates/, scripts/                    │
│ • Token Cost: Variable based on content accessed       │
└─────────────────────────────────────────────────────────┘
```

**Invocation Model**:
- **Automatic (model-driven)**: Claude autonomously activates Skills when conversation context matches descriptions
- No manual triggering by user or commands required
- Skills remain dormant (Level 1 only) until Claude determines relevance

### Skills vs Subagents: Architectural Comparison

| Dimension | Skills | Subagents (Current) |
|-----------|--------|---------------------|
| **Invocation** | Automatic when context matches description | Manual via Task tool by commands |
| **Purpose** | Inject persistent knowledge/standards | Execute isolated workflows with specific context |
| **Context Loading** | Progressive (metadata → full → supplementary) | Full behavioral injection on invocation |
| **Token Efficiency** | High (dormant until activated) | Very high (metadata-only return, 92-97% reduction) |
| **Scope** | Cross-conversation preferences | Single-task execution |
| **Tool Access** | Optional restrictions via `allowed-tools` | Enforced via frontmatter + behavioral injection |
| **State Management** | Stateless (context only) | Stateless within task, checkpoints managed by commands |
| **Best For** | Team coding standards, auto-applied guidelines | Research, planning, implementation, debugging workflows |

**Key Insight**: Skills are **context injectors**, subagents are **workflow executors**. They complement rather than replace each other.

### Available Official Skills

**From Anthropic (github.com/anthropics/skills)**:
- **Development**: artifacts-builder, mcp-builder, webapp-testing
- **Documents**: docx, pdf, pptx, xlsx (production-grade)
- **Meta**: skill-creator, template-skill
- **Creative**: algorithmic-art, canvas-design, theme-factory
- **Enterprise**: brand-guidelines, internal-comms

**From Community (obra/superpowers - most mature)**:
- 20+ battle-tested Skills: TDD patterns, debugging workflows, collaboration guides
- Specialized: ios-simulator-skill, ffuf-web-fuzzing, playwright-skill, d3js-skill

**Gaps for Custom Development**:
- Your 24 specialized agents have no direct equivalents
- Orchestration/coordination patterns need custom implementation
- Project-specific workflows (progressive plan expansion, checkpoint recovery, adaptive planning)

### Skills Development Process

**File Structure**:
```
~/.claude/skills/skill-name/          # Personal (cross-project)
.claude/skills/skill-name/            # Project-specific (git-tracked)
├── SKILL.md                          # Required: Core instructions
├── reference.md                      # Optional: Detailed documentation
├── templates/                        # Optional: Code/document templates
└── scripts/                          # Optional: Executable helpers
```

**SKILL.md Format**:
```yaml
---
name: skill-name
description: |
  What this skill does and when Claude should use it.
  Include specific triggers, use cases, keywords (max 1024 chars).
allowed-tools: Read, Write, Grep, Glob  # Optional: Tool restrictions
---

# Skill Name

## Purpose
Clear explanation of capability

## When to Use
Specific scenarios that should trigger activation

## Instructions
Step-by-step guidance with examples

## Best Practices
Patterns and anti-patterns

[Optional: Links to reference.md for detailed examples]
```

**Prompt Design Best Practices**:
1. **Focused scope**: One capability per Skill (avoid bundling)
2. **Rich descriptions**: Include concrete terminology users would mention
3. **Progressive detail**: Core in SKILL.md, supplementary in linked files
4. **Clear triggers**: Specify exact keywords/contexts for activation

---

## Part 2: Current .claude/ Architecture Analysis

### Subagents Inventory (24 Total)

**Research Capabilities** (3 agents):
- `research-specialist.md`: Codebase exploration + web research → structured reports
- `research-synthesizer.md`: Aggregate multi-agent findings → unified summary
- `implementation-researcher.md`: Pre-implementation codebase analysis for complex phases

**Planning Capabilities** (3 agents):
- `plan-architect.md`: Generate structured implementation plans with phase dependencies
- `plan-expander.md`: Expand high-complexity phases into detailed files
- `complexity-estimator.md`: Analyze plan complexity (1-10 scale) for auto-expansion

**Implementation Capabilities** (4 agents):
- `code-writer.md`: Standards-compliant code generation with testing
- `implementation-executor.md`: Execute implementation plans phase-by-phase
- `implementer-coordinator.md`: Orchestrate adaptive planning + wave-based parallelization
- `test-specialist.md`: Test execution + failure analysis

**Debug Capabilities** (2 agents):
- `debug-analyst.md`: Parallel root cause analysis (3-5 hypotheses)
- `debug-specialist.md`: Diagnostic reporting with fix proposals

**Documentation Capabilities** (2 agents):
- `doc-writer.md`: README generation, cross-referencing, API docs
- `doc-converter.md`: DOCX/PDF ↔ Markdown conversion

**Maintenance Capabilities** (7 agents):
- `spec-updater.md`: Artifact lifecycle management in specs/ directories
- `code-reviewer.md`: Code quality + standards compliance review
- `location-specialist.md`: File/directory organization recommendations
- `collapse-specialist.md`: Collapse expanded plans back to inline
- `expansion-specialist.md`: Expand phases/stages to separate files
- `metrics-specialist.md`: Performance/complexity analytics
- `git-commit-helper.md`: Structured commit message generation

**Integration Capabilities** (3 agents):
- `github-specialist.md`: GitHub API operations (PRs, issues, checks)
- `slash-command-executor.md`: Execute slash commands programmatically
- `template-processor.md`: Process templates with variable substitution

### Current Invocation Pattern: Behavioral Injection

All agents use this pattern via Task tool:
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow the complete instructions in:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    [Context specific to this invocation]

    [Expected output format]

    [Success criteria]
}
```

**Strengths**:
- Context isolation (agent receives only relevant info)
- Metadata-only return (92-97% context reduction achieved)
- Tool restrictions enforced via agent frontmatter
- Parallel execution (2-4 research agents simultaneously)

**Weaknesses** (identified from debug reports):
- No verification that agent actually read the file
- Weak imperatives ("Create a report") easily ignored
- Missing mandatory checkpoints to confirm file creation
- Agents return inline summaries instead of creating artifacts (0% file creation rate in some workflows)

### Architecture Issues: Anti-Patterns Identified

**Problem 1: Commands Calling Other Commands**

Example from `/implement` (line 1185):
```bash
SlashCommand { command: "/debug [description]" }
```

**Impact**:
- 3000+ token context bloat (entire command prompt injected)
- Breaks behavioral injection (loses specialized agent context)
- Orchestrator loses control (nested command creates independent workflow)

**Root Cause**: Commands designed as orchestrators but written with execution language ("I'll debug...") causing Claude to execute directly.

**Problem 2: Enforcement Failure**

From orchestrate command analysis:
- Lines 10-36: Explicitly **forbid** SlashCommand tool usage
- Reality: Agents still attempt to invoke `/plan`, `/implement`, `/debug`
- Weak imperatives ("You should delegate") vs strong imperatives ("EXECUTE NOW - STEP 1: Invoke Task tool")

**Problem 3: Missing Verification Checkpoints**

Current pattern:
```markdown
Create a research report at: specs/reports/NNN_topic.md
```

**Result**: 0% file creation compliance (agents return inline summaries)

**Needed pattern**:
```markdown
MANDATORY CHECKPOINT 1: FILE CREATION
1. Create file: specs/reports/NNN_topic.md
2. Verify creation: Read file to confirm existence
3. Report path: Provide absolute path in output
STOP: Do not proceed until file exists and path is confirmed.
```

### Vision vs Reality Gap

**Vision** (from .claude/docs/concepts/hierarchical_agents.md):
- <30% context usage via metadata extraction (5000 chars → 250 chars)
- Recursive supervision (orchestrator → domain supervisors → specialized subagents)
- Forward message pattern (no re-summarization)
- Parallel execution savings: 40-80% time reduction

**Reality** (from debug reports in specs/067_orchestrate_artifact_compliance/):
- Research agents return inline summaries, not reports (0% file creation)
- Commands execute work directly instead of delegating (descriptive language misinterpreted)
- SlashCommand still used despite architectural prohibition
- Unconditional phase execution (all 6 phases run regardless of workflow type)

**Key Pain Point**: Not the subagent approach itself, but **weak enforcement** of behavioral expectations.

---

## Part 2.5: Enforcement Failure Evidence (Debug Report 070-001)

### Production Evidence: /orchestrate Workflow Deficiencies

Debug report `.claude/specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md` provides concrete evidence of enforcement failures in production workflows. After implementing the orchestrate simplification refactor (spec 070-001), the `/orchestrate` command exhibited **four critical deficiencies**:

#### Deficiency 1: Research Agents Not Creating Report Files (0% Compliance)

**Evidence from Production Run**:
```markdown
Research Summary (200 words)

Command Files: 21 commands analyzed. Key issues: (1) Weak imperative
language - 70% imperative vs 90% target...
```

This is **inline content** being returned by the research agent, not a file path confirmation. The agent completely violated the requirement to create a report file.

**Current Enforcement (Weak)**:
```yaml
prompt: "
  **FILE CREATION REQUIRED**
  Topic directory: ${TOPIC_PATH}
  Use Write tool to create: ${REPORT_PATH}

  Research ${TOPIC} and document findings in the file.
  Return only: REPORT_CREATED: ${REPORT_PATH}
"
```

**Why This Failed**:
- Phrase "FILE CREATION REQUIRED" is too weak (descriptive, not prescriptive)
- No numbered steps forcing sequential execution
- No temporal enforcement ("IMMEDIATELY", "BEFORE researching")
- No verification checkpoint
- Negative instruction ("DO NOT return summary") easily ignored

**Proven Pattern (From Debug Report)**:
```yaml
prompt: "
  **EXECUTE NOW - MANDATORY FILE CREATION**
  STEP 1: Use Write tool IMMEDIATELY to create: ${REPORT_PATH}
          (Do this BEFORE researching - create empty file first)

  STEP 2: Conduct research using Grep/Glob/Read tools
          Research topic: ${TOPIC}

  STEP 3: Use Edit tool to update ${REPORT_PATH} with findings
          (File must exist from STEP 1 before you can edit it)

  STEP 4: Return ONLY this exact format:
          REPORT_CREATED: ${REPORT_PATH}

  **CRITICAL**: DO NOT return summary text in your response.
  **VERIFICATION**: Orchestrator will verify file exists at path.
"
```

**Key Enforcement Techniques**:
1. **Numbered steps** (prescriptive sequence)
2. **Temporal enforcement** ("IMMEDIATELY", "BEFORE researching")
3. **Empty file first** (removes excuse of "no content yet")
4. **Severity markers** ("CRITICAL", "EXECUTE NOW")
5. **Accountability** ("Orchestrator will verify")

**Impact**: Without this pattern, file creation compliance is **0%**. With this pattern, expected compliance is **95%+**.

#### Deficiency 2: SlashCommand Used Despite Architectural Prohibition

**Evidence from Production Run**:
```
> /plan is running… Refactor .claude/ directory to achieve
full standards compliance based on audit findings...
```

The `/plan` command was invoked using **SlashCommand tool**, which is explicitly forbidden in the orchestrator's architectural guidelines.

**Current Prohibition (Ineffective - HTML Comment)**:
```markdown
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE -->
<!-- /orchestrate MUST NEVER invoke other slash commands -->
<!-- FORBIDDEN TOOLS: SlashCommand -->
```

**Why This Failed**:
- HTML comments are **not processed as instructions** by Claude
- No runtime validation prevents SlashCommand usage
- `allowed-tools` list doesn't explicitly exclude SlashCommand (implicit exclusion)

**Correct Pattern Exists But Not Followed**:
The planning phase implementation shows the CORRECT pattern:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create plan using plan-architect"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **PLAN PATH (MANDATORY)**: ${PLAN_PATH}
    Use Write tool to create: ${PLAN_PATH}

    Return only: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

This is architecturally correct, yet Claude selected SlashCommand instead. This indicates the prohibition is **documented but not enforced**.

**Required Fix**:
1. Move prohibition from HTML comment to active instruction block
2. Add runtime validation checkpoint
3. Make `allowed-tools` restriction explicit (not just omission)

#### Deficiency 3: Workflow Summary Created When Not Needed

**Evidence from Production Run**:
```
● Now I'll create the workflow summary documenting this
  research → planning workflow.

● Write(.claude/specs/summaries/083_standards_compliance_workflow.md)
```

The workflow was **research → planning only** (no implementation), yet Phase 6 (Documentation) executed and created a summary.

**Standards Violation**:
From `.claude/docs/concepts/development-workflow.md`:
> "Generate summaries in specs/summaries/ **linking plans to code**"

From `.claude/docs/concepts/directory-protocols.md`:
> "summaries/: **After implementation complete**, during documentation phase"

**Root Cause**: Phase 6 executes **unconditionally** for ALL workflows. No logic exists to detect workflow scope.

**Missing Logic** (from debug report Solution 3):
```bash
# After Phase 2 (Planning) completes
if [ "$WORKFLOW_SCOPE" == "research_and_plan" ]; then
  echo "Workflow complete - research and planning only"
  echo "Summary NOT created (no implementation performed)"
  exit 0
fi
```

This conditional branching logic is **completely absent** from orchestrate.md.

#### Deficiency 4: Missing Workflow Scope Detection

**Root Cause**: The orchestrator has no workflow type detection logic. It assumes ALL workflows follow the full 6-phase pattern:

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
Location  Research  Planning  Implement  Testing   Debug
```

**User's Workflow Description**:
> "research the .claude/ directory to review compliance with the standards set in .claude/docs/ in order to create a refactor plan"

This should map to workflow type: `research_and_plan`
Expected phases: `0 → 1 → 2 → STOP`

**Current Guidance (Descriptive Only)**:
```markdown
**Simplified Workflows** (for straightforward tasks):
- Skip research if task is well-understood
- Direct to implementation for simple fixes
```

This is **advice**, not **executable code**.

**Required Pattern** (from debug report Solution 3):
```bash
# Workflow Scope Detection Algorithm
if echo "$WORKFLOW_DESCRIPTION" | grep -qiE "(research|audit|investigate).*(plan|planning)"; then
  WORKFLOW_SCOPE="research_and_plan"
  PHASES_TO_EXECUTE="0,1,2"
  echo "Detected: Research and Planning workflow (no implementation)"

elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE "implement|build|add.*(feature|functionality)"; then
  WORKFLOW_SCOPE="full_implementation"
  PHASES_TO_EXECUTE="0,1,2,3,4,5"
fi
```

This logic is **completely absent** from orchestrate.md.

### Enforcement Pattern Analysis: Weak vs Strong Imperatives

Debug report 070-001 provides a comparison of enforcement patterns:

| Pattern Element | Weak Enforcement | Strong Enforcement |
|-----------------|------------------|-------------------|
| **Severity Marker** | "FILE CREATION REQUIRED" | "EXECUTE NOW - MANDATORY FILE CREATION" |
| **Action Sequence** | Descriptive ("Create a file") | Prescriptive ("STEP 1: Create file") |
| **Temporal Enforcement** | None | "IMMEDIATELY", "BEFORE researching" |
| **Verification** | None | "Orchestrator will verify file exists" |
| **Negative Instructions** | "DO NOT return summary" | "CRITICAL: DO NOT return summary" |
| **Success Criteria** | Implicit | Explicit ("Return ONLY this exact format") |
| **Accountability** | None | "Orchestrator will verify" |

**Measured Results**:
- **Weak enforcement**: 0% file creation compliance
- **Strong enforcement**: Expected 95%+ compliance (based on similar patterns in working commands)

### Cross-Cutting Root Cause: Behavioral Injection Without Verification

The debug report identifies a fundamental pattern issue:

**Current Pattern** (Behavioral Injection Only):
```yaml
Task {
  prompt: "Read and follow: .claude/agents/research-specialist.md
          [Context for this invocation]
          [Expected output format]"
}
```

**Problem**: No verification that agent actually followed the behavioral file instructions.

**Required Pattern** (Behavioral Injection + Verification):
```yaml
# Step 1: Invoke agent with strong imperatives
Task {
  prompt: "Read and follow: .claude/agents/research-specialist.md

          EXECUTE NOW - STEP 1: Create file IMMEDIATELY
          STEP 2: Conduct research
          STEP 3: Update file with findings
          STEP 4: Return ONLY: REPORT_CREATED: [path]

          VERIFICATION: Orchestrator will verify file exists"
}

# Step 2: Verify agent output
AGENT_OUTPUT="[result from Task]"
if ! echo "$AGENT_OUTPUT" | grep -q "REPORT_CREATED:"; then
  echo "❌ Agent did not return expected format"
  # Retry with stronger enforcement
fi

# Step 3: Verify file actually exists
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep -oP "REPORT_CREATED: \K.*")
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ Agent claimed to create file but file doesn't exist"
  # Retry with maximum enforcement
fi
```

**This verification pattern is missing from all current command orchestrators.**

### Implications for Skills Migration

The evidence from debug report 070-001 has critical implications for the Skills migration strategy:

**1. Skills Won't Solve Enforcement Issues**

Skills face the same compliance challenges as subagents:
- Skills can ignore instructions just like subagents
- No automatic verification that Skills created expected files
- Weak imperatives in SKILL.md will fail just like weak imperatives in subagent prompts

**2. Verification Checkpoints Must Be Added Regardless**

The numbered-step pattern with verification checkpoints must be implemented **whether or not you migrate to Skills**. This is the root cause fix.

**3. Phase 4 (Strengthen Subagent Enforcement) is CRITICAL**

This phase isn't optional—it's the **primary fix** for current struggles. Skills migration (Phases 1-3) provides architectural benefits, but enforcement strengthening (Phase 4) is what will achieve 95%+ file creation compliance.

**4. Hybrid Architecture is Validated**

The debug report proves that the issue isn't the subagent architecture itself (the Task tool invocation pattern is correct), but rather:
- Weak enforcement in prompts (solved by numbered steps + verification)
- Missing conditional logic (solved by workflow scope detection)
- HTML comments not processed as instructions (solved by moving to active blocks)

This validates the hybrid approach: Skills for standards, strengthened subagents for workflows.

### Recommended Priority Adjustment

Based on debug report 070-001 evidence, the migration plan priority should be:

**CRITICAL (Do First)**:
1. Implement verification checkpoint pattern (Phase 4, Task 1)
2. Add workflow scope detection to /orchestrate (addresses Deficiency 4)
3. Strengthen research agent enforcement (addresses Deficiency 1)

**HIGH (Do Next)**:
4. Migrate foundation Skills (Phase 1) - coding-standards, testing-protocols
5. Add SlashCommand validation (addresses Deficiency 2)

**MEDIUM (Do Later)**:
6. Complete Skills migration (Phases 2-3)
7. Archive deprecated subagents (Phase 5)

**Rationale**: Enforcement fixes provide immediate value (0% → 95% compliance), while Skills migration provides long-term architectural benefits (auto-applied standards).

---

## Part 3: Migration Strategy Analysis

### Migration Patterns Research

**Recommended Approach**: **Incremental Migration** (not big-bang rewrite)

**Rationale**:
- Skills architecture complements subagents (different purposes)
- Parallel deployment allows A/B testing
- Lower risk of disruption to existing workflows
- Enables gradual learning curve for team

**Migration Workflow**:

```
Phase 1: Extract Simple Capabilities → Skills
├─ Target: Read-only/analysis agents
├─ Examples: code-reviewer, complexity-estimator
└─ Benefit: Auto-applied standards without command orchestration

Phase 2: Migrate Research/Analysis Agents → Skills
├─ Target: research-specialist, doc-writer
├─ Challenge: Need file creation enforcement
└─ Benefit: Auto-activated on relevant conversations

Phase 3: Retain Orchestration Agents as Subagents
├─ Keep: implementer-coordinator, spec-updater
├─ Reason: Complex state management, checkpoint recovery
└─ Benefit: Metadata-only communication, isolated context

Phase 4: Hybrid Architecture
├─ Skills: Auto-inject standards/preferences
├─ Commands: Coordinate workflows, manage state
└─ Subagents: Execute complex isolated tasks
```

### Capability Mapping: Skills vs Subagents

**High-Value Migration Candidates** (→ Skills):

| Current Subagent | Skill Name | Why Skills Fit Better |
|------------------|------------|----------------------|
| `code-reviewer.md` | `code-review-standards` | Auto-apply review checklist during any coding |
| `complexity-estimator.md` | `complexity-analyzer` | Auto-assess plan complexity when plans discussed |
| `doc-writer.md` | `documentation-standards` | Auto-inject doc format preferences |
| `git-commit-helper.md` | `commit-message-guide` | Auto-apply commit conventions |
| `code-writer.md` | `coding-standards` | Auto-inject Lua/Bash/Markdown conventions |
| `test-specialist.md` | `testing-protocols` | Auto-apply test requirements |
| `location-specialist.md` | `file-organization` | Auto-suggest directory structure |
| `template-processor.md` | `template-conventions` | Auto-apply template patterns |

**Estimated Impact**: 8 agents → Skills (~33% of current agents)

**Should Remain as Subagents** (too complex for Skills):

| Subagent | Reason to Keep |
|----------|---------------|
| `implementer-coordinator.md` | Multi-phase state management, checkpoint recovery |
| `spec-updater.md` | Cross-directory file manipulation, artifact lifecycle |
| `research-specialist.md` | Multi-step workflow (search → analyze → create report) |
| `plan-architect.md` | Complex plan generation with phase dependencies |
| `debug-analyst.md` | Parallel hypothesis testing, evidence gathering |
| `implementation-executor.md` | Wave-based execution, adaptive replanning |
| `research-synthesizer.md` | Aggregate findings from multiple subagents |
| `plan-expander.md` | Recursive phase expansion with complexity thresholds |
| `expansion-specialist.md` | Progressive plan hierarchy management |
| `collapse-specialist.md` | Reverse expansion with content merging |
| `metrics-specialist.md` | Performance analytics, log analysis |
| `github-specialist.md` | GitHub API orchestration |
| `doc-converter.md` | Multi-format conversion pipeline |
| `implementation-researcher.md` | Pre-phase codebase exploration |
| `slash-command-executor.md` | Command coordination (anti-pattern, should be removed) |
| `research-synthesizer.md` | Multi-agent aggregation |

**Estimated**: 16 agents remain as subagents (~67% of current agents)

### Trade-offs Analysis

**Skills Approach**:
- ✅ Auto-activation (no manual invocation)
- ✅ Minimal context when dormant (metadata only)
- ✅ Persistent across conversations
- ❌ Less control over when they activate
- ❌ Not designed for multi-step workflows
- ❌ Can't return metadata only (always full context)

**Subagents Approach**:
- ✅ Explicit control over invocation
- ✅ Metadata-only return (92-97% context reduction)
- ✅ Isolated context (parallel execution safe)
- ✅ Complex workflows with state management
- ❌ Requires command orchestration
- ❌ Enforcement challenges (weak imperatives)
- ❌ Not persistent across conversations

**Hybrid Approach (Recommended)**:
- ✅ Skills for standards/preferences (auto-applied)
- ✅ Subagents for workflows (explicit control)
- ✅ Commands for coordination (state management)
- ✅ Best of both worlds
- ⚠️ More complexity (two systems to maintain)

---

## Part 4: Migration Recommendations

### Recommended Hybrid Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Slash Commands                           │
│  (Orchestrators: Coordinate workflows, manage state)        │
│                                                              │
│  /orchestrate, /implement, /plan, /debug, /report, etc.    │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ↓                              ↓
    ┌──────────────────────┐      ┌──────────────────────┐
    │   Claude Code Skills │      │  Subagent Executors  │
    │  (Auto-Inject)       │      │  (Explicit Invoke)   │
    ├──────────────────────┤      ├──────────────────────┤
    │ • coding-standards   │      │ • implementer-coord  │
    │ • doc-standards      │      │ • spec-updater       │
    │ • test-protocols     │      │ • research-specialist│
    │ • commit-guide       │      │ • plan-architect     │
    │ • complexity-analyzer│      │ • debug-analyst      │
    │ • code-review        │      │ • impl-executor      │
    │ • file-organization  │      │ • plan-expander      │
    │ • template-patterns  │      │ • research-synth     │
    └──────────────────────┘      │ • expansion-spec     │
                                  │ • collapse-spec      │
                                  │ • metrics-spec       │
                                  │ • github-spec        │
                                  │ • doc-converter      │
                                  │ • impl-researcher    │
                                  └──────────────────────┘
```

### Priority Migration Order

**Phase 1: Foundation Skills (Week 1-2, ~16 hours)**
1. `coding-standards` ← `code-writer.md` (Lua/Bash/Markdown conventions)
2. `documentation-standards` ← `doc-writer.md` (README formats, cross-refs)
3. `testing-protocols` ← `test-specialist.md` (Test requirements, coverage)

**Validation**: Test auto-activation during normal coding tasks

**Phase 2: Process Skills (Week 3-4, ~12 hours)**
4. `commit-message-guide` ← `git-commit-helper.md` (Commit conventions)
5. `code-review-standards` ← `code-reviewer.md` (Review checklists)
6. `file-organization` ← `location-specialist.md` (Directory structure)

**Validation**: Monitor activation frequency, refine descriptions

**Phase 3: Analysis Skills (Week 5-6, ~12 hours)**
7. `complexity-analyzer` ← `complexity-estimator.md` (Plan complexity scoring)
8. `template-conventions` ← `template-processor.md` (Template patterns)

**Validation**: A/B test Skills vs subagents for quality/consistency

**Phase 4: Strengthen Subagent Enforcement (Week 7-8, ~20 hours)**
- Refactor remaining 16 subagents with **mandatory verification checkpoints**
- Replace weak imperatives ("Create report") with strong ones ("EXECUTE NOW - STEP 1")
- Add file existence verification after every creation operation
- Prohibit SlashCommand in all command files (enforce via tests)

**Total Estimated Time**: 60 hours across 8 weeks (incremental, parallel with normal work)

### Skills to Import from Community

**Immediate Import Candidates**:
1. **obra/superpowers** (github.com/obra/superpowers):
   - `tdd.skill` - Auto-apply TDD patterns
   - `debugging.skill` - Systematic debugging workflow
   - `collaboration.skill` - Team communication standards

2. **Official Anthropic Skills**:
   - `skill-creator` - Meta-skill for creating new Skills
   - `template-skill` - Reference template

**Custom Development Needed**:
- `progressive-planning` - Plan hierarchy conventions
- `checkpoint-recovery` - Resumable workflow patterns
- `metadata-extraction` - Context reduction techniques
- `adaptive-planning` - Complexity-based replanning

### Implementation Checklist

**Pre-Migration Preparation**:
- [ ] Enable Code Execution Tool beta (required for Skills)
- [ ] Create `.claude/skills/` directory structure
- [ ] Import `skill-creator` and `template-skill` from Anthropic
- [ ] Import `obra/superpowers` Skills for reference
- [ ] Document current subagent behavior for comparison

**Per-Skill Migration**:
- [ ] Extract core capability from subagent markdown
- [ ] Create SKILL.md with focused description (triggers for auto-activation)
- [ ] Add `allowed-tools` restrictions (start conservative)
- [ ] Create reference.md for detailed examples (progressive disclosure)
- [ ] Test activation with relevant prompts
- [ ] A/B test: Skill vs original subagent for quality
- [ ] Update commands to rely on Skill (remove subagent invocation if successful)
- [ ] Deprecate original subagent file (move to archive/)

**Post-Migration Validation**:
- [ ] Monitor context window usage (should remain <30%)
- [ ] Verify auto-activation rate (are Skills triggering appropriately?)
- [ ] Gather team feedback on Skill effectiveness
- [ ] Refine descriptions based on activation patterns
- [ ] Document lessons learned for future Skills

---

## Part 5: Risks and Mitigation

### Risk 1: Skills Don't Activate When Expected

**Likelihood**: High (common issue per community feedback)

**Impact**: Skills become "dead weight" in context without providing value

**Mitigation**:
- Write **highly specific descriptions** with concrete keywords users would mention
- Test activation by asking questions matching intended triggers
- Use `claude --debug` to reveal Skill loading errors
- Iterate on descriptions based on activation analytics
- Fallback: Keep subagent version available during testing

### Risk 2: Too Many Skills Exhaust Context Budget

**Likelihood**: Medium (with 8+ Skills at ~500-2000 tokens each)

**Impact**: Context overflow, reduced response quality

**Mitigation**:
- Limit initial migration to 8 highest-value Skills
- Use progressive disclosure (keep SKILL.md concise, details in reference.md)
- Monitor context usage with `/clear` between sessions
- Deactivate low-use Skills after evaluation period

### Risk 3: Skills Worsen Output Quality

**Likelihood**: Low-Medium (bad information degrades responses)

**Impact**: Inconsistent results, shallow outputs despite good instructions

**Mitigation**:
- Start with read-only analysis Skills (lower risk)
- A/B test Skills vs subagents before deprecating originals
- Keep Skills concise (comprehensive Skills = Claude fills gaps)
- Regular content reviews to remove stale information

### Risk 4: Migration Effort Exceeds Value

**Likelihood**: Low (estimated 60 hours vs ongoing maintenance)

**Impact**: Time investment doesn't yield sufficient improvement

**Mitigation**:
- Phased approach (stop if early phases show no benefit)
- Focus on highest-pain-point agents first (code-reviewer, doc-writer)
- Measure success: activation rate, context reduction, user satisfaction
- Hybrid approach preserves existing subagents (not all-or-nothing)

### Risk 5: Enforcement Issues Persist Despite Architecture Change

**Likelihood**: High (current pain is enforcement, not architecture)

**Impact**: Skills face same file creation compliance issues as subagents

**Mitigation**:
- **Address enforcement in parallel** (not after migration)
- Add mandatory verification checkpoints to all file creation operations
- Use strong imperatives ("EXECUTE NOW - STEP 1") not weak ones ("You should")
- Test enforcement patterns with subagents first (validate before migrating)

---

## Part 6: Success Metrics

### Quantitative Metrics

**Context Efficiency**:
- Current: 92-97% context reduction via metadata-only subagent returns
- Target: Maintain <30% context usage with Skills added
- Measurement: Token usage tracking per workflow

**Activation Rate**:
- Target: 80%+ appropriate activation (Skills activate when relevant)
- Target: <10% inappropriate activation (Skills dormant when not relevant)
- Measurement: Manual review of 50 conversations post-migration

**Migration Progress**:
- Target: 8 Skills created across 8 weeks
- Target: 16 subagents strengthened with verification checkpoints
- Measurement: Completion checkpoints per phase

**File Creation Compliance**:
- Current: 0% (agents return inline summaries)
- Target: 95%+ (agents create files as instructed)
- Measurement: Audit of /orchestrate and /implement workflows

### Qualitative Metrics

**User Experience**:
- Reduced need for explicit command invocation (Skills auto-apply)
- Consistent standards enforcement across conversations
- Fewer "I'll create a report" → inline summary failures

**Maintainability**:
- Clearer separation of concerns (Skills = knowledge, Subagents = workflows)
- Easier onboarding (Skills visible in `.claude/skills/`, self-documenting)
- Reduced command complexity (standards in Skills, not command prompts)

**Architectural Coherence**:
- Alignment with .claude/docs/ vision
- Elimination of command-calling-command anti-pattern
- Consistent behavioral injection patterns

---

## Part 7: Alternative Approaches Considered

### Alternative 1: Full Subagent Replacement

**Approach**: Migrate all 24 subagents to Skills

**Pros**:
- Single system to maintain
- Fully aligned with Skills paradigm

**Cons**:
- Skills not designed for multi-step workflows (implementer-coordinator, spec-updater)
- Lose metadata-only return benefits (Skills inject full content)
- No control over activation timing (problematic for orchestration agents)

**Verdict**: ❌ **Rejected** - Skills and subagents serve different purposes

### Alternative 2: Strengthen Current Architecture Only

**Approach**: Keep all subagents, fix enforcement issues, skip Skills entirely

**Pros**:
- No migration effort
- Proven architecture (when enforcement works)
- Maintain metadata-only context reduction

**Cons**:
- Misses Skills benefits (auto-activation, persistent standards)
- Doesn't address "standards should be automatic" use case
- Requires every command to explicitly invoke standards-checking agents

**Verdict**: ⚠️ **Partial** - Address enforcement regardless, but Skills add value

### Alternative 3: Skills-Only for New Capabilities

**Approach**: Keep existing subagents, use Skills for all new capabilities

**Pros**:
- Zero migration effort
- Gradual adoption
- Learn Skills patterns with low risk

**Cons**:
- Perpetuates dual system complexity
- Doesn't address current enforcement issues
- Misses optimization opportunities (8 agents good candidates for Skills)

**Verdict**: ⚠️ **Compromise** - Valid if migration effort is prohibitive

### Recommended: Hybrid Architecture (Best of Both)

Combines strengths of each approach:
- ✅ Skills for auto-applied standards (8 agents)
- ✅ Subagents for workflows (16 agents)
- ✅ Strengthened enforcement (addresses root cause)
- ✅ Incremental migration (low risk)

---

## Conclusion

### Key Recommendations

1. **Adopt Hybrid Architecture**: Skills for standards/preferences, subagents for workflows
2. **Migrate 8 High-Value Agents** to Skills over 8 weeks (~60 hours)
3. **Strengthen Subagent Enforcement** in parallel (mandatory verification checkpoints)
4. **Import Community Skills**: `obra/superpowers`, `skill-creator`, `template-skill`
5. **Measure Success**: Context usage, activation rate, file creation compliance

### Root Cause Insight

Current struggles stem from **weak enforcement patterns** (weak imperatives, missing verification), not architectural choice. **Evidence from debug report 070-001**:
- **0% file creation compliance** (agents return inline summaries instead of creating files)
- **SlashCommand anti-pattern** (commands call other commands despite prohibition in HTML comments)
- **Missing workflow scope detection** (all 6 phases execute regardless of workflow type)

Skills won't solve enforcement issues alone—**verification checkpoints must be added regardless of architecture**.

**Key Finding**: The proven enforcement pattern from debug report 070-001 (numbered steps + temporal enforcement + verification) can achieve **95%+ compliance**, compared to current **0% compliance** with weak imperatives.

### Next Steps (Priority-Adjusted Based on Debug Report 070-001)

**CRITICAL (Do First - Weeks 1-2)**:
1. **Implement verification checkpoint pattern** (Phase 4, Task 1) - Creates `.claude/docs/concepts/patterns/verification-checkpoints.md`
2. **Add workflow scope detection to /orchestrate** (addresses Deficiency 4 from debug report)
3. **Strengthen research agent enforcement** (addresses Deficiency 1: 0% file creation → 95%+ target)

**HIGH (Do Next - Weeks 3-4)**:
4. **Migrate foundation Skills** (Phase 1) - `coding-standards`, `documentation-standards`, `testing-protocols`
5. **Add SlashCommand validation** (addresses Deficiency 2 from debug report)
6. **Make Phase 6 conditional** (addresses Deficiency 3: unnecessary summaries)

**MEDIUM (Do Later - Weeks 5-8)**:
7. **Complete Skills migration** (Phases 2-3) - Process and analysis Skills
8. **Refactor remaining 16 subagents** with verification checkpoints (Phase 4, Tasks 2-7)
9. **Archive deprecated subagents** (Phase 5)

**Ongoing**:
- Monitor metrics (file creation compliance, context usage, Skills activation rate)
- Refine Skill descriptions based on activation patterns
- Deprecate successful migrations

**Rationale for Priority Adjustment**: Enforcement fixes (verification checkpoints, workflow scope detection) provide **immediate value** (0% → 95% compliance), while Skills migration provides **long-term architectural benefits** (auto-applied standards). Doing enforcement first ensures both subagents and Skills will work correctly.

### Expected Outcomes

- **Reduced cognitive load**: Standards auto-applied without explicit invocation
- **Improved consistency**: Skills enforce conventions across all conversations
- **Maintained efficiency**: <30% context usage via hybrid approach
- **Higher compliance**: 95%+ file creation rate via verification checkpoints
- **Clearer architecture**: Skills (knowledge), Commands (coordination), Subagents (execution)

---

## References

### Documentation
- Claude Code Skills: https://docs.claude.com/en/docs/claude-code/skills
- Skills Engineering: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- Official Skills Repo: https://github.com/anthropics/skills

### Community Resources
- Awesome Claude Skills: https://github.com/travisvn/awesome-claude-skills
- obra/superpowers: https://github.com/obra/superpowers
- Simon Willison Analysis: https://simonwillison.net/2025/Oct/10/claude-skills/

### Internal Documentation
- Current architecture: /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md
- Subagent patterns: /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md
- Enforcement issues: /home/benjamin/.config/.claude/specs/067_orchestrate_artifact_compliance/

### Debug Reports
- **Debug Report 070-001**: /home/benjamin/.config/.claude/specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md
  - Documents 4 critical deficiencies in /orchestrate workflow
  - Provides concrete evidence of 0% file creation compliance
  - Identifies proven enforcement pattern (numbered steps + temporal enforcement + verification)
  - Proposes workflow scope detection algorithm
  - Validates hybrid architecture approach (issue is enforcement, not architecture)

---

**Report Status**: ✅ Complete
**Next Artifact**: Implementation plan (high-level migration roadmap)