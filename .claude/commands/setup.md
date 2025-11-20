---
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: [project-directory] [--force]
description: Setup or analyze CLAUDE.md with automatic mode detection for initialization and diagnostics
command-type: primary
---

# /setup - Project Standards Configuration

YOU ARE EXECUTING AS the /setup command.

**Documentation**: See `.claude/docs/guides/commands/setup-command-guide.md` for complete architecture, usage examples, mode descriptions, and troubleshooting.

---

## Block 1: Setup and Initialization

**EXECUTE NOW**: Execute this bash block immediately

```bash
set +H
# Project detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Source error-handling library for centralized error logging
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Source unified-location-detection library for topic-based organization
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  log_command_error "/setup" "setup_$(date +%s)" "$*" "dependency_error" \
    "Cannot load unified-location-detection library" "initialization"
  echo "ERROR: Cannot load location detection library" >&2
  exit 1
}

# Initialize error log and set workflow metadata
ensure_error_log_exists
COMMAND_NAME="/setup"
WORKFLOW_ID="setup_$(date +%s)"
USER_ARGS="$*"

# Parse arguments (only --force flag supported)
FORCE=false
PROJECT_DIR=""

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=true
      ;;
    --cleanup|--enhance-with-docs|--apply-report|--validate|--analyze)
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "ERROR: Flag not supported in /setup"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "The /setup command handles initialization and diagnostics only."
      echo ""
      echo "For cleanup and optimization operations, use:"
      echo "  /optimize-claude"
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 1
      ;;
    --*)
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
        "Unknown flag: $arg" "argument_parsing"
      echo "ERROR: Unknown flag: $arg"
      echo "Usage: /setup [directory] [--force]"
      exit 1
      ;;
    *)
      [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$arg"
      ;;
  esac
done

# Default to project root (not PWD)
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="${CLAUDE_PROJECT_DIR}"

# Normalize to absolute path
[[ ! "$PROJECT_DIR" = /* ]] && PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"

CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"

# Automatic mode detection
MODE="standard"
if [ -f "$CLAUDE_MD_PATH" ] && [ "$FORCE" != true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CLAUDE.md exists - switching to analysis mode"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To overwrite existing CLAUDE.md, use:"
  echo "  /setup --force"
  echo ""
  MODE="analyze"
fi

export MODE FORCE PROJECT_DIR CLAUDE_MD_PATH COMMAND_NAME WORKFLOW_ID USER_ARGS
```

---

## Block 2: Mode Execution

**EXECUTE NOW**: Execute mode-specific operations

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

case "$MODE" in
  standard)
    echo "Generating CLAUDE.md at: $CLAUDE_MD_PATH"
    echo ""

    # Detect testing framework
    DETECT_OUTPUT=$("${LIB_DIR}/detect-testing.sh" "$PROJECT_DIR" 2>&1)
    TEST_SCORE=$(echo "$DETECT_OUTPUT" | grep "^SCORE:" | cut -d: -f2 | tr -d ' ')
    TEST_FRAMEWORKS=$(echo "$DETECT_OUTPUT" | grep "^FRAMEWORKS:" | cut -d: -f2-)

    # Generate testing protocols
    TESTING_SECTION=$("${LIB_DIR}/generate-testing-protocols.sh" "$TEST_SCORE" "$TEST_FRAMEWORKS" 2>&1)

    # Create CLAUDE.md with all sections
    cat > "$CLAUDE_MD_PATH" << 'EOF'
# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index for this project.

## Code Standards
[Used by: /implement, /refactor, /plan]

### General Conventions
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: ~100 characters (soft limit)
- **Naming**: snake_case for files, language-appropriate for code
- **Error Handling**: Use language-appropriate error handling patterns
- **Documentation**: Every directory has README.md with purpose and module documentation

### Language-Specific Standards
Adapt conventions based on project language (JavaScript/TypeScript, Python, Rust, Go, etc.)

EOF

    echo "$TESTING_SECTION" >> "$CLAUDE_MD_PATH"

    cat >> "$CLAUDE_MD_PATH" << 'EOF'

## Documentation Policy
[Used by: /document, /plan]

### README Requirements
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs

### Documentation Format
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams where appropriate
- Follow CommonMark specification

## Standards Discovery
[Used by: all commands]

### Discovery Method
Commands discover standards by:
1. Searching upward from current directory for CLAUDE.md
2. Checking for subdirectory-specific CLAUDE.md files
3. Merging/overriding: subdirectory standards extend parent standards

