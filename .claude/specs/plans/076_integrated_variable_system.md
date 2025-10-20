# Integrated Variable System Implementation Plan

## Metadata
- **Date**: 2025-10-19
- **Feature**: Integrated Variable System for .claude/ Configuration
- **Scope**: Two-tier variable architecture (system + user-configurable) with centralized config, validation, and security
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Research findings from /orchestrate workflow (inline synthesis)

## Overview

Implement a comprehensive variable system for .claude/ configuration with two architectural tiers:

1. **System Variables** (Tier 1): Environment variables for paths and global settings (runtime resolution)
2. **Template Variables** (Tier 2): User-configurable YAML-based variables for project customization (preprocessing)

The system extends the existing Handlebars template engine (`substitute-variables.sh`) to support:
- Centralized configuration file (`.claude/config/variables.yaml`)
- Variable definitions with types, defaults, and validation schemas
- Clear precedence rules (CLI args → environment → config file → defaults)
- Security safeguards for sensitive values (secrets handling)
- Integration across commands, agent prompts, and utilities

### Research Synthesis

**Existing Foundation**:
- Handlebars-style template system already operational (`substitute-variables.sh`, 243 lines)
- 11 production YAML templates using variable substitution
- Pervasive use of `CLAUDE_PROJECT_DIR` pattern (83 occurrences across 19 files)
- Template integration helpers at `.claude/lib/template-integration.sh`

**Industry Best Practices**:
- Configuration hierarchy: CLI flags > Env vars > Config files > Defaults
- XDG Base Directory compliance for config storage
- Never store secrets in environment variables (use secret managers with runtime injection)
- Handlebars/Mustache for logic-enabled templates, `envsubst` for simple substitution
- Explicit precedence documentation and enforcement

**Architecture Decision**:
- Two-tier system mirrors current architecture (env vars for paths, preprocessing for templates)
- Avoid scope creep: opt-in variable definitions (explicit allowlist)
- Use selective `envsubst` with SHELL_FORMAT to prevent unintended substitution
- Validate variables before substitution (schema-based via `jq`)
- Support `.claude/config/variables.yaml` for user-defined project variables

## Success Criteria

- [ ] Centralized config file `.claude/config/variables.yaml` with schema validation
- [ ] System variables (CLAUDE_*) documented and standardized across all utilities
- [ ] Template variables extensible via config file with type safety
- [ ] Variable precedence enforced (CLI > env > config > defaults)
- [ ] Security: Secrets handled separately, never in plain config files
- [ ] Backward compatibility: Existing template system continues working
- [ ] Documentation: Variable reference guide and migration guide for users
- [ ] Tests: Comprehensive validation, precedence, and security tests

## Technical Design

### Two-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Variable System                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Tier 1: System Variables (Runtime Environment)            │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ • CLAUDE_PROJECT_DIR                                  │ │
│  │ • CLAUDE_DATA_DIR                                     │ │
│  │ • CLAUDE_SPECS_DIR                                    │ │
│  │ • CLAUDE_CONFIG_DIR                                   │ │
│  │                                                       │ │
│  │ Resolution: Exported by detect-project-dir.sh         │ │
│  │ Usage: Direct bash variable expansion ${VAR}          │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  Tier 2: Template Variables (Preprocessing)                │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Config: .claude/config/variables.yaml                 │ │
│  │                                                       │ │
│  │ variables:                                            │ │
│  │   project_name:                                       │ │
│  │     type: string                                      │ │
│  │     default: "my-project"                             │ │
│  │     description: "Project display name"               │ │
│  │   database_type:                                      │ │
│  │     type: enum                                        │ │
│  │     options: [postgres, mysql, sqlite]                │ │
│  │     default: postgres                                 │ │
│  │                                                       │ │
│  │ Resolution: substitute-variables.sh + config loader   │ │
│  │ Usage: Handlebars syntax {{variable_name}}            │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Variable Precedence

