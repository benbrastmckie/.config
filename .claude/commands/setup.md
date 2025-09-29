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

#### Goal: Concise Index File (<100 lines)
```markdown
# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index.

## Project Standards and Guidelines

### Core Documentation
- [Testing Standards](docs/TESTING.md) - Test configuration and commands
- [Code Style Guide](docs/CODE_STYLE.md) - Formatting and conventions
- [Documentation Guidelines](docs/DOCUMENTATION.md) - Writing standards

### Quick Reference
- **Run Tests**: `npm test`
- **Format Code**: `npm run format`
- **Lint**: `npm run lint`

## Specs Directory Protocol
[Keep inline - essential for Claude workflow]
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

Let me analyze your project and help organize your CLAUDE.md efficiently.