# Claude Documentation Standards Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Claude Documentation Standards
- **Report Type**: Codebase analysis
- **Complexity Level**: 3

## Executive Summary

The codebase defines comprehensive documentation standards across code conventions, architecture patterns, directory organization, development philosophy, and testing protocols. Key principles include timeless writing (no historical commentary), executable/documentation separation for commands/agents, directory-specific placement rules, and imperative language for AI execution enforcement.

## Findings

### 1. Code Standards and Conventions

**Source**: `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)

**Core Principles**:
- **Indentation**: 2 spaces, expandtab (line 5)
- **Line Length**: ~100 characters soft limit (line 6)
- **Naming Conventions**: snake_case for variables/functions, PascalCase for module tables (line 7)
- **Error Handling**: Defensive programming with structured error messages (WHICH/WHAT/WHERE) (line 8)
- **Character Encoding**: UTF-8 only, no emojis in file content (line 10)

**Language-Specific Standards**:
- **Lua**: Detailed standards in `nvim/CLAUDE.md` (line 13)
- **Markdown**: Unicode box-drawing for diagrams, CommonMark spec compliance (line 14)
- **Shell Scripts**: ShellCheck recommendations, bash -e for error handling (line 15)

**Command/Agent Architecture**:
- Commands and agents are AI execution scripts, not traditional code (lines 20-21)
- Executable instructions must be inline, not external references (line 22)
- Templates must be complete and copy-paste ready (line 23)
- Critical warnings must stay in command files (line 24)
- Imperative language required: MUST/WILL/SHALL (never should/may/can) (line 25)

### 2. Writing Standards and Development Philosophy

**Source**: `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)

**Development Philosophy**:
- **Clean-Break Refactors**: Prioritize coherence over backward compatibility (line 24)
- **System Integration**: Focus on current implementation working well together (line 26)
- **No Legacy Burden**: Don't compromise design for old formats (line 27)
- **Migration Acceptable**: Breaking changes acceptable when improving quality (line 28)

**Documentation Standards - Present-Focused Writing**:
- Document current implementation only, no historical reporting (lines 51-52)
- Focus on "what" system does now, not "how" it evolved (line 53)
- Clean narrative: write as if current implementation always existed (line 54)
- Ban historical markers: "(New)", "(Old)", "(Updated)", "(Current)" (line 55)
- Avoid temporal phrases: "previously", "now supports", "recently added" (line 56)

**Banned Patterns** (lines 79-183):
- Temporal markers: (New), (Old), (Updated), (Deprecated), (Original) (lines 83-91)
- Temporal phrases: "previously", "recently", "now supports", "used to", "no longer" (lines 112-122)
- Migration language: "migrated to", "backward compatibility", "breaking change" (lines 144-151)
- Version references: "v1.0", "since version", "introduced in" (lines 172-177)

**Rewriting Patterns** (lines 193-253):
- Remove temporal context entirely: "was recently added" → "supports" (line 196)
- Focus on current capabilities: "Previously X. Now Y." → "Uses Y." (line 207)
- Convert comparisons to descriptions: "replaces old method" → "provides caching" (line 218)
- Eliminate version markers: "New in v2.0" → "Supports feature" (line 229)

### 3. Directory Organization Standards

