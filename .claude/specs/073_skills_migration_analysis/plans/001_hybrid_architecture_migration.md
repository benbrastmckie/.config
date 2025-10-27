# Implementation Plan: Hybrid Skills + Subagents Architecture Migration

## Metadata
- **Plan Number**: 073-001
- **Date Created**: 2025-10-23
- **Feature**: Migrate .claude/ system to hybrid Skills + Subagents architecture
- **Complexity**: High (8/10)
- **Estimated Duration**: 8 weeks (~60 hours)
- **Research Reports**:
  - specs/073_skills_migration_analysis/reports/001_skills_vs_subagents_architecture.md
- **Related Debug Reports**:
  - specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md (0% file creation compliance evidence)

## Overview

Migrate the current `.claude/` system from a pure subagent architecture to a **hybrid model** combining Claude Code Skills (for auto-applied standards) and strengthened subagents (for workflow execution). This plan addresses enforcement issues while leveraging Skills for appropriate use cases.

### Success Criteria
- [x] Research completed: Skills architecture understood, migration strategy designed
- [ ] 8 high-value agents migrated to Skills with 80%+ appropriate activation rate
- [ ] 16 workflow agents retained as subagents with strengthened verification checkpoints
- [ ] Context usage remains <30% throughout workflows
- [ ] File creation compliance increases from 0% to 95%+
- [ ] Command-calling-command anti-pattern eliminated (0 SlashCommand calls in commands)

### Technical Approach

**Hybrid Architecture**:
```
Slash Commands (Orchestrators)
    ↓
    ├─→ Skills (Auto-inject standards: 8 agents)
    └─→ Subagents (Execute workflows: 16 agents)
```

**Key Principles**:
1. **Skills** for persistent knowledge (coding standards, doc formats, test protocols)
2. **Subagents** for multi-step workflows (research, planning, implementation, debugging)
3. **Commands** for coordination (state management, checkpoint recovery)
4. **Verification** checkpoints mandatory for all file creation operations

### ⚠️ PRIORITY ADJUSTMENT (Based on Debug Report 070-001)

**Original Phase Order**: 0 → 1 → 2 → 3 → 4 → 5
**Recommended Order**: 0 → **4** (Tasks 1-3) → 1 → 2 → 3 → 4 (Tasks 4-8) → 5

**Rationale**: Debug report `.claude/specs/070_orchestrate_refactor/debug/001_orchestrate_workflow_deficiencies.md` documents **0% file creation compliance** (agents return inline summaries instead of creating files). The verification checkpoint pattern from Phase 4 provides **immediate value** (0% → 95%+ compliance), while Skills migration provides **long-term architectural benefits**.

**Critical Tasks to Do First**:
- Phase 4, Task 1: Define verification checkpoint pattern
- Phase 4, Task 2-3: Refactor research and planning agents with verification
- Then proceed with Phase 1-3 (Skills migration)
- Finally complete Phase 4, Tasks 4-8 (remaining subagent refactoring)

**Why This Matters**: Enforcement strengthening (Phase 4) fixes the root cause of current struggles. Skills migration (Phases 1-3) won't solve enforcement issues—both subagents AND Skills need strong imperatives + verification checkpoints to achieve compliance.

**Flexible Execution**: You can also execute Phases 1-3 (Skills migration) in parallel with Phase 4 (enforcement strengthening), as they're independent efforts.

---

## Phase 0: Foundation and Preparation

**Duration**: Week 1 (~8 hours)

**Objectives**:
- Set up Skills infrastructure
- Import reference Skills from community
- Validate Skills system is working
- Document baseline metrics

### Tasks

#### Task 1: Enable Skills System
- [ ] Verify Code Execution Tool beta is enabled
- [ ] Create directory structure: `.claude/skills/`
- [ ] Create README.md documenting Skills purpose and conventions
- [ ] Test Skills discovery: Create dummy Skill and verify activation

**Validation**:
```bash
# Verify directory exists
test -d /home/benjamin/.config/.claude/skills && echo "✓ Skills dir exists"

# Test dummy Skill activation
# Create: .claude/skills/test-skill/SKILL.md with description "Test when user mentions 'test skill activation'"
# Prompt: "Please test skill activation"
# Expected: Claude mentions test-skill activated
```

#### Task 2: Import Reference Skills
- [ ] Clone `github.com/anthropics/skills` repository to temp directory
- [ ] Copy `skill-creator` to `.claude/skills/skill-creator/`
- [ ] Copy `template-skill` to `.claude/skills/template-skill/`
- [ ] Review `obra/superpowers` repository for useful patterns
- [ ] Import `tdd.skill`, `debugging.skill`, `collaboration.skill` from superpowers (if applicable)

**Files**:
- `.claude/skills/skill-creator/SKILL.md`
- `.claude/skills/template-skill/SKILL.md`
- `.claude/skills/README.md` (document imported Skills)

#### Task 3: Document Baseline Metrics
- [ ] Audit current subagent invocation patterns in `/orchestrate`, `/implement`, `/plan`
- [ ] Count SlashCommand tool usages in all command files
- [ ] Measure context usage for typical workflows (run 3 test workflows)
- [ ] Document current file creation compliance rate (run `/orchestrate` on test task)

