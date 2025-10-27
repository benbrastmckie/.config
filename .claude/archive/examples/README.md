# Examples Directory

Demonstration scripts showing complete workflow patterns for the Claude Code system. Examples provide end-to-end implementations illustrating how different components work together.

## Purpose

This directory contains executable example scripts that demonstrate real-world usage patterns for Claude Code features. Each example is self-contained and runnable, providing both documentation and validation of system capabilities.

**Key Functions**:
- Demonstrate artifact creation workflows
- Show registry integration patterns
- Illustrate end-to-end system usage
- Provide templates for custom workflows

## Module Documentation

### artifact_creation_workflow.sh
**Purpose**: Complete artifact creation workflow demonstration with registry integration

**Functionality**:
- Example 1: Basic artifact creation with directory setup
- Example 2: Research report generation and registration
- Example 3: Implementation plan creation with report linking
- Example 4: Cross-artifact referencing and navigation

**Key Features**:
- Demonstrates `create_artifact_directory()` usage
- Shows artifact numbering and naming conventions
- Illustrates registry integration patterns
- Provides end-to-end workflow examples

**Dependencies**:
- `artifact-utils.sh` - Core artifact management functions
- `.claude/data/registry/artifacts.json` - Artifact registry

## Usage Examples

### Running the Complete Workflow Example

```bash
cd /home/benjamin/.config/.claude/examples
./artifact_creation_workflow.sh
```

**Expected Output**:
```
=== Example 1: Basic Artifact Creation ===
Project: 042_user_authentication
Directory: specs/042_user_authentication/
Next number: 001

=== Example 2: Research Report Creation ===
Created: specs/042_user_authentication/reports/001_authentication_patterns.md

=== Example 3: Implementation Plan ===
Created: specs/042_user_authentication/plans/001_implementation.md

=== Example 4: Cross-Referencing ===
Registry entries created for all artifacts
```

### Using Examples as Templates

To adapt an example for custom workflows:

1. Copy the example script to your working directory
2. Modify the workflow description and artifact names
3. Adjust the artifact types (reports, plans, summaries)
4. Run the adapted script

```bash
cp artifact_creation_workflow.sh ~/my_custom_workflow.sh
# Edit my_custom_workflow.sh with your workflow
bash ~/my_custom_workflow.sh
```

## Integration Points

### Artifact System
Examples demonstrate integration with:
- **Artifact Utilities** (`lib/artifact-utils.sh`) - Directory creation, numbering
- **Registry System** (`.claude/data/registry/`) - Artifact registration and tracking
- **Topic Structure** (`specs/{NNN_topic}/`) - Topic-based organization

### Workflow Commands
These examples complement the following commands:
- `/report` - Research report creation
- `/plan` - Implementation planning
- `/implement` - Plan execution with artifact creation

## Design Philosophy

### Self-Contained Demonstrations
Each example is:
- **Runnable**: Can be executed immediately without modification
- **Complete**: Shows full workflow from start to finish
- **Documented**: Includes inline comments explaining each step
- **Isolated**: Uses temporary data or clearly identified test cases

### Educational Focus
Examples prioritize:
- **Clarity**: Clear variable names and step-by-step progression
- **Best Practices**: Demonstrates recommended patterns and conventions
- **Real-World Relevance**: Based on actual system usage patterns
- **Extensibility**: Easy to adapt for custom workflows

## Navigation

- **Parent**: [.claude/README.md](../README.md) - Claude Code configuration directory
- **Related**: [.claude/lib/README.md](../lib/README.md) - Utility libraries used by examples
- **Related**: [.claude/docs/README.md](../docs/README.md) - Integration guides and standards