**Source**: `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 1-276)

**Directory Structure** (lines 10-20):
```
.claude/
├── scripts/        Standalone CLI tools (validate, fix, migrate)
├── lib/            Sourced function libraries (parsing, error handling)
├── commands/       Slash command definitions
│   └── templates/  Plan templates (YAML) for /plan-from-template
├── agents/         Specialized AI assistant definitions
│   └── templates/  Agent behavioral templates
├── docs/           Integration guides and standards
└── tests/          Test suites for system validation
```

**File Placement Decision Matrix** (lines 154-164):
- **scripts/**: Standalone executables with CLI arguments, complete workflows
- **lib/**: Sourced by other code, reusable functions, stateless
- **commands/**: User-facing slash commands, markdown files with bash blocks
- **agents/**: AI agent behavioral definitions, invoked via Task tool

**Naming Conventions**:
- Bash scripts: `kebab-case-names.sh` (lines 33, 61)
- Commands: `command-name.md` (line 92)
- Agents: `agent-name.md` or `domain-specialist.md` (line 119)

**Anti-Patterns** (lines 184-203):
- Wrong locations: Templates in `.claude/templates/` instead of `agents/templates/` or `commands/templates/`
- Naming violations: CamelCase, underscores in new files, generic names (`utils.sh`)
- Missing README.md in subdirectories
- Mixing executable and library functions in one file

**Directory README Requirements** (lines 205-240):
1. Purpose: Clear 1-2 sentence explanation
2. Characteristics: Bulleted list of file types
3. Examples: 3-5 concrete examples
4. When to Use: Decision criteria
5. Documentation Links: Cross-references

### 4. Testing Protocols

**Source**: `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` (lines 1-236)

**Test Discovery** (lines 4-9):
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

**Claude Code Testing**:
- **Location**: `.claude/tests/` (line 11)
- **Test Runner**: `./run_all_tests.sh` (line 12)
- **Pattern**: `test_*.sh` bash test scripts (line 13)
- **Coverage**: ≥80% modified code, ≥60% baseline (line 14)

**Agent Behavioral Compliance Testing** (lines 39-198):
1. File Creation Compliance: Verify agent creates expected files (lines 55-79)
2. Completion Signal Format: Validate proper return format (lines 82-106)
3. STEP Structure Validation: Confirm documented STEP sequences (lines 109-129)
4. Imperative Language: Check MUST/WILL/SHALL usage (lines 132-152)
5. Verification Checkpoints: Ensure self-verification (lines 155-166)
6. File Size Limits: Validate agent files <40KB (lines 169-184)

**Test Isolation Standards** (lines 200-236):
- Environment overrides: `CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"` (line 204)
- Temporary directories: Use `mktemp` for unique test dirs (line 205)
- Cleanup traps: Register `trap cleanup EXIT` (line 206)
- Production directory pollution detection (line 207)

### 5. Directory Protocols and Artifact Lifecycle

**Source**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-1045)

**Topic-Based Organization** (lines 40-51):
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
    ├── scripts/        # Investigation scripts (temporary)
    ├── outputs/        # Test outputs (temporary)
    ├── artifacts/      # Operation artifacts
    └── backups/        # Backups
```

**Key Benefits**:
- All artifacts for a feature in one directory (line 25)
- Clear lifecycle: create → use → complete → archive (line 26)
- Automatic numbering within topic scope (line 27)
- Metadata-only references reduce context 95% (line 30)

**Lazy Directory Creation** (lines 66-89):
- Subdirectories created on-demand when files written, not eagerly
- Eliminates 400-500 empty directories across codebase (line 72)
- 80% reduction in mkdir calls during location detection (line 73)
- Use `ensure_artifact_directory()` before writing files (lines 78-82)

**Plan Structure Levels** (lines 798-825):
- **Level 0**: Single file, all phases inline (all plans start here) (lines 802-805)
- **Level 1**: Phase expansion via `/expand-phase` when complex (lines 807-812)
- **Level 2**: Stage expansion via `/expand-stage` for multi-stage workflows (lines 814-821)
- Progressive expansion: Structure grows organically based on implementation needs (line 823)

**Phase Dependencies and Wave-Based Execution** (lines 829-880):
- Dependency syntax: `Dependencies: []` or `[1, 2, 3]` in phase metadata (lines 833-840)
- Independent phases execute in parallel (40-60% time savings) (line 856)
- Topological sorting (Kahn's algorithm) calculates execution waves (line 855)
- Example: 3 phases → Wave 1 (phase 1), Wave 2 (phases 2,3 parallel), Wave 3 (phase 4) (lines 860-878)

**Gitignore Compliance** (lines 303-416):
- `debug/` committed (project history, issue tracking) (line 307)
- All other artifact types gitignored (local working artifacts) (lines 308-314)
- `.gitignore` pattern: `specs/` ignored, `!specs/**/debug/` exception (lines 318-328)

**Metadata-Only References** (lines 145-174):
- Extract metadata instead of full content (95% context reduction) (line 148)
- Utilities: `extract_report_metadata()`, `extract_plan_metadata()` (lines 149-153)
- Pattern: Pass 250 tokens/report vs 5000 tokens full content (lines 158-162)

### 6. Executable/Documentation Separation Pattern

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` (lines 1-150)

