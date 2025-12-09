# Phase 4: Advanced Capabilities - Detailed Expansion

**Parent Plan**: [Three-Tier Agent Pattern Improvements](../001-three-tier-agent-improvements-plan.md)

## Phase Overview

**Objective**: Implement doc-analyzer and code-reviewer skills for autonomous quality enforcement, and standardize checkpoint format v3.0 for cross-command resumption

**Complexity**: High

**Dependencies**: Phase 3 (Skills Expansion must be complete with research-specialist, plan-generator, and test-orchestrator skills operational)

**Expected Duration**: 26-34 hours

---

## Stage 1: Doc-Analyzer Skill Implementation [8-10 hours]

### Objective

Create doc-analyzer skill with README structure validation, cross-reference link checking, and documentation gap detection for autonomous quality enforcement on doc file changes.

### Implementation Steps

#### Step 1.1: Create Skill Directory Structure

**File**: `.claude/skills/doc-analyzer/`

```bash
# Create skill directory with standard structure
mkdir -p .claude/skills/doc-analyzer/{scripts,templates}

# Verify directory exists
test -d .claude/skills/doc-analyzer
```

**Deliverable**: Skill directory structure created

#### Step 1.2: Create SKILL.md with Validation Capabilities

**File**: `.claude/skills/doc-analyzer/SKILL.md`

**Required Sections**:

1. **YAML Frontmatter**:
```yaml
---
name: doc-analyzer
description: Analyze documentation quality including README structure validation, cross-reference link checking, and documentation gap detection. Triggers on doc file changes.
allowed-tools: Bash, Read, Glob, Grep
model: haiku-4.5
model-justification: Simple validation patterns, no complex reasoning needed
fallback-model: sonnet-4.5
---
```

