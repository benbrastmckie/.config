# Goose Recipes user_prompt Conversion Implementation Plan

## Metadata
- **Date**: 2025-12-06
- **Feature**: Convert Goose recipe primary parameters from required to user_prompt for interactive prompting
- **Scope**: Update 5 primary parameters across 4 main Goose recipes to enable interactive parameter prompting when invoked without arguments, improving user experience without breaking backward compatibility
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 15.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Goose Recipes user_prompt Conversion Analysis](../reports/001-goose-recipes-user-prompt-analysis.md)

## Overview

This plan converts primary parameters in Goose recipes from `requirement: required` to `requirement: user_prompt`, enabling interactive prompting when recipes are invoked without arguments. This improves user experience by guiding users through parameter input rather than failing with errors.

The conversion targets 5 parameters across 4 main recipes (research.yaml, create-plan.yaml, revise.yaml, implement.yaml). Subrecipes are intentionally excluded as they are invoked programmatically by parent recipes.

## Research Summary

Research analysis identified the following key findings:

**user_prompt Behavior**:
- If parameter provided on command line → Use provided value
- If parameter NOT provided → Goose interactively prompts user to enter value
- Backward compatible with existing CLI parameter passing

**Conversion Candidates** (5 primary parameters):
1. research.yaml: `topic` - Primary user input describing research topic
2. create-plan.yaml: `feature_description` - Primary user input describing feature to implement
3. revise.yaml: `existing_plan_path` - Primary input specifying which plan to revise
4. revise.yaml: `revision_details` - Primary input describing revision requirements
5. implement.yaml: `plan_file` - Primary input specifying which plan to implement

**Parameters NOT to Convert**:
- All subrecipe parameters (remain `required` - invoked programmatically)
- Optional parameters with defaults (remain `optional`)
- Internal state/context parameters (remain `optional`)

**Benefits**:
- Improved user experience (guided workflow vs error messages)
- Backward compatible (existing scripts continue to work)
- Better documentation (descriptions become interactive help text)

## Success Criteria

- [ ] All 5 primary parameters successfully converted to user_prompt requirement type
- [ ] Recipes accept parameters on command line (backward compatibility verified)
- [ ] Recipes prompt interactively when parameters omitted (new behavior verified)
- [ ] No subrecipe parameters converted (programmatic invocation preserved)
- [ ] Documentation updated to reflect interactive prompting capability
- [ ] Manual testing confirms expected behavior for all 4 recipes

## Technical Design

### Architecture Overview

This is a straightforward parameter metadata update with no architectural changes:

**Change Pattern** (applied to each primary parameter):
```yaml
# Before
parameters:
  - key: topic
    input_type: string
    requirement: required  # ← Change this
    description: Natural language description of research topic

# After
parameters:
  - key: topic
    input_type: string
    requirement: user_prompt  # ← To this
    description: Natural language description of research topic
```

**Files to Modify** (4 recipe files):
1. `/home/benjamin/.config/.goose/recipes/research.yaml` - 1 parameter conversion
2. `/home/benjamin/.config/.goose/recipes/create-plan.yaml` - 1 parameter conversion
3. `/home/benjamin/.config/.goose/recipes/revise.yaml` - 2 parameter conversions
4. `/home/benjamin/.config/.goose/recipes/implement.yaml` - 1 parameter conversion

**Files NOT Modified** (4 subrecipe files):
- `/home/benjamin/.config/.goose/recipes/subrecipes/topic-naming.yaml`
- `/home/benjamin/.config/.goose/recipes/subrecipes/research-specialist.yaml`
- `/home/benjamin/.config/.goose/recipes/subrecipes/plan-architect.yaml`
- `/home/benjamin/.config/.goose/recipes/subrecipes/implementer-coordinator.yaml`

### Standards Compliance

**Code Standards**:
- YAML format preserved (no syntax changes)
- Indentation maintained (consistent with existing recipe structure)
- Parameter ordering unchanged

**Documentation Standards**:
- Update .goosehints with user_prompt requirement type documentation
- Add interactive prompting examples to recipe documentation
- Document backward compatibility guarantees

