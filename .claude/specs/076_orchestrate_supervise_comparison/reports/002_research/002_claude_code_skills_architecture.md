# Claude Code Skills Architecture Research Report

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-specialist
- **Topic**: Claude Code skills architecture and token efficiency comparison with agents
- **Report Type**: codebase analysis + best practices

## Executive Summary

Claude Code Skills are **model-invoked modular capabilities** that use a 3-tier progressive disclosure architecture (metadata → full instructions → supplementary resources) to provide specialized expertise with 99% token reduction when dormant. The Skills system fundamentally differs from the current subagent architecture: Skills activate **automatically** based on context matching, while subagents are **explicitly invoked** via Task tool with behavioral injection. For the location detection task specifically, Skills are **NOT recommended** - the location-specialist agent's deterministic workflow (directory scanning, path calculation, structure creation) requires precise orchestration timing that Skills' automatic activation cannot guarantee.

**Key Finding**: Skills excel at **reusable expertise** (standards enforcement, methodologies, quality gates) but struggle with **orchestrated workflows** requiring deterministic execution order. The location-specialist agent must execute in Phase 0 before research agents can save reports in Phase 1 - this temporal dependency is incompatible with Skills' model-invoked activation pattern.

**Token Efficiency Analysis**:
- **Skills (dormant)**: 30-50 tokens until activated = 99% reduction
- **Subagents (metadata-only return)**: 5000 tokens loaded, 95% reduction after execution via metadata return = 250 tokens
- **Hybrid Recommendation**: Skills for standards (automatic activation during implementation), subagents for workflows (explicit control, checkpoint recovery, stateful execution)

## Findings

### Finding 1: Skills System Architecture

**Model-Invoked Activation Pattern**:

Claude Code Skills activate **automatically** when Claude determines relevance to the current task. This is fundamentally different from:
- **Slash commands**: User-invoked (e.g., `/orchestrate`, `/research`)
- **Subagents**: Command-invoked via Task tool with explicit behavioral injection

**Activation Process**:
```
User request → Claude analyzes context → Scans skill descriptions (Tier 1 metadata)
→ Calculates relevance scores → Loads high-relevance skills (Tier 2 content)
→ Executes task with skills active → Returns results
```

**Progressive Disclosure Architecture** (3 tiers):

| Tier | Content | Token Cost | When Loaded |
|------|---------|------------|-------------|
| 1 | Metadata (name, description) | 30-50 tokens | Session start (all skills) |
| 2 | Core instructions (SKILL.md) | 500-2000 tokens | When activated by Claude |
| 3 | Supplementary (reference.md, scripts/, templates/) | Variable | On-demand via links |

**Example**: 20 skills = ~800 tokens baseline (Tier 1), vs loading 20 command files = ~100,000 tokens. Skills achieve **99% reduction** through progressive disclosure.

**Source Files**:
- /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:40-54
- /home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/reports/001_skills_system_architecture.md:74-92

### Finding 2: Skills vs Subagents Architecture Comparison

**Comprehensive Comparison**:

| Dimension | Skills | Subagents (Current .claude/) |
|-----------|--------|------------------------------|
| **Invocation** | Automatic (model-invoked) | Explicit (command-invoked via Task tool) |
| **Purpose** | Inject reusable expertise/standards | Execute isolated workflows with specific goals |
| **Context Loading** | Progressive (30-50 → 500-2000 → variable) | Full behavioral injection (~5000 tokens) |
| **Token Efficiency** | 99% reduction (dormant until activated) | 95% reduction (metadata-only return after execution) |
| **Optimal Use Case** | Standards enforcement, methodologies, quality gates | Orchestration, artifact creation, multi-step workflows |
| **Execution Control** | Indirect (Claude decides when to activate) | Direct (command pre-calculates paths, injects context) |
| **State Management** | Stateless (context only) | Stateless within task, checkpoints managed by commands |
| **Temporal Dependencies** | Cannot guarantee execution order | Explicit sequencing via command orchestration |
| **Tool Restrictions** | Optional via `allowed-tools` frontmatter | Enforced via agent frontmatter + behavioral injection |
| **Best For** | Auto-applied coding standards, testing patterns | Research, planning, implementation, debugging workflows |

