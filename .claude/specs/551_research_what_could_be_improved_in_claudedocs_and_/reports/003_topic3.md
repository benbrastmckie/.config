# Commands README - Quick Reference Documentation Gaps

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Commands README - Analyze gaps in quick-reference documentation for command structure requirements and common setup patterns
- **Report Type**: codebase analysis

## Executive Summary

The `.claude/commands/README.md` provides good high-level documentation but lacks critical quick-reference information for command developers. Missing elements include: (1) standardized library sourcing patterns and how to choose between `library-sourcing.sh` vs direct sourcing, (2) imperative language requirements from Standard 0, (3) agent invocation patterns from Standard 11, and (4) practical examples of common command structure requirements. While comprehensive guides exist in `.claude/docs/guides/`, the README doesn't link to them or provide quick-reference summaries.

## Findings

### 1. Library Sourcing Patterns Are Underdocumented

**Current State** (commands/README.md:39-45):
- Lines 39-45 mention "Shared Utilities Integration" with a list of libraries
- No guidance on WHEN to source libraries vs when commands handle logic inline
- No explanation of `library-sourcing.sh` vs direct sourcing patterns

**Evidence from Codebase**:

Commands use TWO distinct sourcing patterns with no documented decision criteria:

**Pattern A: Unified Library Sourcing** (found in orchestrate.md:242, 255-256):
```bash
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
source "$UTILS_DIR/error-handling.sh"
source "$UTILS_DIR/checkpoint-utils.sh"
```

**Pattern B: Direct Library Sourcing** (found in research.md:51-55):
```bash
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh
source .claude/lib/metadata-extraction.sh
source .claude/lib/overview-synthesis.sh
```

**Library Classification Exists But Not Referenced**:

`.claude/lib/README.md:44-105` provides comprehensive library classification:
- Core Libraries (required by all commands)
- Workflow Libraries (orchestration commands)
- Specialized Libraries (single-command use cases)
- Optional Libraries (can be disabled)
- **Sourcing Best Practices section** (lines 84-105)

**Gap**: The commands README doesn't reference this classification or explain when to use which sourcing pattern.

### 2. Command Structure Requirements Lack Quick Reference

**What's Missing**:

The README describes command metadata fields (lines 515-522) but doesn't provide:

1. **Frontmatter Requirements**: What fields are REQUIRED vs OPTIONAL
2. **Tool Selection Criteria**: How to choose minimal tool set
3. **Section Structure**: What sections commands MUST have
4. **Imperative Language**: Standard 0 requirements for enforcement

**Evidence**:

Command Development Guide exists at `.claude/docs/guides/command-development-guide.md` with comprehensive information:
- Lines 69-97: Complete frontmatter format
- Lines 100+: Detailed metadata field descriptions
- Section structure requirements

**Gap**: README line 732 links to CODE_STANDARDS.md but not to command-development-guide.md. No quick-reference summary in README itself.

### 3. Agent Invocation Patterns Not Summarized

**Critical Pattern Missing**:

README mentions "Commands can invoke agents" (lines 683-689) but provides NO concrete example or reference to Standard 11 (Imperative Agent Invocation Pattern).

**Evidence from Standards**:

`.claude/docs/reference/command_architecture_standards.md:51-200` defines Standard 0 (Execution Enforcement) with:
- Imperative vs Descriptive Language rules
- "EXECUTE NOW" enforcement patterns
- Mandatory verification checkpoints
- Agent invocation templates (lines 138-162)

Standard 11 exists and requires:
- Imperative instructions pattern
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files
- Explicit completion signals
- Fail-fast error handling

Found in 24 command files via grep, but NOT documented in README.

**Gap**: No quick reference to these critical patterns for command developers.

### 4. Common Setup Patterns Missing

**Setup Workflows Undocumented**:

Commands frequently need to:
1. Calculate artifact paths before agent invocation
2. Ensure parent directories exist (lazy creation)
3. Verify file creation post-agent
4. Handle fallback creation when agents fail

**Evidence**:

Pattern appears consistently across commands:
- `orchestrate.md:427`: Unified location detection
- `orchestrate.md:609-610`: Artifact creation and registry
- Agent behavioral files show consistent "STEP 1.5: Ensure Parent Directory Exists" pattern

**Gap**: README doesn't document these common patterns or link to examples.

### 5. Links to Detailed Documentation Are Incomplete

**What Exists**:

