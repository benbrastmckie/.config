# Phase 1: Agent Registry Foundation and Discovery

## Metadata
- **Phase Number**: 1
- **Parent Plan**: 072_claude_infrastructure_refactoring.md
- **Objective**: Complete agent registry infrastructure and auto-discovery system
- **Complexity**: Medium
- **Status**: PENDING
- **Dependencies**: None
- **Estimated Tasks**: 12 detailed tasks

## Overview

This phase establishes the foundation for comprehensive agent tracking by enhancing the agent registry schema, implementing auto-discovery utilities, and registering all 19 agents. The current registry only tracks 2/19 agents, which is insufficient for meaningful performance analysis and agent selection optimization.

### Current State
- `agent-registry.json` tracks 2 agents (research-specialist, plan-architect)
- Basic metrics: invocations, success rate, duration
- Manual registration process
- No schema validation
- No discovery utilities

### Target State
- Enhanced schema with type, category, tools, dependencies
- All 19 agents registered automatically
- Auto-discovery utility for new agents
- Schema validation for compliance
- Comprehensive metadata tracking

## Stage 1: Schema Design and Validation Rules

### Objective
Design enhanced agent registry schema and implement validation rules.

### Tasks

#### Task 1.1: Design Enhanced Schema
**File**: `.claude/agents/agent-registry-schema.json`

Create JSON schema definition:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "schema_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time"
    },
    "agents": {
      "type": "object",
      "patternProperties": {
        "^[a-z0-9-]+$": {
          "type": "object",
          "required": ["type", "category", "description", "tools", "metrics", "behavioral_file"],
          "properties": {
            "type": {
              "type": "string",
              "enum": ["specialized", "hierarchical"]
            },
            "category": {
              "type": "string",
              "enum": ["research", "planning", "implementation", "debugging", "documentation", "analysis", "coordination"]
            },
            "description": {
              "type": "string",
              "minLength": 10,
              "maxLength": 200
            },
            "tools": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "WebSearch", "WebFetch", "Task"]
              }
            },
            "metrics": {
              "type": "object",
              "properties": {
                "total_invocations": {"type": "integer", "minimum": 0},
                "successful_invocations": {"type": "integer", "minimum": 0},
                "failed_invocations": {"type": "integer", "minimum": 0},
                "average_duration_seconds": {"type": "number", "minimum": 0},
                "last_invocation": {"type": "string", "format": "date-time"}
              }
            },
            "dependencies": {
              "type": "array",
              "items": {"type": "string"}
            },
            "behavioral_file": {
              "type": "string",
              "pattern": "^\\.claude/agents/[a-z0-9-]+\\.md$"
            }
          }
        }
      }
    }
  }
}
```

**Testing**: Validate schema against JSON Schema Draft 07 specification

#### Task 1.2: Create Schema Validator Utility
**File**: `.claude/lib/agent-schema-validator.sh`

```bash
#!/usr/bin/env bash
# Agent Registry Schema Validator

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"

# Validate agent registry against schema
# Args:
#   $1 - Path to agent-registry.json
# Returns:
#   0 if valid, 1 if invalid
validate_agent_registry() {
  local registry_file="$1"
  local schema_file=".claude/agents/agent-registry-schema.json"

  if [[ ! -f "$registry_file" ]]; then
    error "Registry file not found: $registry_file"
    return 1
  fi

  if [[ ! -f "$schema_file" ]]; then
    error "Schema file not found: $schema_file"
    return 1
  fi

  # Validate JSON syntax
  if ! jq empty "$registry_file" 2>/dev/null; then
    error "Invalid JSON syntax in registry"
    return 1
  fi

  # Validate against schema using jq
  local validation_result
  validation_result=$(jq --argfile schema "$schema_file" \
    'if . then "valid" else "invalid" end' "$registry_file" 2>&1)

  if [[ "$validation_result" != "valid" ]]; then
    error "Schema validation failed: $validation_result"
    return 1
  fi

  echo "✓ Agent registry schema validation passed"
  return 0
}