**Testing Requirements**:
- Manual testing for each recipe (with and without parameters)
- Verify automated workflows continue to work
- No automated test suite (Goose recipes tested manually)

## Implementation Phases

### Phase 1: Convert Main Recipe Parameters [COMPLETE]

**Objective**: Update all 5 primary parameters across 4 main recipes from required to user_prompt

**Complexity**: Low

**Tasks**:
- [x] Convert research.yaml topic parameter (file: /home/benjamin/.config/.goose/recipes/research.yaml, line 6)
- [x] Convert create-plan.yaml feature_description parameter (file: /home/benjamin/.config/.goose/recipes/create-plan.yaml, line 19)
- [x] Convert revise.yaml existing_plan_path parameter (file: /home/benjamin/.config/.goose/recipes/revise.yaml, line 7)
- [x] Convert revise.yaml revision_details parameter (file: /home/benjamin/.config/.goose/recipes/revise.yaml, line 12)
- [x] Convert implement.yaml plan_file parameter (file: /home/benjamin/.config/.goose/recipes/implement.yaml, line 7)
- [x] Verify YAML syntax remains valid after all changes

**Testing**:
```bash
# Verify YAML syntax for all modified files
for file in research.yaml create-plan.yaml revise.yaml implement.yaml; do
  python3 -c "import yaml; yaml.safe_load(open('.goose/recipes/$file'))" && echo "$file: OK" || echo "$file: SYNTAX ERROR"
done

# Verify requirement field changed to user_prompt
grep -n "requirement: user_prompt" .goose/recipes/research.yaml      # Should show topic parameter
grep -n "requirement: user_prompt" .goose/recipes/create-plan.yaml  # Should show feature_description
grep -n "requirement: user_prompt" .goose/recipes/revise.yaml        # Should show existing_plan_path and revision_details
grep -n "requirement: user_prompt" .goose/recipes/implement.yaml     # Should show plan_file
```

**Expected Duration**: 0.5 hours

### Phase 2: Manual Testing and Validation [COMPLETE]

**Objective**: Verify interactive prompting works correctly and backward compatibility is preserved

**Complexity**: Low

**Tasks**:
- [x] Test research.yaml without parameters (should prompt for topic)
- [x] Test research.yaml with parameters (should use provided value)
- [x] Test create-plan.yaml without parameters (should prompt for feature_description)
- [x] Test create-plan.yaml with parameters (should use provided value)
- [x] Test revise.yaml without parameters (should prompt for existing_plan_path and revision_details)
- [x] Test revise.yaml with parameters (should use provided values)
- [x] Test implement.yaml without parameters (should prompt for plan_file)
- [x] Test implement.yaml with parameters (should use provided value)
- [x] Verify subrecipes still work when invoked programmatically from parent recipes

**Testing**:
```bash
# Interactive prompting tests (manual - user must provide input at prompts)
goose run --recipe .goose/recipes/research.yaml
# Expected: Prompt "Natural language description of research topic: "

goose run --recipe .goose/recipes/create-plan.yaml
# Expected: Prompt "Natural language description of feature to implement: "

goose run --recipe .goose/recipes/revise.yaml
# Expected: Prompt "Path to existing plan file to revise: "
# Expected: Prompt "Natural language description of revision requirements: "

goose run --recipe .goose/recipes/implement.yaml
# Expected: Prompt "Path to implementation plan file: "

# Backward compatibility tests (automated - no user input required)
goose run --recipe .goose/recipes/research.yaml --params topic="Test research topic"
# Expected: Recipe runs with provided topic (no prompt)

goose run --recipe .goose/recipes/create-plan.yaml --params feature_description="Test feature"
# Expected: Recipe runs with provided feature_description (no prompt)

goose run --recipe .goose/recipes/revise.yaml --params existing_plan_path="/path/to/plan.md" revision_details="Test revision"
# Expected: Recipe runs with provided parameters (no prompts)

goose run --recipe .goose/recipes/implement.yaml --params plan_file="/path/to/plan.md"
# Expected: Recipe runs with provided plan_file (no prompt)
```