```
Priority (Highest → Lowest):
1. CLI arguments (--var key=value)
2. Environment variables (CLAUDE_VAR_*)
3. Local config (.claude/config/variables.yaml)
4. Global config (~/.config/claude/variables.yaml)
5. Template defaults (from YAML metadata)
6. System defaults (hardcoded fallbacks)
```

### Configuration File Schema

**Location**: `.claude/config/variables.yaml`

```yaml
# Variable definitions for project-wide customization
version: "1.0"

# User-defined variables
variables:
  # String variable
  project_name:
    type: string
    default: "my-project"
    description: "Project display name"
    required: false

  # Enum variable
  database_type:
    type: enum
    options: [postgres, mysql, sqlite]
    default: postgres
    description: "Database system"

  # Array variable
  supported_languages:
    type: array
    default: ["python", "javascript"]
    description: "Programming languages in project"

  # Boolean variable
  enable_debug:
    type: boolean
    default: false
    description: "Enable debug mode"

  # Secret reference (NOT the value)
  api_key:
    type: secret
    source: env  # Options: env, file, vault
    env_var: "MYPROJECT_API_KEY"
    description: "API authentication key"
    required: true

# System variable overrides (optional)
system:
  CLAUDE_DATA_DIR: ".claude/data"  # Override default
  CLAUDE_SPECS_DIR: "specs"        # Override default
```

### Security Model

**Secrets Handling**:
1. **Never store secrets in `variables.yaml`** - only store references
2. **Secret types**: Reference external sources (env vars, files, secret managers)
3. **Runtime injection**: Secrets resolved at execution time, never cached
4. **Audit logging**: Track secret access (optional, configurable)

**Secret Variable Definition**:
```yaml
variables:
  database_password:
    type: secret
    source: env        # Load from environment variable
    env_var: "DB_PASSWORD"
    required: true

  api_token:
    type: secret
    source: file       # Load from file
    file_path: "${HOME}/.secrets/api_token"
    required: true

  cloud_credentials:
    type: secret
    source: vault      # Future: Integration with HashiCorp Vault, AWS Secrets Manager
    vault_path: "myproject/cloud_creds"
    required: false
```

### Integration Points

**1. Commands** (`.claude/commands/*.md`):
- Variable substitution in agent prompts
- Example: `{{project_name}}` in plan generation prompts

**2. Templates** (`.claude/templates/*.yaml`):
- Already using Handlebars syntax
- Extend to load variables from config file

**3. Utilities** (`.claude/lib/*.sh`):
- Standardize system variables (CLAUDE_*)
- Replace hardcoded paths with variables

**4. Agent Invocations**:
- Substitute variables in agent task prompts
- Enable dynamic context injection

### Backward Compatibility

**Existing Behavior Preserved**:
- `/plan-from-template` continues working unchanged
- Inline variable definitions in templates still supported
- System variables (CLAUDE_PROJECT_DIR) remain functional

**Migration Path**:
- Phase 1: System variables standardization (no breaking changes)
- Phase 2: Config file support (opt-in, additive)
- Phase 3: Deprecation warnings for hardcoded values (non-breaking)
- Phase 4: Full migration guide and automated conversion tools

## Implementation Phases

### Phase 1: System Variable Standardization
**Objective**: Audit and standardize all system-level environment variables across .claude/ codebase
**Complexity**: Medium

Tasks:
- [ ] Audit all CLAUDE_* variables in `.claude/lib/` (19 files identified)
  - Read `/home/benjamin/.config/.claude/lib/detect-project-dir.sh`
  - Grep for all CLAUDE_ variable definitions and usages
  - Document current state: variable names, default values, scope
- [ ] Create canonical list of system variables with definitions
  - CLAUDE_PROJECT_DIR: Root project directory
  - CLAUDE_DATA_DIR: Data/cache/state directory (.claude/data)
  - CLAUDE_SPECS_DIR: Specifications directory (specs/)
  - CLAUDE_CONFIG_DIR: Configuration directory (.claude/config)
  - CLAUDE_LIB_DIR: Utility library directory (.claude/lib)
  - CLAUDE_TEMPLATES_DIR: Template directory (.claude/templates)
