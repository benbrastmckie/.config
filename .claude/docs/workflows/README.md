# Workflows Documentation

## Purpose

Learning-oriented step-by-step tutorials for accomplishing complex workflows. Use this section when you need end-to-end guidance for multi-phase processes like orchestration, adaptive planning, checkpoint management, or document conversion.

## Navigation

- [← Documentation Index](../README.md)
- [Reference](../reference/) - Quick lookup for specifications
- [Guides](../guides/) - Task-focused how-to documentation
- [Concepts](../concepts/) - Understanding-oriented architectural explanations

## Documents in This Section

### [Orchestration Guide](orchestration-guide.md)
**Purpose**: Complete tutorial for parallel operations and multi-agent workflow coordination using the /orchestrate command with artifact-based aggregation and checkpoint system.

**Use Cases**:
- When coordinating complex workflows across research, planning, implementation, and debugging phases
- To leverage parallel execution of independent operations for faster workflows
- When using auto-analysis mode for automatic complexity-based expansion/collapse
- To implement end-to-end development workflows with specialized agents

**See Also**: [Hierarchical Agent Workflow](hierarchical-agent-workflow.md), [Hierarchical Agents](../concepts/hierarchical-agents.md), [Command Reference](../reference/standards/command-reference.md), [Adaptive Planning Guide](adaptive-planning-guide.md)

---