2. **Core Instructions** (< 500 lines total):
   - **README Structure Validation**:
     - Parse documentation-standards.md for required README sections
     - Validate section hierarchy (Purpose → Module Documentation → Usage → Navigation)
     - Check for directory classification (Active Development, Utility, Temporary, Archive)
     - Verify section presence based on directory type
   - **Cross-Reference Link Checking**:
     - Extract markdown links using regex: `\[([^\]]+)\]\(([^\)]+)\)`
     - Distinguish internal vs external links (http:// prefix)
     - For internal links, resolve relative paths from document location
     - Validate target files exist using Bash test -f
     - Report broken links with source file, line number, and target path
   - **Documentation Gap Detection**:
     - Identify missing module documentation (files without corresponding README entries)
     - Check for outdated content markers (e.g., "TODO", "FIXME", "DEPRECATED")
     - Validate code examples have syntax highlighting (triple backtick with language)
     - Check for empty sections (headings with no content)
   - **Autonomous Invocation Detection**:
     - Trigger keywords: "documentation quality", "README validation", "link checking", "doc analysis"
     - Auto-trigger on doc file changes (*.md files in .claude/docs/, .claude/agents/, .claude/commands/)
   - **Explicit Invocation Path**:
     - Callable via `/doc-check` command for manual validation runs
     - Accept directory path argument for scoped analysis
   - **Output Format**:
     - Report structure: Summary → Structure Issues → Broken Links → Documentation Gaps
     - Use severity levels: ERROR (blocking), WARNING (non-blocking), INFO (recommendations)
     - Include file paths and line numbers for all issues

**Validation Patterns**:

```bash
# README structure validation pattern
README_SECTIONS_REQUIRED=("Purpose" "Navigation Links")
README_SECTIONS_ACTIVE_DEV=("Module Documentation" "Usage Examples")

validate_readme_structure() {
  local readme_file="$1"
  local directory_type="$2"  # active, utility, temporary, archive

  # Extract section headings
  local sections=$(grep "^## " "$readme_file" | sed 's/^## //')

  # Check required sections
  for section in "${README_SECTIONS_REQUIRED[@]}"; do
    if ! echo "$sections" | grep -q "^$section$"; then
      echo "ERROR: Missing required section: $section in $readme_file"
    fi
  done

  # Check active development sections
  if [ "$directory_type" = "active" ]; then
    for section in "${README_SECTIONS_ACTIVE_DEV[@]}"; do
      if ! echo "$sections" | grep -q "^$section$"; then
        echo "WARNING: Missing recommended section: $section in $readme_file"
      fi
    done
  fi
}
```

```bash
# Link validation pattern
validate_markdown_links() {
  local doc_file="$1"
  local doc_dir=$(dirname "$doc_file")

  # Extract links: [text](path)
  grep -oP '\[([^\]]+)\]\(([^\)]+)\)' "$doc_file" | while read -r link; do
    local link_text=$(echo "$link" | grep -oP '\[\K[^\]]+')
    local link_path=$(echo "$link" | grep -oP '\(\K[^\)]+')

    # Skip external links
    if [[ "$link_path" =~ ^https?:// ]]; then
      continue
    fi

    # Resolve relative path
    local resolved_path="$doc_dir/$link_path"
    resolved_path=$(realpath -m "$resolved_path" 2>/dev/null || echo "$resolved_path")

    # Check file exists
    if [ ! -f "$resolved_path" ]; then
      local line_num=$(grep -n "$link" "$doc_file" | head -1 | cut -d: -f1)
      echo "ERROR: Broken link in $doc_file:$line_num -> $link_path (resolved: $resolved_path)"
    fi
  done
}
```

**Size Constraint**: Total SKILL.md < 500 lines (progressive disclosure requirement)

**Deliverable**: SKILL.md created with validation logic

#### Step 1.3: Create Skill Documentation

**File**: `.claude/skills/doc-analyzer/README.md`

**Required Sections**:
- Purpose: Documentation quality analysis and validation
- Capabilities: README validation, link checking, gap detection
- Usage Examples: Autonomous vs explicit invocation
- Integration: Auto-trigger on doc changes, manual via `/doc-check`
- Validation Patterns: Examples of each validation type

**Deliverable**: README.md created with usage guidance

#### Step 1.4: Update Skills Catalog

**File**: `.claude/skills/README.md`

**Edit**:
```markdown
Old:
## Available Skills

### [document-converter](document-converter/README.md)
...

New:
## Available Skills

### [document-converter](document-converter/README.md)
...

### [doc-analyzer](doc-analyzer/README.md)

**Description**: Analyze documentation quality including README structure validation, cross-reference link checking, and documentation gap detection.

**Use When**: Validating documentation changes, checking for broken links, ensuring README compliance with standards.

**Capabilities**:
- README structure validation per documentation-standards.md
- Cross-reference link checking (internal links only)
- Documentation gap detection (missing modules, outdated content)
- Autonomous invocation on doc file changes
- Explicit invocation via `/doc-check` command

**Integration**:
- Autonomous: Claude auto-invokes when doc quality needs detected
- Command: `/doc-check` delegates to skill
- Auto-triggers after doc file modifications
```

**Deliverable**: Skills catalog updated with doc-analyzer entry

### Testing

```bash
# Test 1: Verify skill structure
test -f .claude/skills/doc-analyzer/SKILL.md
test -f .claude/skills/doc-analyzer/README.md

# Test 2: Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('.claude/skills/doc-analyzer/SKILL.md').read().split('---')[1])"

# Test 3: Check size constraint
LINES=$(wc -l < .claude/skills/doc-analyzer/SKILL.md)
if [ "$LINES" -ge 500 ]; then
  echo "ERROR: SKILL.md exceeds 500 lines ($LINES)"
  exit 1
fi
echo "Size OK: $LINES lines"

# Test 4: Validate name field matches directory
NAME=$(grep "^name:" .claude/skills/doc-analyzer/SKILL.md | awk '{print $2}')
if [ "$NAME" != "doc-analyzer" ]; then
  echo "ERROR: name field ($NAME) doesn't match directory (doc-analyzer)"
  exit 1
fi

# Test 5: Test README validation pattern (create test README with missing sections)
cat > /tmp/test_readme.md <<'EOF'
# Test README

## Purpose
This is a test.

## Navigation Links
- [Parent](../README.md)
EOF

# Run validation (should report missing Module Documentation for active directory)
# Manual test: source SKILL.md validation functions and test

# Test 6: Test link validation pattern (create doc with broken link)
cat > /tmp/test_doc.md <<'EOF'
# Test Document

See [broken link](./nonexistent.md) for details.
EOF

# Run link validation (should report broken link)
# Manual test: source SKILL.md validation functions and test

echo "✓ Doc-analyzer skill tests passed"
```

### Success Criteria

- [ ] Skill directory created at `.claude/skills/doc-analyzer/`
- [ ] SKILL.md under 500 lines with all validation patterns
- [ ] YAML frontmatter valid with correct name field
- [ ] README structure validation detects missing sections
- [ ] Link validation detects broken internal links
- [ ] Gap detection identifies missing module documentation
- [ ] Skills catalog updated with doc-analyzer entry

---

## Stage 2: Doc-Check Command Implementation [3-4 hours]

### Objective

Create `/doc-check` command for explicit doc-analyzer skill invocation with directory path argument and quality report display.

### Implementation Steps

#### Step 2.1: Create Command File

**File**: `.claude/commands/doc-check.md`

**Required Sections**:

1. **YAML Frontmatter**:
```yaml
---
description: Validate documentation quality using doc-analyzer skill
usage: /doc-check [directory-path]
---
```

2. **Command Structure** (following command-authoring standards):

**Block 1: Argument Capture**
```bash
# Argument 1: directory path (default: .claude/docs/)
TARGET_DIR="${1:-.claude/docs/}"

# Validate directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: Directory not found: $TARGET_DIR"
  exit 1
fi

echo "Analyzing documentation in: $TARGET_DIR"
```

**Block 2: Skill Invocation via Skill Tool**
```markdown
**EXECUTE NOW**: USE the Skill tool to invoke doc-analyzer.

Skill {
  skill: "doc-analyzer"
}

After skill loads, execute documentation analysis:

1. Scan all markdown files in $TARGET_DIR recursively
2. For each file, run:
   - README structure validation (if README.md)
   - Cross-reference link checking
   - Documentation gap detection
3. Aggregate results by severity (ERROR, WARNING, INFO)
4. Display quality report with summary

Quality Report Format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Documentation Quality Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
- Files Analyzed: N
- Errors: X
- Warnings: Y
- Info: Z

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Structure Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List of README structure violations]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Broken Links
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List of broken internal links with file:line references]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Documentation Gaps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List of missing documentation, outdated content markers]
```
```

**Block 3: Error Logging Integration**
```bash
# Source error handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/doc-check"
WORKFLOW_ID="doc_check_$(date +%s)"
USER_ARGS="$*"

# If skill invocation failed, log error
if [ $? -ne 0 ]; then
  log_command_error "agent_error" "Doc-analyzer skill invocation failed" "Target: $TARGET_DIR"
  exit 1
fi

echo "✓ Documentation quality check complete"
```

**Deliverable**: Command file created

#### Step 2.2: Update Command Reference

**File**: `.claude/docs/reference/standards/command-reference.md`

**Edit**: Add `/doc-check` entry to command catalog

```markdown
### /doc-check [directory-path]

**Description**: Validate documentation quality using doc-analyzer skill

**Usage**:
- `/doc-check` - Analyze .claude/docs/ (default)
- `/doc-check .claude/agents/` - Analyze agents documentation
- `/doc-check nvim/docs/` - Analyze Neovim documentation

**Capabilities**:
- README structure validation per documentation-standards.md
- Cross-reference link checking (internal links)
- Documentation gap detection
- Quality report with severity levels

**Output**: Quality report with errors, warnings, and recommendations
```

**Deliverable**: Command reference updated

### Testing

```bash
# Test 1: Command exists and has valid frontmatter
test -f .claude/commands/doc-check.md
grep -q "^description:" .claude/commands/doc-check.md

# Test 2: Test with valid directory (should succeed)
# Manual test: /doc-check .claude/docs/

# Test 3: Test with invalid directory (should error)
# /doc-check /nonexistent/path
# Expected: ERROR: Directory not found

# Test 4: Verify command reference updated
grep -q "/doc-check" .claude/docs/reference/standards/command-reference.md

# Test 5: Test error logging integration
# Manual test: trigger skill error and verify error logged to .claude/data/logs/error_log.jsonl

echo "✓ Doc-check command tests passed"
```

### Success Criteria

- [ ] Command file created at `.claude/commands/doc-check.md`
- [ ] Default directory argument works (.claude/docs/)
- [ ] Custom directory argument works
- [ ] Invalid directory triggers error with helpful message
- [ ] Quality report displays with correct format
- [ ] Error logging integration works
- [ ] Command reference updated with `/doc-check` entry

---

## Stage 3: Code-Reviewer Skill Implementation [8-10 hours]

### Objective

Create code-reviewer skill with linting integration (shellcheck, luacheck), complexity analysis, and security pattern detection for autonomous quality enforcement after implementation.

### Implementation Steps

#### Step 3.1: Create Skill Directory Structure

**File**: `.claude/skills/code-reviewer/`

```bash
# Create skill directory
mkdir -p .claude/skills/code-reviewer/{scripts,templates}

# Verify directory exists
test -d .claude/skills/code-reviewer
```

**Deliverable**: Skill directory structure created

#### Step 3.2: Create SKILL.md with Review Capabilities

**File**: `.claude/skills/code-reviewer/SKILL.md`

**Required Sections**:

1. **YAML Frontmatter**:
```yaml
---
name: code-reviewer
description: Automated code quality review including linting (shellcheck, luacheck), complexity analysis, and security pattern detection. Triggers after implementation phases.
allowed-tools: Bash, Read, Glob, Grep
dependencies:
  - shellcheck>=0.8.0
  - luacheck>=1.0.0
model: haiku-4.5
model-justification: Pattern matching and linting integration, no complex reasoning needed
fallback-model: sonnet-4.5
---
```

2. **Core Instructions** (< 500 lines total):

   - **Linting Integration**:
     - **Bash Linting** (shellcheck):
       ```bash
       # Run shellcheck on bash files
       find_bash_files() {
         find "$1" -type f \( -name "*.sh" -o -name "*.bash" \)
       }

       lint_bash_file() {
         local file="$1"
         # Run shellcheck with standard options
         shellcheck -f gcc "$file" 2>&1 || true
         # Format: file:line:column: severity: message [SC code]
       }
       ```
     - **Lua Linting** (luacheck):
       ```bash
       # Run luacheck on lua files
       find_lua_files() {
         find "$1" -type f -name "*.lua"
       }

       lint_lua_file() {
         local file="$1"
         # Run luacheck with standard options
         luacheck --formatter plain "$file" 2>&1 || true
         # Format: file:line:column: severity message
       }
       ```
     - **Aggregate Linting Results**:
       - Group by severity: ERROR, WARNING
       - Count violations per file
       - Identify top violation patterns (e.g., SC2086, W212)

   - **Complexity Analysis**:
     - **Cyclomatic Complexity** (bash functions):
       ```bash
       # Calculate cyclomatic complexity for bash functions
       analyze_bash_complexity() {
         local file="$1"
         # Count decision points: if, elif, case, while, for, &&, ||
         local function_name=""
         local complexity=1

         while IFS= read -r line; do
           # Detect function start: function_name() {
           if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
             function_name="${BASH_REMATCH[1]}"
             complexity=1
           fi

           # Count decision points
           if [[ "$line" =~ (if|elif|while|for|case|\&\&|\|\|) ]]; then
             complexity=$((complexity + 1))
           fi

           # Detect function end: }
           if [[ "$line" =~ ^} ]] && [ -n "$function_name" ]; then
             if [ "$complexity" -gt 10 ]; then
               echo "WARNING: High complexity in $file:$function_name (complexity: $complexity)"
             fi
             function_name=""
             complexity=1
           fi
         done < "$file"
       }
       ```
     - **Function Length Thresholds**:
       ```bash
       # Check function length (lines)
       check_function_length() {
         local file="$1"
         local max_lines=50  # Threshold

         # Extract functions and count lines
         awk '/^[a-zA-Z_][a-zA-Z0-9_]*\(\)/ { fname=$1; start=NR }
              /^}/ && fname {
                length=NR-start
                if (length > '$max_lines') {
                  print "WARNING: Long function in '$file':" fname " (" length " lines)"
                }
                fname=""
              }' "$file"
       }
       ```
     - **Thresholds**:
       - Cyclomatic complexity > 10: WARNING
       - Function length > 50 lines: WARNING
       - File length > 500 lines: INFO

   - **Security Pattern Detection**:
     - **Common Vulnerabilities**:
       ```bash
       # Detect security anti-patterns
       detect_security_issues() {
         local file="$1"

         # Pattern 1: Unquoted variables (command injection risk)
         grep -n '\$[A-Z_][A-Z0-9_]*[^"]' "$file" | while read -r match; do
           echo "WARNING: Potential command injection in $file: $match"
         done

         # Pattern 2: eval usage (code injection risk)
         grep -n 'eval ' "$file" | while read -r match; do
           echo "ERROR: Unsafe eval usage in $file: $match"
         done

         # Pattern 3: Temp file without mktemp (race condition risk)
         grep -n '/tmp/[^$]' "$file" | while read -r match; do
           if ! echo "$match" | grep -q 'mktemp'; then
             echo "WARNING: Hardcoded temp file in $file: $match"
           fi
         done

         # Pattern 4: Disabled error handling (set +e, || true without justification)
         grep -n 'set +e\||| true' "$file" | while read -r match; do
           echo "INFO: Error suppression detected in $file: $match (verify justification)"
         done
       }
       ```
     - **Security Checklist**:
       - Command injection: Unquoted variables in command contexts
       - Code injection: eval, source of user input
       - Race conditions: Hardcoded temp files without mktemp
       - Error suppression: set +e, || true without comments

   - **Autonomous Invocation Detection**:
     - Trigger keywords: "code review", "code quality", "linting", "security check"
     - Auto-trigger after implementation phases (when code files modified)

   - **Explicit Invocation Path**:
     - Callable via `/review` command for manual review runs
     - Accept file or directory path argument

   - **Output Format**:
     - Report structure: Summary → Linting Results → Complexity Issues → Security Findings
     - Severity levels: ERROR (blocking), WARNING (non-blocking), INFO (recommendations)
     - Include file paths, line numbers, and remediation suggestions

**Security Pattern Examples**:

| Pattern | Severity | Example | Remediation |
|---------|----------|---------|-------------|
| Unquoted variable in command | WARNING | `rm -rf $DIR` | `rm -rf "$DIR"` |
| eval usage | ERROR | `eval "$cmd"` | Avoid eval, use functions |
| Hardcoded temp file | WARNING | `/tmp/myfile` | `mktemp /tmp/myfile.XXXXXX` |
| Error suppression without comment | INFO | `command || true` | Add comment explaining why |

**Deliverable**: SKILL.md created with review logic

#### Step 3.3: Create Skill Documentation

**File**: `.claude/skills/code-reviewer/README.md`

**Required Sections**:
- Purpose: Automated code quality and security review
- Capabilities: Linting, complexity analysis, security detection
- Usage Examples: Autonomous vs explicit invocation
- Integration: Auto-trigger after implementation, manual via `/review`
- Security Patterns: Examples of each detection pattern

**Deliverable**: README.md created with usage guidance

#### Step 3.4: Update Skills Catalog

**File**: `.claude/skills/README.md`

**Edit**: Add code-reviewer entry (similar to doc-analyzer format)

**Deliverable**: Skills catalog updated with code-reviewer entry

### Testing

```bash
# Test 1: Verify skill structure
test -f .claude/skills/code-reviewer/SKILL.md
test -f .claude/skills/code-reviewer/README.md

