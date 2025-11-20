# Commands README.md Update for /repair and /errors Command Integration Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Update commands README.md to document /repair and /errors in Utility Commands section with systematic integration into .claude/docs/
- **Scope**: Add both /repair and /errors to Utility Commands section, update command count to 12, add cross-references, verify /convert-docs placement, ensure full compliance with .claude/docs/ standards
- **Estimated Phases**: 6
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 32.0
- **Research Reports**:
  - [Repair Command Integration Research](../reports/001_repair_command_integration.md)
  - [Revision Insights Research](../reports/001_revision_insights.md)

## Overview

Both `/repair` (error analysis and fix planning) and `/errors` (error log query utility) need to be documented in the Utility Commands section of the commands README.md. Additionally, comprehensive documentation integration is required to ensure both commands are fully integrated with the existing .claude/docs/ ecosystem and comply with all established standards.

The implementation plan addresses:

1. Add /errors to Utility Commands section (read-only query utility)
2. Add /repair to Utility Commands section (analysis and planning utility, not execution)
3. Update command count from 10 to 12
4. Add bidirectional cross-references between /repair and /errors
5. Verify and resolve /convert-docs duplication if present
6. Systematically integrate documentation into .claude/docs/ structure
7. Ensure full compliance with .claude/docs/ standards (directory protocols, output formatting, command authoring, etc.)

This implementation focuses on maintaining consistency with existing documentation patterns while ensuring both commands are properly integrated into the broader documentation ecosystem.

## Research Summary

Key findings from research reports:

**Command Classification** (from revision insights):
- /errors: Utility command (read-only query tool, no modifications)
- /repair: Utility command (analysis + planning, no execution) - NOT a primary workflow
- Rationale: /repair is analysis tool that creates plans (delegated to plan-architect), not a complete end-to-end workflow like /build or /plan

**Current State** (from repair integration research):
- README.md shows 10 commands documented, but 12 command files exist
- Missing documentation: /repair and /errors (both confirmed utility commands)
- Duplication issue: /convert-docs appears in both Primary and Utility sections
- Documentation pattern: Consistent format with Purpose, Usage, Type, Example, Dependencies, Features, Documentation link

**Integration Requirements** (from revision insights):
- Cross-references: /errors → /repair and /repair → /errors
- Natural progression: /errors (query) → /repair (analyze) → /build (execute)
- Documentation guides exist for both commands and need systematic integration
- Full standards compliance required: directory protocols, output formatting, command authoring

**Documentation Ecosystem Integration**:
- Both commands require integration with existing .claude/docs/ structure
- Guide files exist but need verification of cross-references
- Standards compliance verification needed across multiple dimensions
- Navigation and discovery patterns must be maintained

Recommended approach: Follow established documentation patterns for Utility Commands section, add both commands with bidirectional cross-references, systematically integrate with .claude/docs/ ecosystem, and verify full standards compliance.

## Success Criteria

- [ ] /errors command documented in Utility Commands section with complete format
- [ ] /repair command documented in Utility Commands section with complete format
- [ ] Command count updated from 10 to 12 on line 5
- [ ] Bidirectional cross-references added between /repair and /errors in Features sections
- [ ] /convert-docs duplication issue verified and resolved if present
- [ ] All documentation follows established patterns (Purpose, Usage, Type, Example, Dependencies, Features, Documentation link)
- [ ] Navigation links section updated with both commands
- [ ] No formatting or structural inconsistencies introduced
- [ ] Guide files cross-reference each other appropriately
- [ ] Command frontmatter includes correct command-type fields
- [ ] Full compliance with .claude/docs/ standards verified:
  - [ ] Directory protocols compliance
  - [ ] Output formatting standards compliance
  - [ ] Command authoring standards compliance
  - [ ] Link conventions followed (relative paths)
  - [ ] Documentation structure standards met

## Technical Design

### Architecture Overview

This is primarily a documentation update task with systematic integration work. The implementation focuses on:

1. **README.md Updates**: Adding command entries following established patterns
2. **Documentation Integration**: Ensuring guide files are properly cross-referenced
3. **Standards Compliance**: Verifying adherence to all .claude/docs/ standards
4. **Frontmatter Validation**: Ensuring command-type fields are correct

**Primary File to Modify**: `/home/benjamin/.config/.claude/commands/README.md` (773+ lines)

**Source Files for Content**:
- `/home/benjamin/.config/.claude/commands/repair.md` (frontmatter line 5: command-type: primary - needs verification)
- `/home/benjamin/.config/.claude/commands/errors.md` (no command-type field - needs addition)
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (504 lines)
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (306 lines)

**Standards References** (for compliance verification):
- `.claude/docs/concepts/directory-protocols.md` - Topic structure, artifact lifecycle
- `.claude/docs/reference/standards/output-formatting.md` - Output patterns, comment standards
- `.claude/docs/reference/standards/command-authoring.md` - Command structure, frontmatter
- `.claude/docs/reference/standards/code-standards.md` - Link conventions

### Command Classification Rationale

**Why /repair is Utility, Not Primary**:

From repair.md analysis:
- Workflow type: "research-and-plan" with terminal state "plan"
- Does NOT execute implementations (that's /build's role)
- Delegates planning to plan-architect agent
- Analysis and planning only, no end-to-end execution

Comparison:
- **Primary commands** (/build, /plan, /debug): Complete end-to-end workflows with execution
- **Utility commands** (/errors, /setup, /repair): Analysis, query, or planning without execution
- **Workflow pattern**: /errors (query) → /repair (analyze + plan) → /build (execute)

### Documentation Pattern Structure

Each command entry in README.md follows this template:

```markdown
#### /command-name
**Purpose**: Brief description of command goal

**Usage**: `/command-name <args> [--flags]`

**Type**: utility

**Example**:
```bash
/command-name example-args
```

**Dependencies**:
- **Agents**: agent1, agent2
- **Libraries**: lib1.sh, lib2.sh

**Features**:
- Feature description 1
- Feature description 2
- Cross-reference to related command

**Documentation**: [Command Guide](../docs/guides/commands/command-guide.md)
```

### Placement Strategy

**For /errors** (in Utility Commands section, before /setup):
- Rationale: Read-only query utility, foundational for error analysis workflows
- Dependencies: error-handling.sh library only
- Position: After section header, before /repair

**For /repair** (in Utility Commands section, after /errors):
- Rationale: Analysis and planning utility that uses /errors data
- Dependencies: repair-analyst, plan-architect agents; workflow-state-machine.sh, state-persistence.sh libraries
- Position: After /errors to show natural workflow progression

### Cross-Reference Strategy

Bidirectional integration bullets:

**In /errors Features section**:
- "Integrates with /repair for error analysis and fix planning"

**In /repair Features section**:
- "Integration with /errors command for log queries"
- "Generated plans executed via /build workflow"

### Standards Compliance Strategy

**Directory Protocols Compliance**:
- Verify both commands use specs/{NNN_topic}/ structure
- Verify artifact subdirectories (plans/, reports/)
- Check error log location (.claude/data/logs/errors.jsonl)

**Output Formatting Compliance**:
- Verify commands follow bash block consolidation patterns
- Check comment standards (WHAT not WHY)
- Verify library sourcing suppression (2>/dev/null)

**Command Authoring Compliance**:
- Verify frontmatter completeness (allowed-tools, description, command-type, etc.)
- Check argument-hint format
- Verify library-requirements version specifications

**Link Conventions**:
- All links use relative paths from commands/ directory
- Format: `../docs/guides/commands/command-guide.md`

## Implementation Phases

### Phase 1: Verify Current State and Command Classifications [COMPLETE]
dependencies: []

**Objective**: Read README.md, verify /convert-docs duplication, confirm command classifications from frontmatter, understand exact structure for edits

**Complexity**: Low

