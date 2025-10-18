# Phase 5: Discovery and Validation Infrastructure

## Metadata
- **Phase Number**: 5
- **Parent Plan**: 072_claude_infrastructure_refactoring.md
- **Objective**: Create comprehensive discovery and validation utilities for ongoing maintenance
- **Complexity**: Medium-High
- **Status**: PENDING
- **Dependencies**: Phase 1 (agent-discovery.sh pattern), Phase 2 (modular utilities to validate)
- **Estimated Tasks**: 15 detailed tasks

## Overview

This phase creates automated discovery and validation infrastructure for maintaining the `.claude/` ecosystem. Building on the agent-discovery pattern from Phase 1 and the modular utilities from Phase 2, we'll implement comprehensive scanning, validation, and dependency mapping systems.

### Current State
- No automated command metadata extraction
- No comprehensive structure validation beyond specific validators
- No dependency mapping between commands/agents/utilities
- Manual inventory maintenance (error-prone, becomes outdated)
- Dead reference detection is manual
- No centralized command or utility registries

### Target State
- **command-discovery.sh**: Auto-scan commands for metadata extraction
- **structure-validator.sh**: Comprehensive cross-reference validation
- **dependency-mapper.sh**: Dependency graph generation and analysis
- **command-metadata.json**: Registry of all 21 commands with metadata
- **utility-dependency-map.json**: Dependency tracking for 44 utilities
- Automated dead reference detection
- Impact analysis capabilities (what breaks if X changes)

### Key Deliverables

```
.claude/lib/
├── command-discovery.sh (~300 lines)
├── structure-validator.sh (~400 lines)
└── dependency-mapper.sh (~350 lines)

.claude/data/registries/
├── command-metadata.json (auto-generated)
└── utility-dependency-map.json (auto-generated)

.claude/tests/
├── test_command_discovery.sh
├── test_structure_validator.sh
└── test_dependency_mapper.sh
```

## Stage 1: Command Discovery Implementation

### Objective
Create command-discovery.sh utility to scan `.claude/commands/` and extract comprehensive metadata.

### Tasks

#### Task 1.1: Command Discovery Core Infrastructure
**File**: `.claude/lib/command-discovery.sh`

Implement core scanning and metadata extraction framework:

```bash
#!/usr/bin/env bash
# Command Discovery Utility
# Scans .claude/commands/ and extracts metadata for registry population

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/unified-logger.sh"

# Registry paths
COMMAND_REGISTRY="${CLAUDE_ROOT}/.claude/data/registries/command-metadata.json"
COMMANDS_DIR="${CLAUDE_ROOT}/.claude/commands"

#######################################
# Extract YAML frontmatter from command file
# Arguments:
#   $1 - Command file path
# Outputs:
#   YAML frontmatter content (between --- markers)
# Returns:
#   0 on success, 1 if no frontmatter found
#######################################
extract_command_frontmatter() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    error "Command file not found: $file"
    return 1
  fi

  # Extract content between first two --- markers
  awk '/^---$/{if(p==1){exit}else{p=1;next}}p' "$file"
}

#######################################
# Parse frontmatter YAML field
# Arguments:
#   $1 - Frontmatter content
#   $2 - Field name
# Outputs:
#   Field value
# Returns:
#   0 on success, 1 if field not found
#######################################
parse_frontmatter_field() {
  local frontmatter="$1"
  local field="$2"

  echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

#######################################
# Extract sourced utilities from command
# Arguments:
#   $1 - Command file path
# Outputs:
#   Array of sourced utility file names
#######################################
extract_sourced_utilities() {
  local file="$1"

  # Find all 'source' statements
  grep -oP '(?<=source\s).*?\.sh' "$file" 2>/dev/null | \
    xargs -I {} basename {} | \
    sort -u || true
}

#######################################
# Detect agent invocations in command
# Arguments:
#   $1 - Command file path
# Outputs:
#   Array of agent names invoked
#######################################
detect_agent_invocations() {
  local file="$1"

  # Look for Task tool usage with agent names
  # Pattern: invoke_agent "agent-name" or Task tool with .claude/agents/
  grep -oP '(?<=\.claude/agents/)[a-z0-9-]+(?=\.md)' "$file" 2>/dev/null | \
    sort -u || true
}

#######################################
# Detect command dependencies
# Arguments:
#   $1 - Command file path
# Outputs:
#   Array of dependent command names
#######################################
detect_command_dependencies() {
  local file="$1"

  # Look for SlashCommand tool invocations
  # Pattern: SlashCommand with "/command-name"
  grep -oP '(?<=/)[a-z-]+(?=\s|")' "$file" 2>/dev/null | \
    grep -v -E '^(home|tmp|etc|var|usr)' | \
    sort -u || true
}

#######################################
# Scan single command file and extract metadata
# Arguments:
#   $1 - Command file path
# Outputs:
#   JSON object with command metadata
#######################################
scan_command_file() {
  local file="$1"
  local filename=$(basename "$file" .md)

  log_info "Scanning command: $filename"

  # Extract frontmatter
  local frontmatter
  frontmatter=$(extract_command_frontmatter "$file") || {
    log_warn "No frontmatter in $filename, skipping"
    return 1
  }

  # Parse frontmatter fields
  local cmd_type
  local description
  local dependent_cmds
  local allowed_tools

  cmd_type=$(parse_frontmatter_field "$frontmatter" "command-type" || echo "unknown")
  description=$(parse_frontmatter_field "$frontmatter" "description" || echo "")
  dependent_cmds=$(parse_frontmatter_field "$frontmatter" "dependent-commands" || echo "")
  allowed_tools=$(parse_frontmatter_field "$frontmatter" "allowed-tools" || echo "")

  # Extract dependencies
  local sourced_utils
  local agent_invocations
  local cmd_dependencies

  sourced_utils=$(extract_sourced_utilities "$file")
  agent_invocations=$(detect_agent_invocations "$file")
  cmd_dependencies=$(detect_command_dependencies "$file")

  # Get file stats
  local last_modified
  last_modified=$(stat -c %y "$file" 2>/dev/null || stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "$file")

  local line_count
  line_count=$(wc -l < "$file")

  # Build JSON object
  cat <<EOF
{
  "name": "$filename",
  "type": "$cmd_type",
  "description": "$description",
  "file_path": "$file",
  "line_count": $line_count,
  "last_modified": "$last_modified",
  "dependencies": {
    "utilities": $(echo "$sourced_utils" | jq -R -s -c 'split("\n") | map(select(length > 0))'),
    "agents": $(echo "$agent_invocations" | jq -R -s -c 'split("\n") | map(select(length > 0))'),
    "commands": $(echo "$cmd_dependencies" | jq -R -s -c 'split("\n") | map(select(length > 0))')
  },
  "allowed_tools": $(echo "$allowed_tools" | tr ',' '\n' | sed 's/^[[:space:]]*//' | jq -R -s -c 'split("\n") | map(select(length > 0))'),
  "dependent_commands": $(echo "$dependent_cmds" | tr ',' '\n' | sed 's/^[[:space:]]*//' | jq -R -s -c 'split("\n") | map(select(length > 0))')
}
EOF
}
```

