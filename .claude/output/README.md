# Output Directory

This directory contains generated output files from various .claude/ workflows and commands. Output files are gitignored and serve as temporary documentation of workflow execution.

## Output File Types

### Workflow Outputs
- `build-output.md` - Output from /build command execution
- `plan-output.md` - Output from /plan command execution
- `research-output.md` - Output from /research command execution
- `debug-output.md` - Output from /debug command execution
- `repair-output.md` - Output from /repair command execution
- `revise-output.md` - Output from /revise command execution

### Command Outputs
- `convert-docs-output.md` - Output from /convert-docs command
- `errors-output.md` - Output from /errors command

## File Naming Convention

Output files follow the pattern: `{command-name}-output.md` or `{workflow-name}-output.md`

Numbered variants (e.g., `build-output-2.md`) are created when multiple executions occur in the same session.

## Lifecycle

- **Generated**: Automatically created during workflow/command execution
- **Retention**: Temporary - files persist until manually cleaned or overwritten
- **Gitignore**: All files in this directory are gitignored (not committed to version control)
- **Cleanup**: Manual deletion or automated cleanup via workflow scripts

## Navigation

[← Parent](../)