Tasks:
- [x] Read /home/benjamin/.config/.claude/commands/README.md to identify exact line numbers for Utility Commands section
- [x] Verify /convert-docs appears in both Primary and Utility sections (check lines 319-341)
- [x] Read convert-docs.md frontmatter to determine authoritative command-type classification
- [x] Determine if /convert-docs should be removed from one section
- [x] Verify repair.md frontmatter shows command-type: primary (line 5) - this may be incorrect
- [x] Verify errors.md frontmatter lacks command-type field - needs addition
- [x] Document exact line ranges for each section (Primary Commands, Utility Commands, Navigation)
- [x] Count current command entries in README.md (should be 10)

Testing:
```bash
# Verify file structure and sections
grep -n "^## " /home/benjamin/.config/.claude/commands/README.md | head -20

# Check all command headings
grep -n "^#### /" /home/benjamin/.config/.claude/commands/README.md

# Check convert-docs classification
grep -A1 "^command-type:" /home/benjamin/.config/.claude/commands/convert-docs.md

# Verify repair classification
grep "^command-type:" /home/benjamin/.config/.claude/commands/repair.md

# Verify errors has no command-type
grep "^command-type:" /home/benjamin/.config/.claude/commands/errors.md || echo "NOT FOUND (expected)"
```

**Expected Duration**: 0.5 hours

### Phase 2: Add /errors to Utility Commands Section [COMPLETE]
dependencies: [1]

**Objective**: Insert /errors documentation as first entry in Utility Commands section with complete format

**Complexity**: Low

Tasks:
- [x] Read errors.md frontmatter (lines 1-5) to extract metadata
- [x] Read errors-command-guide.md overview section (lines 20-40) for Purpose text
- [x] Construct /errors entry following documentation pattern
- [x] Insert entry at beginning of Utility Commands section (after section header, before any existing commands)
- [x] Include: Purpose, Usage, Type (utility), Example, Dependencies (Libraries: error-handling.sh), Features, Documentation link
- [x] Add cross-reference bullet in Features: "Integrates with /repair for error analysis and fix planning"
- [x] Verify formatting consistency with existing entries

Testing:
```bash
# Verify entry added correctly
grep -A25 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md

# Verify type is utility
grep -A5 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md | grep "^\\*\\*Type\\*\\*: utility"

# Verify documentation link exists
grep -A25 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md | grep "errors-command-guide.md"

# Verify cross-reference to /repair
grep -A25 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md | grep "/repair"
```

**Expected Duration**: 0.5 hours

### Phase 3: Add /repair to Utility Commands Section [COMPLETE]
dependencies: [2]

**Objective**: Insert /repair documentation after /errors in Utility Commands section with complete format and cross-references

**Complexity**: Low

Tasks:
- [x] Read repair.md frontmatter (lines 1-12) to extract metadata
- [x] Read repair-command-guide.md overview (lines 20-50) for Purpose text
- [x] Construct /repair entry following documentation pattern
- [x] Insert entry after /errors in Utility Commands section
- [x] Include: Purpose, Usage, Type (utility), Example, Dependencies (Agents: repair-analyst, plan-architect; Libraries: workflow-state-machine.sh, state-persistence.sh), Features, Documentation link
- [x] Add cross-reference bullets in Features:
  - "Integration with /errors command for log queries"
  - "Generated plans executed via /build workflow"
- [x] Verify formatting consistency with /errors and other entries

Testing:
```bash
# Verify entry added correctly
grep -A30 "^#### /repair" /home/benjamin/.config/.claude/commands/README.md

# Verify placement after /errors
grep -n "^#### /errors" /home/benjamin/.config/.claude/commands/README.md
grep -n "^#### /repair" /home/benjamin/.config/.claude/commands/README.md

# Verify type is utility (not primary)
grep -A8 "^#### /repair" /home/benjamin/.config/.claude/commands/README.md | grep "^\\*\\*Type\\*\\*: utility"

# Verify bidirectional cross-references exist
grep -A10 "^#### /repair" /home/benjamin/.config/.claude/commands/README.md | grep "/errors"
grep -A10 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md | grep "/repair"

# Verify dependencies include both agents and libraries
grep -A30 "^#### /repair" /home/benjamin/.config/.claude/commands/README.md | grep -E "(repair-analyst|plan-architect|workflow-state-machine|state-persistence)"
```

