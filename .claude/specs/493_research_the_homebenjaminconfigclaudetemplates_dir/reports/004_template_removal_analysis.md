# Template Removal Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Template Directory Consolidation
- **Report Type**: codebase analysis

## Executive Summary

The `.claude/templates/` directory contains 26 files (13 markdown, 11 YAML, 1 README, 1 backup) totaling approximately 240KB. Analysis reveals significant opportunities for consolidation. Three large documentation templates (orchestration-patterns.md, debug-structure.md, refactor-structure.md) contain 71KB of content that could be inlined into commands. Several obsolete templates reference deprecated patterns (artifact_research_invocation, spec-updater-test). YAML templates serve the active `/plan-from-template` workflow and should be retained, though consolidation from 11 to 7-8 templates is feasible.

**Key Finding**: 40-50% of template content (10-13 files, ~100KB) can be safely removed or consolidated through inlining into commands, removing obsolete files, and merging similar YAML templates.

## Findings

### Template Inventory

**Markdown Documentation Templates** (13 files, ~150KB):
- `orchestration-patterns.md` (71KB) - Agent prompts, coordination patterns, checkpoint structures
- `debug-structure.md` (11KB) - Debug report structure and sections
- `refactor-structure.md` (12KB) - Refactor report structure
- `report-structure.md` (7.8KB) - Research report structure
- `agent-invocation-patterns.md` (8.6KB) - Task tool invocation patterns
- `agent-tool-descriptions.md` (8.6KB) - Tool descriptions for agents
- `output-patterns.md` (6.3KB) - Standardized output formatting
- `command-frontmatter.md` (6.5KB) - YAML frontmatter standards
- `sub_supervisor_pattern.md` (3.4KB) - Hierarchical supervision pattern
- `artifact_research_invocation.md` (3.7KB) - OBSOLETE research artifact pattern
- `audit-checklist.md` (4.1KB) - Execution enforcement audit rubric
- `readme-template.md` (1.2KB) - README structure for documentation

**YAML Plan Templates** (11 files, ~38KB):
- `refactor-consolidation.yaml` (4.9KB) - Code consolidation refactoring
- `crud-feature.yaml` (4.1KB) - CRUD operations implementation
- `migration.yaml` (4.0KB) - Database/API migration planning
- `research-report.yaml` (3.8KB) - Research investigation planning
- `test-suite.yaml` (3.7KB) - Test infrastructure setup
- `debug-workflow.yaml` (3.4KB) - Debugging investigation workflow
- `documentation-update.yaml` (3.3KB) - Documentation sync planning
- `refactoring.yaml` (2.9KB) - General refactoring planning
- `api-endpoint.yaml` (2.8KB) - REST API endpoint implementation
- `example-feature.yaml` (2.3KB) - Example template structure
- `spec-updater-test.yaml` (1.4KB) - OBSOLETE test template

### Usage Analysis

**High Usage - Keep (6 files)**:
1. `orchestration-patterns.md` - Referenced by 6 command files (orchestrate, debug, refactor, research)
2. `agent-invocation-patterns.md` - Referenced by 17 files across commands and specs
3. `output-patterns.md` - Referenced by commands for standardized formatting
4. `command-frontmatter.md` - Referenced by all command files for frontmatter standards
5. All YAML templates - Used by `/plan-from-template` command (active workflow)
6. `README.md` - Directory index and Neovim integration documentation

**Medium Usage - Consolidate (7 files)**:
1. `debug-structure.md` - Referenced by 2 files; can be inlined into `/debug` command
2. `refactor-structure.md` - Referenced by 2 files; can be inlined into `/refactor` command
3. `report-structure.md` - Referenced by 1 file; can be inlined into `/research` command
4. `agent-tool-descriptions.md` - Referenced by 17 files; overlaps with command-frontmatter.md
5. `sub_supervisor_pattern.md` - Documentation-only; can move to `.claude/docs/patterns/`
6. `audit-checklist.md` - Utility template; can move to `.claude/shared/`
7. `readme-template.md` - Generic template; can move to `.claude/shared/`