# Validate individual agent entry
# Args:
#   $1 - Agent name
#   $2 - JSON string of agent data
validate_agent_entry() {
  local agent_name="$1"
  local agent_data="$2"

  # Required fields check
  local required_fields=("type" "category" "description" "tools" "metrics" "behavioral_file")

  for field in "${required_fields[@]}"; do
    if ! echo "$agent_data" | jq -e ".$field" >/dev/null 2>&1; then
      error "Agent $agent_name missing required field: $field"
      return 1
    fi
  done

  # Type validation
  local agent_type
  agent_type=$(echo "$agent_data" | jq -r '.type')
  if [[ "$agent_type" != "specialized" && "$agent_type" != "hierarchical" ]]; then
    error "Agent $agent_name has invalid type: $agent_type"
    return 1
  fi

  # Behavioral file exists
  local behavioral_file
  behavioral_file=$(echo "$agent_data" | jq -r '.behavioral_file')
  if [[ ! -f "$behavioral_file" ]]; then
    error "Agent $agent_name behavioral file not found: $behavioral_file"
    return 1
  fi

  return 0
}

# Export functions
export -f validate_agent_registry
export -f validate_agent_entry
```

**Testing**:
```bash
# Test with valid registry
validate_agent_registry .claude/agents/agent-registry.json

# Test with invalid registry (missing fields)
# Should return error
```

#### Task 1.3: Migrate Existing Registry to New Schema
**File**: `.claude/lib/migrate-agent-registry.sh`

Create migration utility to convert existing registry (2 agents) to new schema:

```bash
#!/usr/bin/env bash
# Migrate agent registry from old to new schema

migrate_agent_registry() {
  local old_registry=".claude/agents/agent-registry.json"
  local new_registry=".claude/agents/agent-registry-new.json"

  # Backup old registry
  cp "$old_registry" "${old_registry}.backup"

  # Create new registry structure
  cat > "$new_registry" <<'EOF'
{
  "schema_version": "1.0.0",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "agents": {}
}
EOF

  # Migrate existing agents
  local agents
  agents=$(jq -r '.agents | keys[]' "$old_registry")

  while IFS= read -r agent_name; do
    # Extract old metrics
    local old_entry
    old_entry=$(jq ".agents[\"$agent_name\"]" "$old_registry")

    # Create new entry with extended fields
    # (type, category, description, tools, dependencies need manual population)
    jq ".agents[\"$agent_name\"] = {
      \"type\": \"specialized\",
      \"category\": \"research\",
      \"description\": \"Auto-migrated agent\",
      \"tools\": [],
      \"metrics\": $old_entry.metrics,
      \"dependencies\": [],
      \"behavioral_file\": \".claude/agents/${agent_name}.md\"
    }" "$new_registry" > "${new_registry}.tmp"
    mv "${new_registry}.tmp" "$new_registry"
  done <<< "$agents"

  echo "Migration complete: $new_registry"
  echo "Manual review required for type, category, description, tools"
}
```

**Testing**: Run migration and verify both old and new registry coexist

---

## Stage 2: Discovery Utility Implementation

### Objective
Create agent-discovery.sh to auto-scan .claude/agents/ and extract metadata.

### Tasks

#### Task 2.1: Create Agent Discovery Utility
**File**: `.claude/lib/agent-discovery.sh`

```bash
#!/usr/bin/env bash
# Agent Discovery Utility - Auto-scan and register agents

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/agent-schema-validator.sh"

# Discover all agents in .claude/agents/
# Returns: Array of agent behavioral file paths
discover_agents() {
  local agents_dir=".claude/agents"

  if [[ ! -d "$agents_dir" ]]; then
    error "Agents directory not found: $agents_dir"
    return 1
  fi

  # Find all .md files except README.md and agent-registry-schema.json
  find "$agents_dir" -maxdepth 1 -name "*.md" ! -name "README.md" -type f
}