### Fallback Behavior
When CLAUDE.md not found or incomplete:
- Use sensible language-specific defaults
- Suggest creating/updating CLAUDE.md with `/setup`
- Continue with graceful degradation

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again to analyze current configuration.
EOF

    # Verification: Check CLAUDE.md was created and is valid
    if [ ! -f "$CLAUDE_MD_PATH" ]; then
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
        "CLAUDE.md file not created at expected path" "standard_mode_generation" \
        "{\"expected_path\": \"$CLAUDE_MD_PATH\"}"
      echo "ERROR: CLAUDE.md not created" >&2
      exit 1
    fi

    if [ ! -s "$CLAUDE_MD_PATH" ]; then
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
        "CLAUDE.md file is empty" "standard_mode_validation" \
        "{\"file_path\": \"$CLAUDE_MD_PATH\"}"
      echo "ERROR: CLAUDE.md is empty" >&2
      exit 1
    fi

    echo "✓ CLAUDE.md created successfully"
    ;;

  analyze)
    echo "Analyzing CLAUDE.md at: $CLAUDE_MD_PATH"
    echo ""

    # Validate CLAUDE.md exists
    if [ ! -f "$CLAUDE_MD_PATH" ]; then
      log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
        "CLAUDE.md not found at $CLAUDE_MD_PATH" "analysis_mode"
      echo "ERROR: CLAUDE.md not found" >&2
      echo "Run /setup (without flags) to create initial CLAUDE.md"
      exit 1
    fi

    # Initialize topic-based paths for analysis report
    initialize_workflow_paths "CLAUDE.md standards analysis" "research" "2" ""
    REPORT_PATH="${RESEARCH_DIR}/001_standards_analysis.md"

    # Validate structure - check required sections
    REQUIRED=("Code Standards" "Testing Protocols" "Documentation Policy" "Standards Discovery")
    MISSING=()
    for sec in "${REQUIRED[@]}"; do
      grep -q "^## $sec" "$CLAUDE_MD_PATH" || MISSING+=("$sec")
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
      echo "⚠ WARNING: Missing sections:"
      printf '  - %s\n' "${MISSING[@]}"
      echo ""
    else
      echo "✓ Structure validation passed"
    fi

    # Validate metadata format - check for [Used by: ...] tags
    NO_META=$(grep -n "^## " "$CLAUDE_MD_PATH" | while read line; do
      LN=$(echo "$line" | cut -d: -f1)
      # Check if next line has [Used by: metadata
      if ! sed -n "$((LN + 1))p" "$CLAUDE_MD_PATH" | grep -q "\[Used by:"; then
        echo "$line" | cut -d: -f2-
      fi
    done)

    if [ -n "$NO_META" ]; then
      echo "⚠ WARNING: Sections missing [Used by: ...] metadata:"
      echo "$NO_META"
      echo ""
    else
      echo "✓ Metadata validation passed"
    fi

    # Generate comprehensive analysis report
    cat > "$REPORT_PATH" << EOF
# CLAUDE.md Standards Analysis Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Workflow**: $WORKFLOW_ID
- **Target**: $CLAUDE_MD_PATH

## Validation Results

### Structure Validation
$(if [ ${#MISSING[@]} -eq 0 ]; then
  echo "✓ All required sections present"
else
  echo "Missing sections:"
  printf '- %s\n' "${MISSING[@]}"
fi)

### Metadata Validation
$(if [ -z "$NO_META" ]; then
  echo "✓ All sections have [Used by: ...] metadata"
else
  echo "Sections missing metadata:"
  echo "$NO_META"
fi)

## Analysis Complete

Review findings above. For optimization and cleanup operations, use:
  /optimize-claude
EOF

    echo "✓ Analysis report created: $REPORT_PATH"
    ;;
esac
```

---

## Block 3: Completion

**EXECUTE NOW**: Display final status

```bash
set +H
case "$MODE" in
  standard)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Setup Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "CLAUDE.md created at:"
    echo "  $CLAUDE_MD_PATH"
    echo ""
    echo "Workflow: $WORKFLOW_ID"
    echo ""
    echo "Next Steps:"
    echo "  Run /setup to analyze the created CLAUDE.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;

  analyze)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Analysis Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Analysis Report:"
    echo "  $REPORT_PATH"
    echo ""
    echo "Workflow: $WORKFLOW_ID"
    echo ""
    echo "Next Steps:"
    echo "  1. Review the analysis report:"
    echo "     cat $REPORT_PATH"
    echo ""
    echo "  2. Run optimization workflow:"
    echo "     /optimize-claude"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
esac
```

---

**Troubleshooting**: See `.claude/docs/guides/commands/setup-command-guide.md` for common issues and solutions.
