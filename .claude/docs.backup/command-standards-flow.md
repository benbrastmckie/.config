# Command Standards Flow

This document illustrates how standards flow through the development workflow from discovery to validation.

## Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     CLAUDE.md Files                         │
│            (Project Standards Repository)                   │
│                                                             │
│  - Code Standards                                           │
│  - Testing Protocols                                        │
│  - Documentation Policy                                     │
│  - Standards Discovery                                      │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Discovery & Extraction
                 ↓
┌─────────────────────────────────────────────────────────────┐
│                  Development Commands                       │
│             (Standards Consumers)                           │
└─────────────────────────────────────────────────────────────┘

      │                   │                   │
      │                   │                   │
      ↓                   ↓                   ↓
 ┌──────────┐      ┌──────────┐       ┌──────────┐
 │ /report  │      │  /plan   │       │ /refactor│
 │          │      │          │       │          │
 │ Research │──────→ Capture  │       │ Validate │
 │          │      │ Standards│       │ Against  │
 └──────────┘      └────┬─────┘       │ Standards│
                        │              └──────────┘
                        │
                        ↓
                   ┌──────────┐
                   │/implement│
                   │          │
                   │  Apply   │
                   │ Standards│
                   └────┬─────┘
                        │
                        │
                        ↓
                   ┌──────────┐
                   │  /test   │
                   │          │
                   │  Verify  │
                   │  Using   │
                   │ Test Cmds│
                   └────┬─────┘
                        │
                        │
                        ↓
                   ┌──────────┐
                   │/document │
                   │          │
                   │  Follow  │
                   │  Doc     │
                   │  Policy  │
                   └──────────┘
```

## Detailed Command Flow

### Phase 1: Research and Planning

#### /report Command
**Standards Usage**: Minimal (documentation format only)

**What it does**:
- Researches topic
- Creates research report
- Does not enforce code standards (no code generation)

**Standards Used**:
- Documentation Policy (for report format)

**Output**:
- Research report in `specs/reports/NNN_topic.md`

```
/report → [Documentation Policy] → research_report.md
```

#### /plan Command
**Standards Usage**: Discovery and Capture

**What it does**:
- Discovers CLAUDE.md standards
- Creates implementation plan
- Captures standards file path in plan metadata
- Ensures plan reflects project conventions

**Standards Used**:
- Code Standards (to design implementation)
- Testing Protocols (to plan testing strategy)
- Documentation Policy (for plan format)
- Standards Discovery (for finding standards)

**Output**:
- Implementation plan with captured standards

```
/plan → [Discover All Standards] → plan.md
              ↓
    Metadata: Standards File: CLAUDE.md
              Code Style: ...
              Test Commands: ...
```

### Phase 2: Implementation

#### /implement Command
**Standards Usage**: Application and Enforcement (CRITICAL)

**What it does**:
- Discovers CLAUDE.md standards
- Reads standards from plan metadata
- Applies code standards during generation
- Verifies compliance before commits
- Uses test commands from testing protocols

**Standards Used**:
- Code Standards (apply style, naming, error handling)
- Testing Protocols (run tests after each phase)
- Documentation Policy (document code)
- Standards Discovery (find and merge standards)

**Output**:
- Generated code following standards
- Passing tests
- Updated plan with completion markers

```
/implement → [Code Standards] → generated_code.lua
                ↓
           [Apply Style]
                ↓
         [Testing Protocols] → run tests
                ↓
        [Verify Compliance]
                ↓
           git commit
```

### Phase 3: Verification

#### /test Command
**Standards Usage**: Test Execution

**What it does**:
- Discovers test commands from CLAUDE.md
- Runs tests using discovered commands
- Reports results

**Standards Used**:
- Testing Protocols (primary - test commands, patterns)
- Standards Discovery (find testing protocols)

**Output**:
- Test results
- Coverage reports (if configured)

```
/test → [Testing Protocols] → `:TestSuite`
             ↓
    Test Commands: :TestNearest, :TestFile, :TestSuite
             ↓
      Execute and Report