- [ ] Create `.claude/lib/system-variables.sh` utility
  - Export all system variables with defaults
  - Source from detect-project-dir.sh or create new entry point
  - Add validation: check directory existence, set fallbacks
  - File location: `/home/benjamin/.config/.claude/lib/system-variables.sh`
- [ ] Update existing utilities to source `system-variables.sh`
  - Modify top 10 most-used utilities first (based on grep results)
  - Replace inline definitions with sourcing
  - Test: Ensure no behavioral changes
- [ ] Document system variables in `.claude/docs/reference/system-variables.md`
  - Variable name, description, default value, usage examples
  - Update CLAUDE.md to reference this documentation

Testing:
```bash
# Test system variable resolution
source .claude/lib/system-variables.sh
[[ -n "$CLAUDE_PROJECT_DIR" ]] || echo "FAIL: CLAUDE_PROJECT_DIR not set"
[[ -d "$CLAUDE_DATA_DIR" ]] || echo "FAIL: CLAUDE_DATA_DIR not found"

# Test backward compatibility
.claude/tests/test_system_variables.sh
```

**Estimated Time**: 4 hours

---

### Phase 2: Configuration Schema and Validation
**Objective**: Define schema for variables.yaml and implement validation logic
**Complexity**: Medium

Tasks:
- [ ] Design JSON schema for `variables.yaml` structure
  - Schema file: `.claude/config/variables.schema.json`
  - Define types: string, number, boolean, array, enum, secret
  - Define metadata: description, default, required, options
  - Add system variable override section
- [ ] Create `.claude/lib/config-loader.sh` utility
  - Function: `load_config_file <path>` - Parse YAML to JSON using yq or python
  - Function: `validate_config <json>` - Validate against schema using jq
  - Function: `get_config_value <key>` - Extract value from config JSON
  - Function: `merge_configs <global> <local>` - Merge global + local configs
  - Error handling: Invalid YAML, schema violations, missing required fields
- [ ] Create `.claude/lib/variable-resolver.sh` utility
  - Function: `resolve_variable <name>` - Apply precedence rules
  - Precedence: CLI args > Env vars > Local config > Global config > Defaults
  - Function: `resolve_all_variables` - Build complete variable context as JSON
  - Function: `expand_variable_references` - Handle ${VAR} in config values
  - Handle secret types: defer resolution, validate source accessibility
- [ ] Implement variable type validation
  - String: Max length, regex patterns (optional)
  - Number: Min/max ranges (optional)
  - Boolean: True/false only
  - Array: Item type validation (optional)
  - Enum: Validate against options list
  - Secret: Validate source type, check accessibility
- [ ] Create example config file: `.claude/config/variables.yaml.example`
  - Include all variable types with comments
  - Document secret handling patterns
  - Add to git, gitignore actual `variables.yaml`

Testing:
```bash
# Test schema validation
.claude/lib/config-loader.sh validate .claude/config/variables.yaml.example
# Expected: No errors

# Test invalid config
echo "invalid: {malformed" > /tmp/test-invalid.yaml
.claude/lib/config-loader.sh validate /tmp/test-invalid.yaml
# Expected: Schema validation error

# Test variable resolution precedence
export CLAUDE_VAR_test_var="env_value"
echo "variables: {test_var: {default: 'config_value'}}" > /tmp/test-config.yaml
resolved=$(CLAUDE_CONFIG=/tmp/test-config.yaml .claude/lib/variable-resolver.sh resolve test_var)
[[ "$resolved" == "env_value" ]] || echo "FAIL: Precedence not enforced"

# Comprehensive validation tests
.claude/tests/test_config_validation.sh
```

**Estimated Time**: 6 hours

---

### Phase 3: Template Variable Integration
**Objective**: Extend substitute-variables.sh to load variables from config file
**Complexity**: Medium-High