# Test 2: Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('.claude/skills/code-reviewer/SKILL.md').read().split('---')[1])"

# Test 3: Check size constraint
LINES=$(wc -l < .claude/skills/code-reviewer/SKILL.md)
if [ "$LINES" -ge 500 ]; then
  echo "ERROR: SKILL.md exceeds 500 lines ($LINES)"
  exit 1
fi

# Test 4: Test shellcheck integration (create test bash file with violations)
cat > /tmp/test_shellcheck.sh <<'EOF'
#!/usr/bin/env bash
# Test file with shellcheck violations

DIR=/tmp/test
rm -rf $DIR  # SC2086: Unquoted variable

eval "$1"  # SC2294: eval usage

if [ $? -eq 0 ]  # SC2181: Use if directly
then
  echo "Success"
fi
EOF

# Run shellcheck (should detect violations)
shellcheck /tmp/test_shellcheck.sh

# Test 5: Test complexity analysis (create high-complexity function)
cat > /tmp/test_complexity.sh <<'EOF'
#!/usr/bin/env bash

complex_function() {
  if [ "$1" = "a" ]; then
    if [ "$2" = "b" ]; then
      if [ "$3" = "c" ]; then
        if [ "$4" = "d" ]; then
          if [ "$5" = "e" ]; then
            if [ "$6" = "f" ]; then
              echo "Too complex"
            fi
          fi
        fi
      fi
    fi
  fi
}
EOF

# Manual test: source SKILL.md complexity analysis and test

# Test 6: Test security pattern detection
cat > /tmp/test_security.sh <<'EOF'
#!/usr/bin/env bash

# Pattern 1: Unquoted variable
rm -rf $TEMP_DIR

# Pattern 2: eval usage
eval "$USER_INPUT"

# Pattern 3: Hardcoded temp file
echo "data" > /tmp/myfile

# Pattern 4: Error suppression
some_command || true
EOF

# Manual test: source SKILL.md security detection and test

echo "✓ Code-reviewer skill tests passed"
```

### Success Criteria

- [ ] Skill directory created at `.claude/skills/code-reviewer/`
- [ ] SKILL.md under 500 lines with all review patterns
- [ ] Shellcheck integration detects bash violations
- [ ] Luacheck integration detects lua violations (if available)
- [ ] Complexity analysis detects high-complexity functions
- [ ] Security pattern detection identifies common vulnerabilities
- [ ] Skills catalog updated with code-reviewer entry

---

## Stage 4: Review Command Implementation [3-4 hours]

### Objective

Create `/review` command for explicit code-reviewer skill invocation with file/directory path argument and quality report display.

### Implementation Steps

#### Step 4.1: Create Command File

**File**: `.claude/commands/review.md`

**Structure**: Similar to `/doc-check` but for code review

**Required Sections**:

1. **YAML Frontmatter**:
```yaml
---
description: Review code quality using code-reviewer skill
usage: /review [file-or-directory-path]
---
```

2. **Command Structure**:

**Block 1: Argument Capture**
```bash
# Argument 1: file or directory path (default: .claude/lib/)
TARGET_PATH="${1:-.claude/lib/}"

# Validate path exists
if [ ! -e "$TARGET_PATH" ]; then
  echo "ERROR: Path not found: $TARGET_PATH"
  exit 1
fi

if [ -f "$TARGET_PATH" ]; then
  echo "Reviewing file: $TARGET_PATH"
elif [ -d "$TARGET_PATH" ]; then
  echo "Reviewing directory: $TARGET_PATH"
fi
```

**Block 2: Skill Invocation**
```markdown
**EXECUTE NOW**: USE the Skill tool to invoke code-reviewer.

Skill {
  skill: "code-reviewer"
}

After skill loads, execute code review:

1. If file: Review single file
2. If directory: Scan all code files recursively
3. For each file, run:
   - Linting (shellcheck for .sh, luacheck for .lua)
   - Complexity analysis
   - Security pattern detection
4. Aggregate results by severity
5. Display quality report

Quality Report Format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Code Quality Review Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
- Files Analyzed: N
- Errors: X
- Warnings: Y
- Info: Z

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Linting Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Shellcheck and luacheck violations grouped by file]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Complexity Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[High complexity functions and long functions]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Security Findings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Security pattern violations with remediation suggestions]
```
```

**Block 3: Error Logging Integration** (same pattern as `/doc-check`)

**Deliverable**: Command file created

#### Step 4.2: Update Command Reference

**File**: `.claude/docs/reference/standards/command-reference.md`

**Edit**: Add `/review` entry to command catalog

**Deliverable**: Command reference updated

### Testing

```bash
# Test 1: Command exists
test -f .claude/commands/review.md

# Test 2: Test with valid file (should succeed)
# Manual test: /review .claude/lib/core/error-handling.sh

# Test 3: Test with valid directory (should succeed)
# Manual test: /review .claude/lib/

# Test 4: Test with invalid path (should error)
# /review /nonexistent/path
# Expected: ERROR: Path not found

# Test 5: Verify command reference updated
grep -q "/review" .claude/docs/reference/standards/command-reference.md

echo "✓ Review command tests passed"
```

### Success Criteria

- [ ] Command file created at `.claude/commands/review.md`
- [ ] File path argument works (single file review)
- [ ] Directory path argument works (recursive review)
- [ ] Invalid path triggers error with helpful message
- [ ] Quality report displays with correct format
- [ ] Error logging integration works
- [ ] Command reference updated with `/review` entry