**Output**: Create `specs/073_skills_migration_analysis/audit/baseline_metrics.md`:
```markdown
## Baseline Metrics (2025-10-23)

### Subagent Inventory
- Total subagents: 24
- Migration candidates (→ Skills): 8
- Retention candidates (remain subagents): 16

### Current Issues
- SlashCommand usages in commands: [count]
- File creation compliance: 0% (agents return inline summaries)
- Context usage: [measure from 3 test workflows]

### Architecture Violations
- Commands calling commands: [specific examples from /implement, /orchestrate]
- Missing verification checkpoints: [count of file creation operations without verification]
```

**Testing Strategy**:
- Run 3 test workflows: simple feature, bug fix, refactoring
- Monitor for SlashCommand anti-pattern occurrences
- Check if reports/plans created as files vs inline summaries

**Success Criteria**:
- [ ] `.claude/skills/` directory exists with 3+ reference Skills
- [ ] Dummy Skill activates when expected
- [ ] Baseline metrics documented in audit/baseline_metrics.md

---

## Phase 1: Foundation Skills (Coding, Documentation, Testing)

**Duration**: Week 2-3 (~16 hours)

**Objectives**:
- Migrate 3 highest-impact agents to Skills
- Validate auto-activation patterns
- Establish Skills development workflow

### Tasks

#### Task 1: Create `coding-standards` Skill
**Source**: `.claude/agents/code-writer.md`

**Extraction**:
- [ ] Read `code-writer.md` and identify core standards (Lua/Bash/Markdown conventions)
- [ ] Extract standards from CLAUDE.md sections (code_standards, nvim/CLAUDE.md)
- [ ] Create SKILL.md with focused description triggering on code-related keywords

**Skill Structure**:
```yaml
---
name: coding-standards
description: |
  Auto-apply coding standards for Lua, Bash, and Markdown when writing or reviewing code.
  Triggers: writing code, creating functions, lua files, bash scripts, markdown documents.
allowed-tools: Read, Grep, Glob  # Read-only for standards injection
---

# Coding Standards

## Lua Conventions
- 2-space indentation, expandtab
- snake_case for variables/functions, PascalCase for modules
- pcall for error handling
[Link to detailed examples: reference.md]

## Bash Conventions
- ShellCheck compliance, bash -e for error handling
[Link to detailed examples: reference.md]

## Markdown Conventions
- CommonMark specification, Unicode box-drawing for diagrams, no emojis
[Link to detailed examples: reference.md]
```

**Files**:
- `.claude/skills/coding-standards/SKILL.md`
- `.claude/skills/coding-standards/reference.md` (detailed examples, current code-writer.md content)

**Validation**:
- [ ] Test activation: "Write a Lua function to parse configuration"
- [ ] Verify Claude mentions 2-space indentation, snake_case, pcall
- [ ] Test non-activation: "What time is it?" (should not activate)

#### Task 2: Create `documentation-standards` Skill
**Source**: `.claude/agents/doc-writer.md`

**Extraction**:
- [ ] Read `doc-writer.md` and identify core documentation requirements
- [ ] Extract standards from CLAUDE.md documentation_policy section
- [ ] Create SKILL.md with focused description triggering on documentation keywords

**Skill Structure**:
```yaml
---
name: documentation-standards
description: |
  Auto-apply documentation standards for READMEs, API docs, and cross-referencing.
  Triggers: create README, update documentation, write docs, API documentation.
allowed-tools: Read, Grep, Glob
---

# Documentation Standards

## README Requirements
- Purpose, Module Documentation, Usage Examples, Navigation Links
- CommonMark specification, no emojis, no historical commentary

## Cross-Referencing
- Relative links between related docs
- Update parent README when adding subdirectories
[Link to detailed patterns: reference.md]
```

**Files**:
- `.claude/skills/documentation-standards/SKILL.md`
- `.claude/skills/documentation-standards/reference.md`

**Validation**:
- [ ] Test activation: "Create a README for the new auth module"
- [ ] Verify Claude includes Purpose, Module Documentation, Usage Examples sections
- [ ] Test non-activation: "What's in the README?" (should not activate)

#### Task 3: Create `testing-protocols` Skill
**Source**: `.claude/agents/test-specialist.md`

**Extraction**:
- [ ] Read `test-specialist.md` and identify core testing requirements
- [ ] Extract testing protocols from CLAUDE.md testing_protocols section
- [ ] Create SKILL.md with focused description triggering on testing keywords

**Skill Structure**:
```yaml
---
name: testing-protocols
description: |
  Auto-apply testing requirements and coverage standards when writing or running tests.
  Triggers: write tests, run tests, test coverage, test suite, testing strategy.
allowed-tools: Read, Bash, Grep, Glob
---

# Testing Protocols

## Test Requirements
- 80%+ coverage on new code, 60% baseline
- All public APIs must have tests
- Regression tests for all bug fixes

## Test Commands
- Claude Code: `.claude/tests/run_all_tests.sh`
- Neovim: `:TestSuite`, `:TestFile`, `:TestNearest`
[Link to detailed patterns: reference.md]
```

**Files**:
- `.claude/skills/testing-protocols/SKILL.md`
- `.claude/skills/testing-protocols/reference.md`

