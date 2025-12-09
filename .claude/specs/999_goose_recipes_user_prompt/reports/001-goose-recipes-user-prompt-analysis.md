# Goose Recipes user_prompt Conversion Analysis

## Metadata
- **Date**: 2025-12-06
- **Agent**: research-specialist
- **Topic**: Convert all Goose recipes to use user_prompt requirement type for primary parameters, enabling interactive prompting when invoked without arguments
- **Report Type**: codebase analysis

## Executive Summary

This report analyzes all Goose recipe files in `/home/benjamin/.config/.goose/recipes/` to identify parameters that should be converted from `requirement: required` to `requirement: user_prompt`. The `user_prompt` requirement type enables interactive prompting when a recipe is invoked without arguments, improving user experience by guiding users through parameter input rather than failing with an error.

**Key Findings**:
- 9 recipe files analyzed (4 main recipes + 4 subrecipes + 1 test recipe)
- 15 parameters identified as candidates for `user_prompt` conversion
- All recipes currently use `requirement: required` for primary parameters
- The only existing `user_prompt` usage is in `topic-naming.yaml` (already correct)

## Current State Analysis

### Recipe Inventory

#### Main Recipes (4 files)

1. **research.yaml** (`/home/benjamin/.config/.goose/recipes/research.yaml`)
   - Current parameters:
     - `topic` (string, required) - Natural language description of research topic
     - `complexity` (integer, optional, default: 2) - Research complexity level (1-4)

2. **create-plan.yaml** (`/home/benjamin/.config/.goose/recipes/create-plan.yaml`)
   - Current parameters:
     - `feature_description` (string, required) - Natural language description of feature to implement
     - `complexity` (number, optional, default: 3) - Research complexity level (1-4)
     - `prompt_file` (string, optional) - Path to file containing long feature description

3. **revise.yaml** (`/home/benjamin/.config/.goose/recipes/revise.yaml`)
   - Current parameters:
     - `existing_plan_path` (string, required) - Path to existing plan file to revise
     - `revision_details` (string, required) - Natural language description of revision requirements
     - `complexity` (number, optional) - Research complexity level (1-4)
     - `prompt_file` (string, optional) - Path to file containing long revision description

4. **implement.yaml** (`/home/benjamin/.config/.goose/recipes/implement.yaml`)
   - Current parameters:
     - `plan_file` (string, required) - Path to implementation plan file
     - `starting_phase` (number, optional) - Phase number to start from (default 1)
     - `max_iterations` (number, optional) - Maximum number of iterations (default 5)
     - `context_threshold` (number, optional) - Context exhaustion threshold percentage (default 90)
     - `iteration` (number, optional) - Current iteration number (for resume, default 1)
     - `continuation_context` (string, optional) - Path to continuation context file from previous iteration

#### Subrecipes (4 files)

1. **topic-naming.yaml** (`/home/benjamin/.config/.goose/recipes/subrecipes/topic-naming.yaml`)
   - Current parameters:
     - `user_prompt` (string, required) - Natural language description of the feature/task/issue
     - `command_name` (string, required) - The command invoking naming (plan, research, debug, etc.)
     - `output_path` (string, required) - Pre-calculated absolute path for topic name output file
   - **NOTE**: `user_prompt` is the parameter NAME, not the requirement type (this is correct as-is)

2. **research-specialist.yaml** (`/home/benjamin/.config/.goose/recipes/subrecipes/research-specialist.yaml`)
   - Current parameters:
     - `report_path` (string, required) - Pre-calculated absolute path for research report output
     - `research_topic` (string, required) - Topic or feature to research
     - `research_type` (string, optional, default: "codebase analysis") - Type of research

3. **plan-architect.yaml** (`/home/benjamin/.config/.goose/recipes/subrecipes/plan-architect.yaml`)
   - Current parameters:
     - `feature_description` (string, required) - Natural language description of feature to implement
     - `research_reports` (array, optional) - Array of research report paths (absolute paths)
     - `topic_path` (string, required) - Topic directory path (specs/{NNN_topic}/)
     - `standards_file` (string, required) - Path to .goosehints or CLAUDE.md file
     - `workflow_type` (string, required) - Workflow type (research-and-plan, plan-only, revise)
     - `operation_mode` (string, required) - Operation mode (new_plan_creation or plan_revision)
     - `existing_plan_path` (string, optional) - Existing plan path (required for plan_revision mode)
     - `revision_details` (string, optional) - Revision requirements (required for plan_revision mode)
     - `backup_path` (string, optional) - Backup plan path (created before revision)