**Expected Duration**: 0.75 hours

### Phase 4: Update Command Count and Navigation Links [COMPLETE]
dependencies: [2, 3]

**Objective**: Update command count to 12, add navigation links for new commands, verify no duplicates

**Complexity**: Low

Tasks:
- [x] Update line 5: Change "Current Command Count: 10 active commands" to "Current Command Count: 12 active commands"
- [x] Locate Navigation section (approximate lines 756-774)
- [x] Add errors.md to Navigation section in alphabetical order
- [x] Add repair.md to Navigation section in alphabetical order
- [x] Verify alphabetical ordering maintained
- [x] Final read-through to check formatting consistency
- [x] Verify all cross-references are bidirectional
- [x] Check for any duplicate entries or orphaned references

Testing:
```bash
# Verify command count updated
grep "Current Command Count:" /home/benjamin/.config/.claude/commands/README.md

# Count actual command entries (should be 12)
ACTUAL=$(grep -c "^#### /" /home/benjamin/.config/.claude/commands/README.md)
echo "Actual command entries: $ACTUAL (expected: 12)"

# Verify navigation links alphabetically ordered
grep -E "^\- \[.*\.md\]" /home/benjamin/.config/.claude/commands/README.md | tail -20

# Verify no duplicate command headings
grep "^#### /" /home/benjamin/.config/.claude/commands/README.md | sort | uniq -c | grep -v "^[[:space:]]*1 "

# Verify errors.md and repair.md in navigation
grep "errors.md" /home/benjamin/.config/.claude/commands/README.md
grep "repair.md" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.25 hours

### Phase 5: Systematic Documentation Integration with .claude/docs/ [COMPLETE]
dependencies: [3]

**Objective**: Ensure both command guide files are properly integrated with .claude/docs/ ecosystem with cross-references and standards compliance

**Complexity**: Medium

Tasks:
- [x] Read repair-command-guide.md "See Also" section (approximate lines 487-504) to verify cross-references
- [x] Read errors-command-guide.md "See Also" section to verify cross-references
- [x] Verify repair-command-guide.md references errors-command-guide.md (should exist based on integration points at lines 359-380)
- [x] Verify errors-command-guide.md references repair-command-guide.md (add if missing)
- [x] Check both guides reference relevant standards docs:
  - directory-protocols.md (for specs structure)
  - output-formatting.md (for output patterns)
  - command-authoring.md (for command structure)
  - error-handling library API docs
- [x] Verify guide files use relative link paths correctly
- [x] Check that both guides are discoverable from .claude/docs/README.md or appropriate index files
- [x] Verify both guides follow documentation standards (clear sections, examples, troubleshooting)

Testing:
```bash
# Verify cross-references between guides
grep -i "error.*command.*guide" /home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md
grep -i "repair.*command.*guide" /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md

# Verify standards references in guides
grep -E "(directory-protocols|output-formatting|command-authoring)" /home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md
grep -E "(directory-protocols|output-formatting|command-authoring)" /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md

# Verify relative link format
grep -oE '\(\.\.\/[^)]+\.md\)' /home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md | head -10
grep -oE '\(\.\.\/[^)]+\.md\)' /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md | head -10