**Implementation Details**:
- Parse YAML frontmatter using awk (between --- markers)
- Extract command-type, description, dependent-commands from frontmatter
- Detect sourced utilities via grep for `source` statements
- Detect agent invocations via pattern matching `.claude/agents/`
- Detect command dependencies via SlashCommand tool usage
- Generate JSON metadata per command
- Handle missing frontmatter gracefully

**Testing Requirements**:
- Test frontmatter extraction with various formats
- Test utility detection accuracy
- Test agent invocation detection
- Test command dependency detection
- Test JSON generation validity

#### Task 1.2: Registry Population and Management
**File**: `.claude/lib/command-discovery.sh` (continued)

Implement registry population functions:

```bash
#######################################
# Scan all commands and build registry
# Outputs:
#   Complete command-metadata.json content
#######################################
build_command_registry() {
  log_info "Building command registry from $COMMANDS_DIR"

  local commands_json="[]"

  # Scan all command markdown files
  while IFS= read -r cmd_file; do
    local cmd_metadata
    if cmd_metadata=$(scan_command_file "$cmd_file"); then
      commands_json=$(echo "$commands_json" | jq --argjson new "$cmd_metadata" \
        '. + [$new]')
    fi
  done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f | sort)

  # Build complete registry structure
  cat <<EOF
{
  "metadata": {
    "created": "$(date -Iseconds)",
    "last_updated": "$(date -Iseconds)",
    "total_commands": $(echo "$commands_json" | jq 'length'),
    "registry_version": "1.0.0"
  },
  "commands": $(echo "$commands_json" | jq 'INDEX(.name)')
}
EOF
}

#######################################
# Update existing registry with new scan results
# Arguments:
#   $1 - Registry file path (optional, defaults to COMMAND_REGISTRY)
#######################################
update_command_registry() {
  local registry_file="${1:-$COMMAND_REGISTRY}"

  log_info "Updating command registry: $registry_file"

  # Ensure registry directory exists
  mkdir -p "$(dirname "$registry_file")"

  # Build new registry
  local new_registry
  new_registry=$(build_command_registry)

  # Write to file
  echo "$new_registry" | jq '.' > "$registry_file"

  success "Command registry updated: $registry_file"
  echo "$new_registry" | jq -r '.metadata'
}

#######################################
# Query registry for specific command
# Arguments:
#   $1 - Command name
#   $2 - Registry file path (optional)
# Outputs:
#   Command metadata JSON
#######################################
query_command() {
  local cmd_name="$1"
  local registry_file="${2:-$COMMAND_REGISTRY}"

  if [[ ! -f "$registry_file" ]]; then
    error "Registry not found: $registry_file. Run update_command_registry first."
    return 1
  fi

  jq -r --arg name "$cmd_name" '.commands[$name] // empty' "$registry_file"
}

#######################################
# List all commands of specific type
# Arguments:
#   $1 - Command type (primary|dependent|workflow|utility|example)
#   $2 - Registry file path (optional)
# Outputs:
#   Array of command names
#######################################
list_commands_by_type() {
  local cmd_type="$1"
  local registry_file="${2:-$COMMAND_REGISTRY}"

  if [[ ! -f "$registry_file" ]]; then
    error "Registry not found: $registry_file"
    return 1
  fi

  jq -r --arg type "$cmd_type" \
    '.commands | to_entries | .[] | select(.value.type == $type) | .key' \
    "$registry_file"
}
```