```

#### /refactor Command
**Standards Usage**: Validation and Analysis

**What it does**:
- Analyzes code against CLAUDE.md standards
- Identifies violations and improvements
- Creates refactoring report

**Standards Used**:
- Code Standards (validate against)
- Testing Protocols (ensure tests exist)
- Documentation Policy (check documentation)

**Output**:
- Refactoring report with violations and recommendations

```
/refactor → [All Standards] → analyze code
                 ↓
           Find violations
                 ↓
       refactoring_report.md
```

### Phase 4: Documentation

#### /document Command
**Standards Usage**: Documentation Generation

**What it does**:
- Discovers documentation policy from CLAUDE.md
- Updates all relevant documentation
- Ensures compliance with policy

**Standards Used**:
- Documentation Policy (primary - README requirements, format)
- Code Standards (understand code to document)
- Standards Discovery (find documentation policy)

**Output**:
- Updated README files
- Updated module documentation
- Compliance summary

```
/document → [Documentation Policy] → README.md
                  ↓
         README Requirements:
         - Purpose
         - Module Documentation
         - Usage Examples
         - Navigation Links
                  ↓
        Create/Update docs
```

### Phase 5: Setup and Maintenance

#### /setup Command
**Standards Usage**: Generation and Configuration

**What it does**:
- Creates or updates CLAUDE.md
- Configures standards sections
- Ensures structure is parseable by other commands

**Standards Used**:
- Standards Discovery (defines how others discover)
- All standard sections (generates templates)

**Output**:
- CLAUDE.md with parseable sections
- Linked auxiliary files (if needed)

```
/setup → Analyze project
            ↓
     Generate CLAUDE.md:
     - Code Standards section
     - Testing Protocols section
     - Documentation Policy section
     - Standards Discovery section
            ↓
  Validate parseability
```

## Standards Flow Matrix

| Command | Discovers Standards | Uses Standards | Generates Standards | Validates Standards |
|---------|-------------------|----------------|--------------------|--------------------|
| /report | Minimal | Documentation | No | No |
| /plan | Yes | All | Captures | No |
| /implement | Yes | Code, Testing | No | Compliance checks |
| /test | Yes | Testing | No | Execution |
| /test-all | Yes | Testing | No | Execution |
| /document | Yes | Documentation | No | Policy compliance |
| /refactor | Yes | All | No | Full validation |
| /setup | N/A | N/A | Yes | Parseability |
| /debug | Yes | Code, Testing | No | Analysis |
| /orchestrate | Yes | All | No | Ensures subagents follow |

## Integration Points

### Point 1: Plan Creation → Implementation

```
User: /plan "Add user authentication"
      ↓
/plan discovers CLAUDE.md:
  - Code Standards: snake_case, 2 spaces, pcall
  - Testing Protocols: :TestSuite
  - Documentation: README required
      ↓
Plan metadata captures:
  - Standards File: /project/CLAUDE.md
  - Code Style: snake_case, 2 spaces
  - Test Command: :TestSuite
      ↓
User: /implement auth_plan.md
      ↓
/implement reads plan + discovers CLAUDE.md:
  - Confirms standards from plan
  - Applies code standards to generated code
  - Runs :TestSuite after each phase
```

### Point 2: Implementation → Testing

```
/implement Phase 1 complete:
  - Generated auth.lua (using code standards)
  - Ready to test
      ↓
/implement discovers Testing Protocols:
  - Test Commands: :TestSuite
  - Test Pattern: *_spec.lua
      ↓
Run: nvim --headless -c ":TestSuite" -c "qa"
      ↓
Tests pass → Mark phase complete → Commit
```

### Point 3: Implementation → Documentation

```
/implement all phases complete:
  - auth.lua, session.lua created
  - Tests passing
      ↓
User: /document "Added authentication system"
      ↓
/document discovers Documentation Policy:
  - README Requirements: Purpose, Modules, Usage
  - Format: CommonMark, no emojis
      ↓
Updates:
  - src/auth/README.md (new)
  - src/README.md (add auth section)
  - Main README.md (mention authentication)
```

### Point 4: Validation Loop

```
/refactor src/auth
      ↓
Discovers all standards:
  - Code: snake_case, 2 spaces, pcall
  - Testing: coverage >80%
  - Documentation: README per directory
      ↓
Analyzes code:
  - ✓ Naming: all functions snake_case
  - ✓ Indentation: consistent 2 spaces
  - ✗ Testing: only 65% coverage
  - ✗ Documentation: Missing usage examples
      ↓