**Validation**:
- [ ] Test activation: "Write tests for the new auth module"
- [ ] Verify Claude mentions 80% coverage requirement
- [ ] Test non-activation: "What tests exist?" (should not activate)

#### Task 4: A/B Testing and Validation
- [ ] Run 5 coding tasks: 3 with `coding-standards` Skill, 2 with original `code-writer` subagent
- [ ] Compare output quality, standards compliance, context usage
- [ ] Measure activation accuracy: appropriate activation rate, inappropriate activation rate
- [ ] Document findings in `specs/073_skills_migration_analysis/validation/phase_1_results.md`

**Success Criteria**:
- [ ] 3 Skills created with complete SKILL.md + reference.md
- [ ] 80%+ appropriate activation rate (Skills activate when relevant)
- [ ] <10% inappropriate activation rate
- [ ] Output quality matches or exceeds original subagent approach

---

## Phase 2: Process Skills (Commit, Review, Organization)

**Duration**: Week 4-5 (~12 hours)

**Objectives**:
- Migrate 3 process-focused agents to Skills
- Refine activation patterns based on Phase 1 learnings
- Validate Skills don't interfere with workflows

### Tasks

#### Task 1: Create `commit-message-guide` Skill
**Source**: `.claude/agents/git-commit-helper.md`

**Extraction**:
- [ ] Read `git-commit-helper.md` and extract commit message conventions
- [ ] Identify trigger keywords: "create commit", "git commit", "commit message"
- [ ] Create SKILL.md with commit message format and examples

**Skill Structure**:
```yaml
---
name: commit-message-guide
description: |
  Auto-apply commit message conventions when creating git commits.
  Triggers: create commit, git commit, commit message, commit changes.
allowed-tools: Bash, Read
---

# Commit Message Guide

## Format
```
<type>(<scope>): <subject>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Types
- feat, fix, docs, refactor, test, chore
[Link to examples: reference.md]
```

**Files**:
- `.claude/skills/commit-message-guide/SKILL.md`
- `.claude/skills/commit-message-guide/reference.md`

#### Task 2: Create `code-review-standards` Skill
**Source**: `.claude/agents/code-reviewer.md`

**Extraction**:
- [ ] Read `code-reviewer.md` and extract review checklist
- [ ] Identify trigger keywords: "review code", "code review", "check code quality"
- [ ] Create SKILL.md with review criteria

**Skill Structure**:
```yaml
---
name: code-review-standards
description: |
  Auto-apply code review checklist when reviewing code for quality and standards.
  Triggers: review code, code review, check standards, quality check.
allowed-tools: Read, Grep, Glob
---

# Code Review Standards

## Review Checklist
- [ ] Follows project coding standards (see coding-standards Skill)
- [ ] Includes tests with 80%+ coverage
- [ ] Documentation updated (README, inline comments)
- [ ] No emojis in file content
- [ ] Error handling appropriate for language
[Link to detailed criteria: reference.md]
```

**Files**:
- `.claude/skills/code-review-standards/SKILL.md`
- `.claude/skills/code-review-standards/reference.md`

#### Task 3: Create `file-organization` Skill
**Source**: `.claude/agents/location-specialist.md`

**Extraction**:
- [ ] Read `location-specialist.md` and extract directory structure guidelines
- [ ] Identify trigger keywords: "where to put", "file location", "directory structure"
- [ ] Create SKILL.md with organization patterns

**Skill Structure**:
```yaml
---
name: file-organization
description: |
  Auto-suggest appropriate file locations and directory structures.
  Triggers: where to put, file location, create directory, organize files.
allowed-tools: Read, Glob, Bash
---

# File Organization

## Directory Structure
- `.claude/commands/` - Slash commands
- `.claude/agents/` - Subagent definitions (being deprecated)
- `.claude/skills/` - Claude Code Skills
- `.claude/specs/{NNN_topic}/plans/` - Implementation plans
- `.claude/specs/{NNN_topic}/reports/` - Research reports
[Link to complete structure: reference.md]
```

**Files**:
- `.claude/skills/file-organization/SKILL.md`
- `.claude/skills/file-organization/reference.md`

#### Task 4: Integration Testing
- [ ] Run `/implement` command with Skills active (test interaction)
- [ ] Verify Skills don't interfere with subagent invocations
- [ ] Test commit creation: Does `commit-message-guide` activate appropriately?
- [ ] Measure context usage: Are we still <30%?

**Success Criteria**:
- [ ] 3 additional Skills created (total: 6)
- [ ] Skills activate during normal workflows without manual prompting
- [ ] No interference with existing subagent-based commands
- [ ] Context usage remains <30%

---

## Phase 3: Analysis Skills (Complexity, Templates)

**Duration**: Week 6 (~6 hours)

**Objectives**:
- Migrate final 2 capability-focused agents to Skills
- Complete Skill migration for 8 targeted agents
- Validate overall Skills architecture effectiveness

### Tasks

#### Task 1: Create `complexity-analyzer` Skill
**Source**: `.claude/agents/complexity-estimator.md`

**Extraction**:
- [ ] Read `complexity-estimator.md` and extract complexity scoring logic
- [ ] Identify trigger keywords: "plan complexity", "estimate complexity", "complexity score"
- [ ] Create SKILL.md with complexity criteria

**Skill Structure**:
```yaml
---
name: complexity-analyzer
description: |
  Auto-assess plan or task complexity using 1-10 scale when discussing implementation plans.
  Triggers: plan complexity, complexity score, how complex, estimate effort.
