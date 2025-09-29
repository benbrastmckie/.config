---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory]
description: Cleanup and optimize CLAUDE.md by extracting detailed sections into organized auxiliary files
command-type: primary
dependent-commands: validate-setup
---

# Cleanup CLAUDE.md

I'll create or improve the CLAUDE.md file by intelligently organizing content - keeping it concise by extracting detailed sections into auxiliary files when appropriate.

## Target Directory
$1 (or current directory)

## Process

### 1. Analyze Existing CLAUDE.md
First, I'll examine any existing CLAUDE.md to identify:
- Sections that are overly detailed (>50 lines)
- Inline standards that could be extracted
- Testing configurations embedded directly
- Long code examples or templates
- Repetitive documentation patterns

### 2. Smart Section Extraction
I'll offer to extract these types of content into dedicated files:

#### Candidates for Extraction
| Section Type | Target File | When to Extract |
|-------------|------------|-----------------|
| Testing Standards | `docs/TESTING_STANDARDS.md` | >20 lines of test config |
| Code Style Guide | `docs/CODE_STYLE.md` | Detailed formatting rules |
| Documentation Templates | `docs/DOCUMENTATION.md` | Multiple template examples |
| Command Reference | `docs/COMMANDS.md` | >10 command definitions |
| Development Workflow | `docs/WORKFLOW.md` | Multi-step processes |
| Architecture Diagrams | `docs/ARCHITECTURE.md` | Complex ASCII diagrams |
| API Guidelines | `docs/API_STANDARDS.md` | Detailed API patterns |

### 3. Interactive Extraction Process
For each extractable section, I'll:

1. **Identify the section**
   ```
   Found: Testing Standards (45 lines) in CLAUDE.md
   This section contains detailed testing protocols and commands.

   Would you like to:
   [E]xtract to docs/TESTING_STANDARDS.md and link it
   [K]eep in CLAUDE.md as-is
   [S]implify in place without extraction
   ```

2. **Show the proposed extraction**
   ```
   Current (in CLAUDE.md):
   ## Testing Standards
   [45 lines of detailed content...]

   After extraction:
   ## Testing Standards
   See [Testing Standards](docs/TESTING_STANDARDS.md) for detailed protocols.

   Quick reference:
   - Run tests: `npm test`
   - Coverage: `npm run coverage`
   ```

3. **Create the auxiliary file** with proper structure:
   ```markdown
   # Testing Standards

   [Extracted detailed content with improved formatting]

   ## Navigation
   - [← Back to CLAUDE.md](../CLAUDE.md)
   ```

### 4. CLAUDE.md Optimization Pattern

#### Before (Bloated CLAUDE.md):
```markdown
# Project Configuration

## Testing Standards
[50+ lines of test configuration, examples, CI/CD setup...]

## Code Style
[30+ lines of formatting rules, linting config...]

## Documentation
[40+ lines of templates and examples...]
```

#### After (Concise CLAUDE.md):
```markdown
# Project Configuration Index

This CLAUDE.md serves as the central configuration index for this project.

## Project Standards and Guidelines

### Core Documentation
- [Testing Standards](docs/TESTING_STANDARDS.md) - Test configuration, commands, and CI/CD setup
- [Code Style Guide](docs/CODE_STYLE.md) - Formatting rules, linting configuration
- [Documentation Guidelines](docs/DOCUMENTATION.md) - Templates and writing standards

### Quick Reference
- **Run Tests**: `npm test`
- **Format Code**: `npm run format`
- **Lint**: `npm run lint`

## Specs Directory Protocol
[Keep this inline - it's concise and essential]
```

### 5. Extraction Decision Logic

I'll recommend extraction when:
- **Section length** > 30 lines
- **Content type** is reference material (not frequently needed)
- **Multiple examples** or templates present
- **Detailed configuration** that rarely changes
- **Complex diagrams** or architecture documentation

I'll keep inline when:
- **Quick reference** commands (used daily)
- **Critical paths** to other documentation
- **Project overview** information
- **Specs protocol** (core to Claude workflow)

### 6. File Organization Structure

```
project-root/
├── CLAUDE.md                    # Concise index (goal: <100 lines)
├── docs/
│   ├── TESTING_STANDARDS.md    # Extracted testing details
│   ├── CODE_STYLE.md           # Extracted style guide
│   ├── DOCUMENTATION.md        # Extracted doc standards
│   ├── COMMANDS.md             # Extended command reference
│   ├── WORKFLOW.md             # Development processes
│   └── ARCHITECTURE.md         # System design and diagrams
└── specs/
    ├── plans/
    ├── reports/
    └── summaries/
```

### 7. Intelligent Prompting

For each extraction opportunity, I'll provide:
1. **Size comparison**: "Reduces CLAUDE.md by 45 lines (30%)"
2. **Access frequency**: "This section is typically referenced monthly"
3. **Maintainability**: "Separate file allows easier updates"
4. **Navigation impact**: "One click away, clearly linked"

### 8. Post-Extraction Validation

After extracting sections:
- Verify all links work correctly
- Ensure no information is lost
- Add navigation breadcrumbs
- Update any command references
- Test that extracted files are properly formatted

## Interactive Questions

When setting up or improving CLAUDE.md, I'll ask:

1. **Extraction Preference**
   - "Aggressive" - Extract anything >20 lines
   - "Balanced" - Extract >30 lines of reference material
   - "Minimal" - Only extract >50 lines
   - "Manual" - Ask for each section

2. **Directory Structure**
   - Use `docs/` for standards? [Y/n]
   - Create subject-specific subdirectories? [y/N]
   - Preferred naming convention? (CAPS.md vs lowercase.md)

3. **Link Style**
   - Relative paths or absolute from root?
   - Include brief descriptions with links?
   - Add "Quick Reference" sections for extracted content?

## Benefits of This Approach

### For CLAUDE.md
- **Stays focused**: Core configuration only
- **Quick scanning**: Find what you need fast
- **Easy updates**: Less content to maintain
- **Clear hierarchy**: Index pointing to details

### For Auxiliary Files
- **Deep documentation**: No length constraints
- **Better organization**: Topic-focused files
- **Version control**: Smaller, focused diffs
- **Reusability**: Can be referenced from multiple places

## Example Extraction Session

```
Analyzing existing CLAUDE.md...

Found 5 sections that could be extracted:

1. Testing Protocols (52 lines)
   → Recommend: Extract to docs/TESTING_STANDARDS.md

2. Code Style Guide (38 lines)
   → Recommend: Extract to docs/CODE_STYLE.md

3. Quick Commands (12 lines)
   → Recommend: Keep inline (frequently used)

4. ASCII Architecture Diagram (44 lines)
   → Recommend: Extract to docs/ARCHITECTURE.md

5. Specs Protocol (18 lines)
   → Recommend: Keep inline (core to Claude)

Proceed with recommended extractions? [Y/n/customize]
```

Let me analyze your project and intelligently organize your CLAUDE.md file.