**Implementation Details**:
- Build registry by scanning all .md files in .claude/commands/
- Store as JSON with indexed command objects (by name)
- Include metadata section with timestamp, version, count
- Provide query functions for registry access
- Support filtering by command type

**Testing Requirements**:
- Test registry building from scratch
- Test registry updates preserve existing data
- Test query functions return correct results
- Test filtering by type
- Validate JSON schema compliance

#### Task 1.3: Command Discovery Testing
**File**: `.claude/tests/test_command_discovery.sh`

Create comprehensive test suite:

```bash
#!/usr/bin/env bash
# Test suite for command-discovery.sh

source .claude/lib/test-framework.sh
source .claude/lib/command-discovery.sh

test_extract_frontmatter() {
  # Create test command with frontmatter
  local test_file=$(mktemp)
  cat > "$test_file" <<'EOF'
---
command-type: primary
description: Test command
dependent-commands: foo, bar
---
# Command Content
EOF

  local frontmatter
  frontmatter=$(extract_command_frontmatter "$test_file")

  assert_contains "$frontmatter" "command-type: primary"
  assert_contains "$frontmatter" "description: Test command"

  rm -f "$test_file"
}

test_detect_sourced_utilities() {
  local test_file=$(mktemp)
  cat > "$test_file" <<'EOF'
source .claude/lib/base-utils.sh
source .claude/lib/plan-core-bundle.sh
source "$SCRIPT_DIR/artifact-operations.sh"
EOF

  local utils
  utils=$(extract_sourced_utilities "$test_file")

  assert_contains "$utils" "base-utils.sh"
  assert_contains "$utils" "plan-core-bundle.sh"
  assert_contains "$utils" "artifact-operations.sh"

  rm -f "$test_file"
}

test_detect_agent_invocations() {
  local test_file=$(mktemp)
  cat > "$test_file" <<'EOF'
invoke_agent ".claude/agents/plan-architect.md"
load_agent ".claude/agents/code-writer.md"
EOF

  local agents
  agents=$(detect_agent_invocations "$test_file")

  assert_contains "$agents" "plan-architect"
  assert_contains "$agents" "code-writer"

  rm -f "$test_file"
}

test_build_command_registry() {
  local registry
  registry=$(build_command_registry)

  assert_valid_json "$registry"

  local count
  count=$(echo "$registry" | jq -r '.metadata.total_commands')
  assert_greater_than "$count" 0

  # Should contain known commands
  assert_command_exists "$registry" "plan"
  assert_command_exists "$registry" "implement"
}

run_all_tests
```

**Success Criteria**:
- All frontmatter parsing tests pass
- Utility detection accurate for all sourcing patterns
- Agent invocation detection catches all patterns
- Registry building produces valid JSON
- Registry contains all 21 commands

## Stage 2: Structure Validation Implementation

### Objective
Create structure-validator.sh to validate `.claude/` directory structure and detect issues.

### Tasks

#### Task 2.1: Dead Reference Detection
**File**: `.claude/lib/structure-validator.sh`

Implement cross-reference validation:

```bash
#!/usr/bin/env bash
# Structure Validator Utility
# Validates .claude/ directory structure and cross-references

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/unified-logger.sh"

# Configuration
CLAUDE_ROOT="${CLAUDE_ROOT:-.}"
COMMANDS_DIR="$CLAUDE_ROOT/.claude/commands"
AGENTS_DIR="$CLAUDE_ROOT/.claude/agents"
DOCS_DIR="$CLAUDE_ROOT/.claude/docs"
LIB_DIR="$CLAUDE_ROOT/.claude/lib"
SHARED_DIR="$COMMANDS_DIR/shared"

# Validation results
declare -a VALIDATION_ERRORS=()
declare -a VALIDATION_WARNINGS=()
declare -i ERROR_COUNT=0
declare -i WARNING_COUNT=0

#######################################
# Add validation error
# Arguments:
#   $1 - Error message
#######################################
add_error() {
  VALIDATION_ERRORS+=("$1")
  ((ERROR_COUNT++))
  log_error "$1"
}

#######################################
# Add validation warning
# Arguments:
#   $1 - Warning message
#######################################
add_warning() {
  VALIDATION_WARNINGS+=("$1")
  ((WARNING_COUNT++))
  log_warn "$1"
}

#######################################
# Validate shared documentation references in commands
# Checks that all referenced files in commands/shared/ exist
#######################################
validate_shared_doc_references() {
  log_info "Validating shared documentation references..."

  local -i refs_found=0
  local -i refs_missing=0

  # Find all references to commands/shared/ in command files
  while IFS= read -r cmd_file; do
    while IFS= read -r ref; do
      ((refs_found++))

      # Extract referenced file path
      local ref_file="$COMMANDS_DIR/shared/$ref"

      if [[ ! -f "$ref_file" ]]; then
        add_error "Dead reference in $(basename "$cmd_file"): shared/$ref not found"
        ((refs_missing++))
      fi
    done < <(grep -oP '(?<=commands/shared/)[a-zA-Z0-9_-]+\.md' "$cmd_file" 2>/dev/null || true)
  done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f)

  if [[ $refs_missing -eq 0 ]]; then
    success "All $refs_found shared doc references valid"
  else
    add_error "$refs_missing/$refs_found shared doc references broken"
  fi
}

#######################################
# Validate agent references in commands
# Checks that all referenced agents exist
#######################################
validate_agent_references() {
  log_info "Validating agent references..."

  local -i refs_found=0
  local -i refs_missing=0

  # Find all agent references in command files
  while IFS= read -r cmd_file; do
    while IFS= read -r agent_ref; do
      ((refs_found++))

      local agent_file="$AGENTS_DIR/${agent_ref}.md"

      if [[ ! -f "$agent_file" ]]; then
        add_error "Dead agent reference in $(basename "$cmd_file"): $agent_ref not found"
        ((refs_missing++))
      fi
    done < <(grep -oP '(?<=\.claude/agents/)[a-z0-9-]+(?=\.md)' "$cmd_file" 2>/dev/null || true)
  done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f)

  if [[ $refs_missing -eq 0 ]]; then
    success "All $refs_found agent references valid"
  else
    add_error "$refs_missing/$refs_found agent references broken"
  fi
}

#######################################
# Validate utility references in commands and agents
# Checks that all sourced utilities exist
#######################################
validate_utility_references() {
  log_info "Validating utility references..."

  local -i refs_found=0
  local -i refs_missing=0

  # Check commands
  while IFS= read -r file; do
    while IFS= read -r util_ref; do
      ((refs_found++))

      # Resolve utility path
      local util_file="$LIB_DIR/$util_ref"

      if [[ ! -f "$util_file" ]]; then
        add_error "Dead utility reference in $(basename "$file"): $util_ref not found"
        ((refs_missing++))
      fi
    done < <(grep -oP '(?<=source\s).*?\.sh' "$file" 2>/dev/null | xargs -I {} basename {} || true)
  done < <(find "$COMMANDS_DIR" -name "*.md" -type f)

  # Check agents
  while IFS= read -r file; do
    while IFS= read -r util_ref; do
      ((refs_found++))

      local util_file="$LIB_DIR/$util_ref"

      if [[ ! -f "$util_file" ]]; then
        add_warning "Dead utility reference in agent $(basename "$file"): $util_ref not found"
        ((refs_missing++))
      fi
    done < <(grep -oP '(?<=source\s).*?\.sh' "$file" 2>/dev/null | xargs -I {} basename {} || true)
  done < <(find "$AGENTS_DIR" -name "*.md" -type f)

  if [[ $refs_missing -eq 0 ]]; then
    success "All $refs_found utility references valid"
  fi
}

#######################################
# Validate documentation cross-references
# Checks internal links in documentation
#######################################
validate_doc_cross_references() {
  log_info "Validating documentation cross-references..."

  local -i refs_found=0
  local -i refs_missing=0

  while IFS= read -r doc_file; do
    # Find markdown links: [text](path)
    while IFS= read -r link_path; do
      ((refs_found++))

      # Skip external URLs
      if [[ "$link_path" =~ ^https?:// ]]; then
        continue
      fi

      # Resolve relative path
      local doc_dir=$(dirname "$doc_file")
      local resolved_path="$doc_dir/$link_path"

      if [[ ! -f "$resolved_path" && ! -d "$resolved_path" ]]; then
        add_warning "Broken link in $(basename "$doc_file"): $link_path"
        ((refs_missing++))
      fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+' "$doc_file" 2>/dev/null || true)
  done < <(find "$DOCS_DIR" -name "*.md" -type f)

  if [[ $refs_missing -eq 0 ]]; then
    success "All $refs_found documentation links valid"
  fi
}
```

#### Task 2.2: File Structure Compliance Validation
**File**: `.claude/lib/structure-validator.sh` (continued)