allowed-tools: Read, Grep
---

# Complexity Analyzer

## Complexity Scale (1-10)
- **1-3**: Simple (direct implementation, <5 tasks, 1 file)
- **4-6**: Moderate (multiple files, testing required, 5-10 tasks)
- **7-8**: Complex (multi-phase, >10 tasks, integration challenges)
- **9-10**: Very Complex (architecture changes, >15 tasks, high risk)

## Thresholds
- Expansion threshold: 8.0 (auto-expand phases above this)
- Task count threshold: 10 (expand if more tasks)
[Link to detailed criteria: reference.md]
```

**Files**:
- `.claude/skills/complexity-analyzer/SKILL.md`
- `.claude/skills/complexity-analyzer/reference.md`

#### Task 2: Create `template-conventions` Skill
**Source**: `.claude/agents/template-processor.md`

**Extraction**:
- [ ] Read `template-processor.md` and extract template patterns
- [ ] Identify trigger keywords: "use template", "template variables", "process template"
- [ ] Create SKILL.md with template conventions

**Skill Structure**:
```yaml
---
name: template-conventions
description: |
  Auto-apply template processing conventions when working with templates.
  Triggers: use template, template variables, create from template, template pattern.
allowed-tools: Read, Glob
---

# Template Conventions

## Template Variables
- `{{VARIABLE_NAME}}` - Placeholder for substitution
- `{{OPTIONAL_VARIABLE:-default}}` - Optional with default value
- `{{#CONDITION}}...{{/CONDITION}}` - Conditional sections

## Template Locations
- `.claude/templates/` - Reusable templates
- Plan templates: `.claude/templates/plans/`
[Link to examples: reference.md]
```

**Files**:
- `.claude/skills/template-conventions/SKILL.md`
- `.claude/skills/template-conventions/reference.md`

#### Task 3: Comprehensive A/B Testing
- [ ] Run 10 diverse tasks: coding, planning, testing, debugging, documentation
- [ ] Compare workflows with Skills vs without Skills (use `/clear` to reset)
- [ ] Measure activation accuracy across all 8 Skills
- [ ] Gather subjective quality assessment: Are Skills helpful or distracting?
- [ ] Document findings in `specs/073_skills_migration_analysis/validation/phase_3_results.md`

**Success Criteria**:
- [ ] 8 Skills created (migration target complete)
- [ ] 75%+ overall appropriate activation rate
- [ ] Context usage <30%
- [ ] Positive quality assessment (Skills improve or maintain output quality)

---

## Phase 4: Strengthen Subagent Enforcement (Critical)

**Duration**: Week 7-8 (~20 hours)

**Objectives**:
- **Address root cause**: Weak enforcement causing compliance failures
- Refactor all 16 remaining subagents with mandatory verification checkpoints
- Eliminate command-calling-command anti-pattern
- Achieve 95%+ file creation compliance

### Tasks

#### Task 1: Define Verification Checkpoint Pattern
- [ ] Create standardized checkpoint template
- [ ] Document in `.claude/docs/concepts/patterns/verification-checkpoints.md`
- [ ] Include examples: file creation, test execution, git operations

**Checkpoint Template**:
```markdown
## MANDATORY CHECKPOINT: [OPERATION NAME]

**STOP - Execute in exact order:**

1. **[Action 1]**: [Specific tool call or operation]
   - Example: Create file at `path/to/file.md`
   - Tool: Write { file_path: "...", content: "..." }

2. **Verification**: Confirm operation succeeded
   - Example: Read file to verify existence and content
   - Tool: Read { file_path: "..." }
   - Expected: File exists with correct content

3. **Report**: Provide confirmation in output
   - Example: "✓ File created at [absolute path]"
   - Include: Absolute path, file size, first 50 chars of content

**HALT**: Do not proceed until verification confirms success.

**If verification fails**:
- Retry operation once with error details logged
- If retry fails: Report error to orchestrator, do not continue
```

**Files**:
- `.claude/docs/concepts/patterns/verification-checkpoints.md`

#### Task 2: Refactor Research Agents with Verification
**Targets**: `research-specialist.md`, `research-synthesizer.md`, `implementation-researcher.md`

**Changes**:
- [ ] Add file creation checkpoint before returning
- [ ] Replace weak imperative ("Create a report") with strong ("EXECUTE NOW - STEP 1: Create file")
- [ ] Add verification: Read file after creation to confirm
- [ ] Add failure handling: Retry once, escalate if retry fails

**Example Refactor** (research-specialist.md):
```diff
  ## Expected Output

- Provide a research report structured as:
+ MANDATORY CHECKPOINT: CREATE RESEARCH REPORT
+
+ STOP - Execute these steps in exact order:
+
+ 1. **Create Report File**:
+    - Path: specs/reports/NNN_topic.md
+    - Tool: Write { file_path: "[absolute path]", content: "[structured report]" }
+
+ 2. **Verify File Exists**:
+    - Tool: Read { file_path: "[absolute path]" }
+    - Confirm: File content matches what was written
+
+ 3. **Report Path**:
+    - Output format: "✓ Research report created: [absolute path]"
+    - Include: File size, summary (50 words max)
+
+ HALT: Do not proceed until file verified.

  **Research Report Structure**:
  [... existing structure ...]