**Critical Architectural Insight**:

Skills and subagents solve **complementary problems**:
- **Skills**: "What standards should I apply?" (automatic expertise injection)
- **Subagents**: "How should I execute this workflow?" (explicit task delegation)

**Hybrid Architecture Recommended**:
- Preserve orchestration layer (/orchestrate, /implement, behavioral injection, hierarchical agents)
- Adopt skills for standards enforcement (code standards, testing protocols, documentation standards)
- Retain subagents for complex workflows (location-specialist, research-specialist, plan-architect)

**Source Files**:
- /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:60-74
- /home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/reports/001_skills_system_architecture.md:429-448

### Finding 3: Location Detection Task Analysis

**Current Implementation** (location-specialist agent):

**Execution Process** (5 sequential steps):
1. **Analyze Workflow Request** (Step 1): Parse keywords, search codebase, identify affected directories
2. **Determine Specs Root and Topic Number** (Step 2): Find/create specs directory, calculate next topic number (NNN)
3. **Generate Topic Name** (Step 3): Sanitize workflow description to topic name
4. **Create Directory Structure** (Step 4): mkdir topic_path/{reports,plans,summaries,debug,scripts,outputs}
5. **Generate Location Context** (Step 5): Return YAML with absolute paths to all artifact subdirectories

**Temporal Dependencies**:
- Phase 0 (Location): Creates directory structure
- Phase 1 (Research): Saves reports to artifact_paths.reports
- Phase 2 (Planning): Saves plans to artifact_paths.plans using topic_number
- Phase 5 (Debugging): Saves debug reports to artifact_paths.debug

**Critical Requirement**: Location detection MUST complete before any artifact creation. This is a **hard dependency** in the workflow sequence.

**Source Files**:
- /home/benjamin/.config/.claude/agents/location-specialist.md:1-414 (complete agent specification)
- /home/benjamin/.config/.claude/commands/orchestrate.md:397-517 (location-specialist invocation in Phase 0)
- /home/benjamin/.config/.claude/commands/supervise.md:347-430 (location-specialist usage in supervise command)

### Finding 4: Why Skills Are NOT Suitable for Location Detection

**Problem 1: Automatic Activation Creates Timing Ambiguity**

Skills activate when Claude determines relevance - there's no guarantee a "location-detection" skill would activate **before** research agents need to save reports. The workflow requires:

```
REQUIRED SEQUENCE:
Phase 0: location-specialist creates specs/NNN_topic/{reports,plans,summaries,...}
→ THEN Phase 1: research agents save to specs/NNN_topic/reports/001_report.md
```

With skills, this becomes:
```
UNPREDICTABLE SEQUENCE:
User: /orchestrate "research authentication patterns and plan implementation"
→ Claude might activate research-methodology skill first
→ Research agent attempts to save report
→ ERROR: Directory specs/NNN_topic/reports/ doesn't exist yet
```

**Problem 2: No Pre-Calculation of Paths for Behavioral Injection**

The current architecture **pre-calculates artifact paths** in Phase 0 and injects them into subagent prompts:

```yaml
# Orchestrator pre-calculates paths
REPORT_PATH="/home/benjamin/.config/specs/081_auth/reports/001_patterns.md"

# Injects into research agent
Task {
  prompt: "
    REPORT PATH (MANDATORY): ${REPORT_PATH}
    Use Write tool to create: ${REPORT_PATH}
  "
}
```

Skills cannot provide paths **before** research agents are invoked because skills activate **during** agent execution, not before.

**Problem 3: Deterministic Logic Doesn't Benefit from Automatic Activation**