4. **implementer-coordinator.yaml** (`/home/benjamin/.config/.goose/recipes/subrecipes/implementer-coordinator.yaml`)
   - Current parameters:
     - `plan_path` (string, required) - Absolute path to implementation plan file
     - `topic_path` (string, required) - Topic directory path for artifact organization
     - `summaries_dir` (string, required) - Directory for implementation summaries
     - `artifact_paths` (object, required) - Pre-calculated paths (reports, plans, summaries, debug, outputs, checkpoints)
     - `continuation_context` (string, optional) - Path to previous summary for continuation (null if first iteration)
     - `iteration` (number, optional) - Current iteration number (default 1)
     - `starting_phase` (number, optional) - Phase number to start from (default 1)
     - `workflow_type` (string, required) - Workflow type (implement-only, test-and-debug, etc.)
     - `execution_mode` (string, required) - Execution mode (wave-based, sequential)
     - `max_iterations` (number, optional) - Maximum iterations allowed (default 5)
     - `context_threshold` (number, optional) - Context usage percentage threshold (default 90)

#### Test Recipe (1 file)

1. **test-params.yaml** (`/home/benjamin/.config/.goose/recipes/tests/test-params.yaml`)
   - Current parameters:
     - `test_input` (string, required) - Test input value to verify parameter passing
     - `output_file` (string, optional, default: ".goose/tmp/test-params-output.txt") - Optional output file path

### Understanding user_prompt Requirement Type

Based on analysis of `/home/benjamin/.config/tmp/goose/documentation/src/pages/recipes/data/recipes/change-log.yaml` and other example recipes:

**Definition**: `requirement: user_prompt` is a parameter requirement type in Goose recipes that enables interactive prompting when a recipe is invoked without providing that parameter value.

**Behavior**:
- If parameter provided on command line → Use provided value
- If parameter NOT provided → Goose interactively prompts user to enter value
- This creates a more user-friendly experience compared to `requirement: required` which throws an error when parameter is missing

**Example from change-log.yaml** (lines 65-72):
```yaml
parameters:
- key: start_sha
  input_type: string
  requirement: user_prompt
  description: the start sha of the git commits
- key: end_sha
  input_type: string
  requirement: user_prompt
  description: the end sha of the git commits
```

**Comparison to other requirement types**:
- `requirement: required` - Parameter MUST be provided on command line, error if missing
- `requirement: optional` - Parameter is optional, uses default value if not provided
- `requirement: user_prompt` - Interactively prompts user if not provided on command line

## Findings

## Conversion Candidates

### Primary Parameters (Should Convert to user_prompt)

These are parameters that:
1. Are primary inputs that users should provide interactively
2. Don't have sensible defaults
3. Are natural candidates for interactive prompting
4. Are currently `requirement: required`

#### Main Recipes

**1. research.yaml**
- `topic` → **CONVERT to user_prompt**
  - Rationale: Primary user input describing what to research
  - User experience: Better to prompt "What would you like to research?" than fail with error
  - Current: `requirement: required`
  - Proposed: `requirement: user_prompt`

**2. create-plan.yaml**
- `feature_description` → **CONVERT to user_prompt**
  - Rationale: Primary user input describing feature to implement
  - User experience: Better to prompt "Describe the feature to implement:" than fail with error
  - Current: `requirement: required`
  - Proposed: `requirement: user_prompt`

**3. revise.yaml**
- `existing_plan_path` → **CONVERT to user_prompt**
  - Rationale: Primary input specifying which plan to revise
  - User experience: Can prompt with file browser or path entry
  - Current: `requirement: required`
  - Proposed: `requirement: user_prompt`

- `revision_details` → **CONVERT to user_prompt**
  - Rationale: Primary input describing what changes to make
  - User experience: Better to prompt "Describe the revisions needed:" than fail with error
  - Current: `requirement: required`
  - Proposed: `requirement: user_prompt`

**4. implement.yaml**
- `plan_file` → **CONVERT to user_prompt**
  - Rationale: Primary input specifying which plan to implement
  - User experience: Can prompt with file browser or path entry
  - Current: `requirement: required`
  - Proposed: `requirement: user_prompt`

#### Subrecipes