```

**Validation**:
- [ ] Test research-specialist with test task
- [ ] Verify file created (not inline summary)
- [ ] Check verification step executed
- [ ] Confirm error handling works (simulate write failure)

#### Task 3: Refactor Planning Agents with Verification
**Targets**: `plan-architect.md`, `plan-expander.md`

**Changes**:
- [ ] Add plan file creation checkpoint
- [ ] Replace SlashCommand("/plan") with direct plan creation
- [ ] Add verification: Read plan file after creation

**Example Refactor** (plan-architect.md):
```diff
  ## Objective
  Create a structured implementation plan.

- Use the /plan command to generate:
- ```bash
- /plan [feature description] [report-paths]
- ```
+ MANDATORY CHECKPOINT: CREATE IMPLEMENTATION PLAN
+
+ 1. **Create Plan File**:
+    - Path: specs/plans/NNN_feature_name.md
+    - Tool: Write { file_path: "...", content: "[plan content]" }
+
+ 2. **Verify Plan File**:
+    - Tool: Read { file_path: "..." }
+    - Confirm: Plan includes metadata, phases, tasks, testing strategy
+
+ 3. **Report Plan Details**:
+    - Output: "✓ Plan created: [path]"
+    - Include: Phase count, complexity estimate
+
+ HALT: Do not proceed until plan file verified.
```

**Validation**:
- [ ] Test plan-architect with test feature
- [ ] Verify plan file created (not SlashCommand call)
- [ ] Check plan structure includes all required sections

#### Task 4: Refactor Implementation Agents with Verification
**Targets**: `implementation-executor.md`, `implementer-coordinator.md`

**Changes**:
- [ ] Add git commit checkpoint (verify commit created)
- [ ] Add test execution checkpoint (verify tests run and pass)
- [ ] Replace SlashCommand("/debug") with direct debug agent invocation

**Example Refactor** (implementation-executor.md):
```diff
  ## Per-Phase Workflow

  1. Execute phase tasks
  2. Run phase tests
- 3. Create git commit
+ 3. MANDATORY CHECKPOINT: CREATE GIT COMMIT
+    a. Stage files: git add [files]
+    b. Create commit: git commit -m "[message]"
+    c. Verify: git log -1 --format="%H %s" (confirm commit exists)
+    d. Report: "✓ Commit created: [hash] - [subject]"
+ 4. MANDATORY CHECKPOINT: VERIFY TESTS PASS
+    a. Run tests: [test command from plan]
+    b. Capture output
+    c. Parse result: passing/failing
+    d. If failing: HALT, invoke debug-analyst via Task tool (NOT SlashCommand)
+    e. Report: "✓ Tests passing: [count] passed, [count] failed"
```

**Validation**:
- [ ] Test implementation-executor with simple plan
- [ ] Verify commits created and verified
- [ ] Verify tests executed and results captured
- [ ] Check debug invocation uses Task tool (NOT SlashCommand)

#### Task 5: Refactor Debug Agents with Verification
**Targets**: `debug-specialist.md`, `debug-analyst.md`

**Changes**:
- [ ] Add debug report creation checkpoint
- [ ] Add verification: Read report after creation
- [ ] Replace SlashCommand("/debug") self-invocation with direct logic

**Example Refactor** (debug-specialist.md):
```diff
  ## Objective
  Investigate test failures and create diagnostic report.

- Use /debug command:
- ```bash
- /debug "[issue description]" [plan-path]
- ```
+ MANDATORY CHECKPOINT: CREATE DEBUG REPORT
+
+ 1. **Investigate Issue**:
+    - Reproduce failure
+    - Identify root cause
+    - Gather evidence
+
+ 2. **Create Debug Report**:
+    - Path: specs/debug/NNN_issue_name.md
+    - Tool: Write { file_path: "...", content: "[report]" }
+
+ 3. **Verify Report**:
+    - Tool: Read { file_path: "..." }
+    - Confirm: Includes root cause, fix proposals, evidence
+
+ 4. **Report Details**:
+    - Output: "✓ Debug report: [path]"
+    - Include: Root cause (1 sentence), fix count
```

**Validation**:
- [ ] Test debug-specialist with simulated test failure
- [ ] Verify debug report created as file
- [ ] Check report includes root cause and fix proposals

#### Task 6: Refactor Documentation Agents with Verification
**Targets**: `doc-writer.md`, `doc-converter.md`

**Changes**:
- [ ] Add documentation file creation checkpoint
- [ ] Add verification: Read created/updated docs
- [ ] Add cross-reference verification

**Example Refactor** (doc-writer.md):
```diff
  ## Objective
  Update documentation for code changes.