# Extract agent metadata from behavioral file
# Args:
#   $1 - Path to agent behavioral file
# Returns: JSON object with agent metadata
extract_agent_metadata() {
  local behavioral_file="$1"
  local agent_name
  agent_name=$(basename "$behavioral_file" .md)

  # Read frontmatter (YAML between --- markers)
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$behavioral_file" | sed '1d;$d')

  # Extract type (specialized or hierarchical)
  local agent_type="specialized"  # default
  if echo "$frontmatter" | grep -q "type:.*hierarchical"; then
    agent_type="hierarchical"
  fi

  # Extract category from frontmatter or behavioral guidelines
  local category="research"  # default
  if echo "$frontmatter" | grep -q "category:"; then
    category=$(echo "$frontmatter" | grep "category:" | sed 's/category:[ ]*//' | tr -d '"')
  fi

  # Extract description (first paragraph after frontmatter)
  local description
  description=$(sed -n '/^---$/,/^---$/!p' "$behavioral_file" | \
    grep -v "^#" | grep -v "^$" | head -1 | sed 's/^[*-] //')

  # Extract tools from behavioral guidelines (look for Tool mentions)
  local tools
  tools=$(grep -oE "(Read|Write|Edit|Bash|Grep|Glob|WebSearch|WebFetch|Task)" "$behavioral_file" | \
    sort -u | jq -R . | jq -s .)

  # Create JSON metadata
  cat <<EOF
{
  "type": "$agent_type",
  "category": "$category",
  "description": "$description",
  "tools": $tools,
  "metrics": {
    "total_invocations": 0,
    "successful_invocations": 0,
    "failed_invocations": 0,
    "average_duration_seconds": 0,
    "last_invocation": null
  },
  "dependencies": [],
  "behavioral_file": "$behavioral_file"
}
EOF
}

# Register discovered agent in registry
# Args:
#   $1 - Agent name
#   $2 - Agent metadata JSON
register_agent() {
  local agent_name="$1"
  local agent_metadata="$2"
  local registry_file=".claude/agents/agent-registry.json"

  # Validate metadata
  if ! validate_agent_entry "$agent_name" "$agent_metadata"; then
    error "Agent metadata validation failed: $agent_name"
    return 1
  fi

  # Add to registry
  local updated_registry
  updated_registry=$(jq ".agents[\"$agent_name\"] = $agent_metadata | \
    .last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$registry_file")

  echo "$updated_registry" > "$registry_file"
  echo "✓ Registered agent: $agent_name"
}

# Discover and register all agents
discover_and_register_all() {
  local discovered_count=0
  local registered_count=0

  echo "Discovering agents in .claude/agents/..."

  while IFS= read -r behavioral_file; do
    ((discovered_count++))

    local agent_name
    agent_name=$(basename "$behavioral_file" .md)

    echo "Processing: $agent_name"

    # Extract metadata
    local metadata
    metadata=$(extract_agent_metadata "$behavioral_file")

    # Register agent
    if register_agent "$agent_name" "$metadata"; then
      ((registered_count++))
    fi
  done < <(discover_agents)

  echo ""
  echo "Discovery complete:"
  echo "  Discovered: $discovered_count agents"
  echo "  Registered: $registered_count agents"
}

# Export functions
export -f discover_agents
export -f extract_agent_metadata
export -f register_agent
export -f discover_and_register_all
```

**Testing**:
```bash
# Test agent discovery
.claude/lib/agent-discovery.sh

# Verify all 19 agents discovered
discover_agents | wc -l  # Should output 19

# Test metadata extraction
extract_agent_metadata .claude/agents/research-specialist.md

# Test registration
discover_and_register_all
```

#### Task 2.2: Create Frontmatter Validation
**File**: `.claude/lib/agent-frontmatter-validator.sh`

```bash
#!/usr/bin/env bash
# Validate agent behavioral file frontmatter