README has "Navigation" section (lines 790-817) linking to:
- Individual command definitions
- Parent directory
- agents/ and specs/ directories

**What's Missing**:

No links to:
- `.claude/docs/guides/command-development-guide.md` (comprehensive development guide)
- `.claude/docs/reference/command_architecture_standards.md` (architectural standards)
- `.claude/docs/guides/imperative-language-guide.md` (Standard 0 enforcement)
- `.claude/lib/README.md` (library classification and sourcing patterns)
- Behavioral injection pattern documentation
- Agent invocation best practices

### 6. README Structure Doesn't Support Quick Reference Use Case

**Current Structure**:
- Purpose (lines 82-92): What commands do
- Command Architecture (lines 94-120): High-level flow diagram
- Available Commands (lines 122-483): Comprehensive command list
- Command Definition Format (lines 485-513): Metadata structure
- Command Types (lines 523-539): Classification
- Adaptive Plan Structures (lines 541-618): Progressive planning
- Standards Discovery (lines 620-651): CLAUDE.md integration
- Creating Custom Commands (lines 653-679): High-level steps
- Best Practices (lines 702-720): General guidelines

**What's Missing for Quick Reference**:

No dedicated "Command Developer Quick Reference" section with:
1. **Library Sourcing Decision Tree**: When to use which pattern
2. **Required Frontmatter Fields**: Minimal command structure
3. **Imperative Language Checklist**: Standard 0 enforcement patterns
4. **Agent Invocation Template**: Standard 11 pattern
5. **Common Setup Patterns**: Path calculation, directory creation, verification
6. **Links to Deep Documentation**: Where to find comprehensive guides

## Recommendations

### 1. Add "Command Developer Quick Reference" Section

**Location**: After line 651 (end of Standards Discovery), before "Creating Custom Commands"

**Content**:
```markdown
## Command Developer Quick Reference

### Library Sourcing Patterns

**Decision Tree**:
- **Orchestration command** (research → plan → implement): Use `library-sourcing.sh`
- **Specialized command** (1-2 specific libraries): Use direct sourcing
- **See**: [Library Classification](./../lib/README.md#library-classification)

**Pattern A: Unified Library Sourcing** (orchestration commands):
```bash
source .claude/lib/library-sourcing.sh
source_required_libraries "dependency-analyzer.sh" || exit 1
```

**Pattern B: Direct Sourcing** (specialized commands):
```bash
source .claude/lib/convert-core.sh
source .claude/lib/conversion-logger.sh
```

### Required Command Structure

**Minimal Frontmatter**:
```yaml
---
allowed-tools: Read, Write, Bash  # Minimal set needed
argument-hint: <required> [optional]
description: One-line command summary
command-type: primary|support|workflow|utility
---
```

**Required Sections**:
1. Usage examples
2. Standards discovery (how command finds CLAUDE.md)
3. Workflow steps (what command does)
4. Output description (what command produces)

### Imperative Language Requirements (Standard 0)

Commands MUST use imperative enforcement for critical operations:

**Pattern**: "EXECUTE NOW", "MANDATORY", "YOU MUST"
**Use For**: File creation, path calculation, verification checkpoints
**See**: [Imperative Language Guide](../docs/guides/imperative-language-guide.md)

### Agent Invocation Pattern (Standard 11)

**Template**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief task description"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    .claude/agents/agent-name.md

    **EXECUTE NOW**: [Critical instructions]

    Return: EXPECTED_FORMAT: [confirmation]
}
```