**Expected Duration**: 1 hour

### Phase 3: Documentation Updates [COMPLETE]

**Objective**: Document user_prompt requirement type and update recipe usage examples

**Complexity**: Low

**Tasks**:
- [x] Update .goosehints Recipe Structure section with user_prompt requirement type explanation (file: /home/benjamin/.config/.goosehints)
- [x] Add interactive prompting usage examples to .goosehints
- [x] Document backward compatibility guarantees (parameters still accepted on CLI)
- [x] Add note about subrecipes remaining programmatic (not interactive)
- [x] Update recipe instruction blocks with interactive mode notes (if applicable)

**Testing**:
```bash
# Verify .goosehints contains user_prompt documentation
grep -A 5 "user_prompt" /home/benjamin/.config/.goosehints

# Verify documentation is clear and accurate
cat /home/benjamin/.config/.goosehints | grep -A 20 "Recipe Structure"
```

**Expected Duration**: 0.5-1 hours

## Testing Strategy

### Manual Testing Approach

Since Goose recipes are tested manually (no automated test framework):

1. **Interactive Mode Testing**:
   - Invoke each recipe without parameters
   - Verify interactive prompts appear with correct description text
   - Enter valid values and verify recipe proceeds correctly
   - Test cancellation behavior (Ctrl+C during prompt)

2. **Backward Compatibility Testing**:
   - Invoke each recipe with CLI parameters (existing usage pattern)
   - Verify recipes run without prompting
   - Verify parameters are correctly passed through to recipe logic

3. **Subrecipe Testing**:
   - Run parent recipes that invoke subrecipes programmatically
   - Verify subrecipes receive parameters correctly (no interactive prompts)
   - Confirm no regression in parent → subrecipe parameter passing

### Test Scenarios

**Test Case 1: Interactive Prompting**
- Input: `goose run --recipe .goose/recipes/research.yaml`
- Expected: Prompt for topic, accept user input, continue execution
- Success Criteria: Recipe runs successfully with user-provided topic

**Test Case 2: CLI Parameters**
- Input: `goose run --recipe .goose/recipes/research.yaml --params topic="JWT auth"`
- Expected: No prompt, recipe runs with provided topic
- Success Criteria: Recipe runs successfully without user interaction

**Test Case 3: Mixed Parameters** (revise.yaml with 2 user_prompt parameters)
- Input: `goose run --recipe .goose/recipes/revise.yaml --params existing_plan_path="/path/to/plan.md"`
- Expected: No prompt for existing_plan_path, prompt for revision_details
- Success Criteria: Recipe prompts only for missing parameter

**Test Case 4: Subrecipe Invocation**
- Input: Run research.yaml (which invokes topic-naming.yaml subrecipe)
- Expected: Subrecipe receives parameters from parent, no interactive prompts
- Success Criteria: Subrecipe executes successfully without user interaction

## Documentation Requirements

### .goosehints Updates

Add new section documenting user_prompt requirement type:

**Section to Add**:
```markdown
### Parameter Requirement Types

Goose recipes support three requirement types for parameters:

1. **required**: Parameter MUST be provided via --params on command line. Recipe fails with error if missing.
2. **optional**: Parameter is optional. Uses default value if not provided via --params.
3. **user_prompt**: If parameter provided via --params, use provided value. If NOT provided, interactively prompt user to enter value.

#### user_prompt Best Practices

Use user_prompt for:
- Primary user inputs (natural language descriptions, file paths)
- Configuration choices that require user decision
- Parameters without sensible defaults

Do NOT use user_prompt for:
- Subrecipe parameters (invoked programmatically, not by users)
- Parameters with sensible defaults (use optional instead)
- Internal state/context parameters

#### Interactive Prompting Examples

With user_prompt:
```bash
# Without --params: interactive prompt appears
$ goose run --recipe research.yaml
? Natural language description of research topic: _

# With --params: no prompt, uses provided value
$ goose run --recipe research.yaml --params topic="JWT authentication patterns"
```
```

**Files to Update**:
- `/home/benjamin/.config/.goosehints` - Add Parameter Requirement Types section