---

## Stage 5: Checkpoint Format v3.0 Specification [4-5 hours]

### Objective

Define standardized checkpoint schema v3.0 with mandatory fields for cross-command resumption and implement validation logic.

### Implementation Steps

#### Step 5.1: Define Checkpoint v3.0 Schema

**File**: `.claude/lib/workflow/checkpoint-utils.sh`

**Schema Definition**:

```bash
# Schema version for checkpoint format v3.0
readonly CHECKPOINT_SCHEMA_VERSION="3.0"

# Checkpoint v3.0 Mandatory Fields:
# - version: Schema version ("3.0")
# - timestamp: ISO 8601 timestamp of checkpoint creation
# - command_name: Command that created checkpoint (/implement, /test, etc.)
# - workflow_id: Unique workflow identifier (e.g., "implement_auth_1733684800")
# - state_file: Path to state machine file (for cross-command state sharing)
# - continuation_context: Path to continuation context file (if iteration-based)
# - iteration: Current iteration number (default: 0 for non-iterative workflows)
# - max_iterations: Maximum iterations allowed (default: 5)
# - plan_path: Absolute path to plan file
# - current_phase: Current phase number or state name
# - status: Checkpoint status (in_progress, complete, halted)
# - workflow_data: Command-specific workflow data (extensible object)

# Checkpoint v3.0 JSON Structure:
# {
#   "version": "3.0",
#   "timestamp": "2025-12-08T10:30:00Z",
#   "command_name": "/implement",
#   "workflow_id": "implement_auth_1733684800",
#   "state_file": "/home/user/.claude/data/state/implement_auth_state.json",
#   "continuation_context": "/home/user/.claude/specs/042_auth/context.md",
#   "iteration": 2,
#   "max_iterations": 5,
#   "plan_path": "/home/user/.claude/specs/042_auth/plans/001_auth.md",
#   "current_phase": 3,
#   "status": "in_progress",
#   "workflow_data": {
#     "completed_phases": [1, 2],
#     "tests_passing": true,
#     "last_error": null,
#     "command_specific_field": "value"
#   }
# }
```

**Design Rationale**:

| Field | Purpose | Cross-Command Usage |
|-------|---------|---------------------|
| `version` | Schema version tracking | All commands validate schema version |
| `command_name` | Source command identification | Commands know which command created checkpoint |
| `state_file` | Shared state machine location | `/test` can resume from `/implement` state |
| `continuation_context` | Iteration context sharing | Commands can resume multi-iteration workflows |
| `workflow_id` | Unique workflow tracking | Correlate checkpoints, logs, artifacts |
| `plan_path` | Plan reference | All commands operate on same plan |
| `workflow_data` | Extensible command data | Each command stores custom fields |

**Deliverable**: Schema v3.0 defined in checkpoint-utils.sh

#### Step 5.2: Implement save_checkpoint_v3() Function

**File**: `.claude/lib/workflow/checkpoint-utils.sh`

**Function Implementation**:

```bash
# save_checkpoint_v3: Save checkpoint with v3.0 schema
# Usage: save_checkpoint_v3 <checkpoint-json>
# Returns: Path to saved checkpoint file
# Example: save_checkpoint_v3 '{"version":"3.0","command_name":"/implement",...}'
save_checkpoint_v3() {
  local checkpoint_json="${1:-}"

  if [ -z "$checkpoint_json" ]; then
    echo "Usage: save_checkpoint_v3 <checkpoint-json>" >&2
    return 1
  fi

  # Validate JSON structure
  if ! echo "$checkpoint_json" | jq empty 2>/dev/null; then
    echo "ERROR: Invalid JSON provided" >&2
    return 1
  fi

  # Validate mandatory fields
  local required_fields=(
    "version"
    "timestamp"
    "command_name"
    "workflow_id"
    "plan_path"
    "current_phase"
    "status"
  )

  for field in "${required_fields[@]}"; do
    if ! echo "$checkpoint_json" | jq -e ".$field" >/dev/null 2>&1; then
      echo "ERROR: Missing mandatory field: $field" >&2
      return 1
    fi
  done

  # Validate version is 3.0
  local version=$(echo "$checkpoint_json" | jq -r '.version')
  if [ "$version" != "3.0" ]; then
    echo "ERROR: Invalid schema version: $version (expected 3.0)" >&2
    return 1
  fi

  # Extract workflow_id for filename
  local workflow_id=$(echo "$checkpoint_json" | jq -r '.workflow_id')
  local command_name=$(echo "$checkpoint_json" | jq -r '.command_name' | sed 's|^/||')

  # Create checkpoint directory
  local checkpoint_dir="${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints"
  mkdir -p "$checkpoint_dir"

  # Create checkpoint file (includes timestamp in workflow_id)
  local checkpoint_file="${checkpoint_dir}/${command_name}_${workflow_id}_v3.json"
  local temp_file="${checkpoint_file}.tmp"

  # Atomic write
  echo "$checkpoint_json" > "$temp_file"
  mv "$temp_file" "$checkpoint_file"

  echo "$checkpoint_file"
}
```

**Validation Logic**:

```bash
# validate_checkpoint_v3: Validate v3.0 checkpoint structure
# Usage: validate_checkpoint_v3 <checkpoint-file>
# Returns: 0 if valid, 1 if invalid
validate_checkpoint_v3() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Usage: validate_checkpoint_v3 <checkpoint-file>" >&2
    return 1
  fi

  if [ ! -f "$checkpoint_file" ]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  # Validate JSON
  if ! jq empty "$checkpoint_file" 2>/dev/null; then
    echo "ERROR: Invalid JSON in checkpoint file" >&2
    return 1
  fi

  # Check version
  local version=$(jq -r '.version // "unknown"' "$checkpoint_file")
  if [ "$version" != "3.0" ]; then
    echo "ERROR: Invalid schema version: $version (expected 3.0)" >&2
    return 1
  fi

  # Validate mandatory fields
  local required_fields=(
    "version"
    "timestamp"
    "command_name"
    "workflow_id"
    "plan_path"
    "current_phase"
    "status"
  )

  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$checkpoint_file" >/dev/null 2>&1; then
      echo "ERROR: Missing mandatory field: $field" >&2
      return 1
    fi
  done

  # Validate plan_path exists
  local plan_path=$(jq -r '.plan_path' "$checkpoint_file")
  if [ ! -f "$plan_path" ]; then
    echo "WARNING: Plan file not found: $plan_path" >&2
    # Non-fatal warning
  fi

  # Validate status is valid
  local status=$(jq -r '.status' "$checkpoint_file")
  case "$status" in
    in_progress|complete|halted)
      # Valid status
      ;;
    *)
      echo "ERROR: Invalid status: $status (expected: in_progress, complete, halted)" >&2
      return 1
      ;;
  esac

  return 0
}
```

**Deliverable**: save_checkpoint_v3() and validate_checkpoint_v3() implemented

#### Step 5.3: Implement load_checkpoint_v3() Function

**File**: `.claude/lib/workflow/checkpoint-utils.sh`

**Function Implementation**:

```bash
# load_checkpoint_v3: Load checkpoint with v3.0 schema validation
# Usage: load_checkpoint_v3 <checkpoint-file>
# Returns: Checkpoint JSON
# Example: checkpoint=$(load_checkpoint_v3 "/path/to/checkpoint.json")
load_checkpoint_v3() {
  local checkpoint_file="${1:-}"

  if [ -z "$checkpoint_file" ]; then
    echo "Usage: load_checkpoint_v3 <checkpoint-file>" >&2
    return 1
  fi

  # Validate checkpoint before loading
  if ! validate_checkpoint_v3 "$checkpoint_file"; then
    echo "ERROR: Checkpoint validation failed" >&2
    return 1
  fi

  # Check if migration needed (from v2.1 to v3.0)
  local version=$(jq -r '.version // "unknown"' "$checkpoint_file")
  if [ "$version" != "3.0" ]; then
    echo "INFO: Migrating checkpoint from v$version to v3.0" >&2
    checkpoint_file=$(migrate_checkpoint_v2_to_v3 "$checkpoint_file")
    if [ $? -ne 0 ]; then
      echo "ERROR: Migration failed" >&2
      return 1
    fi
  fi

  # Return checkpoint JSON
  cat "$checkpoint_file"
}
```

**Deliverable**: load_checkpoint_v3() implemented with version compatibility check

