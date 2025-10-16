# Research Report: Claude Code Slash Commands Best Practices

**Report ID:** 019
**Created:** 2025-09-30
**Status:** Complete

## Executive Summary

This comprehensive research report documents best practices for creating custom slash commands in Claude Code, covering official documentation, community practices, command design principles, workflow optimization, and advanced features. The findings are based on extensive review of official Anthropic documentation, community repositories, and real-world implementations.

## Table of Contents

1. [Official Documentation](#official-documentation)
2. [Command Creation Fundamentals](#command-creation-fundamentals)
3. [Frontmatter Configuration](#frontmatter-configuration)
4. [Parameter Handling](#parameter-handling)
5. [Command Organization](#command-organization)
6. [Design Principles](#design-principles)
7. [Workflow Optimization](#workflow-optimization)
8. [Advanced Features](#advanced-features)
9. [Security and Performance](#security-and-performance)
10. [Community Best Practices](#community-best-practices)
11. [Examples and Patterns](#examples-and-patterns)
12. [References](#references)

---

## 1. Official Documentation

### Primary Sources

**Main Documentation:**
- **URL:** https://docs.claude.com/en/docs/claude-code/slash-commands
- **Key Focus:** Command creation, frontmatter options, argument handling
- **Status:** Actively maintained by Anthropic

**Best Practices Guide:**
- **URL:** https://www.anthropic.com/engineering/claude-code-best-practices
- **Key Focus:** Design philosophy, workflow recommendations, team collaboration
- **Status:** Official engineering blog post

**Hooks Reference:**
- **URL:** https://docs.claude.com/en/docs/claude-code/hooks
- **Key Focus:** Automation, lifecycle events, command integration

### Core Principles from Official Documentation

1. **Intentional Simplicity:** Claude Code is "intentionally low-level and unopinionated," providing close to raw model access without forcing specific workflows.

2. **Safety First:** "The most important principle is: if you start running Claude Code, it shouldn't change things on your system without permission."

3. **Unix Philosophy:** Claude Code is composable and scriptable, following Unix principles of doing one thing well.

4. **Team Collaboration:** Commands are designed to be shared via version control, creating consistent workflows across development teams.

---

## 2. Command Creation Fundamentals

### Command Types and Scopes

Claude Code supports two types of custom slash commands:

#### Project-Scoped Commands
- **Location:** `.claude/commands/`
- **Visibility:** Available only within the specific project
- **Sharing:** Automatically shared when repository is cloned
- **Display:** Shows "(project)" suffix in `/help` output
- **Use Case:** Team workflows, project-specific automation

#### User-Scoped Commands
- **Location:** `~/.claude/commands/`
- **Visibility:** Available across all projects for the user
- **Sharing:** Personal only (not version controlled)
- **Display:** Shows "(user)" suffix in `/help` output
- **Use Case:** Personal utilities, cross-project tools

### Basic Command Structure

Commands are created as Markdown files where:
- **Filename** (without `.md` extension) becomes the command name
- **File content** contains the prompt/instructions
- **Frontmatter** (optional but recommended) provides metadata

**Minimal Example:**
```markdown
Fix the reported bug and add tests to prevent regression.
```
Saved as `.claude/commands/fix-bug.md`, this becomes `/fix-bug`.

---

## 3. Frontmatter Configuration

### Complete Frontmatter Reference

Frontmatter provides metadata for commands using YAML syntax:

```yaml
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
argument-hint: [message]
description: Create a git commit
model: claude-3-5-haiku-20241022
disable-model-invocation: false
---
```

### Frontmatter Fields

#### `description` (Required)
- **Purpose:** Describes what the command does
- **Visibility:** Shown in `/help` and used by SlashCommand tool
- **Requirement:** Must be populated for command to be invocable via SlashCommand tool
- **Best Practice:** Keep concise (one line), action-oriented

**Example:**
```yaml
description: Review pull request for code quality and security
```

#### `allowed-tools` (Security Critical)
- **Purpose:** Restricts which Claude Code tools the command can use
- **Format:** Comma-separated list of tool names with optional patterns
- **Security:** Prevents commands from accessing unauthorized tools
- **Default:** If omitted, command has access to all available tools

**Syntax Examples:**
```yaml
# Specific git operations only
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)

# Read-only file access
allowed-tools: Read, Grep, Glob

# Full edit capabilities with git
allowed-tools: Read, Edit, Write, Bash(git:*)
```

**Tool Restriction Best Practices:**
1. **Start Restrictive:** Begin with minimal permissions, add as needed
2. **Avoid Wildcards:** `Bash(*)` is overly permissive
3. **Scope Commands:** Limit to project directory when possible
4. **No Dangerous Ops:** Never include `sudo`, `rm -rf`, or network operations

#### `argument-hint`
- **Purpose:** Provides autocomplete suggestions for command parameters
- **Format:** Square brackets for required args, descriptions in natural language
- **Visibility:** Shown when user types the command

**Examples:**
```yaml
# Single argument
argument-hint: [message]

# Multiple positional arguments
argument-hint: [pr-number] [priority] [assignee]

# Optional argument indication
argument-hint: [file-path] [optional-context]
```

#### `model`
- **Purpose:** Specifies which Claude model to use for this command
- **Use Case:** Use smaller models for simple tasks, larger for complex reasoning
- **Format:** Model identifier string

**Examples:**
```yaml
# Fast, cost-effective for simple tasks
model: claude-3-5-haiku-20241022

# Default for most tasks
model: claude-sonnet-4-5-20250929

# Complex reasoning tasks
model: claude-3-5-opus-20241022
```

#### `disable-model-invocation`
- **Purpose:** Prevents command from being available
- **Effect:** Removes command metadata from context
- **Use Case:** Temporarily disable commands without deleting files
- **Default:** `false`

**Example:**
```yaml
disable-model-invocation: true
```

---

## 4. Parameter Handling

### Argument Placeholders

Claude Code supports multiple parameter handling patterns:

#### `$ARGUMENTS` - Capture All
- **Behavior:** Captures all arguments as a single string
- **Use Case:** When you want full flexibility in argument parsing

**Example:**
```markdown
---
description: Fix GitHub issue
argument-hint: [issue-number] [additional-context]
---
Please analyze and fix GitHub issue: $ARGUMENTS
```

**Usage:** `/fix-issue 123 high-priority security-related`
**Expansion:** "Please analyze and fix GitHub issue: 123 high-priority security-related"

#### Positional Parameters - `$1`, `$2`, `$3`, etc.
- **Behavior:** Accesses specific arguments by position
- **Use Case:** When arguments have distinct meanings

**Example:**
```markdown
---
description: Review pull request
argument-hint: [pr-number] [priority] [assignee]
---
Review PR #$1 with priority $2 and assign to $3.

Focus on:
- Security vulnerabilities
- Performance implications
- Code style consistency
```

**Usage:** `/review-pr 456 high alice`
**Expansion:**
```
Review PR #456 with priority high and assign to alice.

Focus on:
- Security vulnerabilities
- Performance implications
- Code style consistency
```

### Parameter Best Practices

1. **Clear Argument Hints:** Use descriptive names that indicate what each parameter means
2. **Validation in Prompt:** Include instructions for handling missing/invalid parameters
3. **Default Behaviors:** Specify what happens when optional arguments are omitted
4. **Mixed Approach:** Combine positional and $ARGUMENTS for flexibility

**Advanced Example:**
```markdown
---
description: Deploy application to environment
argument-hint: [environment] [version] [flags]
---
Deploy application to $1 environment.

Version: ${2:-latest}
Additional flags: $ARGUMENTS

Pre-deployment checklist:
1. Verify environment configuration
2. Run pre-deployment tests
3. Create deployment backup
4. Execute deployment
5. Run post-deployment health checks
```

---

## 5. Command Organization

### Directory Structure and Namespacing

Commands support hierarchical organization through subdirectories:

#### Namespace Pattern
```
.claude/commands/
├── test/
│   ├── unit.md       → /test:unit
│   ├── integration.md → /test:integration
│   └── e2e.md        → /test:e2e
├── deploy/
│   ├── staging.md    → /deploy:staging
│   ├── production.md → /deploy:production
│   └── rollback.md   → /deploy:rollback
└── database/
    ├── migrate.md    → /database:migrate
    ├── seed.md       → /database:seed
    └── backup.md     → /database:backup
```

#### Namespace Invocation

Commands in subdirectories can be invoked with colon-separated namespaces:
- Simple: `/test:unit`
- Nested: `/project:database:migrate`
- Scoped: `/user:utils:format-code`

### Organization Best Practices

#### Logical Grouping
Organize commands by:
1. **Function:** dev, test, deploy, docs
2. **Lifecycle:** init, build, release, maintain
3. **Domain:** frontend, backend, database, infra
4. **Team:** design, engineering, ops, security

#### Recommended Structure

```
.claude/commands/
├── dev/              # Development workflows
│   ├── feature.md    # Create new feature
│   ├── refactor.md   # Refactoring tasks
│   └── review.md     # Code review
├── test/             # Testing commands
│   ├── unit.md       # Unit tests
│   ├── integration.md # Integration tests
│   └── coverage.md   # Coverage reports
├── deploy/           # Deployment workflows
│   ├── staging.md
│   └── production.md
├── docs/             # Documentation
│   ├── api.md        # API documentation
│   └── readme.md     # README updates
└── utils/            # Utilities
    ├── format.md     # Code formatting
    └── lint.md       # Linting
```

### Naming Conventions

#### Command Names
- **Use hyphens:** `fix-bug.md` not `fix_bug.md` or `fixBug.md`
- **Be descriptive:** `review-security.md` not `rev-sec.md`
- **Action-oriented:** Start with verbs (create, update, fix, deploy)
- **Avoid abbreviations:** Unless universally understood (api, db, pr)

#### Examples of Good Names
- `create-feature.md` → `/create-feature`
- `review-pull-request.md` → `/review-pull-request`
- `deploy-to-staging.md` → `/deploy-to-staging`
- `update-dependencies.md` → `/update-dependencies`

#### Examples of Poor Names
- `cf.md` (unclear)
- `doStuff.md` (camelCase, vague)
- `review_pr_123.md` (underscores, too specific)
- `x.md` (meaningless)

---

## 6. Design Principles

### Discoverability

Commands should be easy to find and understand:

#### Description Quality
- **Brief but Complete:** One sentence that fully describes the command
- **Action-Oriented:** Start with a verb (Review, Create, Deploy, Fix)
- **Context-Aware:** Include key details (what, how, constraints)

**Good Examples:**
- "Review pull request for code quality, security, and performance"
- "Deploy application to staging with automated rollback"
- "Create feature branch with standardized naming and structure"

**Poor Examples:**
- "PR stuff" (too vague)
- "This command will help you review code" (too wordy)
- "Review" (missing context)

#### Argument Hints
Provide clear guidance on expected parameters:
```yaml
# Good
argument-hint: [issue-number] [priority-level] [assignee]

# Poor
argument-hint: [args]
```

#### Help Documentation
Consider creating a help command:
```markdown
---
description: Show available custom commands with examples
---
List all custom slash commands available in this project:

@.claude/commands/

For each command, show:
1. Command name and invocation
2. Description
3. Required and optional parameters
4. Example usage
```

### Composability

Commands should work well together:

#### Single Responsibility
Each command should do one thing well:
- ✅ `/test:unit` - Run unit tests
- ✅ `/deploy:staging` - Deploy to staging
- ❌ `/test-and-deploy` - Too much coupling

#### Command Chaining
Design commands to be chainable:
```bash
# Sequential execution via user
claude "/test:unit && /test:integration && /deploy:staging"
```

#### State Management
Commands should not rely on hidden state:
- **Explicit inputs:** All required context via arguments or file references
- **Clear outputs:** Produce artifacts that other commands can use
- **Idempotent:** Running twice produces same result

### Error Handling and User Feedback

#### Validate Inputs
Include validation in command prompts:
```markdown
---
description: Deploy to specified environment
argument-hint: [environment]
---
Deploy application to $1 environment.

VALIDATION:
1. Check that $1 is one of: dev, staging, production
2. If invalid, list available environments and exit
3. Confirm deployment target with user before proceeding
```

#### Provide Context
Help users understand what's happening:
```markdown
Before starting:
1. Show current state
2. Explain what will change
3. List steps that will be executed

After completion:
1. Summarize changes made
2. Provide verification steps
3. Suggest next actions
```

#### Handle Failures Gracefully
```markdown
If any step fails:
1. Report exactly what went wrong
2. Preserve system state
3. Provide recovery steps
4. Suggest how to proceed
```

---

## 7. Workflow Optimization

### Common Development Workflows

#### Explore-Plan-Code-Commit Pattern

**Official Recommendation from Anthropic:**
1. **Explore:** Read relevant files to understand context
2. **Plan:** Use "think" modes for deeper analysis, create plan before implementation
3. **Code:** Implement solution with verification
4. **Commit:** Document changes with clear commit messages

**Implementation as Commands:**

```markdown
# .claude/commands/workflow/explore.md
---
description: Explore codebase to understand context for upcoming work
argument-hint: [feature-or-bug-description]
---
Explore the codebase related to: $ARGUMENTS

Steps:
1. Search for relevant files and code
2. Identify key components and dependencies
3. Review recent changes and related issues
4. Summarize architecture and relevant patterns
5. Identify potential challenges

Output: Structured summary for planning phase
```

```markdown
# .claude/commands/workflow/plan.md
---
description: Create implementation plan with extended thinking
argument-hint: [feature-description]
---
ultrathink

Create detailed implementation plan for: $ARGUMENTS

Planning approach:
1. Review exploration findings
2. Consider alternative approaches
3. Evaluate trade-offs
4. Design solution architecture
5. Break down into phases
6. Identify risks and mitigation
7. Define success criteria

Output: Detailed implementation plan with phases
```

```markdown
# .claude/commands/workflow/implement.md
---
description: Implement planned feature with TDD approach
allowed-tools: Read, Edit, Write, Bash(npm:test*), Bash(git:*)
---
Implement the planned feature following TDD approach:

1. Review implementation plan
2. Write tests first (failing tests)
3. Implement minimum code to pass tests
4. Refactor for quality
5. Run full test suite
6. Verify no regressions

Ensure code follows project standards in @CLAUDE.md
```

```markdown
# .claude/commands/workflow/commit.md
---
description: Create well-formatted git commit
allowed-tools: Bash(git:*)
argument-hint: [commit-type]
---
Create git commit following conventional commits:

1. Review changes with git diff
2. Stage appropriate files
3. Write commit message:
   - Type: $1 (feat, fix, docs, refactor, test, chore)
   - Scope: Component affected
   - Description: What and why (not how)
   - Body: Additional context if needed
4. Verify commit with git log
```

#### Test-Driven Development (TDD) Workflow

```markdown
# .claude/commands/tdd/red.md
---
description: Write failing test for new feature
allowed-tools: Read, Edit, Write, Bash(npm:test*)
argument-hint: [feature-description]
---
Write failing test for: $ARGUMENTS

TDD Red Phase:
1. Identify what needs to be tested
2. Write test that describes expected behavior
3. Run test to confirm it fails
4. Document why test should fail

Output: Failing test with clear expectations
```

```markdown
# .claude/commands/tdd/green.md
---
description: Implement minimum code to pass tests
allowed-tools: Read, Edit, Write, Bash(npm:test*)
---
Implement minimum code to make tests pass:

TDD Green Phase:
1. Review failing tests
2. Implement simplest solution
3. Run tests to verify they pass
4. Do not over-engineer

Output: Passing tests with minimal implementation
```

```markdown
# .claude/commands/tdd/refactor.md
---
description: Refactor code while maintaining passing tests
allowed-tools: Read, Edit, Write, Bash(npm:test*)
---
Refactor code to improve quality:

TDD Refactor Phase:
1. Review current implementation
2. Identify improvements (DRY, SOLID, patterns)
3. Refactor incrementally
4. Run tests after each change
5. Ensure all tests remain passing

Output: Improved code with passing tests
```

### Multi-Step Command Workflows

#### Sequential Workflow Example

```markdown
# .claude/commands/workflows/feature-development.md
---
description: Complete feature development workflow from start to finish
argument-hint: [feature-description]
---
Complete feature development workflow:

Phase 1: Planning (use extended thinking)
- Use /workflow:explore $ARGUMENTS
- Use /workflow:plan $ARGUMENTS

Phase 2: Implementation
- Use /tdd:red $ARGUMENTS
- Use /tdd:green
- Use /tdd:refactor

Phase 3: Quality Assurance
- Run full test suite
- Check code coverage
- Run linters and formatters
- Security scan

Phase 4: Documentation
- Update API documentation
- Add code comments
- Update CHANGELOG
- Create or update tests documentation

Phase 5: Review & Commit
- Self-review checklist
- Create commit with /workflow:commit feat
- Prepare PR description

Report progress after each phase.
```

### Performance Optimization Strategies

#### Context Window Management

**Use `/clear` Frequently:**
- Clear history before starting new tasks
- Prevents context window overflow
- Avoids automatic compaction (which may lose context)

**Manual Compaction:**
```markdown
# .claude/commands/utils/compact.md
---
description: Manually compact context at natural breakpoint
---
Review current conversation and identify:
1. Essential context to preserve
2. Completed work to summarize
3. Deprecated information to discard

Then use /compact to optimize context window.
```

#### Prompt Caching

Claude Code automatically enables prompt caching:
- **Benefit:** Reduces costs by up to 90%
- **Benefit:** Reduces latency by up to 85%
- **Monitor:** Use `/cost` to track token usage

**Best Practices:**
- Reuse common prompts across commands
- Reference stable files (CLAUDE.md) frequently
- Structure commands to maximize cache hits

#### CLAUDE.md Optimization

Create project-specific context file:
```markdown
# .claude/commands/setup/init-claude-md.md
---
description: Initialize CLAUDE.md for project
---
Create .claude/CLAUDE.md with:

1. Project Overview
   - Purpose and scope
   - Key technologies
   - Architecture overview

2. Development Guidelines
   - Code style and conventions
   - Testing requirements
   - Git workflow

3. Common Commands
   - Test commands
   - Build commands
   - Deployment process

4. Project-Specific Context
   - Key files and directories
   - Important patterns
   - Known issues and workarounds

This prevents Claude from having to discover context each time.
```

---

## 8. Advanced Features

### Bash Command Execution

Commands can execute bash commands before main prompt using `!` prefix:

**Example:**
```markdown
---
description: Review recent git changes
allowed-tools: Bash(git:*)
---
!git log --oneline -10
!git diff HEAD~1

Review the above git history and changes:
1. Summarize recent work
2. Identify patterns or issues
3. Suggest improvements
```

**Security Note:** Bash commands are restricted to project directory by default.

### File References with `@` Prefix

Include file contents directly in commands:

**Example:**
```markdown
---
description: Review architecture against standards
---
Review current architecture:
@docs/architecture.md

Compare against coding standards:
@CLAUDE.md

Identify:
1. Violations of standards
2. Inconsistencies
3. Improvement opportunities
```

### Extended Thinking Integration

Trigger extended thinking modes for complex reasoning:

**Thinking Levels (in ascending order):**
1. Normal (no keyword)
2. `think` - 4,000 tokens (~standard thinking)
3. `think hard` - Increased budget
4. `think harder` - Higher budget
5. `megathink` - 10,000 tokens
6. `ultrathink` - 31,999 tokens (maximum)

**Usage in Commands:**
```markdown
---
description: Architect complex system with deep analysis
---
ultrathink

Design architecture for: $ARGUMENTS

Consider:
- Multiple alternative approaches
- Detailed trade-off analysis
- Long-term maintainability
- Performance implications
- Security considerations
- Scalability concerns

Provide comprehensive architectural document.
```

**Alternative Triggers for Ultrathink:**
- "think intensely"
- "think longer"
- "think really hard"
- "think super hard"
- "think very hard"

### MCP (Model Context Protocol) Integration

#### MCP Prompts as Slash Commands

MCP servers can expose prompts that appear as slash commands:

**Format:** `/mcp__servername__promptname`

**Configuration Scopes:**
1. **Project:** `.mcp.json` (version controlled, team-shared)
2. **User:** `~/.mcp.json` (personal, cross-project)

**Example .mcp.json:**
```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    },
    "sentry": {
      "command": "npx",
      "args": ["-y", "@sentry/mcp-server"],
      "env": {
        "SENTRY_AUTH_TOKEN": "your-token"
      }
    }
  }
}
```

**Best Practices:**
- Trust MCP servers carefully (they execute code)
- Use local scope for experiments
- Use project scope for team tools
- Use user scope for personal utilities
- Enable `--mcp-debug` flag for troubleshooting

### Hooks for Automation

Hooks execute automatically at lifecycle events:

#### Hook Types
1. **PreToolUse** - Before tool execution
2. **PostToolUse** - After tool completion
3. **UserPromptSubmit** - When user submits prompt
4. **SessionStart** - When session begins
5. **SessionEnd** - When session ends
6. **Notification** - System notifications
7. **Stop/SubagentStop** - When response completes
8. **PreCompact** - Before context compaction

#### Hook Configuration Example

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit(*)",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$TOOL_ARGS_file_path\""
          }
        ]
      },
      {
        "matcher": "Bash(npm:test*)",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Tests completed at $(date)' >> .test-log"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "git fetch origin"
          }
        ]
      }
    ]
  }
}
```

#### Hook Use Cases
- **Automatic formatting:** Format files after edit
- **Test execution:** Run tests after code changes
- **Linting:** Check code style automatically
- **Logging:** Track command usage
- **Notifications:** Alert on important events
- **Security:** Validate dangerous operations

**Security Considerations:**
- Hooks execute shell commands automatically
- Always validate and sanitize inputs
- Use absolute paths
- Quote shell variables properly
- Block path traversal attempts

### Subagents for Verification

Use subagents for complex workflows:

```markdown
---
description: Review code with specialized subagents
argument-hint: [file-or-directory]
---
Review code in $1 using multiple specialized agents:

1. Launch security subagent
   - Focus: vulnerabilities, input validation, auth
   - Output: Security report

2. Launch performance subagent
   - Focus: bottlenecks, algorithmic complexity, caching
   - Output: Performance analysis

3. Launch style subagent
   - Focus: code style, patterns, maintainability
   - Output: Style recommendations

4. Synthesize findings
   - Prioritize issues
   - Create actionable recommendations
   - Estimate effort for fixes
```

---

## 9. Security and Performance

### Security Best Practices

#### Tool Restrictions

**Principle of Least Privilege:**
```yaml
# Bad - Too permissive
allowed-tools: Bash(*)

# Good - Specific permissions
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
```

**Dangerous Commands to Avoid:**
Never include these in `allowed-tools`:
- `sudo` - Privilege escalation
- `rm -rf` - Destructive file operations
- `curl | sh` - Remote code execution
- `eval` - Code injection risks
- Network operations (unless necessary and validated)

#### Input Validation

Include validation in command prompts:
```markdown
---
description: Deploy to environment
argument-hint: [environment]
---
SECURITY: Validate environment parameter

Allowed environments: dev, staging, production

If $1 is not in allowed list:
1. Show error message
2. List valid environments
3. Exit without action

Proceed with deployment to $1 only after validation.
```

#### File Access Controls

```yaml
# Read-only operations
allowed-tools: Read, Grep, Glob

# Safe write operations (no bash)
allowed-tools: Read, Edit, Write

# Limited bash (git only)
allowed-tools: Read, Edit, Write, Bash(git:*)
```

#### Secrets Management

**Never hardcode secrets:**
```markdown
# Bad
Deploy with API key: abc123def456

# Good
Deploy with API key from environment variable $DEPLOY_API_KEY
Verify key is set before proceeding.
```

**Use environment variables:**
```json
{
  "mcpServers": {
    "service": {
      "env": {
        "API_KEY": "${EXTERNAL_API_KEY}"
      }
    }
  }
}
```

### Performance Optimization

#### Token Budget Management

**SlashCommand Tool Budget:**
- Commands have character budget for descriptions
- Keep descriptions concise
- Use `disable-model-invocation: true` to remove from context

**Monitor Usage:**
```markdown
# .claude/commands/utils/check-cost.md
---
description: Check token usage and costs
---
Use /cost to display:
1. Total tokens used
2. Cost breakdown
3. Cache hit rate
4. Recommendations for optimization
```

#### Context Window Optimization

**Clear Context Regularly:**
```markdown
# .claude/commands/utils/clear-context.md
---
description: Clear context at natural breakpoint
---
Before clearing, create summary of:
1. Completed work
2. Decisions made
3. Next steps

Then execute /clear
```

**Strategic File References:**
Prefer file references over inline content:
```markdown
# Less efficient
Review this code:
[large code block]

# More efficient
Review the code in @src/components/App.tsx
```

#### Model Selection

Choose appropriate models for tasks:

```yaml
# Simple, repetitive tasks
model: claude-3-5-haiku-20241022

# Standard development tasks (default)
# (no model specification needed)

# Complex reasoning, architecture
model: claude-3-5-opus-20241022
```

**Cost Optimization:**
- Use Haiku for: formatting, linting, simple refactoring
- Use Sonnet for: feature development, debugging, reviews
- Use Opus for: architecture, complex problem-solving

---

## 10. Community Best Practices

### Real-World Examples from GitHub

#### Major Community Repositories

1. **Claude-Command-Suite (qdhenry)**
   - **Size:** 148+ commands, 54 AI agents
   - **Organization:** Namespace-based (`/dev:*`, `/test:*`, `/security:*`)
   - **Focus:** Professional workflows, multi-agent orchestration
   - **URL:** https://github.com/qdhenry/Claude-Command-Suite

2. **commands (wshobson)**
   - **Size:** 57 commands (15 workflows, 42 tools)
   - **Organization:** Separated workflows vs. tools
   - **Focus:** Production-ready, composable commands
   - **URL:** https://github.com/wshobson/commands

3. **awesome-claude-code (hesreallyhim)**
   - **Type:** Curated collection
   - **Content:** Commands, workflows, tools, resources
   - **Community:** Active aggregation from multiple contributors
   - **URL:** https://github.com/hesreallyhim/awesome-claude-code

4. **claude-sessions (iannuttall)**
   - **Focus:** Session tracking and documentation
   - **Features:** Progress tracking, knowledge transfer
   - **Use Case:** Long-term project continuity
   - **URL:** https://github.com/iannuttall/claude-sessions

5. **claude-slash-commands (artemgetmann)**
   - **Focus:** Educational resource
   - **Features:** Interactive guide, security examples
   - **Use Case:** Learning command creation
   - **URL:** https://github.com/artemgetmann/claude-slash-commands

### Community Patterns

#### Namespace Organization

Popular namespace patterns:
```
/dev:*          # Development commands
/test:*         # Testing commands
/deploy:*       # Deployment commands
/security:*     # Security auditing
/docs:*         # Documentation
/db:*           # Database operations
/api:*          # API operations
```

#### Workflow vs. Tool Separation

**Workflows:** Multi-step, orchestrated processes
```
/workflows:feature-development
/workflows:release-preparation
/workflows:incident-response
```

**Tools:** Single-purpose utilities
```
/tools:format-code
/tools:security-scan
/tools:generate-docs
```

#### Documentation Standards

From professional suites:
1. Clear command purpose in description
2. Example usage in comments
3. Links to detailed documentation
4. Selection guidelines (when to use)
5. Visual categorization (emojis/icons)

#### Command Chaining

Design for composability:
```markdown
# Each command focuses on one phase
/workflows:explore feature-x
/workflows:plan feature-x
/workflows:implement feature-x
/workflows:test feature-x
/workflows:document feature-x
```

### Team Collaboration Best Practices

#### Shared Command Library

**Structure for Teams:**
```
.claude/
├── commands/
│   ├── shared/          # Team-wide commands
│   │   ├── review.md
│   │   └── deploy.md
│   ├── frontend/        # Frontend team
│   │   └── component.md
│   ├── backend/         # Backend team
│   │   └── api.md
│   └── README.md        # Command documentation
└── settings.json        # Shared allowed-tools
```

#### Command Documentation

Create README for command library:
```markdown
# Team Slash Commands

## Development Workflow
- `/dev:feature [name]` - Create new feature branch and setup
- `/dev:review [pr]` - Review pull request
- `/dev:refactor [target]` - Refactor code with tests

## Testing
- `/test:unit [file]` - Run unit tests for file
- `/test:integration` - Run integration test suite
- `/test:coverage` - Generate coverage report

## Deployment
- `/deploy:staging` - Deploy to staging environment
- `/deploy:production` - Deploy to production (requires approval)
- `/deploy:rollback [version]` - Rollback to previous version

## Usage Examples
### Feature Development
1. Create feature: `/dev:feature user-authentication`
2. Implement with TDD: `/test:unit src/auth.ts`
3. Review: `/dev:review 123`
4. Deploy: `/deploy:staging`
```

#### Version Control Integration

**Commit Commands:**
```bash
git add .claude/commands/
git commit -m "feat: add deployment slash commands"
```

**Update Notifications:**
```markdown
# .claude/commands/utils/check-updates.md
---
description: Check for command library updates
---
Check git log for .claude/commands/:

1. Show recent command additions/changes
2. Highlight new features
3. Identify deprecated commands
4. Suggest updating local user commands
```

---

## 11. Examples and Patterns

### Complete Command Examples

#### Example 1: Code Review

```markdown
---
allowed-tools: Read, Grep, Bash(git:*)
argument-hint: [pr-number]
description: Comprehensive code review of pull request
model: claude-sonnet-4-5-20250929
---

Review PR #$1 following project standards.

**Pre-Review:**
1. Fetch latest changes: `git fetch origin`
2. Checkout PR branch
3. Review PR description and linked issues

**Code Review Checklist:**

1. **Correctness**
   - Logic is sound and handles edge cases
   - No obvious bugs or errors
   - Meets requirements from issue/story

2. **Testing**
   - Tests cover new functionality
   - Tests cover edge cases
   - All tests pass
   - Coverage maintained or improved

3. **Security**
   - Input validation present
   - No SQL injection vulnerabilities
   - No XSS vulnerabilities
   - Secrets not hardcoded
   - Authentication/authorization correct

4. **Performance**
   - No N+1 queries
   - Appropriate caching
   - Efficient algorithms
   - No unnecessary computations

5. **Code Quality**
   - Follows project style guide @CLAUDE.md
   - Proper naming conventions
   - Appropriate comments
   - No code duplication
   - SOLID principles followed

6. **Maintainability**
   - Clear and readable
   - Appropriate abstraction level
   - Proper error handling
   - Logging where appropriate

7. **Documentation**
   - API changes documented
   - README updated if needed
   - Inline comments for complex logic
   - CHANGELOG updated

**Output Format:**
- Summary of changes
- Strengths of implementation
- Issues found (categorized by severity)
- Suggestions for improvement
- Approval status (approve/request changes)
```

#### Example 2: Feature Implementation

```markdown
---
allowed-tools: Read, Edit, Write, Bash(git:*), Bash(npm:test*)
argument-hint: [feature-description]
description: Implement feature following TDD and project standards
---

Implement feature: $ARGUMENTS

**Phase 1: Planning (Extended Thinking)**
think hard

1. Review project structure and patterns
2. Identify affected files and components
3. Consider implementation approaches
4. Choose best approach with rationale
5. Break down into implementation steps

**Phase 2: Test-Driven Implementation**

For each component:
1. Write failing test
   - Test file location follows project conventions
   - Test describes expected behavior
   - Run test to confirm failure

2. Implement minimum code
   - Write simplest code to pass test
   - Follow patterns in @CLAUDE.md
   - Run test to confirm pass

3. Refactor
   - Improve code quality
   - Remove duplication
   - Ensure tests still pass

**Phase 3: Integration**
1. Run full test suite
2. Check code coverage (minimum 80%)
3. Run linter
4. Fix any issues

**Phase 4: Documentation**
1. Add JSDoc/docstring comments
2. Update relevant README sections
3. Add CHANGELOG entry

**Phase 5: Self-Review**
1. Review all changes
2. Check against project standards
3. Verify no debug code remains
4. Confirm all tests pass

**Output:**
- Summary of implementation
- Files modified
- Test coverage report
- Commit message draft
```

#### Example 3: Debugging

```markdown
---
allowed-tools: Read, Grep, Bash(git log:*), Bash(git diff:*), Bash(npm:test*)
argument-hint: [bug-description]
description: Systematic debugging approach for reported bug
---

Debug issue: $ARGUMENTS

**Phase 1: Reproduction**
1. Gather information
   - Review bug report/issue
   - Check error logs
   - Identify affected version

2. Reproduce locally
   - Set up reproduction environment
   - Follow reproduction steps
   - Confirm bug occurs
   - Document exact behavior

**Phase 2: Investigation**
think

1. Analyze symptoms
   - What is the actual behavior?
   - What is the expected behavior?
   - When did it start? (git bisect if needed)

2. Identify scope
   - Which components are affected?
   - Find related code: @src/
   - Check recent changes: git log

3. Hypothesis formation
   - List possible causes
   - Rank by likelihood
   - Plan investigation steps

**Phase 3: Root Cause Analysis**
1. For each hypothesis:
   - Add logging/debugging
   - Test hypothesis
   - Document findings

2. Identify root cause
   - Explain why bug occurs
   - Identify contributing factors
   - Check for similar issues elsewhere

**Phase 4: Fix Development**
1. Write regression test
   - Test reproduces bug
   - Test will pass when fixed
   - Run test to confirm failure

2. Implement fix
   - Fix root cause (not symptoms)
   - Keep changes minimal
   - Run test to confirm fix

3. Verify no regressions
   - Run full test suite
   - Check related functionality
   - Test edge cases

**Phase 5: Documentation**
1. Document root cause in commit message
2. Add code comments if complex
3. Update issue/bug report
4. Consider documentation updates

**Output:**
- Root cause explanation
- Fix description
- Testing performed
- Regression prevention measures
```

#### Example 4: Deployment

```markdown
---
allowed-tools: Bash(git:*), Bash(npm:*), Bash(docker:*)
argument-hint: [environment]
description: Deploy application to specified environment
---

Deploy to $1 environment.

**Validation:**
If $1 not in [dev, staging, production]:
  - Show error: "Invalid environment: $1"
  - List valid environments
  - Exit

**Pre-Deployment Checks:**
1. Verify clean git state
   ```bash
   git status
   ```
   - No uncommitted changes
   - No untracked files in production code

2. Verify on correct branch
   - dev: develop branch
   - staging: main branch
   - production: main branch + version tag

3. Run tests
   ```bash
   npm run test:all
   ```
   - All tests must pass
   - Coverage above threshold

4. Build application
   ```bash
   npm run build
   ```
   - Build must succeed
   - No build warnings in production

5. Security checks
   - No secrets in code
   - Dependencies up to date
   - No known vulnerabilities

**Deployment Process:**
1. Create deployment backup
   ```bash
   ./scripts/backup.sh $1
   ```

2. Deploy application
   ```bash
   ./scripts/deploy.sh $1
   ```

3. Health checks (wait 30s)
   - Application responds
   - Database connected
   - External services accessible

4. Smoke tests
   - Critical paths functional
   - No errors in logs

5. Monitoring verification
   - Metrics reporting
   - Logs flowing
   - Alerts configured

**Post-Deployment:**
1. Update deployment log
2. Notify team (Slack/email)
3. Monitor for 5 minutes
4. Document any issues

**Rollback Procedure:**
If any step fails:
```bash
./scripts/rollback.sh $1
```

**Output:**
- Deployment status (success/failure)
- Version deployed
- Health check results
- Monitoring links
```

#### Example 5: Documentation Update

```markdown
---
allowed-tools: Read, Edit, Write, Grep
argument-hint: [scope]
description: Update documentation based on recent code changes
---

Update documentation for: ${1:-entire project}

**Phase 1: Identify Changes**
1. Review recent commits
   ```bash
   git log --since="1 week ago" --oneline
   ```

2. Identify changed files
   - New features added
   - APIs modified
   - Configuration changed
   - Dependencies updated

**Phase 2: Documentation Audit**

For each change, check if documentation exists and is current:

1. **API Documentation**
   - Check @docs/api/
   - Verify endpoints match code
   - Update request/response examples
   - Add new endpoints

2. **README Files**
   - Main @README.md
   - Component READMEs
   - Setup instructions
   - Environment variables

3. **Code Comments**
   - JSDoc/docstrings
   - Complex logic explanations
   - TODO/FIXME comments

4. **CHANGELOG**
   - Add entries for changes
   - Follow semantic versioning
   - Categorize: Added, Changed, Fixed, Removed

5. **Configuration Docs**
   - Environment setup
   - Build configuration
   - Deployment procedures

**Phase 3: Update Documentation**

For each outdated section:
1. Update content
2. Verify accuracy against code
3. Update examples
4. Check links are valid

**Phase 4: Review**
1. Check documentation builds
2. Verify all links work
3. Ensure examples are runnable
4. Check for consistency

**Output:**
- List of files updated
- Summary of changes
- Remaining documentation TODOs
```

### Pattern Library

#### Pattern: Multi-Agent Orchestration

```markdown
---
description: Coordinate multiple specialized agents for complex task
argument-hint: [task-description]
---

Orchestrate agents for: $ARGUMENTS

**Agent Roles:**

1. **Planner Agent** (Extended Thinking)
   - Role: Create comprehensive plan
   - Tools: Read, Grep
   - Output: Structured implementation plan

2. **Implementer Agent**
   - Role: Write code following plan
   - Tools: Read, Edit, Write
   - Output: Implementation code

3. **Tester Agent**
   - Role: Create comprehensive tests
   - Tools: Read, Edit, Write, Bash(npm:test*)
   - Output: Test suite

4. **Reviewer Agent**
   - Role: Review implementation and tests
   - Tools: Read, Grep
   - Output: Review report

5. **Documenter Agent**
   - Role: Update documentation
   - Tools: Read, Edit, Write
   - Output: Updated docs

**Orchestration:**
1. Launch Planner → wait for plan
2. Launch Implementer with plan → wait for code
3. Launch Tester with code → wait for tests
4. Launch Reviewer with code+tests → wait for review
5. If issues found, iterate
6. Launch Documenter with final code → wait for docs
7. Synthesize final report

**Output:**
- Implementation summary
- Test coverage
- Review results
- Documentation changes
```

#### Pattern: Progressive Enhancement

```markdown
---
description: Incrementally improve feature with verification at each step
argument-hint: [feature-name]
---

Progressive enhancement of: $ARGUMENTS

**Iteration 1: Minimum Viable Implementation**
1. Implement core functionality only
2. Basic tests
3. Verify works
4. Commit

**Iteration 2: Error Handling**
1. Add error handling
2. Add error tests
3. Verify graceful failures
4. Commit

**Iteration 3: Edge Cases**
1. Identify edge cases
2. Implement handling
3. Add edge case tests
4. Verify coverage
5. Commit

**Iteration 4: Optimization**
1. Profile performance
2. Optimize bottlenecks
3. Verify no regressions
4. Commit

**Iteration 5: Documentation**
1. Add code comments
2. Update API docs
3. Add usage examples
4. Commit

Each iteration must:
- Be independently functional
- Pass all tests
- Be committed separately
- Move project forward

**Output:**
- Feature complete with tests
- Performance metrics
- Documentation
```

#### Pattern: Safety-First Refactoring

```markdown
---
description: Refactor code safely with comprehensive testing
allowed-tools: Read, Edit, Write, Bash(npm:test*)
argument-hint: [target]
---

Safely refactor: $ARGUMENTS

**Phase 1: Establish Safety Net**
1. Review existing tests
2. Check test coverage (must be >70%)
3. Add missing tests for target
4. Run tests to establish baseline
5. All tests must pass before proceeding

**Phase 2: Analysis**
think

1. Review current implementation
2. Identify code smells:
   - Duplication
   - Long methods
   - Complex conditionals
   - Poor naming
   - Tight coupling

3. Plan refactoring:
   - Order of operations
   - Intermediate states
   - Verification points

**Phase 3: Incremental Refactoring**

For each refactoring step:
1. Make ONE small change
2. Run tests immediately
3. If tests fail:
   - Revert change
   - Analyze failure
   - Adjust approach
4. If tests pass:
   - Commit change
   - Continue to next step

**Refactoring Techniques:**
- Extract Method
- Rename for Clarity
- Remove Duplication
- Simplify Conditionals
- Introduce Polymorphism
- Extract Class/Module

**Phase 4: Verification**
1. Run full test suite
2. Check coverage (must not decrease)
3. Verify performance (no degradation)
4. Review final code against principles:
   - SOLID
   - DRY
   - KISS
   - YAGNI

**Output:**
- Refactored code
- All tests passing
- Coverage report
- Before/after comparison
```

---

## 12. References

### Official Documentation

1. **Claude Code Slash Commands**
   - URL: https://docs.claude.com/en/docs/claude-code/slash-commands
   - Topic: Command creation, frontmatter, arguments

2. **Claude Code Best Practices**
   - URL: https://www.anthropic.com/engineering/claude-code-best-practices
   - Topic: Design philosophy, workflows, team collaboration

3. **Claude Code Hooks Reference**
   - URL: https://docs.claude.com/en/docs/claude-code/hooks
   - Topic: Automation, lifecycle events

4. **Common Workflows**
   - URL: https://docs.claude.com/en/docs/claude-code/common-workflows
   - Topic: Development patterns, productivity features

5. **MCP Integration**
   - URL: https://docs.claude.com/en/docs/claude-code/mcp
   - Topic: Model Context Protocol, tool integration

6. **SDK Slash Commands**
   - URL: https://docs.claude.com/en/docs/claude-code/sdk/sdk-slash-commands
   - Topic: Programmatic command handling

7. **Claude Code Settings**
   - URL: https://docs.claude.com/en/docs/claude-code/settings
   - Topic: Configuration, allowed-tools

### Community Resources

#### Major GitHub Repositories

1. **Claude-Command-Suite**
   - URL: https://github.com/qdhenry/Claude-Command-Suite
   - Description: 148+ professional slash commands
   - Focus: Structured workflows, multi-agent orchestration

2. **commands (wshobson)**
   - URL: https://github.com/wshobson/commands
   - Description: 57 production-ready commands
   - Focus: Workflows vs tools separation

3. **awesome-claude-code**
   - URL: https://github.com/hesreallyhim/awesome-claude-code
   - Description: Curated collection of commands and resources
   - Focus: Community aggregation

4. **claude-sessions**
   - URL: https://github.com/iannuttall/claude-sessions
   - Description: Session tracking commands
   - Focus: Progress tracking, knowledge transfer

5. **claude-slash-commands**
   - URL: https://github.com/artemgetmann/claude-slash-commands
   - Description: Educational resource
   - Focus: Learning command creation

6. **anthropics/claude-code**
   - URL: https://github.com/anthropics/claude-code
   - Description: Official repository
   - Focus: Examples, issues, changelog

#### Articles and Guides

1. **How I Use Claude Code**
   - URL: https://www.builder.io/blog/claude-code
   - Author: Builder.io
   - Topic: Practical tips, workflows

2. **Cooking with Claude Code**
   - URL: https://www.siddharthbharath.com/claude-code-the-complete-guide/
   - Author: Sid Bharath
   - Topic: Complete guide, best practices

3. **Claude Code Tips & Tricks**
   - URL: https://cloudartisan.com/posts/2025-04-14-claude-code-tips-slash-commands/
   - Topic: Custom slash commands

4. **How to Create Custom Slash Commands**
   - URL: https://en.bioerrorlog.work/entry/claude-code-custom-slash-command
   - Topic: Step-by-step guide

5. **Claude Code Commands Course**
   - URL: https://stevekinney.com/courses/ai-development/claude-code-commands
   - Author: Steve Kinney
   - Topic: Comprehensive course material

6. **ClaudeLog**
   - URL: https://claudelog.com/
   - Topic: Documentation, tutorials, FAQs

### Tool Documentation

1. **Allowed Tools Guide**
   - URL: https://claudelog.com/faqs/what-is-allowed-tools-in-claude-code/
   - Topic: Tool restrictions, security

2. **Hooks Tutorial**
   - URL: https://medium.com/@joe.njenga/use-claude-code-hooks-newest-feature-to-fully-automate-your-workflow-341b9400cfbe
   - Topic: Workflow automation

3. **MCP Configuration**
   - URL: https://scottspence.com/posts/configuring-mcp-tools-in-claude-code
   - Author: Scott Spence
   - Topic: MCP setup best practices

### Performance and Optimization

1. **Ultrathink Deep Dive**
   - URL: https://claudelog.com/faqs/what-is-ultrathink/
   - Topic: Extended thinking modes

2. **Claude Code with Prompt Caching**
   - URL: https://aws.amazon.com/blogs/machine-learning/supercharge-your-development-with-claude-code-and-amazon-bedrock-prompt-caching/
   - Topic: Performance optimization

3. **Best Practices for Performance**
   - URL: https://medium.com/@terrycho/best-practices-for-maximizing-claude-code-performance-f2d049579563
   - Author: Terry Cho
   - Topic: Performance optimization

### Additional Resources

1. **How Anthropic Teams Use Claude Code**
   - URL: https://www.anthropic.com/news/how-anthropic-teams-use-claude-code
   - Topic: Internal practices

2. **Claude Code Cheat Sheet**
   - URL: https://shipyard.build/blog/claude-code-cheat-sheet/
   - Topic: Quick reference

3. **Command Reference**
   - URL: https://developertoolkit.ai/en/appendices/command-reference/
   - Topic: Comprehensive command list

---

## Conclusion

Creating effective custom slash commands in Claude Code requires understanding official documentation, following community best practices, and applying sound design principles. Key takeaways:

### Essential Principles

1. **Simplicity First:** Keep commands focused on single responsibilities
2. **Security Conscious:** Use least-privilege tool restrictions
3. **Team Oriented:** Design for sharing and collaboration
4. **Well Documented:** Clear descriptions and argument hints
5. **Performance Aware:** Optimize for context and token usage

### Getting Started Checklist

- [ ] Create `.claude/commands/` directory in project
- [ ] Define command organization structure
- [ ] Implement high-value commands first
- [ ] Configure `allowed-tools` appropriately
- [ ] Document commands for team
- [ ] Test commands with various inputs
- [ ] Iterate based on usage patterns

### Next Steps

1. Review project-specific needs
2. Study community examples for patterns
3. Start with simple commands
4. Gradually add complexity
5. Share and refine with team
6. Monitor usage and optimize

### Resources for Further Learning

- Official Documentation: https://docs.claude.com/en/docs/claude-code/slash-commands
- Community Examples: https://github.com/hesreallyhim/awesome-claude-code
- Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices

---

**Report Prepared By:** Claude Code Research Agent
**Last Updated:** 2025-09-30
**Version:** 1.0