Location detection is **deterministic**:
1. Scan specs/ directory
2. Find max topic number: `ls -1d specs/[0-9][0-9][0-9]_* | sort | tail -1`
3. Increment: `printf "%03d" $((max_num + 1))`
4. Create directories: `mkdir -p specs/NNN_topic/{reports,plans,...}`

There's no ambiguity requiring Claude's judgment. Skills' automatic activation adds **complexity without benefit**.

**Problem 4: Loss of Verification Checkpoints**

The location-specialist agent has **mandatory verification** at each step:
- Step 2: Verify SPECS_ROOT is absolute
- Step 4: Verify all 6 subdirectories created
- Step 5: Verify all paths in location_context are absolute

Skills cannot enforce verification checkpoints because their activation is **autonomous** - there's no orchestrator monitoring execution flow.

**Source Files**:
- /home/benjamin/.config/.claude/specs/077_research_command_path_resolution/reports/002_claude_code_skills_evaluation.md:76-96 (skills vs library functions for path calculation)
- /home/benjamin/.config/.claude/agents/location-specialist.md:56-120 (verification checkpoints)

### Finding 5: Existing Skills Ecosystem Research

**Search Results**:
- **No skills found in `.claude/skills/` directory** (empty or non-existent)
- **Extensive skills research exists**: 5 comprehensive reports on skills architecture, migration strategy, and integration patterns
- **24 subagents currently in use**: All using behavioral injection pattern via Task tool

**Community Skills Ecosystem**:

**Anthropic Official Skills** (github.com/anthropics/skills):
- 15+ production-grade skills
- Categories: Documents (docx, pdf, pptx, xlsx), Development (artifacts-builder, webapp-testing), Meta (skill-creator, template-skill)
- Token optimization: Progressive disclosure, deterministic code execution for format conversion

**obra/superpowers Community Skills** (github.com/obra/superpowers):
- 20+ battle-tested skills
- Categories: Testing (test-driven-development), Debugging (systematic-debugging, root-cause-tracing), Collaboration (dispatching-parallel-agents, using-git-worktrees)
- **Performance Claims**: 40-60% productivity increase (git worktrees), 50-70% time reduction (parallel agents)

**Migration Status**:
- Project has **researched skills extensively** (5 detailed reports)
- Project has **NOT implemented any skills yet** (no SKILL.md files found)
- Migration plan exists: Hybrid architecture with 8-10 skills for standards enforcement, retain 16 subagents for workflows

**Source Files**:
- /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:76-154 (official and community skills catalog)
- /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/004_skills_migration_recommendations.md:1040-1236 (phased migration plan)
- /home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/reports/001_skills_system_architecture.md:279-320 (community ecosystem analysis)

### Finding 6: Token Efficiency Comparison

**Scenario**: /orchestrate workflow with research → planning phases

**Current Architecture (Subagents Only)**:
- Command file (orchestrate.md): 2000 tokens
- Location-specialist invocation: 5000 tokens (full agent file loaded)
- Location-specialist return: 250 tokens (metadata only - 95% reduction)
- Research-specialist invocation: 5000 tokens × 3 agents = 15,000 tokens
- Research-specialist returns: 250 tokens × 3 = 750 tokens (metadata only)
- **Total**: 2000 + 5000 + 250 + 15,000 + 750 = **23,000 tokens**

**With Skills for Standards Enforcement** (Hybrid):
- Command file: 2000 tokens
- Skills dormant (code-standards, testing-protocols, doc-standards): 120 tokens (3 × 40)
- Location-specialist invocation: 5000 tokens (retained as subagent)
- Location-specialist return: 250 tokens (metadata only)
- Research-specialist invocation: 5000 tokens × 3 = 15,000 tokens
- Skills activate during research: 6000 tokens (3 skills × 2000, first time only)
- Research-specialist returns: 250 tokens × 3 = 750 tokens
- **Total first run**: 2000 + 120 + 5000 + 250 + 15,000 + 6000 + 750 = **29,120 tokens**
- **Total subsequent runs**: 2000 + 120 + 5000 + 250 + 15,000 + 750 = **23,120 tokens** (skills cached)