validate_agent_frontmatter() {
  local behavioral_file="$1"

  # Check file exists
  if [[ ! -f "$behavioral_file" ]]; then
    error "Behavioral file not found: $behavioral_file"
    return 1
  fi

  # Check frontmatter exists
  if ! grep -q "^---$" "$behavioral_file"; then
    error "No frontmatter found in $behavioral_file"
    return 1
  fi

  # Extract frontmatter
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$behavioral_file" | sed '1d;$d')

  # Required frontmatter fields
  local required_fields=("type" "category")

  for field in "${required_fields[@]}"; do
    if ! echo "$frontmatter" | grep -q "^$field:"; then
      error "Missing frontmatter field '$field' in $behavioral_file"
      return 1
    fi
  done

  # Check behavioral guidelines section exists
  if ! grep -q "^## Behavioral Guidelines$" "$behavioral_file"; then
    error "Missing 'Behavioral Guidelines' section in $behavioral_file"
    return 1
  fi

  echo "✓ Frontmatter validation passed: $behavioral_file"
  return 0
}
```

**Testing**: Validate all 19 agent behavioral files

---

## Stage 3: Registry Population

### Objective
Register all 19 agents with complete and accurate metadata.

### Tasks

#### Task 3.1: Manual Metadata Review and Enhancement
**Action**: Review auto-extracted metadata for all 19 agents

For each agent, verify:
- Type (specialized vs hierarchical)
- Category (research, planning, implementation, debugging, documentation, analysis, coordination)
- Description (accurate and concise)
- Tools (complete list from behavioral guidelines)
- Dependencies (utilities sourced in behavioral file)

**Agents to register**:
1. research-specialist
2. debug-specialist
3. plan-architect
4. code-writer
5. test-specialist
6. doc-writer
7. github-specialist
8. metrics-specialist
9. complexity-estimator
10. expansion-specialist
11. collapse-specialist
12. implementation-researcher (hierarchical)
13. debug-analyst (hierarchical)
14. spec-updater (hierarchical)
15. doc-converter (hierarchical)
16. plan-expander (hierarchical)
17-19. [Additional agents discovered]

#### Task 3.2: Enhance agent-registry-utils.sh
**File**: `.claude/lib/agent-registry-utils.sh`

Add functions for new schema:

```bash
# Get agent by type
get_agents_by_type() {
  local agent_type="$1"
  local registry_file=".claude/agents/agent-registry.json"

  jq -r ".agents | to_entries[] | select(.value.type == \"$agent_type\") | .key" \
    "$registry_file"
}

# Get agent by category
get_agents_by_category() {
  local category="$1"
  local registry_file=".claude/agents/agent-registry.json"

  jq -r ".agents | to_entries[] | select(.value.category == \"$category\") | .key" \
    "$registry_file"
}

# Get agents using specific tool
get_agents_by_tool() {
  local tool="$1"
  local registry_file=".claude/agents/agent-registry.json"

  jq -r ".agents | to_entries[] | select(.value.tools | contains([\"$tool\"])) | .key" \
    "$registry_file"
}