Creates report:
  - High Priority: Increase test coverage
  - Medium Priority: Add usage examples to README
```

## Error Handling Flow

### Missing CLAUDE.md

```
Command runs
     ↓
Search for CLAUDE.md
     ↓
Not found
     ↓
Log: "CLAUDE.md not found"
     ↓
Use fallback defaults:
  - Language-specific defaults
  - Common conventions
     ↓
Suggest: "Run /setup to create CLAUDE.md"
     ↓
Continue with graceful degradation
```

### Incomplete CLAUDE.md

```
Command runs
     ↓
Find CLAUDE.md
     ↓
Parse sections
     ↓
Missing "Testing Protocols" section
     ↓
Log: "Testing Protocols section not found"
     ↓
Fallback:
  - Check for package.json (npm test)
  - Check for Makefile (make test)
  - Check for pytest.ini (pytest)
     ↓
Continue with discovered or default tests
```

### Subdirectory Override

```
Command runs in src/frontend/
     ↓
Find CLAUDE.md files:
  - src/frontend/CLAUDE.md ✓
  - CLAUDE.md ✓
     ↓
Parse both:
  - frontend: Line Length: 80 chars
  - root: Line Length: 100 chars
     ↓
Merge (frontend overrides):
  - Use 80 chars for frontend code
  - Inherit other standards from root
     ↓
Apply merged standards
```

## Best Practices

### For Command Developers

1. **Always Discover**: Every command should discover CLAUDE.md (don't assume it exists)
2. **Check Multiple Levels**: Look for both root and subdirectory CLAUDE.md
3. **Merge Properly**: Subdirectory standards override parent standards
4. **Handle Missing Gracefully**: Provide sensible fallbacks
5. **Document What You Use**: Clearly state which sections your command uses
6. **Verify Before Commit**: Check standards compliance before marking complete

### For Users

1. **Create CLAUDE.md**: Run `/setup` to create project standards
2. **Use Subdirectory Standards**: Create scoped standards for specific areas
3. **Keep Updated**: Update CLAUDE.md as project evolves
4. **Trust the Flow**: Commands will discover and apply standards automatically
5. **Validate Regularly**: Run `/refactor` to check standards compliance

## Command Interaction Examples

### Example 1: Full Workflow

```bash
# 1. Research phase
/report "How to implement OAuth2 authentication"
# Creates: specs/reports/034_oauth2_implementation.md

# 2. Planning phase (discovers standards)
/plan "Implement OAuth2 authentication" specs/reports/034_oauth2_implementation.md
# Creates: specs/plans/002_oauth2_authentication.md
# Captures: Standards File: CLAUDE.md, Code Style, Test Commands

# 3. Implementation phase (applies standards)
/implement specs/plans/002_oauth2_authentication.md
# Generates: auth/oauth2.lua (following code standards)
# Runs: :TestSuite (from testing protocols)
# Commits: Each phase with compliance verification

# 4. Testing phase (uses test standards)
/test auth/oauth2.lua
# Runs: :TestFile (discovered from CLAUDE.md)

# 5. Documentation phase (follows doc policy)
/document "Implemented OAuth2 authentication"
# Updates: auth/README.md (following documentation policy)

# 6. Validation phase (checks all standards)
/refactor auth/
# Validates: Code standards, test coverage, documentation
```

### Example 2: Fix and Iterate

```bash
# Find issues
/refactor auth/session.lua
# Report: Naming violations, missing tests

# Fix issues
/implement fix_session_standards.md
# Applies: Code standards for naming
# Adds: Tests (following testing protocols)

# Verify fixes
/test auth/session.lua
# Runs: Tests (discovered from CLAUDE.md)
# Result: All tests pass

# Update docs
/document "Fixed session module standards compliance"
# Updates: Documentation (following policy)
```

## References

- [Standards Integration Pattern](standards-integration-pattern.md) - How to integrate standards
- [CLAUDE.md Section Schema](claude-md-section-schema.md) - Section formats
- [Standards Integration Examples](standards-integration-examples.md) - Concrete examples
- Root CLAUDE.md - Project standards
- Command files in .claude/commands/ - Individual command documentation
