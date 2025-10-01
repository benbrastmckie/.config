---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory]
description: Setup or improve CLAUDE.md with smart extraction of sections into linked auxiliary files
command-type: primary
dependent-commands: validate-setup
---

# Setup Project Standards

I'll create or improve the CLAUDE.md file by intelligently organizing content - keeping it concise by extracting detailed sections into auxiliary files when appropriate.

## Target Directory
$1 (or current directory)

## Standards for Commands

When creating or updating CLAUDE.md, I'll ensure it's optimized for discovery and use by other slash commands:

### Command Integration Requirements

#### Required Sections with Metadata
All generated CLAUDE.md files will include:

1. **Code Standards** section
   - `[Used by: /implement, /refactor, /plan]` metadata
   - Indentation, line length, naming conventions
   - Error handling patterns
   - Language-specific standards

2. **Testing Protocols** section
   - `[Used by: /test, /test-all, /implement]` metadata
   - Test commands and patterns
   - Coverage requirements
   - Test discovery rules

3. **Documentation Policy** section
   - `[Used by: /document, /plan]` metadata
   - README requirements
   - Documentation format guidelines
   - Character encoding rules

4. **Standards Discovery** section
   - `[Used by: all commands]` metadata
   - Discovery method explanation
   - Subdirectory inheritance rules
   - Fallback behavior

#### Section Format
Each section must follow the parseable schema:

```markdown
## Section Name
[Used by: /command1, /command2]

### Subsection
- **Field Name**: value
- **Another Field**: value
```

### Project Type Detection
I'll detect project type and generate appropriate standards:

- **Lua/Neovim**: 2-space indent, snake_case, pcall error handling, `:TestSuite`
- **JavaScript/Node**: 2-space indent, camelCase, try-catch, `npm test`
- **Python**: 4-space indent, snake_case, try-except, `pytest`
- **Shell**: 2-space indent, snake_case, `set -e`, shellcheck

### Validation
After generation, I'll validate that:
- All required sections exist
- Each section has `[Used by: ...]` metadata
- Field format is consistent (`**Field**: value`)
- Commands can parse the structure

## Process

### 1. Analyze Existing CLAUDE.md
I'll examine any existing CLAUDE.md to identify:
- Sections that are overly detailed (>30 lines)
- Inline standards that could be extracted
- Testing configurations embedded directly
- Long code examples or templates
- Content better suited for auxiliary files

### 2. Smart Section Extraction

For sections that would benefit from extraction, I'll offer to move them to dedicated files:

| Section Type | Suggested File | Extraction Trigger |
|-------------|---------------|-------------------|
| Testing Standards | `docs/TESTING.md` | >20 lines of test details |
| Code Style Guide | `docs/CODE_STYLE.md` | Detailed formatting rules |
| Documentation Guide | `docs/DOCUMENTATION.md` | Template examples |
| Command Reference | `docs/COMMANDS.md` | >10 commands |
| Architecture | `docs/ARCHITECTURE.md` | Complex diagrams |

### 3. Interactive Extraction Process

For each extractable section, I'll ask:

```
Found: Testing Standards (45 lines) in CLAUDE.md

Would you like to:
[E]xtract to docs/TESTING.md and link it
[K]eep in CLAUDE.md as-is
[S]implify in place without extraction
```

If you choose extraction, I'll:
1. Create the auxiliary file with the content
2. Replace the section in CLAUDE.md with a concise summary and link
3. Add navigation links between files

### 4. Optimal CLAUDE.md Structure

#### Goal: Command-Parseable Standards File
```markdown
# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index.

## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: [detected or user-specified]
- **Line Length**: [detected or default]
- **Naming**: [language-appropriate conventions]
- **Error Handling**: [language-specific patterns]

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
[How commands should find tests]

### [Project Type] Testing
- **Test Commands**: [detected test commands]
- **Test Pattern**: [detected test file patterns]
- **Coverage Requirements**: [suggested thresholds]

## Documentation Policy
[Used by: /document, /plan]

### README Requirements
[Standard requirements for documentation]

## Standards Discovery
[Used by: all commands]

### Discovery Method
[Standard discovery explanation]

## Specs Directory Protocol
[Kept inline - essential for spec workflow]
```