#### Step 5.4: Document Checkpoint Schema

**File**: `.claude/lib/workflow/README.md`

**Section to Add**:

```markdown
## Checkpoint Format v3.0

### Schema Specification

Checkpoint v3.0 introduces mandatory fields for cross-command resumption:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version ("3.0") |
| `timestamp` | string | Yes | ISO 8601 timestamp |
| `command_name` | string | Yes | Command that created checkpoint |
| `workflow_id` | string | Yes | Unique workflow identifier |
| `state_file` | string | No | Path to shared state machine file |
| `continuation_context` | string | No | Path to continuation context |
| `iteration` | number | No | Current iteration (default: 0) |
| `max_iterations` | number | No | Max iterations (default: 5) |
| `plan_path` | string | Yes | Absolute path to plan file |
| `current_phase` | number/string | Yes | Current phase or state |
| `status` | string | Yes | in_progress, complete, halted |
| `workflow_data` | object | Yes | Command-specific data |

### Cross-Command Resumption

Checkpoint v3.0 enables cross-command workflow resumption:

**Example**: Save checkpoint in `/implement`, resume in `/test`

```bash
# In /implement command:
checkpoint=$(save_checkpoint_v3 '{
  "version": "3.0",
  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "command_name": "/implement",
  "workflow_id": "implement_auth_'$(date +%s)'",
  "state_file": "/path/to/state.json",
  "plan_path": "/path/to/plan.md",
  "current_phase": 3,
  "status": "in_progress",
  "workflow_data": {
    "completed_phases": [1, 2],
    "tests_passing": true
  }
}')

# In /test command:
checkpoint_json=$(load_checkpoint_v3 "$checkpoint_file")
plan_path=$(echo "$checkpoint_json" | jq -r '.plan_path')
completed_phases=$(echo "$checkpoint_json" | jq -r '.workflow_data.completed_phases[]')

# Resume testing from last completed phase
```

### Migration from v2.1

Checkpoints are automatically migrated from v2.1 to v3.0 when loaded:

```bash
# Migration utility
migrate_checkpoint_v2_to_v3 "/path/to/v2_checkpoint.json"
```

See [Checkpoint Migration](#checkpoint-migration) for details.
```

**Deliverable**: Checkpoint v3.0 schema documented in lib/workflow/README.md

### Testing

```bash
# Test 1: Validate schema constants defined
grep -q 'CHECKPOINT_SCHEMA_VERSION="3.0"' .claude/lib/workflow/checkpoint-utils.sh

# Test 2: Test save_checkpoint_v3 with valid data
source .claude/lib/workflow/checkpoint-utils.sh

checkpoint_json='{
  "version": "3.0",
  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "command_name": "/implement",
  "workflow_id": "test_workflow_'$(date +%s)'",
  "plan_path": "/tmp/test_plan.md",
  "current_phase": 1,
  "status": "in_progress",
  "workflow_data": {}
}'

# Create test plan file
echo "# Test Plan" > /tmp/test_plan.md

# Save checkpoint
checkpoint_file=$(save_checkpoint_v3 "$checkpoint_json")
echo "Checkpoint saved: $checkpoint_file"

# Test 3: Validate saved checkpoint
validate_checkpoint_v3 "$checkpoint_file"
if [ $? -eq 0 ]; then
  echo "✓ Checkpoint validation passed"
else
  echo "✗ Checkpoint validation failed"
  exit 1
fi

# Test 4: Load checkpoint
loaded_checkpoint=$(load_checkpoint_v3 "$checkpoint_file")
echo "Checkpoint loaded successfully"

# Test 5: Verify mandatory fields present
echo "$loaded_checkpoint" | jq -e '.version' >/dev/null
echo "$loaded_checkpoint" | jq -e '.command_name' >/dev/null
echo "$loaded_checkpoint" | jq -e '.workflow_id' >/dev/null

# Test 6: Test save with missing mandatory field (should error)
invalid_checkpoint='{
  "version": "3.0",
  "command_name": "/test"
}'

if save_checkpoint_v3 "$invalid_checkpoint" 2>&1 | grep -q "Missing mandatory field"; then
  echo "✓ Missing field validation works"
else
  echo "✗ Missing field validation failed"
  exit 1
fi

# Test 7: Verify README documentation exists
grep -q "Checkpoint Format v3.0" .claude/lib/workflow/README.md

echo "✓ Checkpoint v3.0 implementation tests passed"
```

### Success Criteria

- [ ] Checkpoint v3.0 schema defined with mandatory fields
- [ ] save_checkpoint_v3() validates mandatory fields
- [ ] save_checkpoint_v3() creates checkpoints with v3.0 schema
- [ ] validate_checkpoint_v3() validates schema and fields
- [ ] load_checkpoint_v3() validates before loading
- [ ] Checkpoint schema documented in lib/workflow/README.md
- [ ] All tests pass (save, validate, load, error handling)

---

## Stage 6: Checkpoint Migration Utility Implementation [3-4 hours]

### Objective

Implement migrate_checkpoint_v2_to_v3() migration utility to convert v2.1 checkpoints to v3.0 format for backward compatibility.

### Implementation Steps

#### Step 6.1: Implement Migration Function

**File**: `.claude/lib/workflow/checkpoint-utils.sh`

**Function Implementation**:

```bash
# migrate_checkpoint_v2_to_v3: Migrate checkpoint from v2.1 to v3.0
# Usage: migrate_checkpoint_v2_to_v3 <v2-checkpoint-file>
# Returns: Path to migrated v3.0 checkpoint file
# Example: v3_file=$(migrate_checkpoint_v2_to_v3 "/path/to/v2_checkpoint.json")
migrate_checkpoint_v2_to_v3() {
  local v2_checkpoint_file="${1:-}"

  if [ -z "$v2_checkpoint_file" ]; then
    echo "Usage: migrate_checkpoint_v2_to_v3 <v2-checkpoint-file>" >&2
    return 1
  fi

  if [ ! -f "$v2_checkpoint_file" ]; then
    echo "ERROR: Checkpoint file not found: $v2_checkpoint_file" >&2
    return 1
  fi

  # Validate v2.1 checkpoint
  local version=$(jq -r '.schema_version // .version // "unknown"' "$v2_checkpoint_file")
  if [ "$version" != "2.1" ] && [ "$version" != "2.0" ]; then
    echo "ERROR: Can only migrate from v2.0 or v2.1 (found: $version)" >&2
    return 1
  fi

  # Backup original checkpoint
  local backup_file="${v2_checkpoint_file}.v2_backup"
  cp "$v2_checkpoint_file" "$backup_file"
  echo "Backup created: $backup_file" >&2

  # Extract v2.1 fields and map to v3.0 schema
  local v3_checkpoint
  v3_checkpoint=$(jq '{
    version: "3.0",
    timestamp: (.created_at // .timestamp // "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"),
    command_name: (.workflow_type // "/unknown"),
    workflow_id: (.checkpoint_id // ("checkpoint_" + (now | tostring))),
    state_file: (.state_machine.state_file // null),
    continuation_context: (.continuation_context // null),
    iteration: (.iteration // 0),
    max_iterations: (.max_iterations // 5),
    plan_path: (.workflow_state.plan_path // .plan_path // null),
    current_phase: (.current_phase // .state_machine.current_state // 0),
    status: (
      if .status == "in_progress" then "in_progress"
      elif .status == "complete" then "complete"
      else "in_progress"
      end
    ),
    workflow_data: {
      completed_phases: (.completed_phases // []),
      tests_passing: (.tests_passing // true),
      last_error: (.last_error // null),
      replanning_count: (.replanning_count // 0),
      state_machine: (.state_machine // null),
      phase_data: (.phase_data // {}),
      supervisor_state: (.supervisor_state // {}),
      error_state: (.error_state // {
        last_error: null,
        retry_count: 0,
        failed_state: null
      }),
      legacy_fields: {
        original_version: .schema_version,
        migration_timestamp: "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }
    }
  }' "$v2_checkpoint_file")

  # Validate migrated checkpoint
  local temp_v3_file="${v2_checkpoint_file}.v3_migrated.tmp"
  echo "$v3_checkpoint" > "$temp_v3_file"

  if ! validate_checkpoint_v3 "$temp_v3_file"; then
    echo "ERROR: Migrated checkpoint failed validation" >&2
    rm -f "$temp_v3_file"
    return 1
  fi

  # Create v3.0 checkpoint file (new filename with _v3 suffix)
  local v2_basename=$(basename "$v2_checkpoint_file" .json)
  local v2_dirname=$(dirname "$v2_checkpoint_file")
  local v3_checkpoint_file="${v2_dirname}/${v2_basename}_v3.json"

  mv "$temp_v3_file" "$v3_checkpoint_file"
  echo "Migration complete: $v3_checkpoint_file" >&2

  # Return v3 checkpoint path
  echo "$v3_checkpoint_file"
}
```