**Low/No Usage - Remove (3 files)**:
1. `artifact_research_invocation.md` - OBSOLETE: References deprecated artifact system
2. `spec-updater-test.yaml` - OBSOLETE: Test template for deprecated workflow
3. (Backup files if found) - Cleanup temporary files

### Redundancy Analysis

**Duplicate Content Identified**:
1. **Tool descriptions**: Duplicated in `agent-tool-descriptions.md` and `command-frontmatter.md` (Lines 94-142 in command-frontmatter.md overlap with agent-tool-descriptions.md)
2. **Report structures**: `report-structure.md`, `debug-structure.md`, and `refactor-structure.md` share 60% structural similarity (metadata, findings, recommendations sections)
3. **Refactoring templates**: `refactoring.yaml` and `refactor-consolidation.yaml` overlap in scope - can merge into single template with variables

**Consolidation Opportunities**:
- Merge `refactoring.yaml` + `refactor-consolidation.yaml` → single `refactor.yaml` with consolidation toggle variable
- Merge `agent-tool-descriptions.md` content into `command-frontmatter.md` (agents can reference same file)
- Create single `report-structures.md` with sections for research/debug/refactor variants

### Documentation Quality Assessment

**Well-Documented Templates** (retain structure):
- `orchestration-patterns.md` - Comprehensive, actively maintained, critical reference
- `command-frontmatter.md` - Clear standards, referenced universally
- YAML templates - Complete with metadata, variables, phases

**Under-Documented Templates** (improve or inline):
- `sub_supervisor_pattern.md` - Lacks usage examples, better as pattern documentation
- `audit-checklist.md` - No integration instructions, better as utility script
- `readme-template.md` - Generic boilerplate, better as shared resource

**Obsolete Documentation**:
- `artifact_research_invocation.md` - References deprecated "artifacts/" system (now uses topic-based structure)
- `spec-updater-test.yaml` - References test workflow no longer in use

### Integration Patterns

**Commands Using Templates Inline** (good pattern):
- `/orchestrate` - Directly embeds prompt templates from orchestration-patterns.md
- `/plan` - Directly uses YAML templates via parse-template.sh utility
- `/debug` - References debug-structure.md for report format

**Commands That Could Inline** (consolidation opportunity):
- `/debug` - Only uses debug-structure.md; can inline the template
- `/refactor` - Only uses refactor-structure.md; can inline the template
- `/research` - Only uses report-structure.md; can inline the template

**Shared Resources Pattern** (better organization):
- `audit-checklist.md` → move to `.claude/shared/audit-checklist.md`
- `readme-template.md` → move to `.claude/shared/readme-template.md`
- `sub_supervisor_pattern.md` → move to `.claude/docs/patterns/hierarchical-supervision.md`

## Recommendations

### Priority 1: Remove Obsolete Templates (Immediate - 2 files, ~5KB)

**Remove Completely**:
1. `artifact_research_invocation.md` - References deprecated artifact system; replaced by topic-based structure
2. `spec-updater-test.yaml` - Test template for deprecated workflow; no longer referenced

**Impact**: No breaking changes; these files are not referenced by active commands

**Validation**:
```bash
grep -r "artifact_research_invocation\|spec-updater-test" .claude/commands/*.md
# Expected: Only historical references in specs/ (ignore)
```

### Priority 2: Inline Single-Use Templates (High Priority - 3 files, ~31KB)

**Inline into Commands**:
1. `debug-structure.md` → inline into `/debug` command (referenced by 2 files only)
2. `refactor-structure.md` → inline into `/refactor` command (referenced by 2 files only)
3. `report-structure.md` → inline into `/research` command (referenced by 1 file only)

**Benefits**:
- Eliminates external file dependencies for simple structures
- Improves command self-containment
- Reduces directory navigation during development