# Check discoverability from docs index
grep -i "error" /home/benjamin/.config/.claude/docs/README.md
grep -i "repair" /home/benjamin/.config/.claude/docs/README.md
```

**Expected Duration**: 1.0 hours

### Phase 6: Standards Compliance Verification and Frontmatter Updates [COMPLETE]
dependencies: [1, 5]

**Objective**: Verify full compliance with .claude/docs/ standards and update command frontmatter with correct command-type fields

**Complexity**: Medium

Tasks:
- [x] Add command-type: utility to errors.md frontmatter (insert after line 3)
- [x] Update repair.md frontmatter: change command-type from "primary" to "utility" (line 5)
- [x] Verify directory protocols compliance:
  - Check /repair creates specs/{NNN_topic}/plans/ and specs/{NNN_topic}/reports/
  - Check /errors queries .claude/data/logs/errors.jsonl
  - Verify artifact lifecycle (gitignored specs, committed debug reports)
- [x] Verify output formatting standards compliance:
  - Check bash block consolidation in repair.md
  - Verify comment standards (WHAT not WHY) in both commands
  - Verify library sourcing uses 2>/dev/null pattern
- [x] Verify command authoring standards compliance:
  - Check frontmatter completeness (allowed-tools, description, argument-hint, etc.)
  - Verify library-requirements version specifications in repair.md
  - Check argument-hint format matches actual usage
- [x] Verify link conventions compliance:
  - All relative paths correct
  - No absolute paths in documentation
  - Cross-references use proper markdown format
- [x] Final validation: read both commands and verify they execute without standards violations

Testing:
```bash
# Verify frontmatter updates
grep "^command-type: utility" /home/benjamin/.config/.claude/commands/errors.md
grep "^command-type: utility" /home/benjamin/.config/.claude/commands/repair.md

# Verify directory protocols compliance
grep "specs/{NNN" /home/benjamin/.config/.claude/commands/repair.md
grep "errors.jsonl" /home/benjamin/.config/.claude/commands/errors.md

# Verify library sourcing pattern
grep "2>/dev/null" /home/benjamin/.config/.claude/commands/repair.md
grep "2>/dev/null" /home/benjamin/.config/.claude/commands/errors.md

# Verify library requirements format
grep -A3 "^library-requirements:" /home/benjamin/.config/.claude/commands/repair.md

# Verify no absolute paths in documentation
grep -E "file:///|/home/|/Users/" /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md && echo "ABSOLUTE PATHS FOUND" || echo "No absolute paths (good)"
grep -E "file:///|/home/|/Users/" /home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md && echo "ABSOLUTE PATHS FOUND" || echo "No absolute paths (good)"

# Comprehensive validation
cd /home/benjamin/.config/.claude
bash -n commands/errors.md 2>&1 | grep -i error || echo "errors.md syntax OK"
bash -n commands/repair.md 2>&1 | grep -i error || echo "repair.md syntax OK"
```

**Expected Duration**: 1.0 hours

## Testing Strategy

### Documentation Consistency Testing

1. **Command Count Accuracy**:
   - Declared count matches actual command headings
   - All command files in directory are documented
   - No duplicate entries

2. **Format Compliance**:
   - Each command entry has all required sections in correct order
   - Consistent structure across all entries
   - Cross-references are bidirectional

3. **Link Validity**:
   - Documentation links point to existing guide files
   - Navigation links point to existing command files
   - No broken relative paths
   - All links use relative paths (no absolute paths)

4. **Standards Compliance**:
   - Directory protocols followed (topic structure, artifact locations)
   - Output formatting standards met (bash blocks, comments, library sourcing)
   - Command authoring standards met (frontmatter, dependencies)
   - Link conventions followed (relative paths only)

### Validation Commands

```bash
# === Command Count Validation ===
DECLARED=$(grep "Current Command Count:" /home/benjamin/.config/.claude/commands/README.md | grep -oE "[0-9]+")
ACTUAL=$(grep -c "^#### /" /home/benjamin/.config/.claude/commands/README.md)
echo "Declared: $DECLARED, Actual: $ACTUAL (should both be 12)"

# === Command File Coverage ===
cd /home/benjamin/.config/.claude/commands
for cmd in *.md; do
  [ "$cmd" = "README.md" ] && continue
  CMD_NAME="${cmd%.md}"
  grep -q "^#### /$CMD_NAME" README.md || echo "MISSING: $CMD_NAME"
done

# === Broken Link Detection ===
grep -oE '\(../docs/guides/commands/[^)]+\)' /home/benjamin/.config/.claude/commands/README.md | \
  sed 's/[()]//g' | while read link; do
  FULL_PATH="/home/benjamin/.config/.claude/commands/$link"
  [ -f "$FULL_PATH" ] || echo "BROKEN: $link"