Tasks:
- [ ] Modify `.claude/lib/substitute-variables.sh` to support config loading
  - Read `/home/benjamin/.config/.claude/lib/substitute-variables.sh` (current implementation)
  - Add optional 3rd parameter: `<config-file-path>`
  - If config file provided: merge with inline JSON variables
  - Precedence: Inline JSON > Config file > Template defaults
  - Maintain backward compatibility: If no config file, use existing behavior
- [ ] Update `substitute-variables.sh` to call `variable-resolver.sh`
  - Source `.claude/lib/variable-resolver.sh`
  - For each variable in template: call `resolve_variable <name>`
  - Build merged VARIABLES_JSON with resolved values
  - Pass to existing processing pipeline (simple vars, arrays, conditionals)
- [ ] Add secret variable handling
  - Detect secret type in config schema
  - For secrets: resolve from source (env, file, vault)
  - Never write secret values to temp files or logs
  - Use process substitution or in-memory handling
- [ ] Update `.claude/lib/template-integration.sh` helpers
  - Modify `render_template` function to accept config file path
  - Auto-detect config: look for `.claude/config/variables.yaml`
  - Pass config path to `substitute-variables.sh`
  - Update all helper functions to propagate config parameter
- [ ] Create variable context builder
  - Function: `build_variable_context` - Aggregate all variables into JSON
  - Sources: System vars, config file, env overrides, CLI args
  - Output: Complete JSON for substitute-variables.sh consumption
  - Cache: Optional caching for performance (invalidate on config change)
- [ ] Update `/plan-from-template` command to use config variables
  - Modify command to load `.claude/config/variables.yaml`
  - Merge template-specific variables with global config
  - Interactive prompt: Show config defaults, allow overrides
  - Document in command file: How config variables work with templates

Testing:
```bash
# Test config file integration
cat > /tmp/test-template.yaml <<EOF
content: |
  Project: {{project_name}}
  Database: {{database_type}}
EOF

cat > /tmp/test-config.yaml <<EOF
variables:
  project_name:
    default: "test-project"
  database_type:
    default: "postgres"
EOF

result=$(.claude/lib/substitute-variables.sh /tmp/test-template.yaml '{}' /tmp/test-config.yaml)
[[ "$result" =~ "Project: test-project" ]] || echo "FAIL: Config var not substituted"

# Test precedence: inline JSON > config file
result=$(.claude/lib/substitute-variables.sh /tmp/test-template.yaml '{"project_name":"inline-project"}' /tmp/test-config.yaml)
[[ "$result" =~ "Project: inline-project" ]] || echo "FAIL: Precedence violated"

# Test secret handling
cat > /tmp/test-secret-config.yaml <<EOF
variables:
  api_key:
    type: secret
    source: env
    env_var: "TEST_API_KEY"
EOF
export TEST_API_KEY="secret123"
result=$(.claude/lib/substitute-variables.sh /tmp/test-template-secret.yaml '{}' /tmp/test-secret-config.yaml)
[[ "$result" =~ "secret123" ]] || echo "FAIL: Secret not resolved"
# Verify secret not in logs/temp files
! grep -r "secret123" /tmp/.substitute-variables* || echo "FAIL: Secret leaked to temp files"

# Comprehensive integration tests
.claude/tests/test_template_variable_integration.sh
```

**Estimated Time**: 8 hours

---

### Phase 4: Command and Utility Integration
**Objective**: Enable variable usage in commands, agent prompts, and utilities
**Complexity**: High

Tasks:
- [ ] Create variable substitution wrapper for commands
  - Utility: `.claude/lib/command-variable-wrapper.sh`
  - Function: `preprocess_command_prompt <command-file>` - Substitute vars in .md files
  - Load config, build variable context, apply substitution
  - Return preprocessed command content for execution
- [ ] Identify commands needing variable support (priority order)
  - `/plan` - Use {{project_name}}, {{author}}, {{date}} in plan metadata
  - `/implement` - Use {{test_command}}, {{commit_prefix}} for execution
  - `/orchestrate` - Use {{workflow_timeout}}, {{parallel_research_agents}} for config
  - `/report` - Use {{report_template}}, {{default_sections}} for structure
  - `/setup` - Use {{claude_config_defaults}} for initialization