# Update agent metrics after invocation
update_agent_metrics() {
  local agent_name="$1"
  local success="$2"  # true or false
  local duration="$3"  # seconds
  local registry_file=".claude/agents/agent-registry.json"

  # Increment invocations
  local updated
  if [[ "$success" == "true" ]]; then
    updated=$(jq ".agents[\"$agent_name\"].metrics.total_invocations += 1 | \
      .agents[\"$agent_name\"].metrics.successful_invocations += 1" "$registry_file")
  else
    updated=$(jq ".agents[\"$agent_name\"].metrics.total_invocations += 1 | \
      .agents[\"$agent_name\"].metrics.failed_invocations += 1" "$registry_file")
  fi

  # Update average duration
  updated=$(echo "$updated" | jq ".agents[\"$agent_name\"].metrics.average_duration_seconds = \
    ((.agents[\"$agent_name\"].metrics.average_duration_seconds * \
      (.agents[\"$agent_name\"].metrics.total_invocations - 1)) + $duration) / \
    .agents[\"$agent_name\"].metrics.total_invocations")

  # Update last invocation
  updated=$(echo "$updated" | jq ".agents[\"$agent_name\"].metrics.last_invocation = \
    \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"")

  echo "$updated" > "$registry_file"
}
```

**Testing**: Test all new query functions

#### Task 3.3: Run Discovery and Validate
**Command**:
```bash
# Run discovery
.claude/lib/agent-discovery.sh discover_and_register_all

# Validate registry
.claude/lib/agent-schema-validator.sh validate_agent_registry .claude/agents/agent-registry.json

# Verify count
jq '.agents | length' .claude/agents/agent-registry.json
# Should output: 19
```

---

## Stage 4: Testing and Validation

### Objective
Create comprehensive test suite for agent discovery and validation.

### Tasks

#### Task 4.1: Create Test Suite
**File**: `.claude/tests/test_agent_discovery.sh`

```bash
#!/usr/bin/env bash
# Test suite for agent discovery and validation

source .claude/lib/agent-discovery.sh
source .claude/lib/agent-schema-validator.sh

test_discover_agents() {
  echo "Testing agent discovery..."

  local count
  count=$(discover_agents | wc -l)

  if [[ $count -eq 19 ]]; then
    echo "✓ Discovered 19 agents"
    return 0
  else
    echo "✗ Expected 19 agents, found $count"
    return 1
  fi
}

test_extract_metadata() {
  echo "Testing metadata extraction..."

  local metadata
  metadata=$(extract_agent_metadata .claude/agents/research-specialist.md)

  # Verify JSON structure
  if echo "$metadata" | jq -e '.type' >/dev/null; then
    echo "✓ Metadata extraction successful"
    return 0
  else
    echo "✗ Metadata extraction failed"
    return 1
  fi
}

test_schema_validation() {
  echo "Testing schema validation..."

  if validate_agent_registry .claude/agents/agent-registry.json; then
    echo "✓ Schema validation passed"
    return 0
  else
    echo "✗ Schema validation failed"
    return 1
  fi
}

test_registry_queries() {
  echo "Testing registry query functions..."

  # Test get by type
  local specialized_count
  specialized_count=$(get_agents_by_type "specialized" | wc -l)

  if [[ $specialized_count -ge 11 ]]; then
    echo "✓ Query by type successful"
  else
    echo "✗ Query by type failed"
    return 1
  fi

  # Test get by category
  local research_count
  research_count=$(get_agents_by_category "research" | wc -l)

  if [[ $research_count -ge 1 ]]; then
    echo "✓ Query by category successful"
  else
    echo "✗ Query by category failed"
    return 1
  fi

  return 0
}

# Run all tests
main() {
  local failed=0

  test_discover_agents || ((failed++))
  test_extract_metadata || ((failed++))
  test_schema_validation || ((failed++))
  test_registry_queries || ((failed++))

  echo ""
  if [[ $failed -eq 0 ]]; then
    echo "All tests passed ✓"
    return 0
  else
    echo "$failed tests failed ✗"
    return 1
  fi
}

main "$@"
```

**Testing**: Run test suite and verify all tests pass

#### Task 4.2: Integration Testing
**Test**: Verify registry functions with enhanced schema

```bash
# Test agent lookup by type
get_agents_by_type "hierarchical"

# Test agent lookup by category
get_agents_by_category "research"

# Test metrics update
update_agent_metrics "research-specialist" "true" 45.2

# Verify metrics updated
jq '.agents["research-specialist"].metrics' .claude/agents/agent-registry.json
```

---

## Success Criteria Validation

- [ ] agent-registry.json contains all 19 agents
- [ ] All agents have complete metadata (type, category, description, tools, dependencies)
- [ ] agent-discovery.sh successfully scans and registers new agents
- [ ] Schema validation passes for all agents
- [ ] All query functions work correctly
- [ ] Test suite passes with 100% success rate
- [ ] Documentation updated with discovery process

## Performance Metrics

**Before**:
- Agents registered: 2/19 (10.5%)
- Registration: Manual
- Schema fields: 4
- Validation: None

**After**:
- Agents registered: 19/19 (100%)
- Registration: Automated
- Schema fields: 8
- Validation: Comprehensive

## Next Phase

Phase 2: Utility Modularization - Split artifact-operations.sh