**Migration Mapping Table**:

| v2.1 Field | v3.0 Field | Mapping Logic |
|------------|------------|---------------|
| `schema_version` | `version` | Hardcoded "3.0" |
| `created_at` | `timestamp` | Direct copy |
| `workflow_type` | `command_name` | Prepend "/" if missing |
| `checkpoint_id` | `workflow_id` | Direct copy |
| `workflow_state.plan_path` | `plan_path` | Extract from nested object |
| `current_phase` | `current_phase` | Direct copy |
| `status` | `status` | Map to in_progress/complete/halted |
| `state_machine` | `workflow_data.state_machine` | Move to workflow_data |
| `completed_phases` | `workflow_data.completed_phases` | Move to workflow_data |
| `tests_passing` | `workflow_data.tests_passing` | Move to workflow_data |

**Deliverable**: migrate_checkpoint_v2_to_v3() implemented

#### Step 6.2: Add Migration Documentation

**File**: `.claude/lib/workflow/README.md`

**Section to Add**:

```markdown
## Checkpoint Migration

### Migrating from v2.1 to v3.0

Checkpoint v3.0 is backward-compatible with v2.1 via automatic migration:

**Automatic Migration** (on load):
```bash
# load_checkpoint_v3 automatically migrates v2.1 checkpoints
checkpoint=$(load_checkpoint_v3 "/path/to/v2_checkpoint.json")
# Returns v3.0 checkpoint JSON
```

**Manual Migration**:
```bash
# Migrate v2.1 checkpoint to v3.0 format
v3_file=$(migrate_checkpoint_v2_to_v3 "/path/to/v2_checkpoint.json")
echo "Migrated checkpoint: $v3_file"

# Original v2.1 checkpoint backed up to:
# /path/to/v2_checkpoint.json.v2_backup
```

**Migration Behavior**:
- Original v2.1 checkpoint backed up with `.v2_backup` suffix
- Migrated v3.0 checkpoint saved with `_v3.json` suffix
- Original v2.1 checkpoint preserved (not overwritten)
- All v2.1 fields mapped to v3.0 schema
- Legacy fields preserved in `workflow_data.legacy_fields`

**Field Mapping**:
- `schema_version` → `version` (set to "3.0")
- `workflow_type` → `command_name` (prepend "/" if needed)
- `checkpoint_id` → `workflow_id`
- Nested state moved to `workflow_data` object

**Validation**:
- Migrated checkpoint automatically validated before save
- Invalid migrations return error with details
```

**Deliverable**: Migration documentation added to README.md

### Testing

```bash
# Test 1: Create v2.1 checkpoint for migration testing
cat > /tmp/v2_checkpoint.json <<'EOF'
{
  "schema_version": "2.1",
  "checkpoint_id": "implement_test_20251208",
  "workflow_type": "implement",
  "project_name": "test",
  "created_at": "2025-12-08T10:00:00Z",
  "status": "in_progress",
  "current_phase": 2,
  "completed_phases": [1],
  "workflow_state": {
    "plan_path": "/tmp/test_plan.md"
  },
  "tests_passing": true,
  "last_error": null,
  "state_machine": {
    "current_state": "implement",
    "completed_states": ["research", "plan"]
  }
}
EOF

# Test 2: Migrate v2.1 to v3.0
source .claude/lib/workflow/checkpoint-utils.sh
v3_file=$(migrate_checkpoint_v2_to_v3 /tmp/v2_checkpoint.json)
echo "Migrated checkpoint: $v3_file"

# Test 3: Verify backup created
test -f /tmp/v2_checkpoint.json.v2_backup
echo "✓ Backup created"

# Test 4: Validate migrated checkpoint
validate_checkpoint_v3 "$v3_file"
if [ $? -eq 0 ]; then
  echo "✓ Migrated checkpoint is valid v3.0"
else
  echo "✗ Migration validation failed"
  exit 1
fi

# Test 5: Verify field mapping
version=$(jq -r '.version' "$v3_file")
if [ "$version" != "3.0" ]; then
  echo "✗ Version not migrated correctly: $version"
  exit 1
fi

command_name=$(jq -r '.command_name' "$v3_file")
if [ "$command_name" != "implement" ]; then
  echo "✗ Command name not migrated correctly: $command_name"
  exit 1
fi

plan_path=$(jq -r '.plan_path' "$v3_file")
if [ "$plan_path" != "/tmp/test_plan.md" ]; then
  echo "✗ Plan path not migrated correctly: $plan_path"
  exit 1
fi

# Test 6: Verify legacy fields preserved
jq -e '.workflow_data.legacy_fields.original_version' "$v3_file" >/dev/null
echo "✓ Legacy fields preserved"

# Test 7: Test migration with invalid v2 checkpoint (should error)
cat > /tmp/invalid_checkpoint.json <<'EOF'
{
  "schema_version": "1.0",
  "checkpoint_id": "old_checkpoint"
}
EOF

if migrate_checkpoint_v2_to_v3 /tmp/invalid_checkpoint.json 2>&1 | grep -q "Can only migrate from v2.0 or v2.1"; then
  echo "✓ Invalid version migration rejected"
else
  echo "✗ Invalid version migration check failed"
  exit 1
fi

echo "✓ Checkpoint migration tests passed"
```

### Success Criteria

- [ ] migrate_checkpoint_v2_to_v3() function implemented
- [ ] Original v2.1 checkpoint backed up before migration
- [ ] Migrated checkpoint validated before save
- [ ] All v2.1 fields mapped to v3.0 schema
- [ ] Legacy fields preserved in workflow_data
- [ ] Migration documentation added to README.md
- [ ] All migration tests pass

---

## Stage 7: Command Migration to Checkpoint v3.0 [6-8 hours]

### Objective

Migrate `/implement`, `/test`, `/debug`, and `/repair` commands to use checkpoint v3.0 format for consistent cross-command resumption.

### Implementation Steps

#### Step 7.1: Migrate /implement Command

**File**: `.claude/commands/implement.md`

**Migration Steps**:

1. **Source checkpoint-utils.sh** (verify three-tier sourcing):
```bash
# Tier 1: Core libraries (required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || { echo "Error: Cannot load workflow-state-machine library"; exit 1; }
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Tier 2: Workflow libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || { echo "Error: Cannot load checkpoint-utils library"; exit 1; }
```

2. **Replace save_checkpoint calls with save_checkpoint_v3**:

**Old Pattern**:
```bash
# Old v2.1 checkpoint save
checkpoint_file=$(save_checkpoint "implement" "$project_name" "$workflow_state_json")
```

**New Pattern**:
```bash
# New v3.0 checkpoint save
checkpoint_json=$(jq -n \
  --arg version "3.0" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg command "/implement" \
  --arg workflow_id "implement_${project_name}_$(date +%s)" \
  --arg plan_path "$PLAN_PATH" \
  --argjson current_phase "$CURRENT_PHASE" \
  --arg status "in_progress" \
  --argjson workflow_data "$workflow_state_json" \
  '{
    version: $version,
    timestamp: $timestamp,
    command_name: $command,
    workflow_id: $workflow_id,
    plan_path: $plan_path,
    current_phase: $current_phase,
    status: $status,
    workflow_data: $workflow_data
  }')

checkpoint_file=$(save_checkpoint_v3 "$checkpoint_json")
```

3. **Replace restore_checkpoint calls with load_checkpoint_v3**:

**Old Pattern**:
```bash
# Old v2.1 checkpoint load
checkpoint_json=$(restore_checkpoint "implement" "$project_name")
workflow_state=$(echo "$checkpoint_json" | jq '.workflow_state')
```

**New Pattern**:
```bash
# New v3.0 checkpoint load
checkpoint_json=$(load_checkpoint_v3 "$checkpoint_file")
workflow_data=$(echo "$checkpoint_json" | jq '.workflow_data')
current_phase=$(echo "$checkpoint_json" | jq -r '.current_phase')
plan_path=$(echo "$checkpoint_json" | jq -r '.plan_path')
```