- Use /document command:
- ```bash
- /document [change description]
- ```
+ MANDATORY CHECKPOINT: UPDATE DOCUMENTATION
+
+ 1. **Identify Affected Docs**:
+    - Search for related READMEs, guides, specs
+    - List files to update: [file1, file2, ...]
+
+ 2. **Update Each File**:
+    - For each file:
+      a. Read current content
+      b. Apply changes (Edit tool)
+      c. Verify: Read updated file
+      d. Confirm changes applied correctly
+
+ 3. **Report Updates**:
+    - Output: "✓ Documentation updated: [count] files"
+    - List: [file1], [file2], ...
```

**Validation**:
- [ ] Test doc-writer with sample code change
- [ ] Verify documentation files updated
- [ ] Check verification steps executed

#### Task 7: Eliminate SlashCommand Anti-Pattern
- [ ] Search all command files for `SlashCommand` tool usage: `grep -r "SlashCommand" .claude/commands/`
- [ ] Replace each occurrence with appropriate pattern:
  - SlashCommand("/plan") → Invoke `plan-architect` via Task tool
  - SlashCommand("/debug") → Invoke `debug-specialist` via Task tool
  - SlashCommand("/implement") → Invoke `implementation-executor` via Task tool
  - SlashCommand("/report") → Invoke `research-specialist` via Task tool
- [ ] Document replacement patterns in `.claude/docs/guides/command-development-guide.md`
- [ ] Add test: `test_no_slashcommand_in_commands.sh` to prevent regression

**Files**:
- `.claude/commands/orchestrate.md` (remove SlashCommand references)
- `.claude/commands/implement.md` (remove SlashCommand references)
- `.claude/tests/test_no_slashcommand_in_commands.sh` (new test)

**Validation**:
- [ ] Run: `grep -r "SlashCommand" .claude/commands/` → 0 results
- [ ] Run: `.claude/tests/test_no_slashcommand_in_commands.sh` → PASS

#### Task 8: End-to-End Validation
- [ ] Run `/orchestrate` with complex feature request (e.g., "Add authentication with JWT")
- [ ] Monitor file creation compliance: Are reports/plans created as files?
- [ ] Check SlashCommand usage: Should be 0 occurrences
- [ ] Measure context usage: Should remain <30%
- [ ] Document results in `specs/073_skills_migration_analysis/validation/phase_4_results.md`

**Success Criteria**:
- [ ] 16 subagents refactored with verification checkpoints
- [ ] File creation compliance: 95%+ (measured across 5 test workflows)
- [ ] SlashCommand anti-pattern eliminated: 0 occurrences in commands
- [ ] Context usage: <30% throughout workflows
- [ ] End-to-end `/orchestrate` workflow succeeds with all files created

---

## Phase 5: Cleanup and Documentation

**Duration**: Week 8 (~6 hours)

**Objectives**:
- Archive deprecated subagent files
- Update all documentation to reflect hybrid architecture
- Create migration guide for future Skills
- Validate final metrics vs baseline

### Tasks

#### Task 1: Archive Deprecated Subagent Files
- [ ] Create `.claude/agents/archive/` directory
- [ ] Move migrated subagent files to archive:
  - code-writer.md → coding-standards Skill
  - doc-writer.md → documentation-standards Skill
  - test-specialist.md → testing-protocols Skill
  - git-commit-helper.md → commit-message-guide Skill
  - code-reviewer.md → code-review-standards Skill
  - location-specialist.md → file-organization Skill
  - complexity-estimator.md → complexity-analyzer Skill
  - template-processor.md → template-conventions Skill
- [ ] Add README.md to archive explaining deprecation and Skill mappings

**Files**:
- `.claude/agents/archive/README.md`
- `.claude/agents/archive/[8 deprecated subagent files]`

#### Task 2: Update Documentation
- [ ] Update `CLAUDE.md`:
  - Add Skills section explaining hybrid architecture
  - Update subagent inventory (24 → 16)
  - Add Skills inventory (0 → 8)
  - Document Skills + Subagents decision rationale
- [ ] Update `.claude/docs/concepts/hierarchical_agents.md`:
  - Add Skills tier to architecture diagram
  - Explain Skills vs Subagents use cases
  - Update context reduction strategies (include Skills dormancy)
- [ ] Update `.claude/commands/README.md`:
  - Document that commands invoke subagents via Task tool (NOT SlashCommand)
  - Reference Skills for auto-applied standards
- [ ] Create `.claude/skills/README.md`:
  - List all 8 Skills with descriptions
  - Explain activation triggers
  - Document progressive disclosure pattern
  - Link to reference Skills (skill-creator, template-skill)

**Files**:
- `CLAUDE.md` (updated)
- `.claude/docs/concepts/hierarchical_agents.md` (updated)
- `.claude/commands/README.md` (updated)
- `.claude/skills/README.md` (created)

#### Task 3: Create Migration Guide
- [ ] Create `.claude/docs/guides/skills-migration-guide.md`:
  - When to create a Skill vs keep as subagent
  - How to extract capability from subagent
  - Verification checkpoint pattern
  - A/B testing methodology
  - Activation trigger design best practices

**Files**:
- `.claude/docs/guides/skills-migration-guide.md`

#### Task 4: Final Metrics Validation
- [ ] Run same 3 test workflows from Phase 0 baseline
- [ ] Measure and compare:
  - Context usage (baseline vs final)
  - File creation compliance (baseline: 0% → target: 95%)
  - SlashCommand occurrences (baseline: [count] → target: 0)
  - Skills activation accuracy (target: 80%+ appropriate)
- [ ] Document final metrics in `specs/073_skills_migration_analysis/validation/final_metrics.md`
- [ ] Create comparison report: baseline vs final

**Output**: `specs/073_skills_migration_analysis/validation/final_metrics.md`:
```markdown
## Final Metrics (2025-11-20)

