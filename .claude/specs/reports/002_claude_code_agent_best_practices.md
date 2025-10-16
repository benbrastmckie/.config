# Claude Code Agent and Command Best Practices Research Report

## Metadata
- **Date**: 2025-09-29
- **Scope**: Claude Code subagent architecture, slash command structure, and prompt engineering
- **Primary Directory**: /home/benjamin/.dotfiles
- **Files Analyzed**: 18 command files in .claude/commands/, CLAUDE.md, settings.local.json

## Executive Summary

This report analyzes best practices for creating effective prompts and commands for subagents in Claude Code, based on examination of existing command implementations, official documentation, and architectural patterns. Key findings include standardized YAML frontmatter structures, specialized tool access patterns, and systematic approaches to task decomposition and execution.

**Implementation Update (2025-09-29)**: This research directly informed the successful implementation of the `/subagents` utility command. See [implementation summary](../summaries/001_subagents_implementation_summary.md) for detailed results.

## Current State Analysis

### Existing Command Infrastructure

The codebase contains a sophisticated slash command system with 18 implemented commands in `.claude/commands/`:

**Primary Commands**: setup, plan, implement, report, debug, refactor
**Secondary Commands**: test, test-all, document, cleanup, validate-setup
**Utility Commands**: list-plans, list-reports, list-summaries, update-plan, update-report, revise

### Command Structure Pattern

All commands follow a consistent YAML frontmatter + Markdown structure:

```yaml
---
allowed-tools: [tool1, tool2, ...]
argument-hint: <required> [optional]
description: Brief description of command purpose
command-type: primary|secondary|utility
dependent-commands: [related-commands]
---
```

### Tool Access Patterns

Commands demonstrate sophisticated tool restrictions:
- **Read-only research**: `Read, Bash, Grep, Glob, WebSearch, WebFetch`
- **Development workflow**: `Read, Edit, MultiEdit, Write, Bash, TodoWrite`
- **Analysis tasks**: `Read, Bash, Grep, Glob, Task`

## Key Findings

### 1. Command Architecture Patterns

#### YAML Frontmatter Standards
- **allowed-tools**: Precise tool restriction for security and focus
- **argument-hint**: User-facing parameter documentation using `<required>` and `[optional]`
- **description**: Single-line purpose statement for command discovery
- **command-type**: Hierarchical classification (primary/secondary/utility)
- **dependent-commands**: Cross-referencing for workflow integration

#### Markdown Content Structure
```markdown
# Command Title

Brief introduction paragraph

## Target/Scope
$ARGUMENTS parsing and interpretation

## Process
### 1. Step Name
Detailed methodology

## Output Format
Expected results structure
```

### 2. Subagent Configuration Best Practices

Based on official documentation analysis:

#### YAML Configuration Structure
```yaml
---
name: kebab-case-identifier
description: Natural language trigger condition
tools: tool1, tool2  # Optional, inherits all if omitted
model: sonnet        # Optional, inherits if omitted
---

Detailed system prompt with role definition, capabilities, constraints
```

#### Specialized Tool Access
- Limit tools to minimum required for task
- Use tool restrictions to enforce specialization
- Consider security implications of tool combinations

### 3. Prompt Engineering Patterns

#### Systematic Task Decomposition
Commands consistently follow this pattern:
1. **Scope determination** - Parse arguments and identify target
2. **Context discovery** - Find relevant files and configurations
3. **Standards application** - Apply project-specific rules
4. **Execution phases** - Break work into manageable steps
5. **Validation** - Test and verify results
6. **Documentation** - Update specs and cross-references

#### Interactive Guidance
- Use conditional prompts based on discovered state
- Provide fallback strategies when standards don't exist
- Include help text and examples for user guidance

## Analysis of Effective Command Patterns

### Best Performing Commands

#### `/implement` Command Excellence
- **Auto-resume capability** - Intelligent plan detection and continuation
- **Phase-based execution** - Systematic progress tracking
- **Automated testing** - Built-in validation at each phase
- **Git integration** - Structured commit messages
- **Summary generation** - Post-completion documentation

#### `/debug` Command Sophistication
- **Investigation-only approach** - No code changes during analysis
- **Evidence gathering** - Systematic root cause analysis
- **Multiple solution options** - Comprehensive recommendation framework
- **Risk assessment** - Categorized findings by priority and effort

#### `/refactor` Command Comprehensiveness
- **Standards-based analysis** - CLAUDE.md compliance checking
- **Priority categorization** - Critical/High/Medium/Low classification
- **Effort estimation** - Time-based task sizing
- **Risk evaluation** - Safe/Low/Medium/High risk assessment

### Command Integration Patterns

#### Workflow Dependencies
- **Linear workflows**: setup → validate-setup
- **Research workflows**: report → plan → implement → summaries
- **Iterative workflows**: debug → plan → implement → test
- **Maintenance workflows**: refactor → plan → implement

#### Cross-Reference Systems
- Commands reference each other for workflow guidance
- Consistent file numbering across specs directories
- Automatic discovery of related documents