**See**: [Command Architecture Standards](../docs/reference/command_architecture_standards.md#standard-11)

### Common Setup Patterns

**Path Pre-Calculation**:
```bash
source .claude/lib/unified-location-detection.sh
REPORT_PATH=$(get_or_create_topic_dir "$TOPIC" "specs/reports")
```

**Lazy Directory Creation**:
```bash
ensure_artifact_directory "$REPORT_PATH" || exit 1
```

**File Verification**:
```bash
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: File missing, executing fallback"
  # Fallback creation logic
fi
```
```

**Benefit**: Developers get immediate answers to "How do I..." questions without reading multiple guides.

### 2. Add Links Section to Navigation

**Location**: Lines 790-817 (Navigation section)

**Addition**:
```markdown
### Developer Documentation
- [Command Development Guide](../docs/guides/command-development-guide.md) - Comprehensive development guide
- [Command Architecture Standards](../docs/reference/command_architecture_standards.md) - Architectural requirements
- [Imperative Language Guide](../docs/guides/imperative-language-guide.md) - Enforcement patterns
- [Library API Reference](../lib/README.md) - Library classification and sourcing
- [Agent Development Guide](../docs/guides/agent-development-guide.md) - Agent creation patterns
```

**Benefit**: Developers know where to find deep documentation for each topic.

### 3. Enhance "Creating Custom Commands" Section

**Current State**: Lines 653-679 provide high-level steps

**Enhancement**: Add concrete decision points and pattern references:

```markdown
### Step 3: Choose Tools and Libraries

**Tools**: Select minimal set from: Read, Write, Edit, Bash, Grep, Glob, TodoWrite

**Libraries**:
- Orchestration commands: Use `library-sourcing.sh` (see [Quick Reference](#command-developer-quick-reference))
- Specialized commands: Direct source 1-2 libraries
- See [Library Classification](../lib/README.md#library-classification) for full list

### Step 4: Write Definition

**Use imperative language** (Standard 0) for:
- File creation operations ("EXECUTE NOW: Create file at...")
- Path calculations ("MANDATORY: Calculate paths before agent invocation")
- Verification checkpoints ("YOU MUST verify file exists")

**See**: [Imperative Language Guide](../docs/guides/imperative-language-guide.md)

### Step 5: Add Agent Invocations (If Needed)

**Use Standard 11 pattern**:
- Imperative instructions in agent prompt
- Direct reference to agent behavioral file
- Explicit completion signal format
- Fail-fast error handling

**See**: [Agent Invocation Examples](#agent-invocation-pattern-standard-11)
```

**Benefit**: Developers follow best practices from the start rather than discovering them through trial and error.

### 4. Add Frontmatter Field Reference Table

**Location**: After line 522 (end of metadata fields description)

**Content**:
```markdown
### Frontmatter Field Reference

| Field | Required | Purpose | Example Values |
|-------|----------|---------|----------------|
| `allowed-tools` | Yes | Tool access control | `Read, Write, Bash` |
| `argument-hint` | Yes | Help text format | `<feature> [report-path]` |
| `description` | Yes | One-line summary | `Execute implementation plans` |
| `command-type` | Yes | Command classification | `primary`, `support`, `workflow`, `utility` |
| `dependent-commands` | No | Related commands | `report, plan, debug` |

**Tool Options**: Read, Write, Edit, Bash, Grep, Glob, TodoWrite, SlashCommand, Task
```

**Benefit**: Quick reference for command metadata without reading full guide.

### 5. Document Common Failure Patterns

**Location**: New subsection under "Best Practices" (after line 720)

**Content**:
```markdown
### Common Pitfalls to Avoid

**Agent File Creation Failures**:
- ❌ **Problem**: Agent returns summary text instead of creating file
- ✓ **Solution**: Use imperative language ("ABSOLUTE REQUIREMENT: Create file FIRST")
- See: [Verification and Fallback Pattern](../docs/concepts/patterns/verification-fallback.md)

**Library Sourcing Errors**:
- ❌ **Problem**: Command sources all libraries unnecessarily
- ✓ **Solution**: Use library classification to source only what you need
- See: [Library Sourcing Best Practices](../lib/README.md#sourcing-best-practices)

**Path Resolution Issues**:
- ❌ **Problem**: Hardcoded paths break in different environments
- ✓ **Solution**: Use `unified-location-detection.sh` functions
- See: [Library API Reference](../docs/reference/library-api.md)
```

**Benefit**: Developers avoid known failure modes that waste time and cause frustration.

## References

### Primary Analysis Files
- `/home/benjamin/.config/.claude/commands/README.md` (880 lines) - Main analysis target
- `/home/benjamin/.config/.claude/lib/README.md:44-105` - Library classification and sourcing patterns
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:1-100` - Comprehensive development guide
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:51-200` - Standard 0 and imperative language requirements

### Supporting Evidence
- `/home/benjamin/.config/.claude/commands/research.md:51-55` - Direct sourcing pattern example
- `/home/benjamin/.config/.claude/commands/orchestrate.md:242,255-256,427,609-610` - Unified sourcing and artifact management patterns
- Grep results: 24 commands use `Task {` or Standard 11 patterns (not documented in README)

### Related Documentation
- `.claude/docs/guides/imperative-language-guide.md` - Standard 0 enforcement guide
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation patterns
- `.claude/docs/concepts/patterns/verification-fallback.md` - File creation verification
- `.claude/docs/reference/library-api.md` - Library function reference