### [Hierarchical Agent Workflow](hierarchical-agent-workflow.md) → Consolidated
**Status**: This guide has been consolidated into [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md#tutorial-walkthrough) as the "Tutorial Walkthrough" section.

**Migration**: For step-by-step workflow tutorials, see the comprehensive Tutorial Walkthrough section in [Hierarchical Agents](../concepts/hierarchical-agents.md#tutorial-walkthrough), which includes:
- /orchestrate complete workflow walkthrough
- /implement with subagent delegation tutorial
- /plan with research integration tutorial
- Checkpoint recovery tutorial

**See Also**: [Orchestration Guide](orchestration-guide.md), [Hierarchical Agents](../concepts/hierarchical-agents.md), [Using Agents](../guides/development/agent-development/agent-development-fundamentals.md), [Development Workflow](../concepts/development-workflow.md)

---

### [Adaptive Planning Guide](adaptive-planning-guide.md)
**Purpose**: Comprehensive tutorial for progressive plan organization (L0, L1, L2) and interruption recovery with checkpoints.

**Use Cases**:
- When creating plans that might grow from simple to complex structures
- To understand when to use Level 0 (single file), Level 1 (phase directory), or Level 2 (stage expansion)
- When implementing workflows that need to survive process interruptions
- To learn checkpoint-based resume functionality for long-running workflows

**See Also**: [Checkpoint Template Guide](checkpoint_template_guide.md), [Phase Dependencies](../reference/workflows/phase-dependencies.md), [Orchestration Guide](orchestration-guide.md)

---

### [Checkpoint-Template System Guide](checkpoint_template_guide.md)
**Purpose**: Consolidated guide for workflow state management and template-based plan generation with seamless integration.

**Use Cases**:
- To understand checkpoint schema, fields, and auto-resume behavior
- When implementing checkpoint support in commands for multi-session workflows
- To use templates for rapid plan generation (60-80% faster than manual /plan)
- When leveraging the integrated template → checkpoint → implementation workflow

**See Also**: [Adaptive Planning Guide](adaptive-planning-guide.md), [Data Management Guide](../guides/patterns/data-management.md)

---

### [Spec Updater Guide](spec_updater_guide.md)
**Purpose**: Tutorial for using the spec updater agent to manage specification artifacts within topic-based directory structure.

**Use Cases**:
- To understand how the spec updater creates and organizes artifacts
- When implementing cross-reference maintenance in plans and reports
- To learn topic organization patterns and subdirectory structure
- When managing artifact lifecycle and gitignore compliance

**See Also**: [Directory Protocols](../concepts/directory-protocols.md), [Development Workflow](../concepts/development-workflow.md)

---

### [TTS Integration Guide](tts-integration-guide.md)
**Purpose**: Complete guide for text-to-speech notification system with 2-category approach and uniform "directory, branch" messages.

**Use Cases**:
- To configure voice feedback for workflow completion and permission requests
- When enabling non-intrusive notifications for long-running commands
- To customize TTS categories, voice parameters, and message formats
- When troubleshooting TTS integration or audio output issues

**See Also**: [Orchestration Guide](orchestration-guide.md), [Efficiency Guide](../guides/patterns/performance-optimization.md)

---

### [Document Conversion Guide](conversion-guide.md)
**Purpose**: Complete tutorial for bidirectional document conversion between DOCX, PDF, and Markdown formats using /convert-docs command.

**Use Cases**:
- When converting documents between Markdown, Word, and PDF formats
- To understand automatic tool selection and fallback behavior
- When converting entire directories of documentation
- To troubleshoot conversion quality or tool installation issues

**See Also**: [Creating Commands](../guides/development/command-development/command-development-fundamentals.md), [Command Reference](../reference/standards/command-reference.md)

---

## Quick Start

### Run Your First Orchestration
1. Review [Orchestration Guide](orchestration-guide.md) architecture section
2. Try basic orchestration: `/orchestrate "Research auth patterns and create plan"`
3. Use dry-run mode to preview: `/orchestrate "..." --dry-run`
4. Monitor parallel execution and artifact generation

### Set Up Adaptive Planning
1. Read [Adaptive Planning Guide](adaptive-planning-guide.md) structure levels
2. Create a simple plan with `/plan` (starts as L0)
3. Let complexity trigger auto-expansion to L1
4. Use `/expand` and `/collapse` to manage structure manually

### Enable Checkpoints
1. Study [Checkpoint Template Guide](checkpoint_template_guide.md) schema
2. Run a multi-phase workflow with `/implement`
3. Interrupt the workflow mid-execution
4. Resume with automatic checkpoint detection

### Convert Documents
1. Review [Conversion Guide](conversion-guide.md) quick start
2. Try simple conversion: `/convert-docs ./doc.md to pdf`
3. Convert directory: `/convert-docs ./docs`
4. Review conversion statistics and tool selection

## Directory Structure

```
workflows/
├── README.md                       (this file)
├── orchestration-guide.md          Multi-agent workflow coordination
├── hierarchical-agent-workflow.md  Supervisor-worker agent patterns
├── adaptive-planning-guide.md      Progressive plan organization and checkpoints
├── checkpoint_template_guide.md    Checkpoint and template system integration
├── spec_updater_guide.md           Artifact management and organization
├── tts-integration-guide.md        Voice notification system
└── conversion-guide.md             Document format conversion
```

## Related Documentation

**Other Categories**:
- [Reference](../reference/) - Command and agent specifications used in workflows
- [Guides](../guides/) - Individual how-to guides that workflows combine
- [Concepts](../concepts/) - Architectural principles underlying workflows

**External Directories**:
- [Commands](../../commands/) - Command implementations for workflows
- [Agents](../../agents/) - Specialized agents used in orchestration
- [Data](../../data/) - Runtime data including checkpoints and logs
- [Templates](../../templates/) - Plan templates for rapid generation
- [Libraries](../../lib/) - Utility functions used in workflows

## Workflow Relationships

### Primary Workflows

**Research → Plan → Implement**:
1. [Orchestration Guide](orchestration-guide.md) coordinates the full workflow
2. [Adaptive Planning Guide](adaptive-planning-guide.md) manages plan structure
3. [Checkpoint Template Guide](checkpoint_template_guide.md) enables resume
4. [Spec Updater Guide](spec_updater_guide.md) organizes artifacts

**Template-Based Development**:
1. [Checkpoint Template Guide](checkpoint_template_guide.md) for template selection
2. [Adaptive Planning Guide](adaptive-planning-guide.md) for plan execution
3. [Orchestration Guide](orchestration-guide.md) for implementation coordination

### Supporting Workflows

**Notification Integration**:
- [TTS Integration Guide](tts-integration-guide.md) provides voice feedback
- Integrates with all long-running workflows
- Non-intrusive context awareness

**Documentation Management**:
- [Conversion Guide](conversion-guide.md) for format transformation
- Supports documentation phases in orchestration
- Enables external document integration

## Learning Path

### Beginner Path
1. [Conversion Guide](conversion-guide.md) - Simplest workflow, immediate utility
2. [Adaptive Planning Guide](adaptive-planning-guide.md) - Understanding plan structures
3. [Checkpoint Template Guide](checkpoint_template_guide.md) - State management basics
4. [Spec Updater Guide](spec_updater_guide.md) - Artifact organization
5. [Orchestration Guide](orchestration-guide.md) - Complete workflow coordination
6. [TTS Integration Guide](tts-integration-guide.md) - Enhanced experience

### Advanced Path
1. [Orchestration Guide](orchestration-guide.md) - Start with full workflow
2. [Hierarchical Agent Workflow](hierarchical-agent-workflow.md) - Supervisor-worker patterns
3. [Hierarchical Agents](../concepts/hierarchical-agents.md) - Deep architecture
4. [Adaptive Planning Guide](adaptive-planning-guide.md) - Advanced structures
5. [Checkpoint Template Guide](checkpoint_template_guide.md) - State optimization
6. [Spec Updater Guide](spec_updater_guide.md) - Custom artifact management

### Integration Path
1. [Checkpoint Template Guide](checkpoint_template_guide.md) - Template → checkpoint flow
2. [Adaptive Planning Guide](adaptive-planning-guide.md) - Plan complexity triggers
3. [Spec Updater Guide](spec_updater_guide.md) - Artifact lifecycle
4. [Orchestration Guide](orchestration-guide.md) - Multi-agent coordination
5. [TTS Integration Guide](tts-integration-guide.md) - User experience enhancement

## Workflow Patterns

### Pattern 1: Feature Development
```
/orchestrate "Implement authentication system" --parallel
  → Research phase (3 parallel agents)
  → Planning phase (template-based plan generation)
  → Implementation phase (adaptive planning with checkpoints)
  → Testing phase (automated test execution)
  → Documentation phase (doc generation + conversion)
```

### Pattern 2: Complex Refactoring
```
/plan-from-template refactoring "Modularize auth system"
  → Template generates L0 plan with checkpoint
  → /implement triggers expansion to L1 (complexity threshold)
  → Checkpoint enables multi-session work
  → Spec updater manages artifact organization
```

### Pattern 3: Documentation Project
```
/convert-docs ./research-docs ./final-docs
  → Batch convert DOCX/PDF to Markdown
  → Edit and enhance Markdown files
  → Convert back to DOCX/PDF for distribution
  → TTS notifications on completion
```

## Performance Optimization

**Parallel Execution**:
- Use `--parallel` flag in /orchestrate for 40-60% time savings
- Leverage phase dependencies for wave-based execution
- Review [Phase Dependencies](../reference/workflows/phase-dependencies.md) for syntax

**Context Efficiency**:
- Hierarchical agents achieve 92-97% context reduction
- Forward message pattern eliminates paraphrasing overhead
- Metadata-only passing reduces artifact references by 99%

**Template Acceleration**:
- Template-based planning is 60-80% faster than manual /plan
- Pre-configured patterns reduce decision overhead
- Integrated checkpoint creation eliminates setup steps
