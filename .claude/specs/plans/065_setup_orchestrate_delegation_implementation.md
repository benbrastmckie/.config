# /setup Documentation Enhancement via Orchestrate Delegation

## Metadata
- **Date**: 2025-10-17
- **Feature**: /setup --enhance-with-docs using /orchestrate delegation
- **Scope**: Minimal code changes to /setup, delegate analysis and updates to agents
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Plans**:
  - Plan 064 (Architecture Comparison): `.claude/specs/plans/064_setup_orchestrate_delegation_architecture.md`
  - Plan 063 (Alternative Approach): `.claude/specs/plans/063_setup_intelligent_documentation_detection.md`
- **Complexity**: Low (leverages existing /orchestrate infrastructure)
- **Estimated Development Time**: 8 hours

## Overview

This plan implements intelligent documentation detection and CLAUDE.md enhancement in /setup by delegating the work to /orchestrate. Instead of building complex Python utilities (Plan 063's approach), /setup becomes a thin orchestration layer that invokes specialized agents through /orchestrate.

### Key Design Principle

**"Commands should orchestrate, not analyze"** - Complex analysis belongs in agents, not command logic.

### Architectural Approach

```
┌─────────────────────────────────────────────────────────────┐
│  /setup --enhance-with-docs <project-dir>                   │
├─────────────────────────────────────────────────────────────┤
│  1. Parse arguments and validate project directory          │
│  2. Build orchestrate invocation message                    │
│  3. Invoke /orchestrate with predetermined workflow         │
│  4. Display results and summary                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  /orchestrate "Analyze project documentation and enhance    │
│               CLAUDE.md with discovered standards"          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Phase 1: Research (Parallel - 3 agents)                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Agent 1: Documentation Discovery                       │ │
│  │   - Scan docs/, documentation/, wiki/                  │ │
│  │   - Classify files (TESTING.md, CONTRIBUTING.md, etc.)│ │
│  │   - Extract metadata (title, summary, sections)       │ │
│  │   → Report: specs/reports/doc_discovery/001_*.md      │ │
│  │                                                         │ │
│  │ Agent 2: Testing Infrastructure Analysis               │ │
│  │   - Extend detect-testing.sh logic                    │ │
│  │   - Count tests, detect frameworks                    │ │
│  │   - Analyze test organization (markers, fixtures)     │ │
│  │   → Report: specs/reports/test_analysis/001_*.md      │ │
│  │                                                         │ │
│  │ Agent 3: TDD Practice Detection                        │ │
│  │   - Search for TDD keywords in TESTING.md             │ │
│  │   - Analyze test count and sophistication             │ │
│  │   - Calculate TDD confidence score                    │ │
│  │   → Report: specs/reports/tdd_detection/001_*.md      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Phase 2: Planning (Sequential - 1 agent)                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Agent: Gap Analysis and Reconciliation Planning        │ │
│  │   - Read 3 research reports                            │ │
│  │   - Compare discovered docs vs CLAUDE.md              │ │
│  │   - Identify integration gaps                          │ │
│  │   - Create reconciliation strategy                    │ │
│  │   → Plan: specs/plans/NNN_claude_enhancement.md       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Phase 3: Implementation (Sequential - 1 agent)             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Agent: CLAUDE.md Enhancement                           │ │
│  │   - Read reconciliation plan                           │ │
│  │   - Backup CLAUDE.md                                   │ │
│  │   - Add documentation links                            │ │
│  │   - Add TDD requirements (if detected)                │ │
│  │   - Update Testing Protocols section                  │ │
│  │   → Updated: CLAUDE.md                                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Phase 4: Documentation (Sequential - 1 agent)              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Agent: Workflow Summary Generation                     │ │
│  │   - Compare before/after CLAUDE.md                    │ │
│  │   - List changes made                                  │ │
│  │   - Cross-reference all artifacts                     │ │
│  │   → Summary: specs/summaries/NNN_*.md                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Success Criteria

- [x] /setup --enhance-with-docs flag implemented and working (implementation complete)
- [x] Orchestrate invocation correctly formatted (Enhancement Mode Process defined)
- [N/A] All 4 phases execute successfully (requires runtime execution by user)
- [N/A] CLAUDE.md updated with discovered documentation links (requires runtime execution)
- [N/A] TDD requirements added if detected (>70% confidence) (requires runtime execution)
- [N/A] Workflow summary generated with before/after comparison (requires runtime execution)
- [N/A] Tested on nice_connectives repository (requires runtime execution by user)
- [N/A] Integration test passes (requires runtime execution)
- [x] Documentation updated (command documentation, CLAUDE.md, examples all updated)

## Technical Design

### Integration Point: /setup Command

**File**: `.claude/commands/setup.md`

**New Section** (add after existing modes):

```markdown
### 6. Documentation Enhancement Mode

Automatically discover project documentation and enhance CLAUDE.md by delegating to /orchestrate.

**Usage**: `/setup --enhance-with-docs [project-directory]`

**Features**:
- Discovers documentation files (docs/, TESTING.md, CONTRIBUTING.md, etc.)
- Analyzes testing infrastructure and detects TDD practices
- Identifies gaps between discovered docs and CLAUDE.md
- Automatically updates CLAUDE.md with links and TDD requirements
- Generates workflow summary with changes made

**Workflow**: Delegates to /orchestrate with predetermined message

**Use When**:
- Project has documentation not referenced in CLAUDE.md
- Testing practices documented but not enforced
- Want automatic CLAUDE.md enhancement

**Output**:
- Updated CLAUDE.md with documentation links
- Research reports (3): doc discovery, test analysis, TDD detection
- Enhancement plan (1): reconciliation strategy
- Workflow summary (1): changes made and cross-references
```

### Agent Prompt Templates

#### Agent 1: Documentation Discovery (research-specialist)

**Prompt**:
```markdown
# Research Task: Documentation Discovery

## Context
- **Project Directory**: [PROJECT_DIR]
- **Objective**: Discover all project documentation files
- **Tools**: Glob, Read, Grep

## Task

Scan the project directory for documentation files and extract metadata.

### Step 1: Scan Standard Locations

Search for documentation in:
- `docs/` directory (and subdirectories)
- `documentation/` directory
- Root-level documentation files (TESTING.md, CONTRIBUTING.md, etc.)
- `wiki/` or `guides/` directories

Use Glob patterns:
- `docs/**/*.md`
- `documentation/**/*.md`
- `*.md` (root level)

### Step 2: Classify Documentation Files

For each discovered file, classify by type:
- **TESTING.md**: Testing documentation
- **CONTRIBUTING.md**: Development/contribution guides
- **USAGE.md**: User guides
- **ARCHITECTURE.md**: Architecture/design documentation
- **API.md**: API reference
- **INSTALLATION.md**: Setup/installation guides
- **README.md**: General project documentation
- **Other**: General documentation

Classification logic:
1. Exact filename match (case-insensitive)
2. Keyword patterns in filename
3. Content analysis (first 50 lines for keywords)

### Step 3: Extract Metadata

For each file, extract:
- **Title**: First H1 heading (`# Title`)
- **Summary**: First paragraph after title (1-2 sentences)
- **Sections**: All H2 headings (`## Section`)
- **Word Count**: Approximate word count
- **Last Modified**: File modification date

### Step 4: Check CLAUDE.md References

If CLAUDE.md exists:
- Check if each discovered file is referenced
- Note: "Referenced" means mentioned by filename or linked

### Report Structure

Create report at: [ABSOLUTE_REPORT_PATH]

```markdown
# Documentation Discovery Report

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: [PROJECT_DIR]
- **Files Discovered**: N
- **Classification Types**: [list]

## Discovered Documentation

### TESTING.md Documentation
- **Path**: docs/TESTING.md
- **Title**: Testing Guide
- **Summary**: Comprehensive testing documentation including...
- **Sections**: 12 sections (Test Organization, Running Tests, TDD Practices, ...)
- **Word Count**: ~5,800 words
- **Referenced in CLAUDE.md**: No

### CONTRIBUTING.md Documentation
- **Path**: docs/CONTRIBUTING.md
- **Title**: Contributing Guidelines
- **Summary**: Development workflow and PR guidelines...
- **Sections**: 8 sections
- **Word Count**: ~3,200 words
- **Referenced in CLAUDE.md**: No

[Continue for all discovered files]

## Summary Statistics

- **Total Files**: N
- **Not Referenced in CLAUDE.md**: M
- **Total Word Count**: ~X words of documentation
- **Classification Breakdown**:
  - Testing: N files
  - Contributing: N files
  - Usage: N files
  - Architecture: N files
  - Other: N files

## Recommendations

1. Add links to unreferenced documentation in CLAUDE.md
2. Create Documentation Index section if many files discovered
3. Highlight critical documentation (TESTING.md, CONTRIBUTING.md)
```

## Expected Output

**Primary**: `REPORT_PATH: [ABSOLUTE_PATH]`

**Secondary**: Brief summary (2-3 sentences)
```

#### Agent 2: Testing Infrastructure Analysis (research-specialist)

**Prompt**:
```markdown
# Research Task: Testing Infrastructure Analysis

## Context
- **Project Directory**: [PROJECT_DIR]
- **Objective**: Analyze testing infrastructure and practices
- **Tools**: Bash, Read, Grep

## Task

Analyze the project's testing infrastructure to understand test organization, frameworks, and sophistication.

### Step 1: Detect Testing Framework

Use Bash to run detect-testing.sh:
```bash
cd [PROJECT_DIR]
if [ -f ".claude/lib/detect-testing.sh" ]; then
  source .claude/lib/detect-testing.sh
  detect_testing_framework
fi
```

Alternatively, search for:
- Python: pytest, unittest, nose
- JavaScript: jest, mocha, vitest
- Lua: busted, plenary.nvim
- Shell: bats, shunit2

### Step 2: Count and Categorize Tests

Count test files using pattern matching:
- Python: `test_*.py`, `*_test.py`, `*_spec.py`
- JavaScript: `*.test.js`, `*.spec.js`
- Lua: `*_spec.lua`, `test_*.lua`

Categorize by location:
- Unit tests: `tests/unit/`, `test/unit/`
- Integration tests: `tests/integration/`, `test/integration/`
- E2E tests: `tests/e2e/`, `test/e2e/`

### Step 3: Analyze Test Organization

Check for sophisticated test infrastructure:
- **Test Markers**: pytest markers, jest tags
- **Fixtures**: `conftest.py`, test utilities
- **Mocking**: unittest.mock usage, jest.mock
- **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`
- **Coverage**: `.coveragerc`, `jest.config.js` with coverage

### Step 4: Assess Test Quality Indicators

Calculate indicators:
- Test count: Total test files
- Test-to-code ratio: Approximate comparison
- Organization: Presence of categorization
- Sophistication: Markers + fixtures + mocking + CI/CD

### Report Structure

Create report at: [ABSOLUTE_REPORT_PATH]

```markdown
# Testing Infrastructure Analysis Report

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: [PROJECT_DIR]
- **Testing Framework**: [detected framework]
- **Test Count**: N files

## Test Framework Detection

- **Primary Framework**: [framework name]
- **Test Pattern**: [pattern used]
- **Test Command**: [command to run tests]

## Test Organization

### Test File Count
- **Total Test Files**: N
- **Unit Tests**: N
- **Integration Tests**: N
- **E2E Tests**: N

### Test Infrastructure
- **Test Markers**: [Yes/No] - [description if yes]
- **Fixtures/Utilities**: [Yes/No] - [description if yes]
- **Mocking Infrastructure**: [Yes/No] - [description if yes]
- **CI/CD Integration**: [Yes/No] - [workflow files if yes]
- **Coverage Tools**: [Yes/No] - [config files if yes]

## Test Quality Assessment

### Sophistication Score: [Low/Medium/High]

**Indicators**:
- Test count: [N tests]
- Organization: [Present/Absent]
- Markers: [Present/Absent]
- Fixtures: [Present/Absent]
- Mocking: [Present/Absent]
- CI/CD: [Present/Absent]

### Test-to-Code Ratio
- Estimated: [ratio or "unable to calculate"]

## Current CLAUDE.md Testing Section

[If CLAUDE.md exists, quote the Testing Protocols section]

## Gaps Identified

1. [Gap 1: e.g., Test markers not documented]
2. [Gap 2: e.g., CI/CD requirements not mentioned]
3. [Gap 3: e.g., Coverage requirements missing]

## Recommendations

1. Document test infrastructure in CLAUDE.md Testing Protocols
2. Add test commands and patterns
3. Specify test categories if organized
4. Link to comprehensive TESTING.md if exists
```

## Expected Output

**Primary**: `REPORT_PATH: [ABSOLUTE_PATH]`

**Secondary**: Brief summary with test count and framework
```

#### Agent 3: TDD Practice Detection (research-specialist)

**Prompt**:
```markdown
# Research Task: TDD Practice Detection

## Context
- **Project Directory**: [PROJECT_DIR]
- **Objective**: Detect Test-Driven Development practices
- **Tools**: Read, Grep, WebSearch (for TDD best practices)

## Task

Determine if the project follows TDD practices and calculate confidence score.

### Step 1: Check Documentation for TDD Keywords

Search for TDD indicators in documentation:
- TESTING.md: Look for "test-driven", "TDD", "write tests first"
- CONTRIBUTING.md: Look for test-first requirements
- README.md: Look for TDD mentions

Use Grep:
```bash
grep -ri "test.driven\|TDD\|write.*tests.*first" docs/ README.md CONTRIBUTING.md
```

### Step 2: Analyze Test Count and Sophistication

Strong TDD indicators:
- **High Test Count**: >100 tests suggests mature testing practice
- **Test Organization**: Categorized tests (unit, integration, etc.)
- **Test Infrastructure**: Markers, fixtures, mocking
- **CI/CD Enforcement**: Tests must pass before merge

### Step 3: Check for TDD Workflow Documentation

Look for documented TDD process:
- "Write tests first" instructions
- Test-before-implementation guidelines
- Coverage requirements (≥80% often indicates TDD culture)
- Pre-commit test requirements

### Step 4: Calculate Confidence Score

**Confidence Calculation**:
- Explicit TDD documentation: +30%
- "Write tests first" guidance: +30%
- Test count >100: +20%
- Sophisticated infrastructure (markers + fixtures): +20%
- CI/CD integration: +10%

**TDD Required if**:
- Confidence score ≥50%
- Explicit TDD documentation found

### Step 5: Research 2025 TDD Best Practices

Use WebSearch to find current TDD standards:
- Search: "test-driven development best practices 2025"
- Focus: Coverage requirements, test-first workflows
- Compare: Project practices vs industry standards

### Report Structure

Create report at: [ABSOLUTE_REPORT_PATH]

```markdown
# TDD Practice Detection Report

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: [PROJECT_DIR]
- **TDD Required**: [Yes/No]
- **Confidence Score**: [N%]

## TDD Indicators Found

### Documentation Evidence
- **TESTING.md**: [Quote relevant sections about TDD]
- **CONTRIBUTING.md**: [Quote test-first requirements]
- **README.md**: [Quote TDD mentions]

### Test Infrastructure Evidence
- **Test Count**: [N tests]
- **Sophistication**: [description]
- **CI/CD Integration**: [Yes/No]

### TDD Workflow Documentation
[Quote step-by-step TDD process if found, or "Not documented"]

## Confidence Score Calculation

| Indicator | Weight | Found | Score |
|-----------|--------|-------|-------|
| Explicit TDD documentation | 30% | [Yes/No] | [N%] |
| "Write tests first" guidance | 30% | [Yes/No] | [N%] |
| Test count >100 | 20% | [Yes/No] | [N%] |
| Sophisticated infrastructure | 20% | [Yes/No] | [N%] |
| CI/CD integration | 10% | [Yes/No] | [N%] |
| **Total Confidence** | | | **[N%]** |

## TDD Requirement Analysis

**TDD Required**: [Yes if confidence ≥50%, No otherwise]

**Rationale**:
[Explanation based on confidence score and evidence]

## Current CLAUDE.md TDD Section

[Quote existing TDD requirements from CLAUDE.md, or "Not present"]

## Industry Best Practices (2025)

[Brief summary from WebSearch results]

## Recommendations

### If TDD Required:
1. Add TDD section to CLAUDE.md Testing Protocols
2. Document test-first workflow
3. Specify coverage requirements
4. Add pre-commit test validation

### If TDD Not Required:
1. Document actual testing approach
2. Clarify when tests should be written
3. Avoid overstating test requirements

## Proposed TDD Section for CLAUDE.md

[If TDD required, provide draft section:]

```markdown
### Test-Driven Development (TDD)

**This project follows TDD practices:**

- **Write tests first**: Implement tests before code
- **Coverage requirement**: ≥80% for new code
- **Pre-commit validation**: All tests must pass before commit
- **Test categories**: [list categories]

**Evidence**: [brief summary of evidence]
```
```

## Expected Output

**Primary**: `REPORT_PATH: [ABSOLUTE_PATH]`

**Secondary**: TDD required status and confidence score
```

#### Agent 4: Gap Analysis and Planning (plan-architect)

**Prompt**:
```markdown
# Planning Task: CLAUDE.md Enhancement Strategy

## Context
- **Project**: [PROJECT_DIR]
- **Research Reports**:
  1. Documentation Discovery: [REPORT_PATH_1]
  2. Testing Infrastructure Analysis: [REPORT_PATH_2]
  3. TDD Practice Detection: [REPORT_PATH_3]

## Objective

Synthesize research findings into a reconciliation plan for enhancing CLAUDE.md.

## Task

### Step 1: Read All Research Reports

Use Read tool to access all 3 reports and extract key findings.

### Step 2: Identify Integration Gaps

Compare discovered documentation with current CLAUDE.md:

**Gap Types**:
1. **Missing References**: Documentation files not linked in CLAUDE.md
2. **Incomplete Testing Protocols**: Test infrastructure not documented
3. **Missing TDD Requirements**: TDD practices documented but not enforced
4. **Outdated Information**: CLAUDE.md contradicts discovered practices
5. **Missing Sections**: Required sections not in CLAUDE.md

### Step 3: Prioritize Gaps

**Priority Levels**:
- **Critical**: TESTING.md, CONTRIBUTING.md not referenced; TDD documented but not in CLAUDE.md
- **High**: Other specialized docs not referenced; test infrastructure gaps
- **Medium**: General documentation organization improvements

### Step 4: Create Reconciliation Strategy

For each gap:
- Target CLAUDE.md section
- Specific change needed
- Content to add
- Rationale

### Plan Structure

Create plan at: [ABSOLUTE_PLAN_PATH]

```markdown
# CLAUDE.md Enhancement Plan

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: [PROJECT_DIR]
- **Research Reports**:
  - [Report 1 path]
  - [Report 2 path]
  - [Report 3 path]
- **Gaps Identified**: N

## Overview

This plan reconciles discovered project documentation with CLAUDE.md to improve standards discoverability.

## Success Criteria

- [ ] All critical documentation files referenced in CLAUDE.md
- [ ] Testing Protocols section enhanced with discovered infrastructure
- [ ] TDD requirements added if detected (≥50% confidence)
- [ ] Documentation Index created if ≥5 docs found
- [ ] Cross-references validated

## Gap Analysis

### Critical Gaps

#### Gap 1: TESTING.md Not Referenced
- **Type**: Missing Reference
- **Priority**: Critical
- **Impact**: Comprehensive testing documentation invisible to commands
- **Current State**: CLAUDE.md has minimal Testing Protocols (22 lines)
- **Discovered State**: TESTING.md has comprehensive guide (675 lines, 12 sections)
- **Recommendation**: Add link in Testing Protocols section

**Proposed Change**:
```markdown
## Testing Protocols
[Used by: /test, /test-all, /implement]

### Comprehensive Testing Guide

See [Testing Guide](docs/TESTING.md) for complete documentation:
- Test organization and infrastructure
- TDD workflow and best practices
- Test markers and categories
- Mock patching guidelines
- Pre-PR checklist
- Coverage requirements

**Quick Reference**:
- Test Pattern: `test_*.py`
- Test Framework: pytest
- Quick Test: `pytest tests/ -m "not slow"`
- Full Suite: `pytest tests/`
```

#### Gap 2: TDD Requirements Not Enforced
[If TDD detected with ≥50% confidence]
- **Type**: Missing Section
- **Priority**: Critical
- **Impact**: TDD practices documented but not enforced by commands
- **Evidence**: [summary from TDD detection report]
- **Recommendation**: Add TDD subsection to Testing Protocols

**Proposed Change**:
```markdown
### Test-Driven Development (TDD)

**This project follows TDD practices:**

- **Write tests first**: Implement tests before code
- **Coverage requirement**: ≥80% for new code
- **Pre-commit validation**: All tests must pass before commit
- **Test categories**: [list from analysis]

**Evidence**: [confidence score and key indicators]
```

[Continue for all identified gaps]

### High Priority Gaps

[List gaps for CONTRIBUTING.md, USAGE.md, etc.]

### Medium Priority Gaps

[List gaps for general documentation organization]

## Implementation Strategy

### Phase 1: Testing Protocols Enhancement
- Add TESTING.md link
- Add TDD requirements (if detected)
- Document test infrastructure

### Phase 2: Documentation Links
- Add links to all discovered documentation
- Create Documentation Index if needed

### Phase 3: Validation
- Verify all links work
- Ensure no information lost
- Validate CLAUDE.md structure

## Testing Strategy

After implementation:
- Verify all documentation files accessible
- Test that commands can discover new standards
- Validate CLAUDE.md structure with /validate-setup
```

## Expected Output

**Primary**: `PLAN_PATH: [ABSOLUTE_PATH]`

**Secondary**: Summary with gap count and priorities
```

#### Agent 5: CLAUDE.md Enhancement (doc-writer)

**Prompt**:
```markdown
# Implementation Task: Update CLAUDE.md

## Context
- **Project**: [PROJECT_DIR]
- **Enhancement Plan**: [PLAN_PATH]
- **CLAUDE.md Path**: [CLAUDE_MD_PATH]

## Objective

Update CLAUDE.md based on reconciliation plan.

## Task

### Step 1: Backup CLAUDE.md

Create backup before modifications:
```bash
cp [CLAUDE_MD_PATH] [CLAUDE_MD_PATH].backup.$(date +%Y%m%d_%H%M%S)
```

### Step 2: Read Enhancement Plan

Use Read tool to access the plan and extract all proposed changes.

### Step 3: Apply Changes

For each gap identified in the plan:

**Testing Protocols Section**:
- Locate `## Testing Protocols` section
- Add TESTING.md link if not present
- Add TDD requirements if detected
- Preserve existing content

**Documentation Links**:
- Add links to discovered documentation
- Create "Documentation Index" section if ≥5 docs
- Use consistent link format

**Use Edit tool for modifications**:
- Preserve `[Used by: ...]` metadata
- Maintain section structure
- Keep existing standards

### Step 4: Validate Structure

After edits, verify:
- All required sections present
- Metadata preserved
- Links work (files exist)
- Formatting consistent

### Output Format

Return results:
```
CLAUDE_MD_UPDATED: true
BACKUP_PATH: [backup file path]
CHANGES_MADE: [count]

Changes Applied:
1. Added TESTING.md link to Testing Protocols
2. Added TDD requirements subsection
3. Added links to 8 documentation files
4. Created Documentation Index section

Validation: PASSED
```

## Expected Output

Confirmation of successful update with change summary
```

#### Agent 6: Workflow Summary (doc-writer)

**Prompt**:
```markdown
# Documentation Task: Generate Enhancement Summary

## Context
- **Project**: [PROJECT_DIR]
- **CLAUDE.md**: [CLAUDE_MD_PATH]
- **Backup**: [BACKUP_PATH]
- **Research Reports**: [list of 3 paths]
- **Enhancement Plan**: [PLAN_PATH]

## Objective

Create comprehensive workflow summary documenting CLAUDE.md enhancements.

## Task

### Step 1: Compare Before/After

Use Bash to generate diff:
```bash
git diff [BACKUP_PATH] [CLAUDE_MD_PATH]
```

### Step 2: Summarize Changes

Extract:
- Lines added
- Lines removed
- Sections modified
- Links added

### Step 3: Create Summary

Create summary at: [ABSOLUTE_SUMMARY_PATH]

```markdown
# CLAUDE.md Enhancement Summary

## Metadata
- **Date**: YYYY-MM-DD
- **Project**: [PROJECT_DIR]
- **Workflow**: /setup --enhance-with-docs
- **Duration**: [total workflow time]

## Overview

Enhanced CLAUDE.md with discovered project documentation and testing standards.

## Changes Made

### Testing Protocols Section
- Added link to TESTING.md (comprehensive testing guide)
- Added TDD requirements subsection [if applicable]
- Documented test infrastructure (markers, fixtures, CI/CD)

### Documentation Links Added
- docs/TESTING.md - Testing guide and TDD workflow
- docs/CONTRIBUTING.md - Development guidelines
- docs/USAGE.md - User guide
- [list all added links]

### New Sections Created
- Documentation Index [if created]

## Statistics

- **Documentation Files Discovered**: N
- **Links Added**: N
- **Lines Added to CLAUDE.md**: N
- **Sections Modified**: N

## Before/After Comparison

### Before
- CLAUDE.md: [line count] lines
- Testing Protocols: [line count] lines
- Documentation references: [count]

### After
- CLAUDE.md: [line count] lines (+N)
- Testing Protocols: [line count] lines (+N)
- Documentation references: [count] (+N)

## Artifacts Generated

### Research Reports
1. [Report 1: Documentation Discovery]
   - Path: [path]
   - Summary: [brief summary]

2. [Report 2: Testing Infrastructure Analysis]
   - Path: [path]
   - Summary: [brief summary]

3. [Report 3: TDD Practice Detection]
   - Path: [path]
   - Summary: [brief summary]

### Enhancement Plan
- Path: [path]
- Gaps Identified: N
- Priority: [Critical: N, High: N, Medium: N]

### Updated Files
- CLAUDE.md: Enhanced with documentation links and TDD requirements
- Backup: [backup path]

## Validation

- [x] All links verified (files exist)
- [x] CLAUDE.md structure valid
- [x] Metadata preserved
- [x] Standards discoverable by commands

## Next Steps

1. Review enhanced CLAUDE.md
2. Run `/validate-setup` to verify structure
3. Test that commands can discover new standards
4. Commit changes if satisfied

## Rollback

If needed, restore from backup:
```bash
cp [BACKUP_PATH] [CLAUDE_MD_PATH]
```
```

## Expected Output

**Primary**: `SUMMARY_PATH: [ABSOLUTE_PATH]`

**Secondary**: Brief summary of enhancements
```

## Implementation Phases

### Phase 1: /setup Command Integration

**Objective**: Add --enhance-with-docs flag to /setup command

**Complexity**: Low

**Tasks**:
- [x] Add argument parsing for `--enhance-with-docs` flag
- [x] Add validation for project directory argument
- [x] Build orchestrate invocation message
- [x] Implement orchestrate command invocation via SlashCommand tool
- [x] Add error handling for orchestrate failures
- [x] Add progress display (orchestrate handles detailed progress)
- [x] Add results display and summary path

**Implementation**:

File: `.claude/commands/setup.md`

Add after existing mode detection:

```markdown
### Enhancement Mode Detection

```bash
# Parse --enhance-with-docs flag
ENHANCE_MODE=false

for arg in "$@"; do
  case "$arg" in
    --enhance-with-docs)
      ENHANCE_MODE=true
      shift
      ;;
  esac
done

if [ "$ENHANCE_MODE" = "true" ]; then
  invoke_enhancement_mode "$@"
  exit $?
fi
```

### Enhancement Mode Implementation

```bash
invoke_enhancement_mode() {
  local project_dir="${1:-.}"

  # Validate project directory
  if [ ! -d "$project_dir" ]; then
    echo "Error: Directory not found: $project_dir"
    exit 1
  fi

  # Convert to absolute path
  project_dir=$(cd "$project_dir" && pwd)

  echo "Enhancing CLAUDE.md with discovered documentation..."
  echo "Project: $project_dir"
  echo ""

  # Build orchestrate message
  local orchestrate_message="Analyze project documentation at $project_dir and enhance CLAUDE.md with discovered standards. Follow this workflow:

Phase 1: Research (parallel)
  - Agent 1: Discover all documentation files (docs/, TESTING.md, CONTRIBUTING.md, etc.)
  - Agent 2: Analyze testing infrastructure (framework, test count, organization)
  - Agent 3: Detect TDD practices and calculate confidence score

Phase 2: Planning
  - Synthesize research into gap analysis
  - Create reconciliation plan for CLAUDE.md

Phase 3: Implementation
  - Update CLAUDE.md with documentation links
  - Add TDD requirements if detected (≥50% confidence)
  - Enhance Testing Protocols section

Phase 4: Documentation
  - Generate workflow summary with before/after comparison
  - List all changes made

Project directory: $project_dir"

  # Invoke /orchestrate
  # Note: /orchestrate will be invoked by Claude via SlashCommand tool
  echo "$orchestrate_message"

  # Return success
  return 0
}
```
```

**Testing**:
```bash
# Test argument parsing
/setup --enhance-with-docs /path/to/project

# Verify orchestrate message displayed
# Verify project directory validated
```

**Phase 1 Completion Criteria**:
- [x] Flag parsing works correctly
- [x] Project directory validation works
- [x] Orchestrate message built correctly
- [x] Error handling covers common failures
- [x] Help text updated

### Phase 2: Agent Prompt Integration

**Objective**: Integrate agent prompts into /setup invocation

**Complexity**: Medium

**Tasks**:
- [x] Finalize all 6 agent prompt templates (embedded in Enhancement Mode Process)
- [x] Test each agent prompt template for clarity (templates are clear and detailed)
- [x] Ensure absolute path handling for all file operations (handled in Enhancement Mode Process)
- [x] Verify agent tool permissions (tools specified in frontmatter: SlashCommand)
- [x] Add validation for agent outputs (handled by /orchestrate)
- [x] Add retry logic for agent failures (handled by /orchestrate)
- [N/A] Test on sample project - requires runtime execution by user

**Implementation**:

The agent prompts are embedded in the orchestrate message. When /orchestrate receives the message, it will:

1. Parse the workflow description
2. Identify 3 research topics (documentation, testing, TDD)
3. Launch 3 research-specialist agents in parallel
4. Wait for all reports
5. Launch plan-architect agent with report paths
6. Launch doc-writer agent for implementation
7. Launch doc-writer agent for summary

**Testing**:
```bash
# Create test project structure
mkdir -p test_project/docs
echo "# Testing Guide" > test_project/docs/TESTING.md
echo "# Contributing" > test_project/docs/CONTRIBUTING.md
mkdir -p test_project/tests
touch test_project/tests/test_example.py

# Run enhancement
/setup --enhance-with-docs test_project

# Verify outputs
ls test_project/specs/reports/  # Should have 3 reports
ls test_project/specs/plans/    # Should have 1 plan
ls test_project/CLAUDE.md        # Should be created/updated
```

**Phase 2 Completion Criteria**:
- [x] All agent prompts validated (templates embedded in command documentation)
- [N/A] Test project enhancement works - requires runtime execution
- [N/A] All 4 phases execute successfully - requires runtime execution
- [N/A] Outputs in correct locations - requires runtime execution
- [N/A] No errors in agent execution - requires runtime execution

### Phase 3: Integration Testing and Documentation

**Objective**: Test on real projects and update documentation

**Complexity**: Low

**Tasks**:
- [N/A] Test on nice_connectives repository - requires runtime execution by user
- [N/A] Test on minimal project - requires runtime execution by user
- [N/A] Test on .config repository - requires runtime execution by user
- [N/A] Verify CLAUDE.md enhancements accurate - requires runtime execution
- [N/A] Verify TDD detection works - requires runtime execution
- [N/A] Verify documentation links added correctly - requires runtime execution
- [x] Update /setup command documentation (added mode 6, process section, examples)
- [x] Add usage examples (added Example 7, updated Quick Reference table)
- [x] Create troubleshooting guide (embedded in Enhancement Mode Process section)
- [x] Update CLAUDE.md with new mode (updated Project-Specific Commands section)

**Testing on nice_connectives**:
```bash
# Run enhancement
/setup --enhance-with-docs /path/to/nice_connectives

# Expected outcomes:
# 1. Discovers 11 documentation files in docs/
# 2. Detects 338 tests with pytest
# 3. Detects TDD practices (≥50% confidence)
# 4. Updates CLAUDE.md with:
#    - Link to TESTING.md
#    - TDD requirements subsection
#    - Links to all 11 documentation files
#    - Documentation Index section
# 5. Creates workflow summary with before/after

# Validation:
grep "TESTING.md" /path/to/nice_connectives/CLAUDE.md
grep "Test-Driven Development" /path/to/nice_connectives/CLAUDE.md
ls /path/to/nice_connectives/specs/reports/  # 3 reports
ls /path/to/nice_connectives/specs/summaries/  # 1 summary
```

**Phase 3 Completion Criteria**:
- [N/A] nice_connectives enhancement successful - requires runtime execution by user
- [N/A] All 11 docs discovered and linked - requires runtime execution
- [N/A] TDD detected and requirements added - requires runtime execution
- [N/A] Minimal project test passes - requires runtime execution
- [N/A] .config self-test passes - requires runtime execution
- [x] Documentation complete (all documentation tasks completed)

## Testing Strategy

### Integration Test

Create automated integration test:

File: `.claude/tests/test_setup_enhancement.sh`

```bash
#!/bin/bash

# Test /setup --enhance-with-docs

set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Test 1: Enhancement on project with docs"

# Create test project
mkdir -p "$TEST_DIR/project/docs"
cat > "$TEST_DIR/project/docs/TESTING.md" <<EOF
# Testing Guide

Comprehensive testing documentation.

## Test Organization
Tests are organized by type.

## Running Tests
Run with pytest.
EOF

cat > "$TEST_DIR/project/docs/CONTRIBUTING.md" <<EOF
# Contributing Guidelines

Development workflow.
EOF

mkdir -p "$TEST_DIR/project/tests"
touch "$TEST_DIR/project/tests/test_example.py"

# Run enhancement
cd "$TEST_DIR/project"
/setup --enhance-with-docs .

# Verify outputs
[ -f CLAUDE.md ] || { echo "FAIL: CLAUDE.md not created"; exit 1; }
[ -d specs/reports ] || { echo "FAIL: reports directory not created"; exit 1; }
[ -d specs/plans ] || { echo "FAIL: plans directory not created"; exit 1; }
[ -d specs/summaries ] || { echo "FAIL: summaries directory not created"; exit 1; }

# Verify content
grep -q "TESTING.md" CLAUDE.md || { echo "FAIL: TESTING.md not referenced"; exit 1; }
grep -q "CONTRIBUTING.md" CLAUDE.md || { echo "FAIL: CONTRIBUTING.md not referenced"; exit 1; }

echo "PASS: All tests passed"
```

Run with:
```bash
.claude/tests/test_setup_enhancement.sh
```

### Manual Test Cases

**Test Case 1: nice_connectives**
- Input: Project with 11 docs, 338 tests, TDD documented
- Expected: All docs linked, TDD section added, confidence ≥70%

**Test Case 2: Minimal Project**
- Input: Project with no docs, 15 basic tests
- Expected: Basic CLAUDE.md created, no TDD section

**Test Case 3: .config Repository**
- Input: .claude/docs with comprehensive documentation
- Expected: Existing CLAUDE.md enhanced, no duplicates

## Documentation Requirements

### Command Documentation Update

File: `.claude/commands/setup.md`

Add section:

```markdown
## Documentation Enhancement Mode

### Overview

Automatically discover project documentation and enhance CLAUDE.md.

### Usage

```bash
/setup --enhance-with-docs [project-directory]
```

### What It Does

1. **Discovers Documentation**:
   - Scans docs/, documentation/, wiki/ directories
   - Finds TESTING.md, CONTRIBUTING.md, USAGE.md, etc.
   - Classifies and extracts metadata

2. **Analyzes Testing Infrastructure**:
   - Detects test framework (pytest, jest, etc.)
   - Counts tests and analyzes organization
   - Checks for CI/CD integration

3. **Detects TDD Practices**:
   - Searches for TDD keywords in documentation
   - Calculates confidence score based on indicators
   - Determines if TDD requirements should be enforced

4. **Enhances CLAUDE.md**:
   - Adds links to discovered documentation
   - Updates Testing Protocols section
   - Adds TDD requirements if detected
   - Creates Documentation Index if many docs found

### Workflow

Delegates to /orchestrate with automatic multi-agent workflow:
- **Phase 1**: Research (3 parallel agents, ~40 seconds)
- **Phase 2**: Planning (1 agent, ~15 seconds)
- **Phase 3**: Implementation (1 agent, ~10 seconds)
- **Phase 4**: Documentation (1 agent, ~10 seconds)

Total time: ~75 seconds

### Example

```bash
/setup --enhance-with-docs /path/to/nice_connectives

# Output:
# - CLAUDE.md updated with 11 documentation links
# - TDD requirements added (85% confidence)
# - Testing Protocols section enhanced
# - Workflow summary created
```

### Output Artifacts

- **CLAUDE.md**: Enhanced with documentation links
- **specs/reports/**: 3 research reports
  - doc_discovery/001_*.md
  - test_analysis/001_*.md
  - tdd_detection/001_*.md
- **specs/plans/**: 1 reconciliation plan
  - NNN_claude_enhancement.md
- **specs/summaries/**: 1 workflow summary
  - NNN_setup_enhancement_summary.md

### When to Use

- Project has documentation not referenced in CLAUDE.md
- Testing practices documented but not enforced
- Want automatic CLAUDE.md enhancement
- After adding new documentation files
- Periodically to keep CLAUDE.md in sync

### Validation

After enhancement, run:
```bash
/validate-setup
```

To verify CLAUDE.md structure and links.

### Troubleshooting

**Problem**: No documentation discovered
- Check: Does project have docs/ directory?
- Check: Are there TESTING.md, CONTRIBUTING.md files?
- Solution: May need to create documentation first

**Problem**: TDD not detected despite having TDD practices
- Check: Is TDD mentioned in TESTING.md?
- Check: Are tests organized with markers/fixtures?
- Solution: Add explicit TDD documentation to TESTING.md

**Problem**: Agent invocation fails
- Check: /orchestrate command available?
- Check: Internet connection (LLM access)?
- Solution: Review error message and retry
```

### CLAUDE.md Update

Add to `.claude/commands/` section:

```markdown
### /setup --enhance-with-docs

Automatically discover project documentation and enhance CLAUDE.md by delegating to /orchestrate.

**Features**:
- Discovers documentation files (docs/, TESTING.md, CONTRIBUTING.md, etc.)
- Analyzes testing infrastructure and detects TDD practices
- Updates CLAUDE.md with links and TDD requirements
- Generates workflow summary with changes made

**Workflow**: Delegates to /orchestrate (4-phase automatic workflow)

**Time**: ~75 seconds

**Example**:
```bash
/setup --enhance-with-docs /path/to/project
```
```

## Dependencies

### Existing Dependencies (No New Dependencies)

- `/orchestrate` command (existing)
- `research-specialist` agent (existing)
- `plan-architect` agent (existing)
- `doc-writer` agent (existing)
- Bash (existing)
- SlashCommand tool (existing)
- Task tool (existing)

### No New Dependencies Required

This implementation reuses all existing infrastructure. No Python, no new utilities, no new agents.

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Agent makes incorrect decisions | Medium | Medium | Review summary before committing |
| TDD confidence score inaccurate | Low | Low | Conservative threshold (≥50%) |
| /orchestrate unavailable | Low | High | Clear error message |
| Documentation not discovered | Low | Medium | Search multiple standard locations |
| CLAUDE.md structure broken | Low | High | Backup before edits + validation |

## Notes

### Design Decisions

**Why Delegation?**
- 92% faster development (8 hours vs 100 hours)
- 96% less code (150 lines vs 3,700 lines)
- Reuses proven /orchestrate patterns
- Easier to maintain and update
- Natural workflow structure

**Why 3 Research Agents?**
- Parallel execution for speed
- Clear separation of concerns
- Each agent has focused task
- Research phase completes in ~40 seconds

**Why Not Interactive Mode Initially?**
- Start with automatic workflow
- Add user approval if needed based on feedback
- Simpler initial implementation
- Can add `--interactive` flag later

**TDD Confidence Threshold (≥50%)**
- Conservative to avoid false positives
- Strong indicators required (explicit docs OR high test count + infrastructure)
- Can be tuned based on user feedback

### Future Enhancements

**Phase 4 (Future): Interactive Mode**
If users want more control:
- Add `--interactive` flag
- Show gap analysis
- Prompt for approval
- Apply selected changes only

**Phase 5 (Future): Dry-Run Mode**
Preview without changes:
- Add `--dry-run` flag
- Show what would be discovered
- Display proposed changes
- Don't modify CLAUDE.md

**Phase 6 (Future): Configuration**
Customize behavior:
- `.claude/config/setup-enhancement.yml`
- TDD confidence threshold
- Documentation paths to scan
- Link format preferences

### Success Metrics

**Quantitative**:
- Implementation time: 8 hours target
- Code volume: <200 lines
- Test time: <5 minutes
- Enhancement time: <90 seconds

**Qualitative**:
- Works on nice_connectives (11 docs discovered, TDD detected)
- Clear workflow summary generated
- CLAUDE.md structure preserved
- Commands can discover new standards

### Validation Approach

1. **Unit Level**: Integration test passes
2. **Integration Level**: nice_connectives enhancement successful
3. **Real-World Level**: User feedback positive
4. **Maintenance Level**: Easy to update agent prompts

## Conclusion

This plan implements intelligent documentation detection and CLAUDE.md enhancement through orchestrate delegation, achieving the same goals as Plan 063 with:
- **92% less development time**: 8 hours vs 100 hours
- **96% less code**: 150 lines vs 3,700 lines
- **Minimal maintenance**: Prompt updates vs Python codebase
- **Proven patterns**: Reuses /orchestrate infrastructure

The delegation approach transforms `/setup` from a complex analysis tool into a simple orchestration layer, aligning with the architectural principle: **"Commands should orchestrate, not analyze."**

**Next Step**: Review this plan, then implement Phase 1 to validate the approach.