```bash
#######################################
# Validate .claude/ directory structure
# Checks for required directories and files
#######################################
validate_directory_structure() {
  log_info "Validating directory structure..."

  # Required directories
  local required_dirs=(
    ".claude/commands"
    ".claude/agents"
    ".claude/docs"
    ".claude/lib"
    ".claude/tests"
    ".claude/data/registries"
  )

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$CLAUDE_ROOT/$dir" ]]; then
      add_error "Required directory missing: $dir"
    fi
  done

  # Required files
  local required_files=(
    ".claude/commands/README.md"
    ".claude/agents/agent-registry.json"
    ".claude/docs/README.md"
    ".claude/lib/base-utils.sh"
  )

  for file in "${required_files[@]}"; do
    if [[ ! -f "$CLAUDE_ROOT/$file" ]]; then
      add_error "Required file missing: $file"
    fi
  done

  success "Directory structure validation complete"
}

#######################################
# Validate command frontmatter compliance
# Checks that all commands have valid frontmatter
#######################################
validate_command_frontmatter() {
  log_info "Validating command frontmatter..."

  local -i valid_count=0
  local -i invalid_count=0

  while IFS= read -r cmd_file; do
    local frontmatter
    if ! frontmatter=$(awk '/^---$/{if(p==1){exit}else{p=1;next}}p' "$cmd_file"); then
      add_warning "No frontmatter in $(basename "$cmd_file")"
      ((invalid_count++))
      continue
    fi

    # Check required fields
    local has_type=$(echo "$frontmatter" | grep -c "^command-type:" || true)
    local has_desc=$(echo "$frontmatter" | grep -c "^description:" || true)

    if [[ $has_type -eq 0 ]]; then
      add_warning "Missing command-type in $(basename "$cmd_file")"
      ((invalid_count++))
    elif [[ $has_desc -eq 0 ]]; then
      add_warning "Missing description in $(basename "$cmd_file")"
      ((invalid_count++))
    else
      ((valid_count++))
    fi
  done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f)

  success "$valid_count commands have valid frontmatter, $invalid_count warnings"
}

#######################################
# Run all validations and generate report
# Outputs:
#   Validation report with all errors and warnings
# Returns:
#   0 if no errors, 1 if errors found
#######################################
run_validation() {
  log_info "Starting comprehensive structure validation..."

  # Reset counters
  VALIDATION_ERRORS=()
  VALIDATION_WARNINGS=()
  ERROR_COUNT=0
  WARNING_COUNT=0

  # Run all validation checks
  validate_directory_structure
  validate_shared_doc_references
  validate_agent_references
  validate_utility_references
  validate_doc_cross_references
  validate_command_frontmatter

  # Generate report
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "STRUCTURE VALIDATION REPORT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Errors: $ERROR_COUNT"
  echo "Warnings: $WARNING_COUNT"
  echo ""

  if [[ $ERROR_COUNT -gt 0 ]]; then
    echo "ERRORS:"
    printf '%s\n' "${VALIDATION_ERRORS[@]}"
    echo ""
  fi

  if [[ $WARNING_COUNT -gt 0 ]]; then
    echo "WARNINGS:"
    printf '%s\n' "${VALIDATION_WARNINGS[@]}"
    echo ""
  fi

  if [[ $ERROR_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
    success "✓ All validations passed"
    return 0
  elif [[ $ERROR_COUNT -eq 0 ]]; then
    log_warn "Validation complete with warnings"
    return 0
  else
    error "Validation failed with $ERROR_COUNT errors"
    return 1
  fi
}
```

#### Task 2.3: Structure Validation Testing
**File**: `.claude/tests/test_structure_validator.sh`

```bash
#!/usr/bin/env bash
# Test suite for structure-validator.sh

source .claude/lib/test-framework.sh
source .claude/lib/structure-validator.sh

test_detect_dead_shared_reference() {
  # Create test command with dead reference
  local test_file="$COMMANDS_DIR/test-cmd.md"
  echo "See commands/shared/nonexistent.md" > "$test_file"

  validate_shared_doc_references

  assert_greater_than "$ERROR_COUNT" 0

  rm -f "$test_file"
}

test_detect_missing_agent() {
  local test_file="$COMMANDS_DIR/test-cmd.md"
  echo "invoke .claude/agents/nonexistent-agent.md" > "$test_file"

  validate_agent_references

  assert_greater_than "$ERROR_COUNT" 0

  rm -f "$test_file"
}

test_validate_directory_structure() {
  # Should pass for valid .claude/ structure
  validate_directory_structure

  # Check required directories exist
  assert_directory_exists ".claude/commands"
  assert_directory_exists ".claude/agents"
  assert_directory_exists ".claude/lib"
}

run_all_tests
```

**Success Criteria**:
- Detects all dead references (shared docs, agents, utilities)
- Validates directory structure compliance
- Checks frontmatter compliance in all commands
- Validates documentation cross-references
- Generates accurate validation reports

## Stage 3: Dependency Mapping Implementation

### Objective
Create dependency-mapper.sh to generate dependency graphs and enable impact analysis.

### Tasks

#### Task 3.1: Dependency Graph Construction
**File**: `.claude/lib/dependency-mapper.sh`