- [ ] Update identified commands to support variables
  - For each command: Read command file, identify hardcoded values
  - Replace with variable placeholders: `{{variable_name}}`
  - Update command documentation: List supported variables
  - Add variable definitions to `.claude/config/variables.yaml.example`
  - Test: Ensure commands work with and without config file
- [ ] Enable variables in agent invocation prompts
  - Modify agent registry to preprocess prompts
  - Substitute variables before passing to Task tool
  - Example: `{{codebase_context}}` in research-specialist prompts
  - Document: How to use variables in agent definitions
- [ ] Update utility library to use system variables consistently
  - Audit `.claude/lib/*.sh` for hardcoded `.claude/` paths
  - Replace with `${CLAUDE_LIB_DIR}`, `${CLAUDE_DATA_DIR}`, etc.
  - Test: Run all existing tests to ensure no breakage
  - Utilities to prioritize: checkpoint-utils.sh, metadata-extraction.sh, plan-core-bundle.sh
- [ ] Create variable injection for bash scripts
  - Utility: `.claude/lib/inject-variables.sh`
  - Function: `inject_env_variables` - Export config variables as CLAUDE_VAR_*
  - Usage: Source at script start to make variables available
  - Selective export: Only non-secret variables exported to environment

Testing:
```bash
# Test command variable substitution
cat > /tmp/test-command.md <<EOF
# Test Command
Plan for {{project_name}} using {{database_type}}.
EOF

result=$(.claude/lib/command-variable-wrapper.sh preprocess /tmp/test-command.md)
[[ "$result" =~ "Plan for my-project using postgres" ]] || echo "FAIL: Command vars not substituted"

# Test agent prompt substitution
cat > /tmp/test-agent-prompt.md <<EOF
Research {{topic}} in the context of {{project_name}}.
EOF
# (Integration test with actual agent invocation)

# Test utility integration
.claude/lib/checkpoint-utils.sh save_checkpoint test
checkpoint_file=$(cat .claude/data/checkpoints/test.json)
[[ "$checkpoint_file" =~ "${CLAUDE_DATA_DIR}" ]] && echo "FAIL: Variable not expanded"
# Should contain actual path, not variable placeholder

# Test variable injection
source .claude/lib/inject-variables.sh
[[ -n "$CLAUDE_VAR_project_name" ]] || echo "FAIL: Variable not injected"

# Comprehensive command integration tests
.claude/tests/test_command_variable_integration.sh
```

**Estimated Time**: 10 hours

---

### Phase 5: Security and Secret Management
**Objective**: Implement secure handling for sensitive variables
**Complexity**: Medium-High

Tasks:
- [ ] Implement secret resolution logic
  - Update `.claude/lib/variable-resolver.sh` with secret handlers
  - Handler: `resolve_secret_env <var_name>` - Read from environment variable
  - Handler: `resolve_secret_file <file_path>` - Read from file (with permissions check)
  - Handler: `resolve_secret_vault <vault_path>` - Placeholder for future integration
  - Validation: Ensure secret sources are accessible, fail securely
- [ ] Add security safeguards
  - Function: `validate_secret_access <secret_def>` - Check source accessibility
  - Never log secret values (audit all echo/logging statements)
  - Never write secrets to temp files (use process substitution)
  - Memory safety: Unset secret variables after use
  - Permissions check: Verify secret files are 0600 or stricter
- [ ] Create secret validation tests
  - Test: Secret from environment variable
  - Test: Secret from file with correct permissions
  - Test: Secret from file with incorrect permissions (should fail)
  - Test: Missing secret (required=true should fail, required=false should warn)
  - Test: Secret not leaked to logs or temp files
- [ ] Document secret management best practices
  - Guide: `.claude/docs/guides/secret-management.md`
  - Patterns: How to define secrets in variables.yaml
  - Examples: Environment variables, file-based secrets, future vault integration
  - Security checklist: Permissions, .gitignore, rotation, access control
  - Migration: How to move from hardcoded secrets to variable system