## Technical Architecture Insights

### Context Management
- **Stateless agents** - Each invocation starts fresh
- **Detailed task descriptions** - Comprehensive prompt context
- **Tool-specific permissions** - Granular capability control
- **Parallel execution support** - Multiple agents can work simultaneously

### File Organization Patterns
- **Specs directory protocol** - Standardized documentation structure
- **Numbered file naming** - Sequential identification system
- **Location determination** - Intelligent placement in project hierarchy
- **Template consistency** - Standardized document formats

## Recommendations for Agent Creation

### 1. Command Design Principles

#### Single Responsibility
- Create focused commands that do one thing well
- Use dependent-commands for workflow orchestration
- Avoid "super-agents" that try to do everything

#### Progressive Disclosure
- Start with simple argument patterns
- Add complexity through optional parameters
- Provide examples and help text

#### Fail-Safe Design
- Include validation steps before execution
- Provide rollback strategies
- Use dry-run capabilities where appropriate

### 2. YAML Frontmatter Best Practices

#### Tool Restrictions
```yaml
# Research tasks
allowed-tools: Read, Bash, Grep, Glob, WebSearch, WebFetch

# Development tasks
allowed-tools: Read, Edit, MultiEdit, Write, Bash, TodoWrite

# Analysis tasks
allowed-tools: Read, Bash, Grep, Glob, Task
```

#### Argument Documentation
```yaml
# Clear parameter specification
argument-hint: <feature-name> [report-path1] [report-path2]

# Optional parameters in brackets
argument-hint: [project-directory]

# Multiple formats
argument-hint: <issue-description> [report-path1] [report-path2] ...
```

### 3. Prompt Engineering Strategies

#### Context Establishment
- Begin with clear objective statement
- Parse and validate arguments early
- Discover project structure and standards
- Reference related documentation

#### Process Documentation
- Break complex tasks into numbered phases
- Include validation steps at each phase
- Provide clear success criteria
- Document decision points and alternatives

#### Output Specification
- Define expected deliverables
- Specify file locations and naming
- Include cross-references and metadata
- Plan for future maintenance

### 4. Agent Specialization Patterns

#### Code Analysis Agents
- Focus on specific languages or frameworks
- Include linting and style checking
- Provide refactoring recommendations
- Generate test coverage reports

#### Development Workflow Agents
- Handle specific phases (planning, implementation, testing)
- Manage git workflows and commits
- Update documentation automatically
- Track project standards compliance

#### Research and Investigation Agents
- Specialized in information gathering
- Generate structured reports
- Evaluate alternatives and trade-offs
- Provide actionable recommendations

## Implementation Recommendations

### Immediate Actions

1. **Standardize Command Templates**
   - Create templates for common command patterns
   - Document YAML frontmatter standards
   - Establish tool access guidelines

2. **Create Agent Specialization Guide**
   - Define categories for different agent types
   - Establish naming conventions
   - Document tool permission patterns

3. **Enhance Workflow Integration**
   - Map common development workflows
   - Create workflow-specific agent chains
   - Document command dependencies

### Future Enhancements

1. **Dynamic Agent Generation**
   - Use Claude to generate initial agent configurations
   - Create interactive agent builders
   - Implement agent testing frameworks

2. **Advanced Context Management**
   - Implement context preservation strategies
   - Create context-aware agent selection
   - Develop parallel execution patterns

3. **Quality Assurance Framework**
   - Create agent validation tools
   - Implement performance monitoring
   - Develop agent effectiveness metrics

## References

### Codebase Files
- `/home/benjamin/.dotfiles/.claude/commands/` - Command implementations
- `/home/benjamin/.dotfiles/.claude/settings.local.json` - Permission configuration
- `/home/benjamin/.dotfiles/CLAUDE.md` - Project standards and protocols
- `/home/benjamin/.dotfiles/specs/` - Documentation structure

### External Documentation
- Claude Code Subagents Documentation: https://docs.claude.com/en/docs/claude-code/sub-agents
- Claude Code Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices
- Awesome Claude Code Subagents: https://github.com/VoltAgent/awesome-claude-code-subagents

### Command Dependencies Map
```
setup → validate-setup
report → plan → implement → summaries
debug → plan → implement → test
refactor → plan → implement
list-* → update-* → revise
```

## Lessons Learned

1. **Consistency is Critical** - Standardized patterns across all commands enable predictable behavior
2. **Tool Restrictions Enhance Focus** - Limiting tool access improves agent specialization
3. **Documentation Integration** - Commands that update their own documentation are more maintainable
4. **Workflow Awareness** - Commands that understand their place in development workflows are more effective
5. **Error Recovery** - Commands with built-in error handling and recovery are more robust

## Next Steps

1. Use these findings to improve existing command implementations
2. Create new specialized agents based on identified patterns
3. Develop agent testing and validation frameworks
4. Document agent interaction patterns for complex workflows
5. Establish metrics for measuring agent effectiveness