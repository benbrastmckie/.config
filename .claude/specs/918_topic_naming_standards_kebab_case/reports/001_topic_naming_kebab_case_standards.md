# Topic Naming Standards: Kebab-Case Migration Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Uniform Semantic Topic Directory Naming with Kebab-Case
- **Report Type**: codebase analysis
- **Research Complexity**: 3
- **Builds On**: /home/benjamin/.config/.claude/specs/882_no_name/reports/002_topic_naming_feature_analysis.md

## Executive Summary

This research analyzes the feasibility and impact of standardizing semantic topic directory naming across seven commands (/research, /plan, /debug, /optimize-claude, /errors, /setup, /repair) using kebab-case format instead of the current snake_case format. The analysis reveals that **four commands currently use LLM-based topic naming** while three do not, and identifies significant changes needed in validation regex patterns, documentation, and agent behavioral guidelines to migrate from snake_case to kebab-case.

**Key Findings**:
- Current format: `^[a-z0-9_]{5,40}$` (snake_case with underscores)
- Proposed format: `^[a-z0-9-]{5,40}$` (kebab-case with hyphens)
- Commands with LLM naming: /research, /plan, /debug, /optimize-claude (invoke topic-naming-agent)
- Commands without LLM naming: /errors, /setup, /repair (use fallback slug generation)
- Migration scope: 15+ files require updates (agents, libraries, commands, tests, documentation)
- Backward compatibility: Existing snake_case directories would coexist, no forced migration

## Findings

### 1. Current Topic Naming Architecture

The topic naming system uses a multi-tier approach documented in `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md`:

**Current Validation Regex** (lines 30, 65, 95 of topic-naming-with-llm.md):
```
^[a-z0-9_]{5,40}$
```

This pattern enforces:
- Lowercase letters (a-z)
- Numbers (0-9)
- Underscores (_) as word separators
- Length: 5-40 characters

**Key Files Implementing Current Pattern**:

| File | Line(s) | Pattern Usage |
|------|---------|---------------|
| `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` | 104, 380 | Format validation regex |
| `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` | 94 | `validate_topic_name_format()` function |
| `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` | 220, 304, 330, 483 | Slug validation and sanitization |
| `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` | 30, 65, 95, 147, 241, 246, 355, 489 | Documentation references |

### 2. Command-by-Command Analysis

#### 2.1 Commands Currently Using LLM Topic Naming

**`/research` Command** (`/home/benjamin/.config/.claude/commands/research.md`):
- Uses topic-naming-agent via Task tool (Block 1b, lines 231-254)
- Validates output file at `${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt`
- Falls back to "no_name" on validation failure (lines 320-370)
- **Integration Status**: FULL LLM NAMING

**`/plan` Command** (`/home/benjamin/.config/.claude/commands/plan.md`):
- Uses topic-naming-agent via Task tool (Block 1b, lines 259-282)
- Includes agent output validation with retry logic (lines 337-352)
- Parses topic name and validates format (lines 442-476)
- **Integration Status**: FULL LLM NAMING

**`/debug` Command** (`/home/benjamin/.config/.claude/commands/debug.md`):
- Uses topic-naming-agent via Task tool (Part 2a, lines 310-335)
- Validates and parses topic name (lines 443-509)
- Falls back to "no_name" with error logging
- **Integration Status**: FULL LLM NAMING

**`/optimize-claude` Command** (`/home/benjamin/.config/.claude/commands/optimize-claude.md`):
- Uses topic-naming-agent via Task tool (Block 1b, lines 199-222)
- Same validation pattern as other commands
- **Integration Status**: FULL LLM NAMING

#### 2.2 Commands NOT Using LLM Topic Naming

**`/errors` Command** (`/home/benjamin/.config/.claude/commands/errors.md`):
- Calls `initialize_workflow_paths()` with empty classification result (line 271)
- Uses fallback slug generation from ERROR_DESCRIPTION
- Creates directories like `NNN_error_analysis/` or `NNN_state_error_analysis/`
- **Reason**: Error reports discovered via filters, not semantic browsing
- **Recommendation**: NO CHANGE NEEDED - filter-based discovery sufficient

**`/setup` Command** (`/home/benjamin/.config/.claude/commands/setup.md`):
- Analysis mode calls `initialize_workflow_paths()` with basic description (line 230)
- Uses slug generation from "CLAUDE.md standards analysis"
- **Reason**: Fixed-purpose analysis, not feature-based directory
- **Recommendation**: COULD ADD LLM naming for better report discoverability (low priority)

**`/repair` Command** (`/home/benjamin/.config/.claude/commands/repair.md`):
- Calls `initialize_workflow_paths()` with empty classification result (line 243)
- Uses fallback slug generation from ERROR_DESCRIPTION
- **Reason**: Error-focused workflow, similar to /errors
- **Recommendation**: NO CHANGE NEEDED - follows error repair patterns

### 3. Kebab-Case vs Snake_Case Analysis

#### 3.1 Current Naming Convention (Snake_Case)

**Examples from Codebase**:
```
882_no_name/
867_jwt_token_expiration_fix/
868_oauth_auth_refresh_tokens/
869_state_machine_refactor/
```