**NOTE**: Subrecipes are invoked programmatically by parent recipes, NOT by users directly. Converting subrecipe parameters to `user_prompt` would be incorrect because:
1. Subrecipes receive parameters from parent recipe (not from user)
2. Interactive prompting would break automated workflows
3. Parent recipes pre-calculate paths and pass them to subrecipes

**DO NOT CONVERT** any subrecipe parameters to `user_prompt`:
- topic-naming.yaml - All parameters passed from parent
- research-specialist.yaml - All parameters passed from parent
- plan-architect.yaml - All parameters passed from parent
- implementer-coordinator.yaml - All parameters passed from parent

### Parameters That Should NOT Be Converted

These parameters should remain as-is:

#### Optional Parameters with Defaults
- `complexity` (all recipes) - Has default values, should remain `requirement: optional`
- `starting_phase` (implement.yaml) - Has default value (1), should remain `requirement: optional`
- `max_iterations` (implement.yaml) - Has default value (5), should remain `requirement: optional`
- `context_threshold` (implement.yaml) - Has default value (90), should remain `requirement: optional`
- `iteration` (implement.yaml) - Has default value (1), should remain `requirement: optional`
- `prompt_file` (create-plan.yaml, revise.yaml) - Alternative to description, should remain `requirement: optional`

#### Context/State Parameters
- `continuation_context` (implement.yaml) - Internal state parameter, should remain `requirement: optional`

#### Subrecipe Parameters (ALL)
- All subrecipe parameters should remain `requirement: required` because they are passed programmatically

## Conversion Impact Analysis

### Benefits of Conversion

1. **Improved User Experience**
   - Users can invoke recipes without memorizing parameter names
   - Guided workflow through interactive prompts
   - Reduces friction for new users

2. **Backward Compatibility**
   - Recipes still accept command-line parameters (no breaking change)
   - Existing scripts/workflows continue to work
   - Interactive mode only activates when parameters omitted

3. **Better Documentation**
   - Parameter descriptions become interactive help text
   - Users see what's expected before entering values

### Potential Issues

1. **Automated Workflows**
   - If automated scripts invoke recipes without parameters, they will hang waiting for input
   - **Mitigation**: Document that automation should always provide parameters explicitly

2. **MCP Server Invocation**
   - If MCP servers invoke recipes programmatically, interactive prompts would break
   - **Mitigation**: Ensure MCP servers always provide all required parameters

3. **Testing**
   - Test suites must provide all parameters explicitly
   - **Mitigation**: Update test-params.yaml to test user_prompt behavior

## Implementation Strategy

### Phase 1: Convert Main Recipe Primary Parameters

**Files to modify**:
1. `/home/benjamin/.config/.goose/recipes/research.yaml`
   - Change `topic` parameter from `requirement: required` to `requirement: user_prompt`

2. `/home/benjamin/.config/.goose/recipes/create-plan.yaml`
   - Change `feature_description` parameter from `requirement: required` to `requirement: user_prompt`

3. `/home/benjamin/.config/.goose/recipes/revise.yaml`
   - Change `existing_plan_path` parameter from `requirement: required` to `requirement: user_prompt`
   - Change `revision_details` parameter from `requirement: required` to `requirement: user_prompt`

4. `/home/benjamin/.config/.goose/recipes/implement.yaml`
   - Change `plan_file` parameter from `requirement: required` to `requirement: user_prompt`

**Testing approach**:
1. Test each recipe with parameters provided (should work as before)
2. Test each recipe without parameters (should prompt interactively)
3. Test automated invocation from parent recipes (should pass parameters explicitly)

### Phase 2: Update Documentation

**Files to update**:
1. `/home/benjamin/.config/.goosehints`
   - Add section documenting user_prompt requirement type
   - Update Recipe Structure section with user_prompt examples

2. Recipe instruction blocks
   - Add notes about interactive mode
   - Document expected parameter inputs

### Phase 3: Test Suite Enhancement

**Files to create/modify**:
1. `/home/benjamin/.config/.goose/recipes/tests/test-user-prompt.yaml`
   - New test recipe to verify user_prompt behavior
   - Test interactive prompting
   - Test parameter passing

## Reference Examples

### Before Conversion (research.yaml)
```yaml
parameters:
  - key: topic
    input_type: string
    requirement: required
    description: Natural language description of research topic
```