### Recipe Instruction Updates (Optional)

Consider adding notes to recipe instructions about interactive mode:

```yaml
instructions: |
  This recipe can be invoked interactively (without parameters) or with CLI parameters.

  Interactive mode:
    goose run --recipe research.yaml

  CLI mode:
    goose run --recipe research.yaml --params topic="Your research topic"
```

## Dependencies

### External Dependencies

- Goose CLI tool with user_prompt requirement type support (already available)
- Python 3 for YAML validation (system dependency)
- Existing Goose recipe infrastructure (subrecipes, workflow state)

### Internal Dependencies

- No dependencies on other implementation plans
- No changes required to subrecipes or parent recipe invocation logic
- No changes to workflow state management or artifact organization

### Prerequisites

- Working Goose installation at `/home/benjamin/.config/.goose/`
- Existing recipe files in good state (no syntax errors)
- Ability to test recipes manually (interactive terminal access)

## Risk Analysis

### Low-Risk Changes

1. **Backward Compatibility**: Existing CLI parameter passing continues to work unchanged
2. **Syntax Safety**: Only changing one YAML field value (required → user_prompt)
3. **Scope Isolation**: Changes confined to 4 recipe files, no cascading effects

### Potential Issues and Mitigations

**Issue 1: Automated Scripts Break**
- **Risk**: Automated scripts that invoke recipes without parameters will hang waiting for input
- **Likelihood**: Low (most automation provides parameters explicitly)
- **Mitigation**: Document that automation should always provide --params
- **Rollback**: Revert parameter to requirement: required

**Issue 2: MCP Server Invocation**
- **Risk**: If MCP servers invoke recipes programmatically, interactive prompts would break
- **Likelihood**: Medium (depends on MCP server implementation)
- **Mitigation**: Verify MCP server integration provides parameters explicitly
- **Rollback**: Revert parameter to requirement: required

**Issue 3: Subrecipe Prompting**
- **Risk**: Accidentally converting subrecipe parameters would break parent recipes
- **Likelihood**: Very Low (implementation plan explicitly excludes subrecipes)
- **Mitigation**: Double-check only main recipe parameters are converted
- **Rollback**: N/A (not converting subrecipes)

## Rollback Plan

If issues are discovered after conversion:

1. **Immediate Rollback**: Revert all 5 parameter changes back to `requirement: required`
2. **Selective Rollback**: Revert only problematic recipes while keeping others as user_prompt
3. **Hybrid Approach**: Keep user_prompt but add default values to enable automated invocation

**Rollback Commands**:
```bash
# Revert all changes using git
git checkout HEAD -- .goose/recipes/research.yaml
git checkout HEAD -- .goose/recipes/create-plan.yaml
git checkout HEAD -- .goose/recipes/revise.yaml
git checkout HEAD -- .goose/recipes/implement.yaml

# Or use backup files (if created before implementation)
cp .goose/recipes/research.yaml.backup .goose/recipes/research.yaml
cp .goose/recipes/create-plan.yaml.backup .goose/recipes/create-plan.yaml
cp .goose/recipes/revise.yaml.backup .goose/recipes/revise.yaml
cp .goose/recipes/implement.yaml.backup .goose/recipes/implement.yaml
```

## Notes

**Why This Conversion Improves UX**:

Current user experience:
```bash
$ goose run --recipe research.yaml
ERROR: Required parameter 'topic' not provided
```

Improved user experience:
```bash
$ goose run --recipe research.yaml
? Natural language description of research topic: _
[User enters topic interactively]
[Recipe proceeds with provided topic]
```

**Why Subrecipes Are Excluded**:

Subrecipes are invoked by parent recipes, not by users directly:
```yaml
# Parent recipe (research.yaml) invokes subrecipe programmatically
instructions: |
  goose run --recipe subrecipes/topic-naming.yaml \
    --params user_prompt="{{ topic }}" \
            command_name="research" \
            output_path="$TOPIC_NAME_FILE"
```

Converting subrecipe parameters to user_prompt would cause interactive prompts during parent recipe execution, breaking the automated workflow.