```bash
#!/usr/bin/env bash
# Dependency Mapper Utility
# Maps dependencies between commands, agents, and utilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/unified-logger.sh"

# Configuration
DEPENDENCY_MAP="${CLAUDE_ROOT}/.claude/data/registries/utility-dependency-map.json"

#######################################
# Build utility dependency graph
# Outputs:
#   JSON dependency map
#######################################
build_utility_dependency_map() {
  log_info "Building utility dependency map..."

  local utilities_json="{}"

  # Scan all utilities
  while IFS= read -r util_file; do
    local util_name=$(basename "$util_file")

    # Find what sources this utility
    local sourced_by=()

    # Check commands
    while IFS= read -r cmd_file; do
      if grep -q "$util_name" "$cmd_file" 2>/dev/null; then
        sourced_by+=("command:$(basename "$cmd_file" .md)")
      fi
    done < <(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -type f)

    # Check other utilities
    while IFS= read -r other_util; do
      if [[ "$other_util" != "$util_file" ]]; then
        if grep -q "$util_name" "$other_util" 2>/dev/null; then
          sourced_by+=("utility:$(basename "$other_util")")
        fi
      fi
    done < <(find "$LIB_DIR" -name "*.sh" -type f)

    # Find dependencies of this utility
    local dependencies=()
    while IFS= read -r dep; do
      dependencies+=("$dep")
    done < <(grep -oP '(?<=source\s).*?\.sh' "$util_file" 2>/dev/null | xargs -I {} basename {} || true)

    # Extract exported functions
    local functions=()
    while IFS= read -r func; do
      functions+=("$func")
    done < <(grep -oP '^[a-z_][a-z0-9_]*\(\)' "$util_file" | sed 's/()//' || true)

    # Build JSON entry
    local sourced_by_json=$(printf '%s\n' "${sourced_by[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))')
    local dependencies_json=$(printf '%s\n' "${dependencies[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))')
    local functions_json=$(printf '%s\n' "${functions[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))')

    utilities_json=$(echo "$utilities_json" | jq \
      --arg name "$util_name" \
      --argjson sourced_by "$sourced_by_json" \
      --argjson deps "$dependencies_json" \
      --argjson funcs "$functions_json" \
      '.[$name] = {
        "sourced_by": $sourced_by,
        "dependencies": $deps,
        "functions_exported": $funcs
      }')
  done < <(find "$LIB_DIR" -name "*.sh" -type f | sort)

  # Build complete map
  cat <<EOF
{
  "metadata": {
    "created": "$(date -Iseconds)",
    "total_utilities": $(echo "$utilities_json" | jq 'length')
  },
  "utilities": $utilities_json
}
EOF
}

#######################################
# Detect circular dependencies
# Arguments:
#   $1 - Dependency map JSON
# Outputs:
#   Array of circular dependency chains
#######################################
detect_circular_dependencies() {
  local dep_map="$1"

  log_info "Detecting circular dependencies..."

  # Simple cycle detection: for each utility, check if it transitively depends on itself
  local -a cycles=()

  while IFS= read -r util_name; do
    local -A visited=()
    local -a stack=("$util_name")

    while [[ ${#stack[@]} -gt 0 ]]; do
      local current="${stack[-1]}"
      unset 'stack[-1]'

      if [[ -n "${visited[$current]:-}" ]]; then
        continue
      fi
      visited[$current]=1

      # Get dependencies of current
      local deps
      deps=$(echo "$dep_map" | jq -r --arg util "$current" '.utilities[$util].dependencies[]? // empty')

      while IFS= read -r dep; do
        if [[ "$dep" == "$util_name" ]]; then
          cycles+=("Circular: $util_name -> ... -> $dep")
        else
          stack+=("$dep")
        fi
      done <<< "$deps"
    done
  done < <(echo "$dep_map" | jq -r '.utilities | keys[]')

  printf '%s\n' "${cycles[@]}"
}

#######################################
# Generate text-based dependency graph
# Arguments:
#   $1 - Utility name
#   $2 - Dependency map JSON
# Outputs:
#   Tree visualization of dependencies
#######################################
generate_dependency_tree() {
  local util_name="$1"
  local dep_map="$2"
  local prefix="${3:-}"

  echo "${prefix}${util_name}"

  local deps
  deps=$(echo "$dep_map" | jq -r --arg util "$util_name" '.utilities[$util].dependencies[]? // empty')

  local -a dep_array=()
  while IFS= read -r dep; do
    [[ -n "$dep" ]] && dep_array+=("$dep")
  done <<< "$deps"

  for i in "${!dep_array[@]}"; do
    local dep="${dep_array[$i]}"
    if [[ $i -eq $((${#dep_array[@]} - 1)) ]]; then
      generate_dependency_tree "$dep" "$dep_map" "${prefix}└─ "
    else
      generate_dependency_tree "$dep" "$dep_map" "${prefix}├─ "
    fi
  done
}

#######################################
# Analyze impact of changing a utility
# Arguments:
#   $1 - Utility name
#   $2 - Dependency map JSON
# Outputs:
#   Impact analysis report
#######################################
analyze_utility_impact() {
  local util_name="$1"
  local dep_map="$2"

  log_info "Analyzing impact of changes to $util_name"

  # Find direct consumers
  local sourced_by
  sourced_by=$(echo "$dep_map" | jq -r --arg util "$util_name" '.utilities[$util].sourced_by[]? // empty')

  local -a commands=()
  local -a utilities=()

  while IFS= read -r consumer; do
    if [[ "$consumer" =~ ^command: ]]; then
      commands+=("${consumer#command:}")
    elif [[ "$consumer" =~ ^utility: ]]; then
      utilities+=("${consumer#utility:}")
    fi
  done <<< "$sourced_by"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "IMPACT ANALYSIS: $util_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Direct Impact:"
  echo "  Commands affected: ${#commands[@]}"
  echo "  Utilities affected: ${#utilities[@]}"
  echo ""

  if [[ ${#commands[@]} -gt 0 ]]; then
    echo "Affected Commands:"
    printf '  - %s\n' "${commands[@]}"
    echo ""
  fi

  if [[ ${#utilities[@]} -gt 0 ]]; then
    echo "Affected Utilities:"
    printf '  - %s\n' "${utilities[@]}"
    echo ""

    echo "Transitive Impact (utilities that depend on affected utilities):"
    for util in "${utilities[@]}"; do
      local trans_sourced
      trans_sourced=$(echo "$dep_map" | jq -r --arg util "$util" '.utilities[$util].sourced_by[]? // empty')
      if [[ -n "$trans_sourced" ]]; then
        echo "  Via $util:"
        echo "$trans_sourced" | sed 's/^/    - /'
      fi
    done
  fi
}
```

#### Task 3.2: Dependency Mapping Testing
**File**: `.claude/tests/test_dependency_mapper.sh`