### Migration Outcomes
- Skills created: 8
- Subagents retained: 16
- Subagents deprecated: 8

### Performance Improvements
| Metric | Baseline | Final | Change |
|--------|----------|-------|--------|
| File creation compliance | 0% | 95%+ | +95% ✓ |
| SlashCommand occurrences | [count] | 0 | -100% ✓ |
| Context usage | [%] | <30% | [maintained/improved] ✓ |
| Skills activation accuracy | N/A | 80%+ | N/A |

### Qualitative Improvements
- Standards auto-applied without explicit invocation
- Commands no longer call other commands
- Clear separation: Skills (knowledge) vs Subagents (workflows)
- Verification checkpoints ensure file creation compliance
```

#### Task 5: Create Workflow Summary
- [ ] Generate workflow summary following project standards
- [ ] Include:
  - All 4 phases completed
  - Research report reference
  - Implementation plan reference
  - Final metrics comparison
  - Lessons learned
  - Recommendations for future

**Files**:
- `specs/073_skills_migration_analysis/summaries/001_hybrid_architecture_migration.md`

**Success Criteria**:
- [ ] All deprecated subagent files archived with README
- [ ] Documentation updated to reflect hybrid architecture
- [ ] Migration guide created for future reference
- [ ] Final metrics validate success (95%+ file creation, 0 SlashCommand, 80%+ activation)
- [ ] Workflow summary created

---

## Testing Strategy

### Unit-Level Testing (Per Skill/Subagent)

**Skill Activation Testing**:
- Create test prompts matching Skill descriptions
- Verify Skill activates (check output mentions Skill concepts)
- Test non-activation (unrelated prompts should not trigger)
- Measure false positive rate (<10% target)

**Subagent Verification Testing**:
- Invoke refactored subagent with test task
- Verify file creation checkpoint executed
- Verify verification step executed (file read after write)
- Verify error handling (simulate write failure)

### Integration Testing (Command + Skills + Subagents)

**Test Case 1: Simple Feature Implementation**
- Run: `/orchestrate Add logging to authentication module`
- Verify:
  - `coding-standards` Skill activates during implementation
  - `testing-protocols` Skill activates when writing tests
  - `commit-message-guide` Skill activates during git commit
  - Implementation files created (not inline summaries)
  - Tests run and pass
  - Git commit created with proper format

**Test Case 2: Research-Heavy Task**
- Run: `/orchestrate Research best practices for rate limiting`
- Verify:
  - Research report created as file: `specs/reports/NNN_rate_limiting.md`
  - `documentation-standards` Skill activates when creating report
  - No SlashCommand invocations
  - Context usage <30%

**Test Case 3: Bug Fix with Debugging**
- Run: `/orchestrate Fix the test failure in auth module`
- Verify:
  - Debug report created as file: `specs/debug/NNN_auth_test_failure.md`
  - Fix applied and verified
  - Tests re-run and pass
  - Git commit created
  - `commit-message-guide` Skill activates

### Regression Testing

**Anti-Pattern Prevention**:
- Test: `test_no_slashcommand_in_commands.sh`
  - Searches all `.claude/commands/*.md` for `SlashCommand` usage
  - Fails if any found (prevents regression)

**File Creation Compliance**:
- Test: `test_file_creation_compliance.sh`
  - Runs 3 workflows (research, planning, debugging)
  - Verifies expected files created
  - Fails if inline summaries returned instead

**Context Usage**:
- Test: `test_context_usage.sh`
  - Runs complex workflow
  - Monitors token usage (requires manual instrumentation)
  - Fails if exceeds 30% threshold

### Coverage Target

- **Skill Coverage**: 100% (all 8 Skills tested for activation and non-activation)
- **Subagent Coverage**: 100% (all 16 refactored subagents tested for verification checkpoints)
- **Integration Coverage**: 80% (major workflows tested end-to-end)
- **Regression Coverage**: Critical anti-patterns tested (SlashCommand, file creation)

---

## Risk Mitigation

### Risk 1: Skills Don't Activate Appropriately
**Mitigation**:
- Write highly specific descriptions with concrete keywords
- Test activation with 10+ diverse prompts per Skill
- Iterate on descriptions based on false positive/negative rates
- Fallback: Keep subagent available during Skills validation period

### Risk 2: Verification Checkpoints Add Too Much Complexity
**Mitigation**:
- Create reusable checkpoint template (copy-paste pattern)
- Document pattern clearly in verification-checkpoints.md
- Start with 1-2 subagents, refine pattern, then scale to others
- Provide examples for each checkpoint type (file creation, test execution, git commit)

### Risk 3: Migration Takes Longer Than Estimated
**Mitigation**:
- Phased approach allows stopping after any phase if value not realized
- Focus on highest-impact Skills first (coding-standards, documentation-standards)
- Parallel work: Skills migration (Phase 1-3) can overlap with subagent strengthening (Phase 4)
- If time-constrained: Complete Phases 0-1 (foundation + 3 core Skills) and pause

### Risk 4: Skills Increase Context Usage Beyond 30%
**Mitigation**:
- Progressive disclosure: Keep SKILL.md concise, details in reference.md
- Monitor context usage after each phase
- Deactivate low-use Skills if context budget exceeded
- Limit total Skills to 8 (based on research recommendations)

### Risk 5: Team Adoption Challenges
**Mitigation**:
- Document Skills clearly in `.claude/skills/README.md`
- Provide activation examples for each Skill
- Create migration guide for future Skills development
- Gather feedback after Phase 1 (adjust approach if needed)

---

## Success Metrics Summary

### Quantitative Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| File creation compliance | 0% | 95%+ | Audit 10 workflows, count file creations vs inline summaries |
| SlashCommand anti-pattern | [count] | 0 | `grep -r "SlashCommand" .claude/commands/` |
| Context usage | [%] | <30% | Token tracking across workflows |
| Skills activation accuracy | N/A | 80%+ | Manual review of 50 conversations |
| Inappropriate activation | N/A | <10% | False positive rate in activation tests |

### Qualitative Metrics

- **Standards Enforcement**: Coding/doc/testing standards auto-applied without manual invocation
- **Architecture Clarity**: Clear separation between Skills (knowledge), Commands (coordination), Subagents (workflows)
- **Maintainability**: Easier onboarding, self-documenting Skills, reusable verification patterns
- **User Experience**: Reduced need for explicit command invocation, consistent standards across conversations

---

## Rollback Plan

If migration outcomes are negative (increased context, poor activation, decreased quality):

### Phase-by-Phase Rollback

**After Phase 1 (Foundation Skills)**:
- If Skills don't activate or decrease quality:
  - Delete `.claude/skills/[skill-name]` directories
  - Restore original subagent invocations in commands
  - Document why Skills approach didn't fit

**After Phase 2-3 (Process/Analysis Skills)**:
- If specific Skills underperform:
  - Archive underperforming Skill
  - Restore corresponding subagent from archive
  - Document lessons learned

**After Phase 4 (Subagent Strengthening)**:
- If verification checkpoints cause issues:
  - Remove checkpoint sections from subagents
  - Revert to original behavioral injection pattern
  - Keep strong imperatives (still improvement over baseline)

### Complete Rollback (Worst Case)

If hybrid architecture proves unworkable:
- [ ] Delete `.claude/skills/` directory entirely
- [ ] Restore all 24 original subagent files from git history
- [ ] Revert command files to pre-migration state
- [ ] Keep only: Strong imperatives, no SlashCommand anti-pattern (proven improvements)
- [ ] Document comprehensive lessons learned for future architectural decisions

---

## Appendices

### Appendix A: Current Subagent Inventory (24 Total)

**Research** (3): research-specialist, research-synthesizer, implementation-researcher
**Planning** (3): plan-architect, plan-expander, complexity-estimator
**Implementation** (4): code-writer, implementation-executor, implementer-coordinator, test-specialist
**Debug** (2): debug-analyst, debug-specialist
**Documentation** (2): doc-writer, doc-converter
**Maintenance** (7): spec-updater, code-reviewer, location-specialist, collapse-specialist, expansion-specialist, metrics-specialist, git-commit-helper
**Integration** (3): github-specialist, slash-command-executor, template-processor

### Appendix B: Skills Migration Mapping

| Subagent (Deprecated) | Skill (Replacement) | Status |
|-----------------------|---------------------|--------|
| code-writer.md | coding-standards | Phase 1 |
| doc-writer.md | documentation-standards | Phase 1 |
| test-specialist.md | testing-protocols | Phase 1 |
| git-commit-helper.md | commit-message-guide | Phase 2 |
| code-reviewer.md | code-review-standards | Phase 2 |
| location-specialist.md | file-organization | Phase 2 |
| complexity-estimator.md | complexity-analyzer | Phase 3 |
| template-processor.md | template-conventions | Phase 3 |

### Appendix C: Subagents Retained (16 Total)

**Complex Workflows** (retain as subagents):
- implementer-coordinator (multi-phase state management)
- spec-updater (cross-directory file manipulation)
- research-specialist (multi-step workflow)
- plan-architect (complex plan generation)
- debug-analyst (parallel hypothesis testing)
- implementation-executor (wave-based execution)
- research-synthesizer (multi-agent aggregation)
- plan-expander (recursive phase expansion)
- expansion-specialist (progressive plan hierarchy)
- collapse-specialist (reverse expansion)
- metrics-specialist (performance analytics)
- github-specialist (GitHub API orchestration)
- doc-converter (multi-format conversion)
- implementation-researcher (pre-phase exploration)
- debug-specialist (diagnostic reporting)

**Deprecated/Remove**:
- slash-command-executor (anti-pattern, remove entirely)

### Appendix D: Reference Skills to Import

**Anthropic Official**:
- skill-creator (meta-skill for Skill development)
- template-skill (starter template)

**Community (obra/superpowers)**:
- tdd.skill (TDD patterns)
- debugging.skill (systematic debugging)
- collaboration.skill (team communication)

### Appendix E: Verification Checkpoint Template

See `.claude/docs/concepts/patterns/verification-checkpoints.md` (created in Phase 4, Task 1)

---

**Plan Status**: Ready for execution
**Next Steps**: Execute Phase 0 (Foundation and Preparation)
**Estimated Completion**: 2025-11-20 (8 weeks from 2025-10-23)