**Analysis**:
- **Skills increase tokens on first run** (+6120 tokens, +27%)
- **Skills provide consistency without command overhead** (standards enforced automatically)
- **Skills NOT suitable for location detection** (timing ambiguity, no pre-calculation, loss of verification)

**Optimal Architecture**:
- **Use skills for**: Standards enforcement (auto-activate during implementation/testing)
- **Keep subagents for**: Location detection, research, planning, implementation (explicit orchestration required)

**Source Files**:
- /home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/reports/001_skills_system_architecture.md:481-483 (token analysis)
- /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:867-873 (context efficiency metrics)

## Recommendations

### Recommendation 1: DO NOT Use Skills for Location Detection

**Rationale**: Location detection requires:
1. **Deterministic execution order** (Phase 0 before all other phases)
2. **Pre-calculated paths** for behavioral injection into subsequent agents
3. **Mandatory verification checkpoints** at each step
4. **Explicit orchestration** by command logic

Skills' model-invoked activation pattern violates all four requirements.

**Action**: Retain location-specialist as a subagent invoked explicitly via Task tool in Phase 0 of /orchestrate and /supervise commands.

**Priority**: CRITICAL - Do not migrate this agent to skills.

**Source**: /home/benjamin/.config/.claude/specs/077_research_command_path_resolution/reports/002_claude_code_skills_evaluation.md:106-112

### Recommendation 2: Consider Skills for Standards Enforcement

**Rationale**: Standards enforcement (code standards, testing protocols, documentation standards) benefits from **automatic activation**:
- No need for explicit invocation in every command
- Standards applied consistently across all phases
- Skills read standards from CLAUDE.md (portable across projects)
- 99% token reduction when dormant

**Candidate Skills**:
1. **code-standards-enforcement**: Auto-activates when editing code files, reads ## Code Standards from CLAUDE.md
2. **testing-protocols-enforcement**: Auto-activates during test execution, reads ## Testing Protocols
3. **documentation-standards-enforcement**: Auto-activates when writing docs, reads ## Documentation Policy

**Action**: Prototype these 3 meta-level enforcement skills as Phase 1 of skills adoption.

**Priority**: HIGH - Provides immediate value (automatic consistency) without disrupting orchestration.

**Source**: /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/004_skills_migration_recommendations.md:381-583

### Recommendation 3: Adopt obra/superpowers Collaboration Skills

**Rationale**: obra/superpowers provides battle-tested skills for:
- **dispatching-parallel-agents**: Coordinate 2-4 subagents for concurrent research/debugging (50-70% time reduction)
- **using-git-worktrees**: Manage multiple feature branches without directory switching (40-60% productivity increase)
- **test-driven-development**: RED-GREEN-REFACTOR cycle enforcement
- **systematic-debugging**: 4-phase root cause investigation