```bash
#!/usr/bin/env bash
# Test suite for dependency-mapper.sh

source .claude/lib/test-framework.sh
source .claude/lib/dependency-mapper.sh

test_build_dependency_map() {
  local dep_map
  dep_map=$(build_utility_dependency_map)

  assert_valid_json "$dep_map"

  local total_utils
  total_utils=$(echo "$dep_map" | jq -r '.metadata.total_utilities')
  assert_greater_than "$total_utils" 0
}

test_detect_circular_deps() {
  # Create test utilities with circular dependency
  echo 'source test-util-b.sh' > /tmp/test-util-a.sh
  echo 'source test-util-a.sh' > /tmp/test-util-b.sh

  # Build map and detect cycles
  local dep_map
  dep_map=$(build_utility_dependency_map)

  local cycles
  cycles=$(detect_circular_dependencies "$dep_map")

  # Should detect the cycle
  assert_contains "$cycles" "Circular"

  rm -f /tmp/test-util-{a,b}.sh
}

test_impact_analysis() {
  local dep_map
  dep_map=$(build_utility_dependency_map)

  # Analyze impact of base-utils.sh (should affect many things)
  local impact
  impact=$(analyze_utility_impact "base-utils.sh" "$dep_map")

  assert_contains "$impact" "Commands affected"
  assert_contains "$impact" "Utilities affected"
}

run_all_tests
```

**Success Criteria**:
- Accurately maps all utility dependencies
- Detects circular dependencies
- Generates readable dependency trees
- Provides accurate impact analysis
- Handles edge cases (missing files, broken refs)

## Stage 4: Registry Population and Management

### Objective
Populate command-metadata.json and utility-dependency-map.json registries and create management utilities.

### Tasks

#### Task 4.1: Initial Registry Population
**File**: `.claude/lib/populate-registries.sh`

```bash
#!/usr/bin/env bash
# Registry Population Utility
# Populates all discovery registries

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/command-discovery.sh"
source "$SCRIPT_DIR/dependency-mapper.sh"

#######################################
# Populate all registries
# Arguments:
#   --dry-run: Show what would be done without making changes
#######################################
populate_all_registries() {
  local dry_run=false

  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
    log_info "DRY RUN MODE - no changes will be made"
  fi

  log_info "Populating all discovery registries..."

  # 1. Command registry
  if [[ "$dry_run" == false ]]; then
    update_command_registry
  else
    log_info "[DRY RUN] Would update command registry"
  fi

  # 2. Utility dependency map
  if [[ "$dry_run" == false ]]; then
    local dep_map
    dep_map=$(build_utility_dependency_map)

    mkdir -p "$(dirname "$DEPENDENCY_MAP")"
    echo "$dep_map" | jq '.' > "$DEPENDENCY_MAP"

    success "Utility dependency map created: $DEPENDENCY_MAP"
  else
    log_info "[DRY RUN] Would build utility dependency map"
  fi

  # 3. Validation report
  if [[ "$dry_run" == false ]]; then
    run_validation > "$CLAUDE_ROOT/.claude/data/validation-report.txt"
    success "Validation report created"
  else
    log_info "[DRY RUN] Would run structure validation"
  fi

  success "Registry population complete"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  populate_all_registries "$@"
fi
```

#### Task 4.2: Registry Query Utilities
**File**: `.claude/lib/query-registries.sh`

```bash
#!/usr/bin/env bash
# Registry Query Utilities
# Convenience functions for querying discovery registries

source "$(dirname "${BASH_SOURCE[0]}")/command-discovery.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dependency-mapper.sh"

#######################################
# Find commands that use a specific utility
# Arguments:
#   $1 - Utility name
#######################################
find_commands_using_utility() {
  local util_name="$1"

  jq -r --arg util "$util_name" \
    '.commands | to_entries[] | select(.value.dependencies.utilities | index($util)) | .key' \
    "$COMMAND_REGISTRY"
}

#######################################
# Find commands that invoke a specific agent
# Arguments:
#   $1 - Agent name
#######################################
find_commands_using_agent() {
  local agent_name="$1"

  jq -r --arg agent "$agent_name" \
    '.commands | to_entries[] | select(.value.dependencies.agents | index($agent)) | .key' \
    "$COMMAND_REGISTRY"
}

#######################################
# Show utility usage statistics
# Outputs:
#   Table of utilities sorted by usage count
#######################################
show_utility_usage_stats() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "UTILITY USAGE STATISTICS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  printf "%-40s %s\n" "Utility" "Usage Count"
  echo "────────────────────────────────────────────────────"

  jq -r '.utilities | to_entries[] |
    "\(.key)|\(.value.sourced_by | length)"' \
    "$DEPENDENCY_MAP" | \
  while IFS='|' read -r util count; do
    printf "%-40s %d\n" "$util" "$count"
  done | sort -k2 -nr
}
```

**Success Criteria**:
- Registries populated with accurate data
- Query utilities work correctly
- Dry-run mode prevents accidental changes
- Statistics generation accurate

## Stage 5: Testing and Integration

### Objective
Create comprehensive test suite and validate all discovery utilities.

### Tasks

#### Task 5.1: Integration Testing
**File**: `.claude/tests/test_discovery_integration.sh`