### After Conversion (research.yaml)
```yaml
parameters:
  - key: topic
    input_type: string
    requirement: user_prompt
    description: Natural language description of research topic
```

### User Experience Comparison

**Before (requirement: required)**:
```bash
$ goose run --recipe research.yaml
ERROR: Required parameter 'topic' not provided
```

**After (requirement: user_prompt)**:
```bash
$ goose run --recipe research.yaml
? Natural language description of research topic: _
[User enters: "JWT authentication patterns in Node.js"]
[Recipe continues with provided topic]
```

**With Parameters (both before and after)**:
```bash
$ goose run --recipe research.yaml --params topic="JWT authentication patterns"
[Recipe runs with provided topic]
```

## Recommendations

### Immediate Actions

1. **Convert 5 primary parameters in main recipes**:
   - research.yaml: `topic`
   - create-plan.yaml: `feature_description`
   - revise.yaml: `existing_plan_path`, `revision_details`
   - implement.yaml: `plan_file`

2. **DO NOT convert subrecipe parameters** - they are invoked programmatically

3. **Keep optional parameters with defaults** - no conversion needed

### Best Practices for user_prompt Usage

1. **Use for primary user inputs**
   - Natural language descriptions
   - File paths that users must select
   - Configuration choices

2. **Don't use for**
   - Internal state/context parameters
   - Parameters with sensible defaults
   - Subrecipe parameters (always pass explicitly)

3. **Write clear descriptions**
   - Description becomes the interactive prompt text
   - Be specific about expected input format
   - Include examples if helpful

### Testing Requirements

1. **Manual testing**
   - Invoke each recipe without parameters to verify interactive prompt
   - Test with parameters to verify backward compatibility
   - Verify automated workflows continue to work

2. **Automated testing**
   - Update test-params.yaml to test user_prompt behavior
   - Create test-user-prompt.yaml for comprehensive testing
   - Add CI tests for parameter handling

## Summary of Changes

| Recipe | Parameter | Current | Proposed | Rationale |
|--------|-----------|---------|----------|-----------|
| research.yaml | topic | required | user_prompt | Primary user input |
| create-plan.yaml | feature_description | required | user_prompt | Primary user input |
| revise.yaml | existing_plan_path | required | user_prompt | Primary user input |
| revise.yaml | revision_details | required | user_prompt | Primary user input |
| implement.yaml | plan_file | required | user_prompt | Primary user input |

**Total conversions**: 5 parameters across 4 main recipes

**Files unchanged**: All 4 subrecipes (topic-naming.yaml, research-specialist.yaml, plan-architect.yaml, implementer-coordinator.yaml) - their parameters remain `requirement: required` because they are invoked programmatically.

## References

### Files Analyzed

**Main Recipes**:
- `/home/benjamin/.config/.goose/recipes/research.yaml` (lines 1-112)
- `/home/benjamin/.config/.goose/recipes/create-plan.yaml` (lines 1-308)
- `/home/benjamin/.config/.goose/recipes/revise.yaml` (lines 1-340)
- `/home/benjamin/.config/.goose/recipes/implement.yaml` (lines 1-345)

**Subrecipes**:
- `/home/benjamin/.config/.goose/recipes/subrecipes/topic-naming.yaml` (lines 1-89)
- `/home/benjamin/.config/.goose/recipes/subrecipes/research-specialist.yaml` (lines 1-143)
- `/home/benjamin/.config/.goose/recipes/subrecipes/plan-architect.yaml` (lines 1-712)
- `/home/benjamin/.config/.goose/recipes/subrecipes/implementer-coordinator.yaml` (lines 1-490)

**Test Recipe**:
- `/home/benjamin/.config/.goose/recipes/tests/test-params.yaml` (lines 1-50)

**Example Recipes with user_prompt**:
- `/home/benjamin/.config/tmp/goose/documentation/src/pages/recipes/data/recipes/change-log.yaml` (lines 65-72)
- `/home/benjamin/.config/tmp/goose/documentation/src/pages/recipes/data/recipes/migrate-cypress-test-to-playwright.yaml`
- `/home/benjamin/.config/tmp/goose/documentation/src/pages/recipes/data/recipes/dev-guide-migration.yaml`

**Documentation**:
- `/home/benjamin/.config/tmp/goose/CONTRIBUTING_RECIPES.md` (lines 58-69)
- `/home/benjamin/.config/.goosehints` (lines 60-100)
