# Implementation Patterns Reference

**Purpose**: Design patterns, workflows, and best practices for agent system implementation

**Last Updated**: 2026-02-05 (extracted from design.md analysis)

---

## Core Philosophy

The system follows a **human-guided, plan-first approach** with these principles:

| Principle              | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| **Pattern Control**    | Define coding patterns once, AI uses them consistently |
| **Approval Gates**     | Review and approve before execution                    |
| **Repeatable Results** | Same patterns = same quality code                      |
| **Editable Agents**    | Full control via markdown (no vendor lock-in)          |
| **Token Efficiency**   | MVI principle: only load what's needed                 |

---

## Code Quality Standards

### Critical Patterns (Always Use)

- ✅ **Pure functions** - Same input = same output, no side effects
- ✅ **Immutability** - Create new data, don't modify existing
- ✅ **Composition** - Build complex from simple components
- ✅ **Small functions** - Under 50 lines per function
- ✅ **Explicit dependencies** - Dependency injection pattern

### Anti-Patterns (Always Avoid)

- ❌ Mutation and side effects
- ❌ Deep nesting (> 3 levels)
- ❌ God modules (too many responsibilities)
- ❌ Global state
- ❌ Large functions (> 50 lines)

**Golden Rule**: If you can't easily test it, refactor it.

### Error Handling Pattern

```typescript
// ✅ Explicit error handling with result types
function parseJSON(text: string): Result<JSONData, string> {
  try {
    return { success: true, data: JSON.parse(text) };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// ✅ Validate at boundaries
function createUser(userData: UserInput): Result<User, ValidationError[]> {
  const validation = validateUserData(userData);
  if (!validation.isValid) {
    return { success: false, errors: validation.errors };
  }
  return { success: true, user: saveUser(userData) };
}
```

### Dependency Injection

```typescript
// ✅ Dependencies explicit and injected
function createUserService(database: Database, logger: Logger) {
  return {
    createUser: (userData: UserInput) => {
      logger.info("Creating user");
      return database.insert("users", userData);
    },
  };
}

// ❌ Hidden dependencies via imports
import db from "./database.js";
function createUser(userData: UserInput) {
  return db.insert("users", userData); // Hidden dependency
}
```

---

## Naming Conventions

| Type           | Format                | Example                    |
| -------------- | --------------------- | -------------------------- |
| **Files**      | lowercase-with-dashes | `user-service.ts`          |
| **Functions**  | verbPhrases           | `getUser`, `validateEmail` |
| **Predicates** | is/has/can prefixes   | `isValid`, `hasPermission` |
| **Variables**  | descriptive camelCase | `userCount` (not `uc`)     |
| **Constants**  | UPPER_SNAKE_CASE      | `MAX_RETRIES`              |
| **Types**      | PascalCase            | `UserProfile`              |

---

## Context File Guidelines

### MVI Principle (Minimal Viable Information)

Keep files concise for quick loading and lower token usage:

| File Type    | Max Lines  | Read Time   |
| ------------ | ---------- | ----------- |
| **Concepts** | <100 lines | ~30 seconds |
| **Guides**   | <150 lines | ~45 seconds |
| **Examples** | <80 lines  | ~20 seconds |

### Context Hierarchy (Priority Order)

Later context overrides earlier (cascading inheritance):

1. **Core Standards** - Universal patterns
2. **Workflows** - Process definitions
3. **Domain-Specific** - Language/framework patterns
4. **Project-Specific** - Team patterns (highest priority)

---

## Workflow Patterns

### 4-Stage Design Iteration

For UI/UX design work with approval gates:

```
Stage 0: CREATE PLAN (MANDATORY)
         ↓ Create design document
Stage 1: LAYOUT DESIGN
         ↓ ASCII wireframe → User approval
Stage 2: THEME DESIGN
         ↓ Colors, typography, spacing → User approval
Stage 3: ANIMATION DESIGN
         ↓ Micro-interactions, timing → User approval
Stage 4: IMPLEMENTATION
         ↓ Code implementation → User review
```

### Task Delegation Workflow