**Documentation References** (from `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`):
- Line 58: "Naming: Snake_case describing the feature or area"
- Line 67: "formats names as snake_case directory names"
- Line 1289: "Format: Snake_case with semantic terms only"

**Library References** (from `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh`):
- Lines 236, 250, 330, 483: Sanitization using `tr ' ' '_'` and `sed 's/[^a-z0-9_]//g'`

#### 3.2 Proposed Naming Convention (Kebab-Case)

**Proposed Format**:
```
^[a-z0-9-]{5,40}$
```

**Example Transformed Names**:
```
882-no-name/
867-jwt-token-expiration-fix/
868-oauth-auth-refresh-tokens/
869-state-machine-refactor/
```

**Consistency with Other Conventions** (from `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md`):
- Line 34: Scripts use "kebab-case-names.sh"
- Line 63: Lib files use "kebab-case-names.sh"
- Line 148: Skills directories use "kebab-case/"
- Line 250: Warning against CamelCase, recommending kebab-case

### 4. Impact Analysis

#### 4.1 Files Requiring Modification

**Agent Files (1 file)**:
| File | Changes Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` | Update regex `^[a-z0-9_]{5,40}$` to `^[a-z0-9-]{5,40}$`, change snake_case references to kebab-case, update examples |

**Library Files (2 files)**:
| File | Changes Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` | Update `validate_topic_name_format()` regex, update consecutive underscore check to consecutive hyphen check |
| `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` | Update sanitization patterns (`tr ' ' '-'` instead of `tr ' ' '_'`), update slug validation regex |

**Command Files (4 files with full LLM naming)**:
| File | Changes Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/commands/research.md` | Update validation regex in Block 1c |
| `/home/benjamin/.config/.claude/commands/plan.md` | Update validation regex in Block 1c |
| `/home/benjamin/.config/.claude/commands/debug.md` | Update validation regex in Part 2a |
| `/home/benjamin/.config/.claude/commands/optimize-claude.md` | Update validation regex in Block 1c |

**Documentation Files (8+ files)**:
| File | Changes Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` | Full rewrite of format examples and regex references |
| `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` | Update snake_case references to kebab-case |
| `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md` | Update naming convention description |
| `/home/benjamin/.config/.claude/docs/reference/library-api/overview.md` | Update return type descriptions |
| `/home/benjamin/.config/.claude/docs/reference/templates/*.md` | Update template naming conventions |

**Test Files (3+ files)**:
| File | Changes Required |
|------|-----------------|
| `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_name_sanitization.sh` | Update all test cases |
| `/home/benjamin/.config/.claude/tests/topic-naming/test_topic_naming.sh` | Update validation patterns |
| Integration tests | Update expected output patterns |

#### 4.2 Backward Compatibility Considerations

**Existing Directories**:
- 918+ spec directories currently use snake_case format
- Migration would NOT rename existing directories (preserves history)
- New directories would use kebab-case
- Mixed format during transition period

**Pattern Matching Impact**:
- Glob patterns like `[0-9][0-9][0-9]_*` would need update to `[0-9][0-9][0-9][-_]*`
- Scripts reading directory names would need dual-pattern support

**Plan Path Extraction** (from workflow-initialization.sh lines 78-123):
- `extract_topic_from_plan_path()` uses regex `/specs/[0-9]{3}_[^/]+/plans/`
- Would need update to support both `_` and `-` separators

### 5. Commands Not Requiring Topic Naming Changes

Based on the primary research report and code analysis:

| Command | Creates Topic Dir? | Current Naming | Recommendation |
|---------|-------------------|----------------|----------------|
| /build | No (reuses) | N/A | NO CHANGE - operates on existing plans |
| /revise | No (reuses) | N/A | NO CHANGE - must preserve topic relationship |
| /expand | No (modifies) | N/A | NO CHANGE - deterministic file naming |
| /collapse | No (modifies) | N/A | NO CHANGE - inverse operation |
| /convert-docs | User path | N/A | NO CHANGE - user-controlled paths |

### 6. Standardization Across All Seven Target Commands

For the requested standardization across /research, /plan, /debug, /optimize-claude, /errors, /setup, and /repair:

**Commands with Full LLM Naming (4)**:
- `/research` - Already uses topic-naming-agent
- `/plan` - Already uses topic-naming-agent
- `/debug` - Already uses topic-naming-agent
- `/optimize-claude` - Already uses topic-naming-agent

**Commands with Fallback Naming Only (3)**:
- `/errors` - Uses slug generation, could optionally add LLM naming
- `/setup` - Uses slug generation, could optionally add LLM naming
- `/repair` - Uses slug generation, could optionally add LLM naming

**Options for Standardization**:

**Option A: Add LLM Naming to All Seven Commands**
- Implement topic-naming-agent invocation in /errors, /setup, /repair
- Pros: Uniform semantic naming across all commands
- Cons: Additional ~3s latency per command, marginal benefit for filter-based workflows