- [ ] Add secret audit logging (optional, configurable)
  - Config: `audit_secrets: true/false` in variables.yaml
  - Log file: `.claude/data/logs/secret-access.log`
  - Log entry: timestamp, variable name, source type (NOT the value)
  - Log rotation: Max 10MB, 5 files retained
  - Privacy: Ensure logs don't contain secrets
- [ ] Create secret rotation support
  - Function: `invalidate_secret_cache` - Clear any cached secret values
  - Hook: Detect config file changes, auto-invalidate cache
  - Document: How to rotate secrets (update source, invalidate cache, test)

Testing:
```bash
# Test secret from environment variable
export TEST_SECRET="my-secret-value"
cat > /tmp/test-secret-config.yaml <<EOF
variables:
  test_secret:
    type: secret
    source: env
    env_var: "TEST_SECRET"
    required: true
EOF

resolved=$(.claude/lib/variable-resolver.sh resolve test_secret /tmp/test-secret-config.yaml)
[[ "$resolved" == "my-secret-value" ]] || echo "FAIL: Secret not resolved"

# Test secret from file
echo "file-secret-value" > /tmp/test-secret-file
chmod 600 /tmp/test-secret-file
cat > /tmp/test-file-secret-config.yaml <<EOF
variables:
  file_secret:
    type: secret
    source: file
    file_path: "/tmp/test-secret-file"
EOF

resolved=$(.claude/lib/variable-resolver.sh resolve file_secret /tmp/test-file-secret-config.yaml)
[[ "$resolved" == "file-secret-value" ]] || echo "FAIL: File secret not resolved"

# Test incorrect permissions (should fail)
chmod 644 /tmp/test-secret-file
! .claude/lib/variable-resolver.sh resolve file_secret /tmp/test-file-secret-config.yaml 2>/dev/null || \
  echo "FAIL: Accepted secret file with insecure permissions"

# Test secret not leaked
.claude/lib/variable-resolver.sh resolve test_secret /tmp/test-secret-config.yaml > /tmp/test-output.log
! grep "my-secret-value" /tmp/test-output.log || echo "FAIL: Secret leaked to logs"

# Test required secret missing
unset TEST_SECRET
! .claude/lib/variable-resolver.sh resolve test_secret /tmp/test-secret-config.yaml 2>/dev/null || \
  echo "FAIL: Missing required secret did not fail"

# Comprehensive security tests
.claude/tests/test_secret_security.sh
```

**Estimated Time**: 6 hours

---

### Phase 6: Documentation and Migration Tools
**Objective**: Provide comprehensive documentation and tools for adoption
**Complexity**: Medium

Tasks:
- [ ] Create variable reference documentation
  - File: `.claude/docs/reference/variable-reference.md`
  - Section: System variables (CLAUDE_*) with descriptions and defaults
  - Section: Template variables (how to define in variables.yaml)
  - Section: Variable syntax (Handlebars {{var}}, bash ${VAR})
  - Section: Precedence rules with examples
  - Section: Type reference (string, number, boolean, array, enum, secret)
  - Examples: Common use cases and patterns
- [ ] Create user migration guide
  - File: `.claude/docs/guides/variable-migration-guide.md`
  - Step 1: Initialize config file (copy from .example)
  - Step 2: Define project variables (what to move from hardcoded)
  - Step 3: Update custom commands/templates to use variables
  - Step 4: Migrate secrets to secure sources
  - Step 5: Test and validate
  - Troubleshooting: Common issues and solutions
- [ ] Update CLAUDE.md with variable system section
  - Add section: `<!-- SECTION: variable_system -->`
  - Used by: All commands
  - Content: Overview, config file location, quick reference
  - Link to detailed documentation