**Deliverable**: `/implement` command migrated to v3.0

#### Step 7.2: Migrate /test Command

**File**: `.claude/commands/test.md`

**Migration Steps**: Same pattern as `/implement`

1. Source checkpoint-utils.sh
2. Replace save_checkpoint with save_checkpoint_v3
3. Replace restore_checkpoint with load_checkpoint_v3
4. Update workflow_data extraction

**V3.0 Checkpoint Structure for /test**:
```json
{
  "version": "3.0",
  "command_name": "/test",
  "workflow_id": "test_auth_1733684800",
  "plan_path": "/path/to/plan.md",
  "current_phase": "test_execution",
  "status": "in_progress",
  "workflow_data": {
    "test_categories": ["unit", "integration"],
    "completed_categories": ["unit"],
    "tests_passing": true,
    "coverage_percentage": 85,
    "last_test_run": "2025-12-08T10:30:00Z"
  }
}
```

**Deliverable**: `/test` command migrated to v3.0

#### Step 7.3: Migrate /debug Command

**File**: `.claude/commands/debug.md`

**Migration Steps**: Same pattern

**V3.0 Checkpoint Structure for /debug**:
```json
{
  "version": "3.0",
  "command_name": "/debug",
  "workflow_id": "debug_auth_1733684800",
  "plan_path": "/path/to/debug_plan.md",
  "current_phase": "investigation",
  "status": "in_progress",
  "workflow_data": {
    "investigation_vectors": ["logs", "code", "dependencies"],
    "completed_vectors": ["logs"],
    "root_cause_candidates": ["race condition in auth middleware"],
    "confidence_scores": {"logs": 0.8}
  }
}
```

**Deliverable**: `/debug` command migrated to v3.0

#### Step 7.4: Migrate /repair Command

**File**: `.claude/commands/repair.md`

**Migration Steps**: Same pattern

**V3.0 Checkpoint Structure for /repair**:
```json
{
  "version": "3.0",
  "command_name": "/repair",
  "workflow_id": "repair_errors_1733684800",
  "plan_path": "/path/to/repair_plan.md",
  "current_phase": "error_analysis",
  "status": "in_progress",
  "workflow_data": {
    "error_dimensions": ["type", "timeframe", "command"],
    "completed_dimensions": ["type"],
    "error_patterns": ["state_error in /implement"],
    "fix_recommendations": ["Add state validation before phase transition"]
  }
}
```

**Deliverable**: `/repair` command migrated to v3.0

### Testing

```bash
# Test 1: Verify /implement uses v3.0
grep -q "save_checkpoint_v3" .claude/commands/implement.md
grep -q "load_checkpoint_v3" .claude/commands/implement.md

# Test 2: Verify /test uses v3.0
grep -q "save_checkpoint_v3" .claude/commands/test.md

# Test 3: Verify /debug uses v3.0
grep -q "save_checkpoint_v3" .claude/commands/debug.md

# Test 4: Verify /repair uses v3.0
grep -q "save_checkpoint_v3" .claude/commands/repair.md

# Test 5: Integration test - cross-command resumption
# Manual test:
# 1. Run /implement to phase 3, save v3.0 checkpoint
# 2. Exit /implement
# 3. Run /test with --resume flag
# 4. Verify /test loads v3.0 checkpoint from /implement
# 5. Verify /test can extract plan_path and workflow_data

echo "✓ All commands migrated to checkpoint v3.0"
```

### Success Criteria

- [ ] `/implement` command uses save_checkpoint_v3() and load_checkpoint_v3()
- [ ] `/test` command uses v3.0 checkpoint format
- [ ] `/debug` command uses v3.0 checkpoint format
- [ ] `/repair` command uses v3.0 checkpoint format
- [ ] All commands source checkpoint-utils.sh with three-tier sourcing
- [ ] Checkpoint validation errors handled gracefully
- [ ] Cross-command resumption tested and working

---

## Stage 8: Cross-Command Resumption Testing [2-3 hours]

### Objective

Test and validate cross-command resumption scenarios to ensure checkpoint v3.0 enables workflow continuity across command boundaries.

### Test Scenarios

#### Scenario 1: /implement → /test Resumption

**Test Case**: Save checkpoint in `/implement`, resume in `/test`

**Steps**:
1. Create test plan with 3 phases
2. Run `/implement plan.md` to complete phase 2
3. Verify v3.0 checkpoint saved with:
   - `command_name: "/implement"`
   - `current_phase: 2`
   - `workflow_data.completed_phases: [1, 2]`
4. Run `/test plan.md --resume`
5. Verify `/test` loads checkpoint and extracts:
   - `plan_path` to find plan file
   - `workflow_data.completed_phases` to know which phases tested
   - `workflow_id` to correlate logs

**Expected Result**: `/test` resumes from `/implement` checkpoint without errors

**Success Criteria**:
- [ ] `/test` loads v3.0 checkpoint created by `/implement`
- [ ] Plan path extracted correctly
- [ ] Workflow data accessible
- [ ] Test execution continues from correct state

#### Scenario 2: /test → /debug Resumption

**Test Case**: Test failure triggers debug with checkpoint context

**Steps**:
1. Run `/test plan.md` with failing tests
2. Verify v3.0 checkpoint saved with:
   - `command_name: "/test"`
   - `workflow_data.tests_passing: false`
   - `workflow_data.last_test_run` timestamp
3. Run `/debug plan.md --resume`
4. Verify `/debug` loads checkpoint and extracts:
   - `plan_path` for context
   - `workflow_data.tests_passing` to understand failure
   - `workflow_data.last_test_run` for temporal context

**Expected Result**: `/debug` has full context from `/test` checkpoint

**Success Criteria**:
- [ ] `/debug` loads v3.0 checkpoint created by `/test`
- [ ] Test failure context extracted
- [ ] Debug investigation informed by test results

#### Scenario 3: /debug → /implement Resumption

**Test Case**: Debug identifies fix, resume implementation

**Steps**:
1. Run `/debug issue.md` to identify root cause
2. Create fix plan based on debug findings
3. Verify v3.0 checkpoint saved with:
   - `command_name: "/debug"`
   - `workflow_data.root_cause_candidates`
   - `workflow_data.fix_recommendations`
4. Run `/implement fix_plan.md` (new workflow)
5. Optionally reference debug checkpoint for context

**Expected Result**: `/implement` can access debug findings if needed

**Success Criteria**:
- [ ] Debug checkpoint contains actionable findings
- [ ] Implementation can proceed with fix plan
- [ ] Cross-workflow correlation possible via workflow_id

#### Scenario 4: /repair → /implement Resumption

**Test Case**: Repair analysis generates fix plan for implementation

**Steps**:
1. Run `/repair --since 1h --type state_error`
2. Generate repair plan from error analysis
3. Verify v3.0 checkpoint saved with:
   - `command_name: "/repair"`
   - `workflow_data.error_patterns`
   - `workflow_data.fix_recommendations`
4. Run `/implement repair_plan.md`
5. Verify implementation references repair analysis

**Expected Result**: Seamless transition from error analysis to fix implementation

**Success Criteria**:
- [ ] Repair checkpoint contains error patterns and fixes
- [ ] Implementation can access repair context
- [ ] Fix plan incorporates repair recommendations

### Integration Test Script

**File**: `.claude/tests/integration/test_cross_command_resumption.sh`

