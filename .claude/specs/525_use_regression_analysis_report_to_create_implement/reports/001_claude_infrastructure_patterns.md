# Existing .claude/ Infrastructure Patterns Research Report

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Existing .claude/ Infrastructure Patterns
- **Report Type**: codebase analysis

## Executive Summary

The .claude/ directory follows a well-established four-pillar organizational structure: commands/ (26 slash commands), lib/ (52 shell libraries), agents/ (18 specialized agents + 1 registry), and templates/ (11 YAML plan templates). Library organization uses functional grouping with a sophisticated deduplication shim pattern (artifact-operations.sh wraps split libraries), consolidation bundles (plan-core-bundle.sh), and centralized sourcing (library-sourcing.sh). Agent behavioral files use YAML frontmatter for metadata and reside in .claude/agents/ with shared guidelines in agents/shared/. Documentation follows a clear hierarchy: docs/concepts/ for patterns, docs/guides/ for procedures, docs/reference/ for technical specs. The infrastructure achieves 85% token reduction through lazy directory creation patterns and path pre-calculation optimizations.

## Findings

### Directory Structure Conventions

The .claude/ infrastructure uses a four-pillar organizational structure verified across all examined files:

**Primary Directories** (/home/benjamin/.config/.claude/):
- **commands/** - 26 markdown files defining slash commands (e.g., coordinate.md, implement.md, research.md)
  - **commands/templates/** - 11 YAML plan templates for /plan-from-template command
  - **commands/shared/** - Archived (cleanup completed 2025-10-27, files moved to docs/)
- **lib/** - 52 shell script libraries providing reusable functionality
- **agents/** - 18 specialized agent behavioral files (*.md) + agent-registry.json
  - **agents/shared/** - 3 behavioral guideline files (100% active usage)
  - **agents/prompts/** - Agent-specific prompt templates
- **docs/** - Comprehensive documentation hierarchy
  - **docs/concepts/** - Architecture patterns and principles
  - **docs/guides/** - Step-by-step procedures and tutorials
  - **docs/reference/** - Technical specifications and API docs
  - **docs/workflows/** - Workflow documentation
- **specs/** - 100 topic-based directories for artifacts (plans, reports, summaries)
- **tests/** - Test suites for command and library validation
- **data/** - Runtime data (logs, metrics, checkpoints)

**Key Convention**: Commands in commands/, libraries in lib/, agents in agents/, plan templates in commands/templates/ (not .claude/templates/).

### Library Organization and Loading Patterns

The library system demonstrates sophisticated organization with three key patterns:

**Pattern 1: Consolidated Sourcing via library-sourcing.sh**

File: /home/benjamin/.config/.claude/lib/library-sourcing.sh (111 lines)

This library provides unified sourcing of core dependencies:
- Lines 42-54: Defines 7 core libraries (workflow-detection, error-handling, checkpoint-utils, unified-logger, unified-location-detection, metadata-extraction, context-pruning)
- Lines 56-59: Accepts optional additional libraries as arguments
- Lines 62-81: Implements O(n²) deduplication algorithm to prevent double-sourcing
- Lines 83-107: Fail-fast error handling with detailed diagnostics

Usage pattern in commands:
```bash
source .claude/lib/library-sourcing.sh
source_required_libraries || exit 1
```

**Pattern 2: Functional Deduplication Shim**

File: /home/benjamin/.config/.claude/lib/artifact-operations.sh (57 lines)

This is a backward-compatibility shim demonstrating the infrastructure's approach to refactoring:
- Lines 3-13: Header documents deprecation timeline (created 2025-10-29, removal 2026-01-01)
- Lines 23-49: Sources both split libraries (artifact-creation.sh, artifact-registry.sh)
- Lines 51-56: Emits deprecation warning once per process (ARTIFACT_OPS_DEPRECATION_WARNING_SHOWN guard)
- Migration guidance: Update 77 command references over 1-2 release cycles

This pattern enables non-breaking refactoring while guiding migrations.

**Pattern 3: Consolidation Bundles**

File: /home/benjamin/.config/.claude/lib/plan-core-bundle.sh (referenced in CLAUDE.md)

Some functionality is bundled into single libraries for convenience:
- Plan parsing functions grouped together
- Reduces number of source statements needed
- Trade-off: Larger file size for simpler dependencies

**Library Dependency Chain**:
- artifact-creation.sh sources: base-utils.sh, unified-logger.sh, artifact-registry.sh (line 8-10)
- library-sourcing.sh: Self-contained, no dependencies
- unified-location-detection.sh: Pure bash, no library dependencies (line 8)

**Performance Optimization**:
- Lazy directory creation pattern (unified-location-detection.sh lines 222-250)
- 80% reduction in mkdir calls during location detection
- Eliminated 400-500 empty subdirectories through ensure_artifact_directory() pattern

### Agent Behavioral File Locations and Naming

The agent system uses a registry-based architecture with strict file conventions:

**Agent Registry**: /home/benjamin/.config/.claude/agents/agent-registry.json (385 lines)
- Line 2: Schema version 1.0.0
- Line 3: Last updated timestamp (2025-10-27T03:23:49Z)
- Lines 4-384: JSON object with 18 agent definitions

**Agent Definition Structure** (example from lines 270-291):
```json
{
  "research-specialist": {
    "type": "specialized",
    "category": "research",
    "description": "Specialized in codebase research...",
    "tools": ["Read", "Write", "Grep", "Glob", "WebSearch", "WebFetch"],
    "metrics": {
      "total_invocations": 0,
      "successful_invocations": 0,
      ...
    },
    "dependencies": [],
    "behavioral_file": ".claude/agents/research-specialist.md"
  }
}
```

**Naming Convention**:
- Agent ID: kebab-case (e.g., research-specialist, plan-architect)
- Behavioral file: {agent-id}.md in .claude/agents/
- Path format: Always relative from project root (.claude/agents/...)

**Behavioral File Structure** (research-specialist.md: 671 lines):
- Lines 1-7: YAML frontmatter with metadata (allowed-tools, model, description)
- Lines 9+: Markdown documentation with procedural instructions
- Required sections: Research Execution Process, Completion Criteria, Integration Notes

**Shared Guidelines**: /home/benjamin/.config/.claude/agents/shared/
- error-handling-guidelines.md (9,291 bytes) - Error handling patterns
- progress-streaming-protocol.md (6,450 bytes) - Progress reporting format
- README.md (5,746 bytes) - Index of shared behavioral guidelines

**100% Active Usage**: All 3 files in agents/shared/ are referenced by multiple agents (verified in cleanup analysis).

### Template Storage and Usage Patterns

Templates follow a dual-location pattern based on template type:

**Plan Templates** (YAML format):
- **Location**: .claude/commands/templates/ (NOT .claude/templates/)
- **Count**: 11 templates organized by category
- **Command**: /plan-from-template (8,772 bytes at commands/plan-from-template.md)
- **Categories** (from templates/README.md lines 30-49):
  - Feature Development: crud-feature.yaml, api-endpoint.yaml, example-feature.yaml
  - Code Quality: refactoring.yaml, refactor-consolidation.yaml, test-suite.yaml
  - Operations: migration.yaml, debug-workflow.yaml, documentation-update.yaml
  - Research: research-report.yaml

**Template Format** (YAML):
- Frontmatter defines variable placeholders ({{FEATURE_NAME}}, {{COMPONENT_NAME}}, etc.)
- Body contains phase structure with task checklists
- Integration via .claude/lib/template-integration.sh and parse-template.sh

**Agent Prompt Templates**:
- **Location**: .claude/agents/prompts/ (mentioned in registry structure)
- **Usage**: Reusable prompt fragments for agent invocations
- **Integration**: Loaded by commands when invoking agents via Task tool

**Documentation Templates**:
- **Location**: .claude/docs/reference/ (post-cleanup migration)
- **Examples**: orchestration-patterns.md (70K), debug-structure.md (11K), report-structure.md (7.7K)
- **Migration**: Moved from commands/shared/ during spec 496 cleanup (2025-10-27)

**Key Insight**: Template location depends on usage context:
- Plans → commands/templates/
- Agent prompts → agents/prompts/
- Documentation → docs/reference/

### Existing Shim Patterns and Implementations

The infrastructure uses shims strategically for backward compatibility during refactoring:

**Shim Example 1: artifact-operations.sh** (analyzed above)
- **Purpose**: Wrap split libraries (artifact-creation.sh + artifact-registry.sh)
- **Technique**: Source both libraries, re-export all functions
- **Migration**: 77 command references to update over 1-2 releases
- **Deprecation**: One-time warning per process, documented removal date

**Shim Pattern Components**:
1. **Version header** (lines 1-21): Documents old/new usage, migration timeline
2. **Relative path resolution** (lines 23-25): Use BASH_SOURCE[0] for portability
3. **Validation** (lines 27-37): Check both target libraries exist before sourcing
4. **Source operations** (lines 40-49): Load both libraries with error handling
5. **Warning emission** (lines 51-56): One-time deprecation notice with guard variable

**Lazy Directory Creation Pattern** (unified-location-detection.sh lines 222-287):

This is a different type of "shim" - a migration from eager to lazy creation:
- **Old behavior**: create_topic_structure() created all subdirectories upfront
- **New behavior**: Only creates topic root, subdirectories created on-demand
- **Shim function**: ensure_artifact_directory() (lines 222-250) creates parent dir when writing files
- **Impact**: Eliminated 400-500 empty directories, 80% reduction in mkdir calls

**Path Pre-calculation Optimization** (artifact-creation.sh lines 44-54):

MODE-BASED shim pattern enabling path calculation without side effects:
```bash
# PATH-ONLY MODE: content parameter empty
# Returns path without creating directory
if [ -z "$content" ]; then
  local next_num=$(get_next_artifact_number "$artifact_subdir" || echo "001")
  local artifact_file="${artifact_subdir}/${next_num}_${artifact_name}.md"
  echo "$artifact_file"
  return 0
fi

# FILE CREATION MODE: content parameter provided
# Creates directory and file (original behavior)
```

This achieves 85% token reduction in orchestration commands (Phase 0 optimization).

### Standards for Creating New Infrastructure Components

The infrastructure follows documented standards across multiple reference files:

**Command Architecture Standards** (.claude/docs/reference/command_architecture_standards.md):
- Standard 11: Imperative Agent Invocation Pattern (lines referenced in CLAUDE.md)
  - Use Task tool to invoke agents (not SlashCommand)
  - Inject behavioral context from .claude/agents/{agent}.md
  - Include explicit completion signals (e.g., REPORT_CREATED:)
  - Fail-fast error handling with diagnostic commands

**Library API Standards** (.claude/docs/reference/library-api.md):
- Unified location detection functions (perform_location_detection, ensure_artifact_directory)
- 85% token reduction through path pre-calculation
- 25x speedup vs agent-based detection

**Agent Development Standards** (.claude/docs/guides/agent-development-guide.md):
- YAML frontmatter required: allowed-tools, model, description
- Behavioral instructions use imperative language (MUST/WILL/SHALL)
- Completion criteria checklist (28 criteria for research-specialist)
- Registry integration via agent-registry.json

**Model Selection Standards** (.claude/docs/guides/model-selection-guide.md):
- Haiku: Simple tasks (<200 lines code, <10 files)
- Sonnet: Complex analysis (research, planning, multi-file changes)
- Opus: Critical decisions (architecture, security, data integrity)

**Directory Protocol Standards** (.claude/docs/concepts/directory-protocols.md):
- Topic-based structure: specs/{NNN_topic}/
- Artifact subdirectories: plans/, reports/, summaries/, debug/
- Progressive organization: Level 0 → Level 1 → Level 2
- Phase dependencies enable parallel execution

**Imperative Language Standards** (.claude/docs/guides/imperative-language-guide.md):
- Required actions: MUST/WILL/SHALL (never should/may/can)
- Verification checkpoints: MANDATORY, ABSOLUTE REQUIREMENT
- Error handling: CRITICAL, NEVER, DO NOT

**Behavioral Injection Pattern** (.claude/docs/concepts/patterns/behavioral-injection.md):
- Commands invoke agents via Task tool
- Context injection (behavioral file + workflow-specific data)
- Anti-pattern: Documentation-only YAML blocks (must use imperative Task invocation)

**Verification and Fallback Pattern** (.claude/docs/concepts/patterns/verification-fallback.md):
- All file creation operations require MANDATORY VERIFICATION checkpoints
- Three-stage pattern: Attempt creation → Verify existence → Fallback if failed
- 100% file creation reliability (mandatory verification enforces this)

## Recommendations

### For Creating New Shims

When splitting or refactoring existing libraries:

1. **Create deprecation shim** following artifact-operations.sh pattern:
   - Document old/new usage in header
   - Set removal timeline (1-2 releases, ~2-3 months)
   - Source all target libraries
   - Emit one-time warning per process
   - Track references needing updates

2. **Use relative path resolution** via BASH_SOURCE[0] for portability

3. **Validate targets** before sourcing (fail-fast if libraries missing)

4. **Update library-sourcing.sh** if shim involves core libraries

### For Library Organization

When adding new library functionality:

1. **Prefer functional grouping** over alphabetical organization:
   - Related functions in same file (e.g., artifact-creation.sh)
   - Consolidation bundles for frequently co-used functions
   - Separate concerns (creation vs registry vs validation)

2. **Document dependencies** explicitly in header comments

3. **Use lazy patterns** for directory/file creation where possible:
   - Calculate paths without side effects (mode-based pattern)
   - Create directories only when writing files
   - Reduces empty directory proliferation

4. **Export functions** for subshell usage (export -f function_name)

### For Agent Behavioral Files

When creating new specialized agents:

1. **Register in agent-registry.json** with complete metadata:
   - Unique kebab-case ID
   - Type (specialized/hierarchical/documentation)
   - Category (research/planning/implementation/analysis/debugging)
   - Tools array (Read/Write/Edit/Bash/Grep/Glob/WebSearch/etc.)
   - Metrics structure (initialized to zeros)
   - Behavioral file path (.claude/agents/{id}.md)

2. **Include YAML frontmatter** in behavioral file:
   - allowed-tools, model, description, model-justification

3. **Structure instructions** with numbered steps and checkpoints:
   - Use imperative language (MUST/WILL/SHALL)
   - Include verification checkpoints
   - Define completion criteria (checklist format)
   - Document error handling and retry strategies

4. **Place shared guidelines** in agents/shared/ only if used by 3+ agents

### For Template Storage

When adding new templates:

1. **Plan templates** → .claude/commands/templates/ (YAML format)
   - Update templates/README.md with category and description
   - Define variable placeholders in frontmatter
   - Structure phases with task checklists

2. **Agent prompts** → .claude/agents/prompts/ (reusable fragments)

3. **Documentation templates** → .claude/docs/reference/ (markdown)

4. **Verify 3+ command usage** before creating "shared" templates

## References

### Directory Structure
- /home/benjamin/.config/.claude/ (top-level directory listing)
- /home/benjamin/.config/.claude/commands/ (26 command files)
- /home/benjamin/.config/.claude/lib/ (52 library files)
- /home/benjamin/.config/.claude/agents/ (18 agent files + registry)
- /home/benjamin/.config/.claude/commands/templates/ (11 YAML templates)

### Library Files Analyzed
- /home/benjamin/.config/.claude/lib/library-sourcing.sh (lines 1-111)
- /home/benjamin/.config/.claude/lib/artifact-operations.sh (lines 1-57)
- /home/benjamin/.config/.claude/lib/artifact-creation.sh (lines 1-267)
- /home/benjamin/.config/.claude/lib/unified-location-detection.sh (lines 1-526)

### Agent Files Analyzed
- /home/benjamin/.config/.claude/agents/agent-registry.json (lines 1-385)
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-671)
- /home/benjamin/.config/.claude/agents/shared/README.md

### Template Files Analyzed
- /home/benjamin/.config/.claude/commands/templates/README.md (lines 1-78)
- /home/benjamin/.config/.claude/commands/shared/README.md (lines 1-86, cleanup documentation)

### Documentation Standards
- /home/benjamin/.config/CLAUDE.md (project configuration index)
- .claude/docs/reference/command_architecture_standards.md (Standard 11)
- .claude/docs/reference/library-api.md (unified location detection)
- .claude/docs/guides/agent-development-guide.md
- .claude/docs/guides/imperative-language-guide.md
- .claude/docs/concepts/patterns/behavioral-injection.md
- .claude/docs/concepts/patterns/verification-fallback.md
- .claude/docs/concepts/directory-protocols.md