- [ ] Create variable initialization tool
  - Script: `.claude/utils/init-variables.sh`
  - Interactive: Prompt user for common variable values
  - Generate: Create `.claude/config/variables.yaml` from user input
  - Validate: Run schema validation after generation
  - Usage: Run during `/setup` or standalone
- [ ] Create variable migration tool
  - Script: `.claude/utils/migrate-variables.sh`
  - Scan: Analyze existing commands/templates for hardcoded values
  - Suggest: Recommend variable definitions for common patterns
  - Convert: Optionally auto-replace with variable placeholders
  - Report: Generate migration report with manual action items
- [ ] Update existing documentation referencing hardcoded values
  - Search docs for absolute paths, magic numbers, hardcoded configs
  - Replace with variable references or examples using variables
  - Files to check: All files in `.claude/docs/`, `.claude/commands/README.md`
- [ ] Create variable usage examples
  - Example 1: Custom project name in plans
  - Example 2: Database type selection in templates
  - Example 3: API keys from environment (secrets)
  - Example 4: Override system directories for testing
  - Add examples to documentation and `.example` config file

Testing:
```bash
# Test initialization tool
.claude/utils/init-variables.sh --non-interactive --defaults
[[ -f .claude/config/variables.yaml ]] || echo "FAIL: Config file not created"

# Test migration tool
.claude/utils/migrate-variables.sh --scan-only > /tmp/migration-report.txt
[[ -s /tmp/migration-report.txt ]] || echo "FAIL: Migration report empty"

# Test schema validation
.claude/lib/config-loader.sh validate .claude/config/variables.yaml
# Expected: No errors

# Validate documentation links
.claude/tests/test_documentation_links.sh

# Validate examples
for example in .claude/docs/reference/variable-reference.md; do
  # Extract code blocks, attempt to execute
  # Ensure examples are valid and functional
done
```

**Estimated Time**: 5 hours

---

## Testing Strategy

### Unit Tests
- **Config Loader**: Schema validation, YAML parsing, error handling
- **Variable Resolver**: Precedence rules, type validation, secret resolution
- **Template Substitution**: Handlebars syntax, config integration, backward compatibility
- **Security**: Secret handling, permissions, leak prevention

### Integration Tests
- **Command Integration**: Variable substitution in /plan, /implement, /orchestrate
- **Template System**: /plan-from-template with config variables
- **Agent Prompts**: Variable injection in Task tool invocations
- **Utilities**: System variables in checkpoint, metadata, plan utilities

### Security Tests
- **Secret Leak Prevention**: Verify secrets not in logs, temp files, error messages
- **Permission Validation**: Reject secret files with insecure permissions
- **Access Control**: Validate secret sources before resolution
- **Audit Logging**: Ensure audit logs don't contain secret values

### Performance Tests
- **Variable Resolution**: Measure overhead of precedence resolution
- **Caching**: Validate cache invalidation on config changes
- **Template Rendering**: Ensure no regression in substitute-variables.sh performance

### Backward Compatibility Tests
- **Existing Templates**: Verify all 11 production templates work unchanged
- **System Variables**: Ensure CLAUDE_PROJECT_DIR usage remains functional
- **Template Integration**: Validate template-integration.sh helpers still work

## Documentation Requirements

**Files to Create**:
1. `.claude/docs/reference/variable-reference.md` - Complete variable reference
2. `.claude/docs/reference/system-variables.md` - System variable documentation
3. `.claude/docs/guides/variable-migration-guide.md` - Migration guide
4. `.claude/docs/guides/secret-management.md` - Security best practices
5. `.claude/config/variables.schema.json` - JSON schema for validation
6. `.claude/config/variables.yaml.example` - Example configuration

**Files to Update**:
1. `CLAUDE.md` - Add variable system section
2. `.claude/commands/README.md` - Document variable support in commands
3. `.claude/templates/README.md` - Update template variable documentation
4. `.claude/docs/concepts/development-workflow.md` - Include variable workflow

**Documentation Standards**:
- Follow CommonMark specification
- Use Unicode box-drawing for diagrams
- Include code examples with syntax highlighting
- Provide troubleshooting sections
- Link between related documentation
- Keep examples current with implementation

