# Manual Testing Tools

Interactive testing tools for manual validation workflows.

## Purpose

This directory contains manual testing scripts that require human interaction or judgment. These tools support exploratory testing, integration validation, and scenarios that are difficult to fully automate.

## Test Organization

Manual tests cover:
- End-to-end workflow validation
- Hybrid classification testing
- Interactive feature exploration

## Running Tests

```bash
# Run manual test (interactive)
cd /home/benjamin/.config/.claude/tests/utilities/manual
bash manual_e2e_hybrid_classification.sh
```

Manual tests typically:
- Prompt for user input
- Display results for human verification
- Require judgment calls on correctness

## Files in This Directory

### manual_e2e_hybrid_classification.sh
**Purpose**: Manual end-to-end testing of hybrid workflow classification
**Coverage**: Combined scope and workflow detection, integration validation
**Dependencies**: Sample workflows, LLM classifier

**Test Flow**:
1. Presents workflow scenarios
2. Runs classification system
3. Displays classification results
4. Prompts user to verify correctness

## Navigation

- [← Parent Directory](../README.md)
- [Related: benchmarks/](../benchmarks/README.md)