These skills **complement** subagents (don't replace them) by providing **methodologies** that apply automatically during subagent execution.

**Action**: Install complete obra/superpowers plugin (~20 skills) via:
```bash
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**Priority**: HIGH - Low effort (plugin installation), high value (proven 40-70% performance gains).

**Source**: /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:805-817

### Recommendation 4: Document Skills vs Subagents Decision Criteria

**Rationale**: Future developers may be tempted to convert all subagents to skills during "modernization" efforts. Document **when to use each** to prevent architectural regressions.

**Suggested Documentation** (create `.claude/docs/guides/skills-vs-subagents-decision.md`):

```markdown
## When to Use Skills

Skills excel at:
- **Automatic standards enforcement**: Code standards, testing protocols, documentation standards
- **Reusable methodologies**: TDD workflows, debugging patterns, code review checklists
- **Quality gates**: Verification patterns, defense-in-depth, pre-commit checks
- **Context-aware expertise**: Activate automatically when relevant to task

## When to Use Subagents

Subagents excel at:
- **Deterministic workflows**: Location detection, path calculation, directory creation
- **Orchestrated sequences**: Research → planning → implementation (explicit phase order)
- **Pre-calculated context**: Behavioral injection with pre-computed paths
- **Stateful processes**: Checkpoint recovery, adaptive replanning, progressive expansion
- **Verification checkpoints**: Mandatory validation at each step

## Hybrid Architecture (Recommended)

Use both:
- **Commands**: Orchestrate workflows, manage state, coordinate phases
- **Skills**: Inject standards and methodologies automatically
- **Subagents**: Execute complex workflows with explicit control
```

**Action**: Create decision guide and link from CLAUDE.md ## Quick Reference.

**Priority**: MEDIUM - Documentation to prevent future regressions.

**Source**: /home/benjamin/.config/.claude/specs/077_research_command_path_resolution/reports/002_claude_code_skills_evaluation.md:131-147

### Recommendation 5: Measure Skills Impact Before Full Migration

**Rationale**: Skills increase tokens on first activation (+6000 tokens for 3 standards enforcement skills). Measure impact before migrating more capabilities.

**Metrics to Track**:
1. **Token usage**: Baseline vs with skills (first run and subsequent runs)
2. **Activation rate**: How often skills activate appropriately vs inappropriately
3. **Consistency improvement**: Standards violations before vs after skills adoption
4. **Context utilization**: Maintain <30% context usage target

**Action**: After installing obra/superpowers and creating 3 meta-level enforcement skills, run 10 /orchestrate workflows and measure token usage, activation patterns, and consistency improvements.

**Success Criteria**:
- Token usage ≤105% of baseline (5% overhead acceptable)
- Activation rate ≥80% appropriate, ≤10% inappropriate
- Standards violations reduced by ≥50%
- Context utilization remains <30%

**Priority**: HIGH - Validation before committing to full migration.

**Source**: /home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md:851-891

## Related Reports

- **Overview Report**: [Streamlining /supervise Project Location Detection](./OVERVIEW.md) - Synthesis of all research findings with cross-cutting themes and unified recommendations

## References

### Internal Research Reports (Comprehensive Skills Analysis)

- **/home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md**: Complete architecture comparison, enforcement failure analysis, hybrid architecture recommendation (1035 lines)
- **/home/benjamin/.config/.claude/specs/075_skills_integration_systematic_refactor/reports/001_skills_system_architecture.md**: Skills system components, invocation mechanisms, lifecycle management (888 lines)
- **/home/benjamin/.config/.claude/specs/077_research_command_path_resolution/reports/002_claude_code_skills_evaluation.md**: Skills feasibility for path resolution, skills vs library functions comparison (172 lines)
- **/home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/004_skills_migration_recommendations.md**: Phased migration strategy, meta-level enforcement skills, integration patterns
- **/home/benjamin/.config/.claude/specs/073_skills_migration_analysis/reports/002_anthropic_skills_ecosystem.md**: Official Anthropic skills catalog, community skills (obra/superpowers)

### Codebase Files Analyzed

- **/home/benjamin/.config/.claude/agents/location-specialist.md:1-414**: Complete agent specification with 5-step execution process, verification checkpoints, absolute path requirements
- **/home/benjamin/.config/.claude/commands/orchestrate.md:397-517**: Location-specialist invocation in Phase 0, fallback handling, path injection into subsequent phases
- **/home/benjamin/.config/.claude/commands/supervise.md:347-430**: Location-specialist usage pattern, output parsing, error handling

### External Documentation

- **Claude Code Skills**: https://docs.claude.com/en/docs/claude-code/skills (official documentation)
- **Skills API**: https://docs.claude.com/en/api/skills-guide (API integration guide)
- **Anthropic Skills Repository**: https://github.com/anthropics/skills (official skills source)
- **obra/superpowers Repository**: https://github.com/obra/superpowers (community skills library)
- **Engineering Deep Dive**: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills (architecture analysis)
