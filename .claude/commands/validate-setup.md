---
allowed-tools: Read, Bash, Grep, Glob
argument-hint: [project-directory]
description: Validate CLAUDE.md setup and check all linked standards files
command-type: dependent
parent-commands: setup
---

# Validate Project Setup

I'll validate that CLAUDE.md and all linked standards files are properly configured.

## Target Directory
$1 (or current directory)

## Validation Process

### 1. CLAUDE.md Validation
I'll check that CLAUDE.md:
- Exists in the project root or appropriate location
- Contains required sections
- Has valid links to standards files
- Includes specs directory protocol
- Defines project commands

### 2. Standards Files Check
For each linked file in CLAUDE.md:
- Verify file exists
- Check file is readable
- Validate basic structure
- Ensure no broken links

### 3. Specs Directory Structure
I'll verify:
- Specs directories follow the protocol
- Proper subdirectories exist (plans/, reports/, summaries/)
- Files follow NNN_name.md convention
- Numbers are sequential without gaps

### 4. Command Validation
Test that documented commands:
- Are executable
- Have correct syntax
- Reference valid tools/scripts

### 5. Coverage Analysis
I'll identify:
- Missing standards documentation
- Undocumented project areas
- Incomplete sections in CLAUDE.md
- Orphaned specs directories

## Validation Report

```
=== CLAUDE.md Setup Validation ===

CLAUDE.md Status: [Found/Missing]
Location: [Path]

Standards Files:
✓ Code Standards: [Path] - Valid
✓ Testing Standards: [Path] - Valid
✗ Documentation Standards: Missing

Specs Directories:
- /src/feature/specs/ - Complete (plans/, reports/, summaries/)
- /lib/module/specs/ - Partial (missing summaries/)

Command Validation:
✓ Test commands verified
✗ Build command not found

Issues Found:
1. [Issue description]
2. [Issue description]

Recommendations:
- [Suggested fix]
- [Suggested improvement]

Overall Status: [VALID/NEEDS ATTENTION]
```

## Fix Suggestions

For each issue found, I'll provide:
- Specific fix commands
- Template content for missing files
- Correction for malformed sections
- Update commands for outdated content

Let me validate your project setup.