### 5. Decision Criteria

I'll recommend extraction when:
- Section is >30 lines of detailed content
- Content is reference material (not daily use)
- Multiple examples or templates present
- Complex configuration rarely changed

I'll keep inline when:
- Quick reference commands (<10 lines)
- Critical navigation/index information
- Specs protocol (core to Claude)
- Daily-use information

### 6. File Organization

```
project/
├── CLAUDE.md              # Concise index
├── docs/
│   ├── TESTING.md        # Extracted test details
│   ├── CODE_STYLE.md     # Extracted style guide
│   └── ...               # Other extracted sections
└── specs/
    ├── plans/
    ├── reports/
    └── summaries/
```

### 7. Benefits

**Concise CLAUDE.md:**
- Quick to scan and navigate
- Focuses on essential info
- Easy to maintain
- Clear hierarchy

**Auxiliary Files:**
- Detailed documentation without length constraints
- Topic-focused organization
- Better version control (smaller diffs)
- Can be referenced from multiple places

## Interactive Setup

I'll ask about your preferences:

1. **Extraction threshold**:
   - Aggressive (>20 lines)
   - Balanced (>30 lines)
   - Conservative (>50 lines)

2. **Directory structure**:
   - Use `docs/` for standards?
   - Preferred file naming?

3. **Content to prioritize for extraction**:
   - Testing details?
   - Code style rules?
   - Architecture diagrams?
   - Command references?

## Example Session

```
Analyzing CLAUDE.md... Found 248 lines.

Extraction opportunities:
1. Testing Standards (52 lines) → docs/TESTING.md
2. Code Style (38 lines) → docs/CODE_STYLE.md
3. Architecture Diagram (44 lines) → docs/ARCHITECTURE.md

After extraction: CLAUDE.md would be 95 lines (62% reduction)

Proceed with extractions? [Y/n/customize]
```

## Integration with Other Commands

### How /setup Supports Other Commands

This command creates the foundation that other commands rely on:

#### For /implement
- Generates **Code Standards** section with indentation, naming, error handling
- Creates **Testing Protocols** section with test commands
- Ensures standards are parseable for automatic application

#### For /test
- Generates **Testing Protocols** section with test commands and patterns
- Detects project test framework and configuration
- Documents test discovery rules

#### For /document
- Generates **Documentation Policy** section with README requirements
- Sets format guidelines and character encoding rules
- Defines navigation link patterns

#### For /plan
- Creates all standard sections for plan generation
- Documents project conventions for accurate planning
- Ensures plans can capture standards properly

#### For /refactor
- Generates comprehensive standards for validation
- Documents code quality thresholds
- Provides clear validation criteria

### Standards Generation Workflow

```
User runs: /setup
     ↓
/setup analyzes project:
  - Detects language (Lua, JS, Python, etc.)
  - Finds test framework
  - Identifies existing conventions
     ↓
Generates CLAUDE.md with:
  - Code Standards (with [Used by: ...] metadata)
  - Testing Protocols (with test commands)
  - Documentation Policy (with requirements)
  - Standards Discovery (with discovery rules)
     ↓
Validates parseability:
  - Checks all sections have metadata
  - Verifies field format consistency
  - Tests that commands can parse structure
     ↓
Result: CLAUDE.md optimized for command integration
```

### Example: Generated Standards

For a Lua/Neovim project, /setup would generate:

```markdown
## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for modules
- **Error Handling**: Use pcall for operations that might fail

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua`
- **Test Framework**: plenary.nvim, busted
```

These sections are immediately usable by /implement, /test, and other commands.

Let me analyze your project and help organize your CLAUDE.md efficiently.