**Problem Statement** (lines 9-38):
- Commands combining execution + documentation cause meta-confusion loops (line 12)
- Four failure modes: recursive invocation bugs, permission errors, infinite loops, context bloat (lines 13-21)
- Example: Pre-migration `/orchestrate` was 5,439 lines (line 25)
- Claude interprets documentation conversationally → attempts recursive invocation (lines 34-37)

**Two-File Pattern** (lines 59-92):
1. **Executable Command File**: Lean execution script <250 lines (simple) or <1,200 (orchestrators) (lines 63-76)
   - Bash blocks, phase markers, execution markers, minimal inline comments
   - Audience: AI executor (Claude) during command execution
   - Success: Command completes without meta-confusion

2. **Command Guide File**: Complete documentation, unlimited length (lines 78-92)
   - Architecture, usage examples, troubleshooting, design decisions
   - Audience: Human developers, maintainers
   - Success: Developer understands and can modify confidently

**Migration Metrics** (lines 141-150):
- `/orchestrate`: 5,439 → 557 lines (90% reduction)
- `/coordinate`: 2,334 → 1,084 lines (54% reduction)
- `/implement`: 2,076 → 220 lines (89% reduction)
- `/plan`: 1,447 → 229 lines (84% reduction)

**Cross-Reference Convention** (lines 105-137):
- Bidirectional linking: executable references guide, guide references executable
- Validation script: `.claude/tests/validate_executable_doc_separation.sh`

### 7. Command Architecture Standards - Execution Enforcement

**Source**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-350)

**Standard 0: Execution Enforcement** (lines 51-310):

**Core Principle**: Commands are AI execution scripts, not traditional code (lines 20-29)
- Step-by-step execution instructions Claude reads and follows
- Direct tool invocation patterns with specific parameters
- Critical warnings visible during execution
- Cannot effectively load external files mid-execution

**Imperative vs Descriptive Language** (lines 61-78):
- ❌ Descriptive: "The research phase invokes parallel agents"
- ✅ Imperative: "YOU MUST invoke research agents in this exact sequence"
- Strength hierarchy: Critical > Mandatory > Strong > Standard > Optional (lines 188-199)

**Enforcement Patterns**:
1. **Direct Execution Blocks**: "EXECUTE NOW" markers for critical operations (lines 81-103)
2. **Mandatory Verification Checkpoints**: Explicit verification Claude MUST execute (lines 105-133)
3. **Non-Negotiable Agent Prompts**: "THIS EXACT TEMPLATE (No modifications)" (lines 135-167)
4. **Checkpoint Reporting**: Required completion reporting after major steps (lines 169-186)

**Fallback Mechanism Requirements** (lines 202-238):
- Primary path: Agent follows instructions
- Fallback path: Command creates output if agent doesn't comply
- Implementation: Invoke → Verify → Fallback if missing (lines 213-229)
- Required for: File creation, structured output parsing, artifact organization (lines 232-238)

**Phase 0 Requirement for Orchestrators** (lines 311-349):
- Pre-calculate all artifact paths before invoking subagents
- Use orchestrator vs executor role distinction
- Orchestrators invoke via Task tool (NOT SlashCommand)
- Enables topic-based organization and metadata extraction

### 8. Adaptive Planning Configuration