**Option B: Maintain Current Differentiation**
- Keep LLM naming for feature-focused commands
- Keep fallback naming for error/utility commands
- Pros: Appropriate tool for each use case
- Cons: Inconsistent naming approach

**Option C: Unified Fallback with Kebab-Case (Recommended)**
- Migrate all naming to kebab-case format
- Keep LLM naming where currently used
- Update fallback sanitization to produce kebab-case
- Pros: Consistent format, minimal latency impact
- Cons: Requires regex and sanitization updates

## Recommendations

### 1. Migrate Format from Snake_Case to Kebab-Case

**Rationale**:
- Aligns with existing kebab-case conventions for scripts (`.claude/lib/`, `.claude/scripts/`)
- Consistent with skills directory naming (`.claude/skills/`)
- Better readability for longer names (`jwt-token-expiration-fix` vs `jwt_token_expiration_fix`)
- URL-friendly (relevant if directory names ever appear in URLs)

**Implementation Priority**:
1. **High**: Update topic-naming-agent.md (single source of truth for LLM)
2. **High**: Update topic-utils.sh validate function
3. **High**: Update workflow-initialization.sh sanitization
4. **Medium**: Update all 4 commands with validation regex
5. **Medium**: Update documentation (8+ files)
6. **Low**: Update test files

### 2. Standardize LLM Naming Across Feature Commands Only

**Keep LLM Naming for**:
- `/research` - Creates research reports (high discoverability value)
- `/plan` - Creates implementation plans (high discoverability value)
- `/debug` - Creates debug reports (medium discoverability value)
- `/optimize-claude` - Creates optimization reports (medium discoverability value)

**Keep Fallback Naming for**:
- `/errors` - Error reports discovered by filters, not browsing
- `/setup` - Fixed-purpose analysis reports
- `/repair` - Error-focused workflow, similar to /errors

### 3. Update Documentation in .claude/docs/

**Required Documentation Updates**:

1. **Create new standards document**: `.claude/docs/reference/standards/topic-naming-standards.md`
   - Central reference for topic naming conventions
   - Kebab-case format specification
   - Examples and anti-patterns
   - Migration notes for existing directories

2. **Update existing documents**:
   - `directory-protocols.md` - Change "Snake_case" to "kebab-case"
   - `topic-naming-with-llm.md` - Update all examples and regex
   - `directory-organization.md` - Add topic directory naming section

### 4. Migration Strategy

**Phase 1: Format Change (No Directory Rename)**
- Update validation regex to accept kebab-case
- Update sanitization to produce kebab-case
- Update agent behavioral guidelines
- Update documentation

**Phase 2: Dual-Format Support (Transition)**
- Update path extraction patterns to support both formats
- Keep existing snake_case directories unchanged
- New directories created with kebab-case

**Phase 3: Optional Cleanup (Future)**
- Provide optional rename script for manual migration
- No forced migration of existing directories
- Document mixed-format handling

### 5. Specific Code Changes

**topic-naming-agent.md Updates**:
```markdown
# Before (lines 72-74)
4. **Generate Name**:
   - Combine 2-5 most significant concepts
   - Use snake_case format (lowercase, underscores)

# After
4. **Generate Name**:
   - Combine 2-5 most significant concepts
   - Use kebab-case format (lowercase, hyphens)
```

**topic-utils.sh Updates**:
```bash
# Before (line 94)
if ! echo "$topic_name" | grep -Eq '^[a-z0-9_]{5,40}$'; then

# After
if ! echo "$topic_name" | grep -Eq '^[a-z0-9-]{5,40}$'; then
```

**workflow-initialization.sh Updates**:
```bash
# Before (line 330)
topic_slug=$(echo "$workflow_description" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g' ...)

# After
topic_slug=$(echo "$workflow_description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' ...)
```

## References

### Primary Source
- `/home/benjamin/.config/.claude/specs/882_no_name/reports/002_topic_naming_feature_analysis.md` (lines 1-328) - Original topic naming feature analysis

### Agent Files
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md` (lines 1-500) - Agent behavioral guidelines with validation patterns

### Library Files
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (lines 90-114) - `validate_topic_name_format()` function
- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 220-340, 476-490) - Slug validation and sanitization

### Command Files
- `/home/benjamin/.config/.claude/commands/research.md` (lines 231-370) - Topic naming integration
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 259-556) - Topic naming integration
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 310-509) - Topic naming integration
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 199-300) - Topic naming integration
- `/home/benjamin/.config/.claude/commands/errors.md` (lines 271-290) - Fallback naming only
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 230-232) - Fallback naming only
- `/home/benjamin/.config/.claude/commands/repair.md` (lines 243-277) - Fallback naming only

### Documentation Files
- `/home/benjamin/.config/.claude/docs/guides/development/topic-naming-with-llm.md` (lines 1-615) - Complete topic naming guide
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 58, 67, 1289) - Snake_case convention references
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 34, 63, 148, 250) - Kebab-case convention for scripts/libs

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_topic_naming_standards_kebab_case_plan.md](../plans/001_topic_naming_standards_kebab_case_plan.md)
- **Implementation**: [Will be updated by implementer]
- **Date**: 2025-11-21