```
Stage 1: DISCOVER
         ↓ Find relevant context files (read-only)

Stage 2: PROPOSE
         ↓ Show user lightweight summary (no files written)

Stage 3: APPROVE
         ↓ Wait for explicit user approval

Stage 4: INIT SESSION
         ↓ Create session directory with context.md
         ↓ Persist discovered paths

Stage 5: DELEGATE
         ↓ Pass session to working agents

Stage 6: CLEANUP
         ↓ Archive or delete session directory
```

**Critical Principle**: Never write files before user approval.

---

## Session-Based Context Management

### Session File Structure

```
.opencode/sessions/{YYYY-MM-DD}-{task-slug}/
├── context.md           # Main session context
├── .cache/              # Cached context files
│   ├── code-quality.md
│   └── patterns.md
└── .manifest.json       # Cache status tracking
```

### Context File Format

```markdown
# Task Context: {Task Name}

Session ID: {YYYY-MM-DD}-{task-slug}
Created: {ISO timestamp}
Status: in_progress

## Current Request

{What user asked for}

## Context Files (Standards to Follow)

- .opencode/context/core/standards/code-quality.md
- {other paths discovered}

## Reference Files (Source Material)

- {project files to reference}

## External Context Fetched

- .tmp/external-context/{package}/{topic}.md — {description}

## Components

- {Component 1} — {what it does}

## Constraints

{Technical constraints}

## Exit Criteria

- [ ] {measurable completion condition}

## Progress

- [ ] Session initialized
- [ ] Tasks created
- [ ] Implementation complete
```

### Cache Invalidation Rules

- **INVALID**: Source file modified, session >24 hours old
- **VALID**: Timestamps match, session <24 hours old

---

## Subagent Invocation Pattern

```typescript
// Standard subagent task invocation
task({
  subagent_type: "TaskManager",
  description: "Break down feature implementation",
  prompt: `
    Load context from .opencode/sessions/{session-id}/context.md

    Task: Implement {feature description}

    Steps:
    1. Read context.md for standards and constraints
    2. Break into atomic subtasks (< 60 min each)
    3. Create task JSON files
    4. Return task list for orchestration
  `,
});
```

---

## Semantic Task Structure

### Task JSON Fields

| Field              | Contains             | Example                                            |
| ------------------ | -------------------- | -------------------------------------------------- |
| `context_files`    | Standards only       | `.opencode/context/core/standards/code-quality.md` |
| `reference_files`  | Source material      | `src/auth/existing-service.ts`                     |
| `external_context` | Cached external docs | `.tmp/external-context/drizzle-orm/patterns.md`    |

**Never mix them** - downstream agents expect clear separation.

---

## Anti-Patterns to Avoid

- ❌ **Writing files before approval** - Always get explicit approval first
- ❌ **Loading full codebase** - Token waste, use targeted context
- ❌ **Auto-execution** - Human review required for quality
- ❌ **Mixing context types** - Keep standards vs source separate
- ❌ **Large monolithic files** - Break into focused modules
- ❌ **Hidden dependencies** - Always use explicit injection
- ❌ **Deep nesting** - Flatten control flow when possible

---

## Success Metrics

| Metric                 | Target          | Measurement                     |
| ---------------------- | --------------- | ------------------------------- |
| **Token Efficiency**   | 80% reduction   | Compare to full-context loading |
| **First-Pass Quality** | >80%            | Minimal refactoring required    |
| **Approval Time**      | <5 min per gate | Time to review and approve      |
| **Context Hit Rate**   | >60%            | Cache effectiveness             |
| **Session Cleanup**    | 100%            | All sessions cleaned after use  |

---

## References

- [Security and Permissions Reference](./security-permissions.md)
- [Multi-Task Creation Standard](./standards/multi-task-creation-standard.md)
- [Context Loading Best Practices](../guides/context-loading-best-practices.md)
- [Code Quality Standards](../../context/core/standards/code-quality.md)

---

**Note**: These patterns were extracted from design.md (2026-02-05), an analysis of OpenAgents Control framework patterns that informed this system's architecture.