done

# === Cross-Reference Validation ===
# Verify /errors references /repair
grep -A25 "^#### /errors" /home/benjamin/.config/.claude/commands/README.md | grep -q "/repair" || echo "MISSING: /errors -> /repair cross-ref"

# Verify /repair references /errors
grep -A30 "^#### /repair" /home/benjamin/.config/.claude/commands/README.md | grep -q "/errors" || echo "MISSING: /repair -> /errors cross-ref"

# === Duplicate Detection ===
grep "^#### /" /home/benjamin/.config/.claude/commands/README.md | sort | uniq -c | grep -v "^[[:space:]]*1 " && echo "DUPLICATES FOUND" || echo "No duplicates (good)"

# === Frontmatter Validation ===
# Verify command-type fields exist and are correct
grep "^command-type: utility" /home/benjamin/.config/.claude/commands/errors.md || echo "MISSING/INCORRECT: errors.md command-type"
grep "^command-type: utility" /home/benjamin/.config/.claude/commands/repair.md || echo "MISSING/INCORRECT: repair.md command-type"

# === Standards Compliance Validation ===
# Verify no absolute paths in guides
GUIDE_DIR="/home/benjamin/.config/.claude/docs/guides/commands"
for guide in errors-command-guide.md repair-command-guide.md; do
  if grep -qE "file:///|/home/|/Users/" "$GUIDE_DIR/$guide"; then
    echo "ABSOLUTE PATHS in $guide (violation)"
  fi
done

# Verify library sourcing patterns
grep -q "2>/dev/null" /home/benjamin/.config/.claude/commands/repair.md || echo "WARNING: repair.md may not suppress library output"
```

### Success Validation

Run all validation commands and verify:
- Declared count (12) matches actual command entries (12)
- No missing command documentation
- No broken documentation links
- Bidirectional cross-references between /errors and /repair exist
- Navigation section includes all commands
- Frontmatter command-type fields are correct (both utility)
- No duplicate command entries
- No absolute paths in documentation
- Standards compliance verified across all dimensions

## Documentation Requirements

### Existing Documentation Files

The following guide files already exist and will be verified/updated:
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (504 lines)
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (306 lines)

### Documentation Integration Tasks

1. **Cross-Reference Updates** (Phase 5):
   - Ensure guide files reference each other
   - Add references to relevant standards docs
   - Verify discoverability from .claude/docs/ index files

2. **Standards References** (Phase 5 & 6):
   - Link to directory-protocols.md for topic structure
   - Link to output-formatting.md for output standards
   - Link to command-authoring.md for command structure
   - Link to error-handling library API docs

3. **No New Documentation Files Required**:
   - All necessary guide files exist
   - Task is integration and compliance, not creation

## Dependencies

### Command Files (Source Material)
- `/home/benjamin/.config/.claude/commands/repair.md` (403 lines) - Frontmatter, usage, workflow
- `/home/benjamin/.config/.claude/commands/errors.md` - Frontmatter, usage, queries
- `/home/benjamin/.config/.claude/commands/convert-docs.md` - Verify command-type classification

### Guide Files (Feature Descriptions)
- `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md` (504 lines) - Complete usage guide
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (306 lines) - Error query guide

### Agent Files (Dependency Metadata)
- `/home/benjamin/.config/.claude/agents/repair-analyst.md` - Confirm agent name for dependencies
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Shared dependency

### Library Files (Dependency Metadata)
- Workflow libraries: workflow-state-machine.sh, state-persistence.sh
- Error handling library: error-handling.sh

### Standards Documentation (Compliance Verification)
- `.claude/docs/concepts/directory-protocols.md` - Topic structure standards
- `.claude/docs/reference/standards/output-formatting.md` - Output and comment standards
- `.claude/docs/reference/standards/command-authoring.md` - Command structure standards
- `.claude/docs/reference/standards/code-standards.md` - Link convention standards

No external tools or installations required. All work is documentation updates and standards compliance verification.