```bash
#!/usr/bin/env bash
# Integration tests for discovery infrastructure

source .claude/lib/test-framework.sh

test_full_discovery_workflow() {
  # Test complete workflow: scan -> populate -> validate -> query

  log_info "Testing full discovery workflow..."

  # 1. Populate registries
  bash .claude/lib/populate-registries.sh

  # 2. Verify registries exist
  assert_file_exists "$COMMAND_REGISTRY"
  assert_file_exists "$DEPENDENCY_MAP"

  # 3. Validate structure
  source .claude/lib/structure-validator.sh
  run_validation

  # 4. Query registries
  source .claude/lib/query-registries.sh
  local plan_cmd
  plan_cmd=$(query_command "plan")

  assert_valid_json "$plan_cmd"
  assert_contains "$plan_cmd" "description"
}

test_registry_update_idempotency() {
  # Test that updating registries twice produces same result

  bash .claude/lib/populate-registries.sh
  local first_update=$(cat "$COMMAND_REGISTRY")

  sleep 1

  bash .claude/lib/populate-registries.sh
  local second_update=$(cat "$COMMAND_REGISTRY")

  # Ignore timestamp differences
  local first_clean=$(echo "$first_update" | jq 'del(.metadata.last_updated)')
  local second_clean=$(echo "$second_update" | jq 'del(.metadata.last_updated)')

  assert_equals "$first_clean" "$second_clean"
}

run_all_tests
```

#### Task 5.2: Performance Testing
**File**: `.claude/tests/test_discovery_performance.sh`

```bash
#!/usr/bin/env bash
# Performance tests for discovery utilities

test_command_discovery_performance() {
  log_info "Testing command discovery performance..."

  local start_time=$(date +%s%N)

  source .claude/lib/command-discovery.sh
  update_command_registry

  local end_time=$(date +%s%N)
  local duration=$(( (end_time - start_time) / 1000000 ))

  log_info "Command discovery took ${duration}ms"

  # Should complete in < 5 seconds for 21 commands
  assert_less_than "$duration" 5000
}

test_dependency_mapping_performance() {
  log_info "Testing dependency mapping performance..."

  local start_time=$(date +%s%N)

  source .claude/lib/dependency-mapper.sh
  build_utility_dependency_map > /dev/null

  local end_time=$(date +%s%N)
  local duration=$(( (end_time - start_time) / 1000000 ))

  log_info "Dependency mapping took ${duration}ms"

  # Should complete in < 10 seconds for 44 utilities
  assert_less_than "$duration" 10000
}
```

**Success Criteria**:
- All integration tests pass
- Registry updates are idempotent
- Performance within acceptable limits
- No regressions in existing functionality

## Testing Summary

### Test Coverage

**Unit Tests**:
- `test_command_discovery.sh`: 8 tests for metadata extraction
- `test_structure_validator.sh`: 6 tests for validation checks
- `test_dependency_mapper.sh`: 5 tests for dependency analysis

**Integration Tests**:
- `test_discovery_integration.sh`: 4 tests for full workflow
- `test_discovery_performance.sh`: 2 tests for performance

**Total**: 25 new tests covering all discovery utilities

### Test Execution

```bash
# Run all discovery tests
.claude/tests/run_all_tests.sh --category discovery

# Run specific test
bash .claude/tests/test_command_discovery.sh

# Run with verbose output
DEBUG=1 bash .claude/tests/test_structure_validator.sh
```

## Success Criteria

### Functional Requirements
- [ ] command-discovery.sh scans all 21 commands accurately
- [ ] structure-validator.sh detects all known issues
- [ ] dependency-mapper.sh generates accurate graphs
- [ ] command-metadata.json populated with complete data
- [ ] utility-dependency-map.json tracks all 44 utilities
- [ ] Dead reference detection catches broken links
- [ ] Impact analysis provides accurate results

### Quality Requirements
- [ ] All 25 tests pass
- [ ] Command discovery completes in < 5 seconds
- [ ] Dependency mapping completes in < 10 seconds
- [ ] No false positives in validation
- [ ] Registry updates are idempotent
- [ ] Comprehensive error handling

### Documentation Requirements
- [ ] All utilities have inline documentation
- [ ] Function comments follow standards
- [ ] README sections updated
- [ ] Usage examples provided

## Dependencies

### From Phase 1
- Agent-discovery.sh pattern for scanning and metadata extraction
- Agent-registry.json schema as template for command registry

### From Phase 2
- Modular utilities as validation targets
- base-utils.sh for error handling
- unified-logger.sh for logging

### Integration Points
- Validation utilities from Phase 3 (if exists)
- Documentation structure from Phase 4
- Agent registry from Phase 1

## Notes

### Design Decisions

**Why JSON registries instead of databases?**
- Simplicity: Easy to inspect and modify manually
- Portability: No external dependencies
- Git-friendly: Can track changes in version control
- Sufficient scale: 21 commands, 44 utilities, 19 agents

**Why separate command-discovery from structure-validator?**
- Single Responsibility: Discovery focuses on metadata extraction
- Validation focuses on correctness checking
- Allows independent evolution of both utilities
- Different use cases: discovery for inventory, validation for CI/CD

**Why text-based dependency graphs?**
- No external visualization tools required
- Works in terminal environments
- Sufficient for current needs
- Can add visual rendering later if needed

### Future Enhancements

**Out of scope for this phase**:
- Real-time registry updates during command execution
- Web-based visualization of dependency graphs
- Automated dependency update recommendations
- Pre-commit hooks for validation
- Registry API for programmatic access
- Historical tracking of registry changes

---

**Phase Status**: PENDING
**Ready for**: Implementation via `/implement`
**Estimated effort**: 2-3 days for complete implementation and testing
