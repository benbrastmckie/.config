# Goose Recipes user_prompt Conversion - Manual Testing Guide

## Overview

This guide documents the manual testing procedures for validating the user_prompt conversion in Goose recipes. The conversion affects 5 parameters across 4 main recipes.

**Date Created**: 2025-12-06
**Testing Type**: Manual (no automated test framework for Goose recipes)
**Expected Duration**: 1 hour

## Files Modified

1. `/home/benjamin/.config/.goose/recipes/research.yaml` - topic parameter
2. `/home/benjamin/.config/.goose/recipes/create-plan.yaml` - feature_description parameter
3. `/home/benjamin/.config/.goose/recipes/revise.yaml` - existing_plan_path and revision_details parameters
4. `/home/benjamin/.config/.goose/recipes/implement.yaml` - plan_file parameter

## Test Scenarios

### Test Case 1: Interactive Prompting - research.yaml

**Objective**: Verify interactive prompting works when no parameters provided

**Test Command**:
```bash
goose run --recipe .goose/recipes/research.yaml
```

**Expected Behavior**:
- Goose displays prompt: "Natural language description of research topic: "
- User can enter topic text interactively
- Recipe proceeds with user-provided topic

**Success Criteria**:
- [ ] Prompt appears with correct description text
- [ ] User input is accepted
- [ ] Recipe executes successfully with provided topic

### Test Case 2: Backward Compatibility - research.yaml

**Objective**: Verify CLI parameter passing still works (backward compatibility)

**Test Command**:
```bash
goose run --recipe .goose/recipes/research.yaml --params topic="JWT authentication patterns"
```

**Expected Behavior**:
- No interactive prompt appears
- Recipe runs immediately with provided topic
- Topic value is correctly used in workflow

**Success Criteria**:
- [ ] No prompt displayed
- [ ] Recipe executes without user interaction
- [ ] Topic parameter correctly passed to workflow

### Test Case 3: Interactive Prompting - create-plan.yaml

**Objective**: Verify interactive prompting for create-plan workflow

**Test Command**:
```bash
goose run --recipe .goose/recipes/create-plan.yaml
```

**Expected Behavior**:
- Goose displays prompt: "Natural language description of feature to implement: "
- User can enter feature description interactively
- Recipe proceeds with user-provided description

**Success Criteria**:
- [ ] Prompt appears with correct description text
- [ ] User input is accepted
- [ ] Recipe executes successfully with provided feature_description

### Test Case 4: Backward Compatibility - create-plan.yaml

**Objective**: Verify CLI parameter passing for create-plan

**Test Command**:
```bash
goose run --recipe .goose/recipes/create-plan.yaml --params feature_description="Add dark mode toggle to settings"
```

**Expected Behavior**:
- No interactive prompt appears
- Recipe runs immediately with provided feature_description
- Feature description correctly used in planning workflow

**Success Criteria**:
- [ ] No prompt displayed
- [ ] Recipe executes without user interaction
- [ ] Feature description parameter correctly passed to workflow

### Test Case 5: Multiple Interactive Prompts - revise.yaml

**Objective**: Verify multiple user_prompt parameters prompt sequentially

**Test Command**:
```bash
goose run --recipe .goose/recipes/revise.yaml
```

**Expected Behavior**:
- First prompt: "Path to existing plan file to revise: "
- User enters plan path
- Second prompt: "Natural language description of revision requirements: "
- User enters revision details
- Recipe proceeds with both user-provided values

**Success Criteria**:
- [ ] First prompt appears for existing_plan_path
- [ ] Second prompt appears for revision_details
- [ ] Both inputs are accepted
- [ ] Recipe executes with both provided values

### Test Case 6: Mixed Parameters - revise.yaml

**Objective**: Verify partial CLI parameters prompt only for missing values

**Test Command**:
```bash
goose run --recipe .goose/recipes/revise.yaml --params existing_plan_path="/home/benjamin/.config/.claude/specs/999_goose_recipes_user_prompt/plans/001-goose-recipes-user-prompt-plan.md"
```

**Expected Behavior**:
- No prompt for existing_plan_path (provided via CLI)
- Prompt appears for revision_details (not provided)
- User enters revision details interactively
- Recipe proceeds with CLI parameter + user input

**Success Criteria**:
- [ ] No prompt for existing_plan_path
- [ ] Prompt appears only for revision_details
- [ ] Recipe executes with mixed parameter sources

### Test Case 7: Full Backward Compatibility - revise.yaml

**Objective**: Verify all parameters can be provided via CLI

**Test Command**:
```bash
goose run --recipe .goose/recipes/revise.yaml \
  --params existing_plan_path="/path/to/plan.md" \
  --params revision_details="Add error handling to Phase 2"
```

**Expected Behavior**:
- No interactive prompts appear
- Recipe runs immediately with all provided parameters
- Both parameters correctly used in workflow

