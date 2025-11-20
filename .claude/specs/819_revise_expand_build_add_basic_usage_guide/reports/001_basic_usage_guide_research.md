# Basic Usage Guide Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Basic usage guide with examples for /research, /plan, /revise, /expand, /build workflows
- **Report Type**: pattern recognition

## Executive Summary

This research analyzes the five core workflow commands (/research, /plan, /revise, /expand, /build) to identify clear usage patterns and create a basic usage guide with examples. The commands form a coherent workflow system: /research for standalone investigation, /plan for research+planning, /revise for plan updates, /expand for detail expansion, and /build for execution. Two primary workflow patterns emerge: (1) research-only for investigation tasks, and (2) research-plan-expand-build pipeline for feature implementation.

## Findings

### 1. Command Overview and Relationships

The five commands serve distinct but complementary purposes in the development workflow:

| Command | Purpose | Input | Output | Next Step |
|---------|---------|-------|--------|-----------|
| /research | Investigation without planning | Topic description | Reports in specs/NNN/reports/ | /plan or manual review |
| /plan | Research + create new plan | Feature description | Reports + plan in specs/NNN/ | /expand or /build |
| /revise | Research + modify existing plan | Plan path + revision details | Updated plan + backup + reports | /expand or /build |
| /expand | Add detail to plan phases | Plan path + phase number | Expanded phase files | /build |
| /build | Execute implementation plan | Plan path (optional) | Implemented code + commits | Done or /debug |

### 2. Workflow Pattern 1: Research-Only

**Use Case**: Investigate technologies, explore codebases, or understand domains without committing to implementation.

**Syntax**: `/research "<topic description>" [--complexity 1-4]`

**Default Complexity**: 2 (moderate depth)

**Examples from research-command-guide.md (lines 91-126)**:

```bash
# Basic research
/research "authentication patterns in codebase"

# Higher complexity for comprehensive investigation
/research "React performance optimization techniques --complexity 3"

# Hierarchical supervision for exhaustive research
/research "microservices architecture migration strategy --complexity 4"
```

**Output Structure**:
- Creates specs/{NNN_topic}/reports/ directory
- Generates numbered reports: 001_topic1.md, 002_topic2.md, etc.
- Report count scales with complexity (1-2 for complexity 1, up to 12+ for complexity 4)

**Expected Duration** (from research-command-guide.md lines 198-205):
- Complexity 1: ~5-10 minutes
- Complexity 2: ~10-20 minutes
- Complexity 3: ~20-40 minutes
- Complexity 4: ~40-90 minutes (hierarchical)

### 3. Workflow Pattern 2: Research-Plan-Expand-Build Pipeline

**Use Case**: Complete feature implementation from research through deployment.

**Step 1: Create Plan with Research**

**Syntax**: `/plan "<feature description>" [--complexity 1-4]`

**Default Complexity**: 3 (deeper than research-only)

**Examples from plan-command-guide.md (lines 99-147)**:

```bash
# Basic feature planning
/plan "implement user authentication with JWT tokens"

# Higher complexity for complex features
/plan "implement real-time collaborative editing --complexity 4"

# Architecture decision with research
/plan "migrate from REST API to GraphQL"
```

**Output**:
- Research reports in specs/{NNN_topic}/reports/
- Implementation plan in specs/{NNN_topic}/plans/001_{topic}_plan.md

**Step 2 (Optional): Revise Plan**

**Use Case**: Update plan when requirements change or new insights emerge.

**Syntax**: `/revise "revise plan at <plan-path> based on <reason>" [--complexity 1-4]`

**Default Complexity**: 2 (focused investigation)

**Examples from revise-command-guide.md (lines 100-156)**:

```bash
# Basic plan revision
/revise "revise plan at .claude/specs/752_auth/plans/001_plan.md based on new security requirements"

# Higher complexity for major revisions
/revise "revise plan at ./plans/001_api.md based on performance testing results showing N+1 query issues --complexity 3"

# Post-implementation revision
/revise "revise plan at .claude/specs/753_caching/plans/001_plan.md based on implementation learnings about Redis memory limits"
```

**Output**:
- Backup created at plans/backups/{plan}_{timestamp}.md
- Plan file modified in place
- New research reports added to reports/

**Step 3 (Optional): Expand Complex Phases**

**Use Case**: Break down complex phases into detailed implementation specifications.

**Syntax**:
- Auto-analysis: `/expand <plan-path>`
- Explicit phase: `/expand phase <plan-path> <phase-number>`
- Stage expansion: `/expand stage <phase-path> <stage-number>`

**Examples from expand-command-guide.md (lines 74-125)**:

```bash
# Auto-analyze and expand all complex phases
/expand /home/user/.claude/specs/027_auth/plans/027_auth_plan.md

# Explicitly expand Phase 3
/expand phase /home/user/.claude/specs/027_auth/plans/027_auth_plan.md 3

# Expand stage within phase (Level 2)
/expand stage /home/user/.claude/specs/027_auth/plans/027_auth_plan/phase_3_frontend.md 2
```

**Output**:
- Creates phase files in {plan_name}/ directory
- Updates parent plan metadata (Structure Level: 0 -> 1 -> 2)
- Phase files contain 300-500+ lines of detailed specifications