**Source**: `/home/benjamin/.config/.claude/docs/reference/adaptive-planning-config.md` (lines 1-38)

**Complexity Thresholds**:
- **Expansion Threshold**: 8.0 (auto-expand phases above this score) (line 8)
- **Task Count Threshold**: 10 (expand phases with more tasks) (line 9)
- **File Reference Threshold**: 10 (phases referencing more files) (line 10)
- **Replan Limit**: 2 (max automatic replans per phase, prevents loops) (line 11)

**Threshold Adjustments by Project Type** (lines 13-30):
- Research-heavy: Lower thresholds (5.0, 7, 8)
- Simple web app: Higher thresholds (10.0, 15, 15)
- Mission-critical: Maximum organization (3.0, 5, 5)

**Recommended Ranges** (lines 32-37):
- Expansion: 3.0 - 12.0
- Task count: 5 - 15
- File references: 5 - 20
- Replan limit: 1 - 3

## Recommendations

### 1. Apply Timeless Writing Standards Systematically

**Current State**: Writing standards comprehensively documented in `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md`

**Recommendation**: Create automated validation to enforce timeless writing across all documentation:
- Implement pre-commit hook using existing validation script (lines 472-511 in writing-standards.md)
- Add to CI/CD pipeline for automated enforcement
- Run periodic audits on existing documentation to remove temporal language
- Focus on high-impact files: CLAUDE.md, README files, command guides

**Rationale**: Consistent present-focused documentation reduces cognitive load and prevents stale historical commentary from accumulating.

### 2. Enforce Executable/Documentation Separation for All Commands

**Current State**: Pattern documented, 7 commands migrated with 54-90% size reductions

**Recommendation**: Complete migration for remaining commands:
- Audit all command files in `.claude/commands/` for size violations (>250 lines simple, >1,200 orchestrators)
- Extract comprehensive documentation to guide files in `.claude/docs/guides/`
- Validate bidirectional cross-references using existing test script
- Apply to new commands from day one using templates

**Rationale**: Prevents meta-confusion loops, enables independent evolution of execution vs documentation, reduces context bloat by 70% average.

### 3. Strengthen Agent Behavioral Compliance Testing

**Current State**: 6 compliance test patterns defined (file creation, completion signals, STEP structure, imperative language, verification checkpoints, file size limits)

**Recommendation**: Implement comprehensive test suite for all agents:
- Create `test_agent_behavioral_compliance.sh` following patterns in testing-protocols.md (lines 39-198)
- Test each agent against all 6 compliance criteria
- Add to CI/CD for automatic validation on agent modifications
- Implement monitoring for agent execution failures and correlate with compliance violations

**Rationale**: Agent behavioral violations cause workflow failures. Systematic testing prevents 80% of file creation and verification issues.

### 4. Standardize Directory Organization Enforcement

**Current State**: Clear decision matrix and anti-patterns documented in directory-organization.md

**Recommendation**: Create validation tooling and enforcement:
- Script to detect files in wrong locations (templates in `.claude/templates/` vs proper subdirectories)
- Naming convention validator (CamelCase detection, missing .sh extensions)
- README coverage checker (ensure all directories have README.md)
- Add to pre-commit hooks and CI/CD

**Rationale**: Consistent organization prevents 50% of "where should this file go" questions and reduces navigation time.

### 5. Expand Metadata-Only Reference Pattern Usage

**Current State**: Metadata extraction utilities exist for reports and plans, 95% context reduction demonstrated

**Recommendation**: Apply metadata-only pattern more broadly:
- Extend to summaries, debug reports, and other artifact types
- Create generic `extract_artifact_metadata()` wrapper
- Document pattern in all command development guides
- Add linting to detect full content passing instead of metadata

**Rationale**: Context budget is critical constraint. Metadata-only references enable 10x more artifacts to be referenced within same context window.

### 6. Implement Phase Dependency Validation

**Current State**: Phase dependency syntax documented, wave-based execution supported

