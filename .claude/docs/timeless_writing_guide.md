# Timeless Writing Guide for Documentation

This guide provides patterns and examples for maintaining present-focused, timeless documentation that complies with the project's documentation standards (CLAUDE.md "Development Philosophy → Documentation Standards").

## Core Principles

### 1. Present-Focused Writing
Documentation should describe the current state of the system as if it has always existed in this form.

### 2. No Historical Commentary
Avoid references to past states, changes, updates, or migrations in functional documentation.

### 3. Separation of Concerns
- **Functional Documentation**: Describes what the system does (timeless)
- **CHANGELOG.md**: Records when features were added (historical)
- **Migration Guides**: Explains how to upgrade (transitional)

## Banned Patterns

### Temporal Markers
Labels that reference time or change state:

**Banned Labels**:
- (New)
- (Old)
- (Updated)
- (Current)
- (Deprecated)
- (Original)
- (Legacy)
- (Previous)

**Example Violations**:
```markdown
❌ Parallel Execution (New)
❌ Old authentication method (Deprecated)
❌ Configuration options (Updated)
```

**Correct Approach**:
```markdown
✓ Parallel Execution
✓ Authentication method
✓ Configuration options
```

### Temporal Phrases
Words and phrases that anchor content to a point in time:

**Banned Phrases**:
- "previously"
- "recently"
- "now supports"
- "used to"
- "no longer"
- "in the latest version"
- "updated to"
- "changed from"
- "as of this writing"
- "going forward"
- "will eventually"

**Example Violations**:
```markdown
❌ The system now supports async operations.
❌ Previously, we used synchronous calls.
❌ Authentication was recently added to handle security.
❌ The old method used basic auth.
❌ This feature is no longer available.
```

**Correct Approach**:
```markdown
✓ The system supports async operations.
✓ Authentication handles security.
✓ Use OAuth for authentication.
```

### Migration Language
References to transitions between versions or implementations:

**Banned Phrases**:
- "migration from"
- "migrated to"
- "backward compatibility"
- "breaking change"
- "deprecated in favor of"
- "replaces the old"
- "instead of the previous"

**Example Violations**:
```markdown
❌ Migrated to JWT tokens for authentication.
❌ This approach replaces the old session system.
❌ Maintained backward compatibility with v1.0 API.
❌ Breaking change: API now requires tokens.
```

**Correct Approach**:
```markdown
✓ Uses JWT tokens for authentication.
✓ Authentication uses token-based verification.
✓ API requires authentication tokens.
```

### Version References
Mentions of specific versions in feature descriptions:

**Banned Patterns**:
- "v1.0", "version 2.0"
- "since version"
- "as of version"
- "introduced in"

**Example Violations**:
```markdown
❌ Added in v2.0: async support
❌ Since version 1.5, the system uses caching.
❌ As of Claude Code v2.0.1, agents support parallel execution.
```

**Correct Approach**:
```markdown
✓ Supports async operations
✓ The system uses caching for performance.
✓ Agents support parallel execution.
```

## Rewriting Patterns

### Pattern 1: Remove Temporal Context Entirely

**Before**: "Feature X was recently added to support Y"
**After**: "Feature X supports Y"

**Before**: "The system now uses async operations"
**After**: "The system uses async operations"

**Before**: "This method was updated to handle edge cases"
**After**: "This method handles edge cases"

### Pattern 2: Focus on Current Capabilities

**Before**: "Previously, the system used polling. Now it uses webhooks."
**After**: "The system uses webhooks for real-time updates."

**Before**: "Old approach (deprecated): Use basic auth. New approach: Use OAuth."
**After**: "Use OAuth for authentication."

**Before**: "Changed from flat file storage to database"
**After**: "Uses database for data persistence."

### Pattern 3: Convert Comparisons to Descriptions

**Before**: "This replaces the old caching method"
**After**: "Provides in-memory caching for performance"

**Before**: "No longer uses synchronous calls"
**After**: "Uses asynchronous operations for non-blocking execution"

**Before**: "Improved error handling compared to v1.0"
**After**: "Provides comprehensive error handling with detailed messages"

### Pattern 4: Eliminate Version Markers

**Before**: "New in v2.0: parallel execution"
**After**: "Supports parallel execution for independent tasks"

