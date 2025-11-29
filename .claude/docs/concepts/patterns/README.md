# Architectural Patterns Catalog

**AUTHORITATIVE SOURCE**: This catalog is the single source of truth for all architectural patterns in Claude Code. Guides and workflows should reference these patterns rather than duplicating their explanations.

[Used by: all commands, agents, and workflows]

This directory documents the core architectural patterns that enable reliable, efficient multi-agent orchestration in Claude Code. These patterns have been validated through implementation and testing, demonstrating measurable improvements in file creation rates (100%), context reduction (95-99%), and time savings (40-60%).

## Pattern Catalog

### Core Patterns

- **[Template vs Behavioral Distinction](../../reference/architecture/template-vs-behavioral.md)** - Critical architectural principle for inline vs reference

### Agent Coordination Patterns

1. **[Behavioral Injection](./behavioral-injection.md)** - Commands inject context into agents via file reads instead of tool invocations
2. **[Hierarchical Supervision](./hierarchical-supervision.md)** - Multi-level agent coordination with recursive supervision for complex workflows
3. **[Forward Message Pattern](./forward-message.md)** - Direct subagent response passing without paraphrasing

### Context Management Patterns

4. **[Metadata Extraction](./metadata-extraction.md)** - Extract title + summary + paths for 95-99% context reduction
5. **[Context Management](./context-management.md)** - Techniques for maintaining <30% context usage throughout workflows

### Reliability Patterns

6. **[Verification and Fallback](./verification-fallback.md)** - MANDATORY VERIFICATION checkpoints with fallback mechanisms for 100% file creation
7. **[Checkpoint Recovery](./checkpoint-recovery.md)** - State preservation and restoration for resilient workflows
8. **[Error Handling](./error-handling.md)** - Centralized JSONL-based error logging with query interface and recovery patterns

### Performance Patterns

9. **[Parallel Execution](./parallel-execution.md)** - Wave-based and concurrent agent execution for 40-60% time savings
10. **[Workflow Scope Detection](./workflow-scope-detection.md)** - Conditional phase execution based on workflow type for context savings

### Classification Patterns

11. **[LLM-Based Hybrid Classification](./llm-classification-pattern.md)** - LLM semantic understanding with automatic regex fallback for 98%+ accuracy and zero operational risk

### File Organization Patterns

12. **[Executable/Documentation Separation](./executable-documentation-separation.md)** - Separate lean executable logic (<250 lines) from comprehensive documentation (unlimited) to eliminate meta-confusion loops and enable independent evolution

## Anti-Patterns

### [Inline Template Duplication](../../troubleshooting/inline-template-duplication.md)

**Problem**: Duplicating agent behavioral guidelines in command prompts instead of referencing agent files

**Impact**: 90% unnecessary code, maintenance burden, synchronization issues

**Detection**:
- >50 lines per agent invocation
- STEP sequences in commands (expect <5)
- PRIMARY OBLIGATION in command files (should be 0)

**Fix**: Extract to `.claude/agents/*.md`, reference via behavioral injection

**See**: [Inline Template Duplication Troubleshooting](../../troubleshooting/inline-template-duplication.md)

## Pattern Relationships

```
Agent Coordination Layer:
  Behavioral Injection ←→ Hierarchical Supervision ←→ Forward Message
           ↓                      ↓                         ↓
Context Management Layer:
  Metadata Extraction ←→ Context Management
           ↓                      ↓
Reliability Layer:
  Verification/Fallback ←→ Checkpoint Recovery
           ↓
Performance Layer:
  Parallel Execution
```

## Using This Catalog

### For Command Development
When creating or updating commands:
1. Use **Executable/Documentation Separation** to create lean command files (<250 lines) with comprehensive guides
2. Use **Behavioral Injection** to invoke agents (not SlashCommand tool)
3. Add **Verification and Fallback** for file creation operations
4. Implement **Metadata Extraction** when passing reports/plans between agents
5. Use **Checkpoint Recovery** for long-running workflows
6. Apply **Parallel Execution** for independent tasks

### For Agent Development
When creating or updating agents:
1. Follow **Hierarchical Supervision** patterns for multi-agent coordination
2. Return metadata using **Metadata Extraction** format (title + summary + paths)
3. Use **Forward Message Pattern** to pass subagent responses
4. Implement **Context Management** techniques to minimize token usage

### For Workflow Design
When designing multi-phase workflows:
1. Start with **Hierarchical Supervision** architecture
2. Apply **Parallel Execution** where phases are independent
3. Use **Checkpoint Recovery** for resumability
4. Implement **Metadata Extraction** between all phases
5. Monitor with **Context Management** metrics

## Pattern Selection Guide

| Scenario | Recommended Patterns |
|----------|---------------------|
| Command invoking single agent | Behavioral Injection, Verification/Fallback |
| Command coordinating 2-4 agents | + Metadata Extraction, Forward Message |
| Command coordinating 5-9 agents | + Hierarchical Supervision (2 levels) |
| Command coordinating 10+ agents | + Hierarchical Supervision (3 levels, recursive) |
| Long-running workflow (>5 phases) | + Checkpoint Recovery, Context Management |
| Independent parallel tasks | + Parallel Execution |
| Multi-scope orchestration (research/plan/implement) | + Workflow Scope Detection |
| Semantic classification/intent detection | + LLM-Based Hybrid Classification |
| All commands/agents | Executable/Documentation Separation (always apply) |

## Performance Metrics

These patterns have demonstrated:
- **File Creation Rate**: 100% (10/10 tests) with Verification/Fallback
- **Context Reduction**: 95-99% with Metadata Extraction
- **Time Savings**: 40-60% with Parallel Execution
- **Context Usage**: <30% throughout workflows with Context Management
- **Classification Accuracy**: 97%+ with LLM-Based Hybrid Classification (vs 92% regex-only)
- **Classification Cost**: $0.03/month for typical usage (100 classifications/day)
- **Reliability**: Zero file creation failures, 100% classification availability with combined patterns

## Related Documentation

- [Hierarchical Agents Guide](../hierarchical-agents.md) - Complete agent architecture
- [Creating Commands Guide](../../guides/development/command-development/command-development-fundamentals.md) - Command development
- [Creating Agents Guide](../../guides/development/agent-development/agent-development-fundamentals.md) - Agent development
- [Testing Patterns Guide](../../guides/patterns/testing-patterns.md) - Validation approaches
- [Performance Measurement Guide](../../guides/patterns/performance-optimization.md) - Metrics and benchmarks

## See Also

- [Command Architecture Standards](../../reference/architecture/overview.md)
- [Orchestration Guide](../../workflows/orchestration-guide.md)
- [Development Workflow](../development-workflow.md)

## Navigation

- [← Parent Directory](../README.md)
- [Related: Troubleshooting](../../troubleshooting/README.md)
- [Related: Pattern Guides](../../guides/patterns/README.md)