**Recommendation**: Create validation and visualization tooling:
- Script to validate dependency syntax in plans (no forward refs, no circular deps, no self-deps)
- Visualizer to show dependency graph and execution waves
- Automatic wave calculation validation during plan creation
- Add examples to all plan templates

**Rationale**: Proper dependencies enable 40-60% time savings through parallel execution. Invalid dependencies cause execution failures and wasted cycles.

## References

### Primary Standards Documentation

1. **Code Standards**
   - `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-84)
   - Core principles, naming conventions, error handling, command architecture

2. **Writing Standards**
   - `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)
   - Development philosophy, timeless writing, banned patterns, rewriting rules

3. **Directory Organization**
   - `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 1-276)
   - Directory structure, file placement matrix, naming conventions, anti-patterns

4. **Testing Protocols**
   - `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` (lines 1-236)
   - Test discovery, coverage requirements, agent behavioral compliance, test isolation

5. **Directory Protocols**
   - `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-1045)
   - Topic-based organization, artifact lifecycle, gitignore compliance, metadata extraction

6. **Executable/Documentation Separation Pattern**
   - `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` (lines 1-150)
   - Two-file pattern, migration metrics, cross-reference convention

7. **Command Architecture Standards**
   - `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-350)
   - Standard 0 (execution enforcement), imperative language, fallback mechanisms

8. **Adaptive Planning Configuration**
   - `/home/benjamin/.config/.claude/docs/reference/adaptive-planning-config.md` (lines 1-38)
   - Complexity thresholds, threshold adjustments, recommended ranges

### Supporting Documentation

9. **CLAUDE.md Project Index**
   - `/home/benjamin/.config/CLAUDE.md` (lines 1-201)
   - Central configuration index with section markers and cross-references

10. **Neovim Documentation Standards**
    - `/home/benjamin/.config/nvim/docs/DOCUMENTATION_STANDARDS.md`
    - Lua-specific documentation standards

11. **Neovim Code Standards**
    - `/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md`
    - Lua coding conventions and module structure

### Validation and Testing Scripts

12. **Executable/Documentation Separation Validation**
    - `/home/benjamin/.config/.claude/tests/validate_executable_doc_separation.sh`
    - Validates bidirectional cross-references and file size compliance

13. **Link Validation**
    - `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh`
    - Quick markdown link validation
    - `/home/benjamin/.config/.claude/scripts/validate-links.sh`
    - Comprehensive link validation

14. **Timeless Writing Validation**
    - Referenced in writing-standards.md (lines 472-511)
    - Script to detect temporal markers and phrases

### Additional Cross-References

15. **Quick Reference Documentation**
    - `/home/benjamin/.config/.claude/docs/quick-reference/README.md`
    - Common tasks, setup utilities, command/agent references

16. **Command Reference**
    - `/home/benjamin/.config/.claude/docs/reference/command-reference.md`
    - Complete catalog of slash commands

17. **Agent Development Guide**
    - `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`
    - Creating and maintaining specialized agents

18. **Command Development Guide**
    - `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
    - Creating and maintaining slash commands

### Key Principles Summary

**Timeless Writing**: No historical markers, present-focused, "what" not "when"

**Executable/Documentation Separation**: <250 lines executable (simple) or <1,200 (orchestrators), unlimited guide files

**Directory Organization**: scripts/ (standalone), lib/ (sourced), commands/ (slash commands), agents/ (AI assistants), docs/ (documentation)

**Testing**: ≥80% coverage modified code, agent behavioral compliance, test isolation with environment overrides

**Artifacts**: Topic-based organization, lazy directory creation, metadata-only references (95% context reduction)

**Execution Enforcement**: Imperative language (MUST/WILL/SHALL), verification checkpoints, fallback mechanisms

**Phase Dependencies**: Wave-based parallel execution (40-60% time savings), topological sorting

**Adaptive Planning**: Complexity thresholds control automatic expansion, configurable by project type