**Before**: "As of version 1.5, supports custom plugins"
**After**: "Supports custom plugins for extensibility"

**Before**: "Introduced in 2025: agent-based architecture"
**After**: "Uses agent-based architecture for specialized tasks"

### Pattern 5: Preserve Technical Accuracy While Removing History

**Before**:
```markdown
The authentication system was migrated from basic auth to OAuth in v2.0.
This provides better security and supports SSO. The old basic auth method
is deprecated but maintained for backward compatibility.
```

**After**:
```markdown
The authentication system uses OAuth for secure access and SSO support.
```

**Analysis**: Technical details preserved (OAuth, SSO), historical migration removed.

## Legitimate Technical Usage

Some words match banned patterns but serve legitimate technical purposes. These should be preserved:

### State Tracking
**Legitimate**: "recently modified files" (file state)
**Legitimate**: "most recently discussed plan" (conversation state)
**Legitimate**: "previously-failed tests" (debug state)

These describe current state attributes, not historical commentary.

### Technical Conditionals
**Legitimate**: "If no longer needed, remove the file" (code logic)
**Legitimate**: "When authentication is no longer valid" (conditional)

These are conditional statements in code, not temporal references.

### API Design
**Legitimate**: "Maintains backward compatibility" (API contract specification)
**Legitimate**: "deprecated/" (directory name for deprecated code)

These describe technical constraints, not documentation of past changes.

### Metrics and Reporting
**Legitimate**: "No Recent Activity" (timestamp-based metric)
**Legitimate**: "Last updated: 2025-10-16" (metadata field)

These are data points, not prose descriptions.

### Passive Voice Purpose
**Legitimate**: "This function is used to parse JSON" (purpose, not temporal "used to")
**Legitimate**: "Configuration is stored in .env files" (current state)

"Used to" as passive voice ("is used to") differs from temporal "used to" (past tense).

## Decision Framework

When encountering potential violations, ask:

### 1. Is it describing current state?
- **Yes**: Likely legitimate
- **No**: Likely violation

### 2. Is it in prose documentation?
- **Yes**: Apply timeless writing standards
- **No** (code, logs, data): May be legitimate technical usage

### 3. Does removing it lose technical information?
- **Yes**: Rewrite to preserve information without temporal reference
- **No**: Remove entirely

### 4. Is it comparing to a past state?
- **Yes**: Violation - rewrite to describe current state only
- **No**: May be legitimate

## Where Historical Information Belongs

### CHANGELOG.md
Version-by-version chronological record:
```markdown
## [2.0.0] - 2025-10-15
### Added
- OAuth authentication support
- Parallel agent execution
- Wave-based task coordination

### Changed
- Migrated from basic auth to OAuth
- Improved error handling with retry logic

### Deprecated
- Basic auth methods (use OAuth instead)

### Removed
- Synchronous-only operation mode
```

### Migration Guides
Separate documents for version upgrades:
```markdown
# Migrating from v1.0 to v2.0

## Authentication Changes
**Old approach** (v1.0):
...

**New approach** (v2.0):
...

## Step-by-step migration:
1. Update authentication configuration
2. Replace basic auth calls with OAuth
3. Test authentication flow
```

### Commit Messages
Git history for code-level changes:
```
feat: add OAuth authentication support

Replaces basic auth with OAuth for improved security.
Maintains backward compatibility with existing sessions.

BREAKING CHANGE: Authentication endpoints now require OAuth tokens
```

## Common Scenarios

### Scenario 1: Documenting a Refactored Feature

**Wrong Approach**:
```markdown
## Authentication (Updated)

The authentication system was refactored in v2.0 to use OAuth instead of
basic auth. This provides better security and SSO support. The old basic
auth method is deprecated.
```

**Correct Approach**:
```markdown
## Authentication

The authentication system uses OAuth for secure access and single sign-on (SSO) support.
```

### Scenario 2: Explaining System Architecture

**Wrong Approach**:
```markdown
## Architecture (Redesigned)

Previously, the system used a monolithic design. We recently migrated to a
microservices architecture for better scalability. The old monolithic approach
is no longer supported.
```

**Correct Approach**:
```markdown
## Architecture

The system uses a microservices architecture for scalability and modularity.
Each service handles a specific domain and communicates via REST APIs.
```