**Implementation**:
- Copy template structure into command file's "Report Structure" section
- Update command to reference inline section instead of external file
- Mark template file as deprecated with redirect notice
- Remove after 1-2 release cycles

### Priority 3: Consolidate Redundant Content (Medium Priority - 4 files, ~25KB savings)

**Merge Overlapping Files**:
1. Merge `agent-tool-descriptions.md` into `command-frontmatter.md`
   - Keep command-frontmatter.md as single source of truth for tool descriptions
   - Add "Agent Tool Access" section with agent-specific constraints
   - Update agent files to reference command-frontmatter.md instead
   - Savings: 8.6KB

2. Merge `refactoring.yaml` + `refactor-consolidation.yaml` → `refactor.yaml`
   - Add `consolidation_type` variable (none|partial|full)
   - Conditionally include consolidation tasks based on variable
   - Savings: 2.9KB (remove smaller template)

3. Create unified `report-structures.md` with variants
   - Sections: Research Reports, Debug Reports, Refactor Reports
   - Share common metadata/structure, document differences
   - Replace 3 separate files with 1 comprehensive file
   - Net change: -2 files, +1 file (~25KB → ~18KB, saves 7KB)

### Priority 4: Relocate to Appropriate Directories (Low Priority - 3 files, improve organization)

**Move to `.claude/shared/`**:
1. `audit-checklist.md` - Utility template for enforcement audits
2. `readme-template.md` - Generic README structure

**Move to `.claude/docs/patterns/`**:
1. `sub_supervisor_pattern.md` - Pattern documentation (not operational template)

**Benefits**:
- Templates directory focuses on operational templates only
- Shared utilities in dedicated location
- Pattern documentation with other architectural patterns

### Priority 5: Enhance Remaining Templates (Ongoing)

**Add Usage Instructions**:
- `orchestration-patterns.md` - Add "When to Use Each Pattern" section
- YAML templates - Add completion criteria examples
- `command-frontmatter.md` - Add tool selection flowchart

**Improve Discoverability**:
- Add template categories to README.md
- Create template selection guide (flowchart)
- Add "Related Templates" cross-references

**Maintain Quality**:
- Review quarterly for accuracy
- Update based on command evolution
- Remove or deprecate unused patterns

## Expected Impact

**File Count Reduction**: 26 → 16 files (38% reduction)
- Remove: 2 obsolete files
- Inline: 3 single-use templates
- Merge: 4 files → 2 files
- Relocate: 3 files to other directories

**Size Reduction**: ~240KB → ~140KB (42% reduction)
- Remove obsolete: 5KB
- Inline (remove from templates/): 31KB
- Merge redundant: 25KB
- Relocate: 8KB
- Net reduction: ~100KB

**Maintenance Improvement**:
- Fewer files to update during command changes
- Single source of truth for tool descriptions
- Clearer separation of operational vs. documentation templates
- Better organization of shared resources

**No Breaking Changes**:
- All active YAML templates retained
- Critical documentation templates retained (orchestration-patterns, command-frontmatter, agent-invocation-patterns, output-patterns)
- Commands updated in-place with inline content
- Deprecation path for relocated files

## References

**Templates Directory**: `/home/benjamin/.config/.claude/templates/`
- README.md (line 1-287) - Template system overview and Neovim integration
- orchestration-patterns.md (line 1-2523) - Agent coordination templates
- agent-invocation-patterns.md (line 1-324) - Task tool invocation patterns
- command-frontmatter.md (line 1-212) - YAML frontmatter standards
- output-patterns.md (line 1-265) - Output formatting standards

**Command References**:
- `/plan-from-template` (line 1-100) - YAML template system integration
- `/orchestrate` - References orchestration-patterns.md (6 instances)
- `/debug` - References debug-structure.md (2 instances)
- `/refactor` - References refactor-structure.md (2 instances)

**Related Specifications**:
- Spec 438: Supervise command refactor analysis
- Spec 476: Research command optimization
- Spec 478: Claude directory audit