## Dependencies

**External Dependencies**:
- `yq` or Python YAML library (for YAML parsing)
- `jq` (for JSON manipulation and schema validation)
- `envsubst` (GNU gettext, for basic substitution fallback)

**Internal Dependencies**:
- `.claude/lib/detect-project-dir.sh` (existing)
- `.claude/lib/substitute-variables.sh` (existing, will be extended)
- `.claude/lib/template-integration.sh` (existing, will be updated)

**Development Dependencies**:
- Bash 4.0+ (for associative arrays and modern features)
- Git (for version control and testing)
- Test framework: `.claude/tests/` infrastructure

## Risk Assessment

**Risk: Scope Creep**
- **Likelihood**: High
- **Impact**: High (delays, complexity)
- **Mitigation**: Strict phase boundaries, opt-in variable definitions, no automatic conversion

**Risk: Breaking Changes**
- **Likelihood**: Medium
- **Impact**: High (user disruption)
- **Mitigation**: Extensive backward compatibility tests, phased rollout, migration tools

**Risk: Security Vulnerabilities**
- **Likelihood**: Medium
- **Impact**: Critical (secret exposure)
- **Mitigation**: Security-focused Phase 5, audit logging, comprehensive security tests

**Risk: Performance Degradation**
- **Likelihood**: Low
- **Impact**: Medium (slower command execution)
- **Mitigation**: Caching strategies, performance benchmarks, lazy resolution

**Risk: Configuration Complexity**
- **Likelihood**: Medium
- **Impact**: Medium (user confusion, adoption barrier)
- **Mitigation**: Clear documentation, initialization wizard, sensible defaults

## Notes

### Design Decisions

**Why Two-Tier Architecture?**
- Mirrors existing usage: System vars for infrastructure, template vars for customization
- Clear separation of concerns: Runtime (env) vs preprocessing (templates)
- Enables different substitution strategies: Fast for env vars, logic-enabled for templates

**Why YAML for Configuration?**
- Aligns with existing template format (11 .yaml templates)
- Human-friendly syntax for manual editing
- Supports comments for documentation
- Standard tooling available (yq, Python YAML libraries)

**Why Handlebars Syntax?**
- Already implemented in substitute-variables.sh
- Supports conditionals and loops ({{#if}}, {{#each}})
- Familiar to users of Mustache/Handlebars ecosystems
- Distinct from bash variables (${VAR}) - no confusion

**Why Not Replace All Hardcoded Values?**
- Scope creep risk: 80% of utilities reference paths
- Backward compatibility burden
- Diminishing returns: Not all hardcoded values need variability
- Opt-in approach: Users choose what to parameterize

### Implementation Order Rationale

1. **Phase 1 first**: Standardize foundation before building on it
2. **Phase 2 before 3**: Define schema before implementing substitution
3. **Phase 3 before 4**: Core template engine before command integration
4. **Phase 5 mid-way**: Security early, but after core architecture stable
5. **Phase 6 last**: Documentation after implementation complete

### Future Enhancements

**Post-MVP Features** (not in this plan):
- Vault integration (HashiCorp Vault, AWS Secrets Manager)
- Variable type plugins (custom validators)
- Global config directory (`~/.config/claude/variables.yaml`)
- Variable interpolation in config values (recursive substitution)
- Variable usage analytics (which vars are actually used)
- Auto-completion for variable names in editors

### Success Metrics

**Adoption Metrics**:
- Number of user-created variables in config files
- Commands using variable system (target: 50% of commands)
- Reduction in hardcoded values (measure via static analysis)

**Quality Metrics**:
- Test coverage: >80% for new code
- Zero security vulnerabilities (secret leaks)
- Backward compatibility: 100% of existing templates work
- Documentation completeness: All variables documented

**Performance Metrics**:
- Variable resolution overhead: <50ms per command
- Template rendering: No regression vs current substitute-variables.sh
- Cache hit rate: >90% for repeated variable resolutions