### Scenario 3: Describing Configuration Options

**Wrong Approach**:
```markdown
## Configuration

New in v2.0: The system now supports environment variables for configuration.
Previously, configuration was stored in JSON files (deprecated). Use .env
files going forward.
```

**Correct Approach**:
```markdown
## Configuration

The system uses environment variables for configuration. Create a `.env` file
with the following options:

- `AUTH_METHOD`: Authentication method (oauth, token)
- `API_URL`: Base URL for API endpoints
```

### Scenario 4: Command Documentation

**Wrong Approach**:
```markdown
## /orchestrate Command (New)

Recently added in v2.0, this command coordinates multiple agents through
complex workflows. This replaces the old approach of manually invoking
commands sequentially.
```

**Correct Approach**:
```markdown
## /orchestrate Command

Coordinates multiple specialized agents through end-to-end development workflows.
Automatically manages research, planning, implementation, debugging, and documentation
phases with intelligent parallelization.
```

## Review Process

### Self-Review Checklist

Before submitting documentation:

1. **Scan for banned patterns**:
   ```bash
   grep -E "(New\)|Old\)|Updated\)|Deprecated\)|previously|recently|now supports|used to|no longer)" doc.md
   ```

2. **Verify present focus**: Read each sentence - does it describe current state or past change?

3. **Check for comparisons**: Any phrases comparing to "old" or "previous" approaches?

4. **Validate technical accuracy**: Did removing temporal context lose important technical information?

5. **Ensure natural flow**: Does the documentation read smoothly without temporal references?

### Peer Review Focus

When reviewing others' documentation:

1. **Identify temporal language**: Flag any historical references
2. **Suggest rewrites**: Provide present-focused alternatives
3. **Preserve technical details**: Ensure rewrites maintain accuracy
4. **Check edge cases**: Verify legitimate technical usage isn't over-corrected

## Enforcement Tools

### Grep Validation Script

Create `.claude/scripts/validate_docs_timeless.sh`:

```bash
#!/bin/bash
# Validates documentation for timeless writing policy compliance

VIOLATIONS_FOUND=0

echo "Scanning for temporal markers..."
if grep -r -E "\((New|Old|Updated|Current|Deprecated|Original|Legacy|Previous)\)" \
    .claude/docs/ .claude/templates/ .claude/commands/ 2>/dev/null; then
    echo "❌ Found temporal markers"
    VIOLATIONS_FOUND=1
fi

echo ""
echo "Scanning for temporal phrases..."
if grep -r -E "\b(previously|recently|now supports|used to|no longer|in the latest|updated to|changed from)\b" \
    .claude/docs/ .claude/templates/ .claude/commands/ 2>/dev/null; then
    echo "❌ Found temporal phrases"
    VIOLATIONS_FOUND=1
fi

echo ""
echo "Scanning for migration language..."
if grep -r -E "\b(migration from|migrated to|backward compatibility|breaking change|deprecated in favor)\b" \
    .claude/docs/ .claude/templates/ .claude/commands/ 2>/dev/null; then
    echo "❌ Found migration language"
    VIOLATIONS_FOUND=1
fi

if [ $VIOLATIONS_FOUND -eq 0 ]; then
    echo "✓ All documentation follows timeless writing policy"
    exit 0
else
    echo ""
    echo "❌ Violations found - review and rewrite affected sections"
    exit 1
fi
```

### Pre-Commit Hook Integration

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run timeless writing validation on documentation files

DOC_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|markdown)$')

if [ -n "$DOC_FILES" ]; then
    echo "Validating documentation for timeless writing..."
    if ! .claude/scripts/validate_docs_timeless.sh; then
        echo ""
        echo "Documentation validation failed."
        echo "Please remove temporal references before committing."
        exit 1
    fi
fi
```

## Summary

### Quick Reference

**Write**: Present-focused, current state descriptions
**Avoid**: Past comparisons, version markers, temporal phrases
**Preserve**: Technical accuracy, natural flow, clarity
**Separate**: Historical records belong in CHANGELOG.md, not functional docs

### Key Takeaway

Documentation should answer: "What does the system do?" not "How did the system change?"

---

For complete policy details, see CLAUDE.md "Development Philosophy → Documentation Standards" (lines 276-283).