```bash
#!/usr/bin/env bash
# Integration test for cross-command checkpoint resumption

set -euo pipefail

# Source checkpoint utilities
source .claude/lib/workflow/checkpoint-utils.sh

# Test 1: /implement → /test resumption
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: /implement → /test Resumption"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Simulate /implement checkpoint
implement_checkpoint=$(jq -n '{
  version: "3.0",
  timestamp: "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  command_name: "/implement",
  workflow_id: "implement_test_'$(date +%s)'",
  plan_path: "/tmp/test_plan.md",
  current_phase: 2,
  status: "in_progress",
  workflow_data: {
    completed_phases: [1, 2],
    tests_passing: true
  }
}')

# Save checkpoint
checkpoint_file=$(save_checkpoint_v3 "$implement_checkpoint")
echo "Saved /implement checkpoint: $checkpoint_file"

# Simulate /test loading checkpoint
loaded_checkpoint=$(load_checkpoint_v3 "$checkpoint_file")
command_name=$(echo "$loaded_checkpoint" | jq -r '.command_name')
plan_path=$(echo "$loaded_checkpoint" | jq -r '.plan_path')
completed_phases=$(echo "$loaded_checkpoint" | jq -r '.workflow_data.completed_phases[]')

if [ "$command_name" = "/implement" ] && [ "$plan_path" = "/tmp/test_plan.md" ]; then
  echo "✓ /test successfully resumed from /implement checkpoint"
else
  echo "✗ /test failed to resume from /implement checkpoint"
  exit 1
fi

# Test 2: Version compatibility check
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: v2.1 → v3.0 Migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create v2.1 checkpoint
cat > /tmp/v2_checkpoint.json <<EOF
{
  "schema_version": "2.1",
  "checkpoint_id": "test_migration_$(date +%s)",
  "workflow_type": "implement",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "in_progress",
  "current_phase": 1,
  "workflow_state": {
    "plan_path": "/tmp/test_plan.md"
  }
}
EOF

# Migrate to v3.0
v3_file=$(migrate_checkpoint_v2_to_v3 /tmp/v2_checkpoint.json)
echo "Migrated v2.1 checkpoint to: $v3_file"

# Validate v3.0 checkpoint
if validate_checkpoint_v3 "$v3_file"; then
  echo "✓ v2.1 checkpoint migrated successfully to v3.0"
else
  echo "✗ v2.1 migration failed validation"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All Cross-Command Resumption Tests Passed ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Deliverable**: Integration test script created

### Testing

```bash
# Run integration test script
bash .claude/tests/integration/test_cross_command_resumption.sh

# Expected output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 1: /implement → /test Resumption
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Saved /implement checkpoint: /path/to/checkpoint.json
# ✓ /test successfully resumed from /implement checkpoint
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test 2: v2.1 → v3.0 Migration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Migrated v2.1 checkpoint to: /path/to/v3.json
# ✓ v2.1 checkpoint migrated successfully to v3.0
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# All Cross-Command Resumption Tests Passed ✓
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Success Criteria

- [ ] /implement → /test resumption works
- [ ] /test → /debug resumption works
- [ ] Debug findings accessible in implementation
- [ ] Repair analysis accessible in implementation
- [ ] v2.1 → v3.0 migration works seamlessly
- [ ] Integration test script passes all scenarios
- [ ] Cross-command workflow continuity validated

---

## Stage 9: CLAUDE.md Updates [1-2 hours]

### Objective

Update CLAUDE.md sections to document new skills and checkpoint v3.0 format.

### Implementation Steps

#### Step 9.1: Update Skills Architecture Section

**File**: `CLAUDE.md`

**Section**: `<!-- SECTION: skills_architecture -->`

**Edit**:

```markdown
Old:
**Available Skills**:
- `document-converter` - Bidirectional document conversion (Markdown, DOCX, PDF)

New:
**Available Skills**:
- `document-converter` - Bidirectional document conversion (Markdown, DOCX, PDF)
- `research-specialist` - Autonomous research capabilities with parallel topic analysis
- `plan-generator` - Reusable planning logic for /create-plan, /repair, /debug
- `test-orchestrator` - Autonomous test enforcement and quality checks
- `doc-analyzer` - Documentation quality analysis (README validation, link checking)
- `code-reviewer` - Automated code quality review (linting, complexity, security)
```

**Deliverable**: Skills architecture section updated

#### Step 9.2: Update State-Based Orchestration Section

**File**: `CLAUDE.md`

**Section**: `<!-- SECTION: state_based_orchestration -->`

**Edit**: Add checkpoint v3.0 information

```markdown
Add subsection:

**Checkpoint Format v3.0**: The checkpoint system uses v3.0 schema for cross-command resumption. See [Checkpoint Utils README](.claude/lib/workflow/README.md#checkpoint-format-v30) for complete schema specification and migration guide.

**Key Features**:
- Mandatory fields for cross-command compatibility (version, command_name, workflow_id, state_file, plan_path)
- Backward-compatible migration from v2.1
- Shared state machine for workflow continuity
- Extensible workflow_data for command-specific state
```

**Deliverable**: State-based orchestration section updated

### Testing

```bash
# Verify skills architecture section updated
grep -q "doc-analyzer" CLAUDE.md
grep -q "code-reviewer" CLAUDE.md

# Verify state-based orchestration section updated
grep -q "Checkpoint Format v3.0" CLAUDE.md

echo "✓ CLAUDE.md updates verified"
```

### Success Criteria

- [ ] Skills architecture section lists all 6 skills
- [ ] State-based orchestration section documents checkpoint v3.0
- [ ] Cross-references to lib/workflow/README.md added
- [ ] No broken links introduced

---

## Phase 4 Summary

### Deliverables

**Skills Created**:
1. `doc-analyzer` skill with README validation, link checking, gap detection
2. `code-reviewer` skill with linting, complexity analysis, security detection
3. `/doc-check` command for explicit doc-analyzer invocation
4. `/review` command for explicit code-reviewer invocation

**Checkpoint v3.0**:
1. Checkpoint schema v3.0 specification with mandatory fields
2. `save_checkpoint_v3()` function with validation
3. `load_checkpoint_v3()` function with version compatibility
4. `migrate_checkpoint_v2_to_v3()` migration utility
5. Command migrations: /implement, /test, /debug, /repair
6. Cross-command resumption testing suite

**Documentation**:
1. Skills catalog updated with 2 new skills
2. Command reference updated with 2 new commands
3. Checkpoint schema documented in lib/workflow/README.md
4. CLAUDE.md updated with skills and checkpoint v3.0

### Artifacts Created

| Artifact | Path | Size Estimate |
|----------|------|---------------|
| doc-analyzer SKILL.md | `.claude/skills/doc-analyzer/SKILL.md` | ~400 lines |
| doc-analyzer README | `.claude/skills/doc-analyzer/README.md` | ~100 lines |
| code-reviewer SKILL.md | `.claude/skills/code-reviewer/SKILL.md` | ~450 lines |
| code-reviewer README | `.claude/skills/code-reviewer/README.md` | ~120 lines |
| /doc-check command | `.claude/commands/doc-check.md` | ~80 lines |
| /review command | `.claude/commands/review.md` | ~80 lines |
| checkpoint-utils.sh updates | `.claude/lib/workflow/checkpoint-utils.sh` | +300 lines |
| lib/workflow README | `.claude/lib/workflow/README.md` | +200 lines |
| Integration test | `.claude/tests/integration/test_cross_command_resumption.sh` | ~150 lines |
| Skills README updates | `.claude/skills/README.md` | +60 lines |
| CLAUDE.md updates | `CLAUDE.md` | +30 lines |

**Total New Code**: ~1,970 lines

### Success Metrics

**Skills**:
- [ ] 2 new skills created (doc-analyzer, code-reviewer)
- [ ] 2 new commands created (/doc-check, /review)
- [ ] Skills catalog updated from 4 to 6 skills
- [ ] All skills under 500 lines (progressive disclosure)
- [ ] All skills have valid YAML frontmatter

**Checkpoint v3.0**:
- [ ] Checkpoint schema v3.0 defined and documented
- [ ] 4 commands migrated to v3.0 format
- [ ] Migration utility implemented and tested
- [ ] Cross-command resumption validated
- [ ] Backward compatibility with v2.1 verified

**Quality**:
- [ ] All validation tests pass
- [ ] Integration tests pass
- [ ] No broken links in documentation
- [ ] Standards compliance verified
- [ ] Error logging integrated

### Dependencies

**Completed Prerequisites**:
- Phase 3 complete (research-specialist, plan-generator, test-orchestrator skills operational)
- Skills infrastructure validated
- Skills catalog established

**External Dependencies**:
- shellcheck (for code-reviewer linting)
- luacheck (for code-reviewer linting, optional)
- jq (for checkpoint JSON manipulation)

### Next Steps

After Phase 4 completion:
1. Integration testing across all phases (Phase 1-4 end-to-end)
2. Performance monitoring (skills auto-invocation frequency, cross-command resumption success rate)
3. Documentation review and cleanup
4. User acceptance testing with real workflows

---

## Navigation

- [← Parent Plan](../001-three-tier-agent-improvements-plan.md)
- [← Phase 3: Skills Expansion](phase_3_skills_expansion.md) (if created)
- [Related: Skills README](../../../skills/README.md)
- [Related: Checkpoint Utils](../../../lib/workflow/checkpoint-utils.sh)