**Expansion Criteria** (from expand-command-guide.md lines 25-30):
- Complexity score >= 8
- Phase has >10 tasks
- Implementation requires detailed specifications

**Step 4: Execute Plan**

**Use Case**: Implement plan phases with automated testing and debugging.

**Syntax**: `/build [plan-file] [starting-phase] [--dry-run]`

**Examples from build-command-guide.md (lines 174-283)**:

```bash
# Execute most recent plan
/build

# Execute specific plan from phase 3
/build .claude/specs/123_auth/plans/001_auth_implementation.md 3

# Preview what would be executed
/build --dry-run

# Auto-resume from checkpoint
/build
```

**Output**:
- Implements plan phases via implementer-coordinator agent
- Runs tests automatically
- Creates git commits per phase
- Transitions to debug phase if tests fail
- Updates plan with [COMPLETE] markers

**Workflow States** (from build-command-guide.md lines 61-82):
```
IMPLEMENT -> TEST -> (DOCUMENT if pass | DEBUG if fail) -> COMPLETE
```

### 4. Common Workflow Chains

**Research -> Plan Chain** (from research-command-guide.md lines 234-237):
```bash
/research "user authentication approaches"
# Review reports
/plan "implement JWT authentication"  # Create plan based on research
```

**Iterative Research** (from research-command-guide.md lines 249-251):
```bash
/research "API design patterns"           # Initial investigation
# Review findings, identify gaps
/research "REST vs GraphQL comparison"    # Deeper dive on specific aspect
```

**Plan -> Build Chain** (from plan-command-guide.md lines 253-256):
```bash
/plan "implement caching layer"
# Review plan
/build  # Auto-detects and executes plan
```

**Implementation -> Revise Chain** (from revise-command-guide.md lines 294-300):
```bash
/build plans/001.md              # Start implementation
# Discover issues during implementation
/revise "revise plan at plans/001.md based on discovered API limitations"
/build plans/001.md              # Continue with revised plan
```

**Debug Loop** (from build-command-guide.md lines 393-398):
```bash
/build              # Tests fail, debug phase runs
# Apply fixes manually
/build              # Retry from test phase (checkpoint resumes)
```

### 5. Options and Flags

**Common Flags**:
- `--complexity 1-4`: Research depth level (default varies by command)
- `--file <path>`: Load description from file for long prompts
- `--dry-run`: Preview mode (build only)

**Complexity Defaults**:
- /research: 2 (moderate)
- /plan: 3 (deep, for planning)
- /revise: 2 (focused)

### 6. Output Conventions

**Specs Directory Structure**:
```
.claude/specs/
  {NNN}_{topic}/
    reports/
      001_topic1.md
      002_topic2.md
    plans/
      001_{topic}_plan.md
      backups/
        001_{topic}_plan_{timestamp}.md
      {plan_name}/           # If expanded
        phase_1_setup.md
        phase_2_impl.md
```

**Progress Markers** (from build-command-guide.md lines 142-165):
```markdown
### Phase 1: Setup [COMPLETE]
### Phase 2: Implementation [IN PROGRESS]
### Phase 3: Testing [NOT STARTED]
```

## Recommendations

### 1. Structure the Usage Guide by Workflow Pattern

Organize the README around the two primary patterns:
- **Pattern 1**: Research-only workflow
- **Pattern 2**: Plan-build pipeline

This mirrors how developers think about their tasks rather than listing commands alphabetically.

### 2. Include Quick-Start Examples First

Start with the simplest examples to show immediate value:
```bash
# Quick research
/research "existing auth patterns"

# Full implementation
/plan "add user auth"
/build
```

### 3. Document Common Chains

Show command combinations that work together:
- Research -> Plan -> Build (new feature)
- Build -> Revise -> Build (iterative development)
- Plan -> Expand -> Build (complex feature)

### 4. Add Troubleshooting Quick Reference

Include most common issues:
- No plan found: Run /plan first
- Tests fail: Apply fixes, re-run /build
- Plan too vague: Add complexity flag

### 5. Include Complexity Selection Guide

Help users choose complexity level:
- 1: Quick exploration (5-10 min)
- 2: Standard investigation (10-20 min)
- 3: Deep research (20-40 min)
- 4: Exhaustive analysis (40-90 min)

### 6. Show Real-World Scenarios

Include complete workflow examples:
- "Adding a new API endpoint"
- "Migrating authentication system"
- "Investigating performance issues"

## References

### Command Guides
- `.claude/docs/guides/commands/research-command-guide.md` (lines 91-126, 198-205, 234-251)
- `.claude/docs/guides/commands/plan-command-guide.md` (lines 99-147, 253-256)
- `.claude/docs/guides/commands/revise-command-guide.md` (lines 100-156, 294-300)
- `.claude/docs/guides/commands/expand-command-guide.md` (lines 25-30, 74-125)
- `.claude/docs/guides/commands/build-command-guide.md` (lines 61-82, 142-165, 174-283, 393-398)

### Command Implementations
- `.claude/commands/research.md` (lines 1-13 metadata, 29-196 setup block)
- `.claude/commands/plan.md` (lines 1-14 metadata, 26-204 setup block)

### Directory Structure
- `.claude/docs/guides/commands/README.md` (existing guide index)