**Success Criteria**:
- [ ] No prompts displayed
- [ ] Recipe executes without user interaction
- [ ] Both parameters correctly passed to workflow

### Test Case 8: Interactive Prompting - implement.yaml

**Objective**: Verify interactive prompting for implement workflow

**Test Command**:
```bash
goose run --recipe .goose/recipes/implement.yaml
```

**Expected Behavior**:
- Goose displays prompt: "Path to implementation plan file: "
- User can enter plan file path interactively
- Recipe proceeds with user-provided path

**Success Criteria**:
- [ ] Prompt appears with correct description text
- [ ] User input is accepted
- [ ] Recipe executes successfully with provided plan_file

### Test Case 9: Backward Compatibility - implement.yaml

**Objective**: Verify CLI parameter passing for implement workflow

**Test Command**:
```bash
goose run --recipe .goose/recipes/implement.yaml --params plan_file="/home/benjamin/.config/.claude/specs/999_goose_recipes_user_prompt/plans/001-goose-recipes-user-prompt-plan.md"
```

**Expected Behavior**:
- No interactive prompt appears
- Recipe runs immediately with provided plan_file
- Plan file path correctly used in implementation workflow

**Success Criteria**:
- [ ] No prompt displayed
- [ ] Recipe executes without user interaction
- [ ] Plan file parameter correctly passed to workflow

### Test Case 10: Subrecipe Invocation

**Objective**: Verify subrecipes still work when invoked programmatically (no interactive prompts)

**Test Command**:
```bash
# Run parent recipe that invokes subrecipe
goose run --recipe .goose/recipes/research.yaml --params topic="Test subrecipe invocation"
```

**Expected Behavior**:
- research.yaml invokes topic-naming.yaml subrecipe internally
- Subrecipe receives parameters from parent recipe (not from user prompts)
- No interactive prompts during subrecipe execution
- Workflow completes successfully

**Success Criteria**:
- [ ] Parent recipe runs successfully
- [ ] Subrecipe executes without user interaction
- [ ] No unexpected prompts during subrecipe execution
- [ ] Topic naming subrecipe generates correct output

## Testing Notes

### Cancellation Behavior

Test that users can cancel interactive prompts:
- Press Ctrl+C during interactive prompt
- Expected: Recipe exits cleanly without error
- Goose should handle cancellation gracefully

### Empty Input Handling

Test empty input during interactive prompts:
- Press Enter without typing anything
- Expected behavior varies by Goose implementation:
  - May re-prompt user
  - May accept empty value (if parameter allows)
  - May fail with validation error

### Long Input Handling

Test long text input (500+ characters):
- Enter multi-line description or very long single line
- Expected: Goose accepts long input correctly
- Recipe processes full input value

## Risk Mitigation

### Automated Script Compatibility

**Risk**: Automated scripts that invoke recipes without parameters will hang waiting for input

**Mitigation Check**:
1. Review any existing automation scripts
2. Verify they provide --params explicitly
3. Update scripts if necessary to pass parameters via CLI

**Documentation Update**: Add note to .goosehints about always providing parameters in automated contexts

### MCP Server Integration

**Risk**: MCP servers that invoke recipes programmatically may break if they don't provide parameters

**Mitigation Check**:
1. Test any MCP server integrations that use Goose recipes
2. Verify MCP servers pass parameters explicitly
3. Update MCP server code if necessary

**Rollback Plan**: Revert problematic parameters to `requirement: required` if MCP issues found

## Test Results Documentation

After completing manual tests, document results here:

### Test Execution Date: _____________

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC1: Interactive - research.yaml | [ ] Pass [ ] Fail | |
| TC2: Backward compat - research.yaml | [ ] Pass [ ] Fail | |
| TC3: Interactive - create-plan.yaml | [ ] Pass [ ] Fail | |
| TC4: Backward compat - create-plan.yaml | [ ] Pass [ ] Fail | |
| TC5: Multiple prompts - revise.yaml | [ ] Pass [ ] Fail | |
| TC6: Mixed params - revise.yaml | [ ] Pass [ ] Fail | |
| TC7: Full backward compat - revise.yaml | [ ] Pass [ ] Fail | |
| TC8: Interactive - implement.yaml | [ ] Pass [ ] Fail | |
| TC9: Backward compat - implement.yaml | [ ] Pass [ ] Fail | |
| TC10: Subrecipe invocation | [ ] Pass [ ] Fail | |

### Issues Found

Document any issues encountered during testing:

1. Issue: _______________________________
   - Severity: [ ] Critical [ ] High [ ] Medium [ ] Low
   - Workaround: _________________________
   - Resolution: _________________________

### Rollback Decision

If critical issues found:
- [ ] Proceed with conversion (issues acceptable)
- [ ] Rollback all changes
- [ ] Selective rollback (specify recipes): __________________

## Sign-off

Testing completed by: _________________
Date: _________________
Approved for deployment: [ ] Yes [ ] No
