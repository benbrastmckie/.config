# System Testing Guide

**Purpose**: Validate the .opencode/ agent system works end-to-end

**Last Updated**: 2026-02-05 (migrated and updated from testing-guide.md)

---

## Pre-Flight Checks

### 1. Configuration Validation

Verify `opencode.json` schema is valid:

```bash
# Check JSON is valid
node -e "JSON.parse(require('fs').readFileSync('.opencode/opencode.json'))"

# Verify schema URL is accessible
curl -I https://opencode.ai/config.json
```

### 2. Directory Structure

Ensure all required directories exist:

```
.opencode/
├── commands/           # Layer 1: User commands (8+ files)
├── skills/             # Layer 2: Skill wrappers (skill-*/)
├── agents/             # Layer 3: Execution agents (8+ files)
├── context/            # Context knowledge base
│   ├── core/
│   │   ├── orchestration/   # Routing, delegation
│   │   ├── formats/         # Output formats
│   │   ├── standards/     # Quality standards
│   │   └── workflows/       # Process patterns
│   └── project/
│       ├── neovim/        # Neovim domain knowledge
│       └── repo/          # Repository-specific
├── rules/              # Automatic behavior rules
├── docs/               # Documentation (guides/, reference/, examples/)
└── sessions/           # Runtime session storage (created on demand)
```

---

## Workflow Testing

### Test 1: Basic OpenCode Startup

```bash
cd /home/benjamin/Projects/Logos/Website
claude
```

**Expected**: Claude Code starts without errors
**Verify**:

- No schema validation errors in output
- Build agent loads successfully
- Available commands listed in help

### Test 2: Command System

Test each command layer:

**Layer 1 - Commands**:

```
/task Create test task for validation
```

**Expected**: Task created in TODO.md with next available number

**Layer 2 - Skills**:

```
/research {task_number}
```

**Expected**: Skill validates task, delegates to agent

**Layer 3 - Agents**:
Verify agent execution in research output

### Test 3: Context File Loading

Test hierarchical context loading:

```
Load context from .opencode/context/core/orchestration/architecture.md
Load context from .opencode/context/project/repo/project-context.md
```

**Expected**: Files load successfully, content appears in conversation
**Verify**: Context from multiple levels can be loaded simultaneously

### Test 4: Three-Layer Architecture

Verify the complete flow:

```
1. Command receives input
   /research 1

2. Skill validates and prepares
   - skill-{language}-research loads
   - Validates task exists
   - Prepares delegation context

3. Agent executes
   - {language}-research-agent loads
   - Loads relevant context
   - Creates artifacts
   - Returns structured result
```

### Test 5: Language-Based Routing

Test routing for each supported language:

**Neovim**:

```
/task Create neovim test task
task_id = (note the number)
/research {task_id}
```

**Expected**: Routes to skill-neovim-research → neovim-research-agent

**Web**:

```
/task Create web test task
task_id = (note the number)
/research {task_id}
```

**Expected**: Routes to skill-web-research → web-research-agent

**General/Meta**:

```
/task Create meta test task
/set-meta {task_id}
/research {task_id}
```

**Expected**: Routes to skill-researcher → general-research-agent

### Test 6: Full Workflow Integration

End-to-end test:

```
1. Create Task:
   /task "Create test component"
   Note the task number (e.g., 100)

2. Research:
   /research 100
   Verify: Research report created in specs/{NNN}_{slug}/reports/

3. Plan:
   /plan 100
   Verify: Implementation plan created in specs/{NNN}_{slug}/plans/

4. Implement:
   /implement 100
   Verify: Implementation completes, artifacts created

5. Cleanup:
   /todo
   Verify: Completed tasks archived
```

---

## Verification Checklist

### Configuration

- [ ] opencode.json is valid JSON
- [ ] All required directories exist
- [ ] Schema URL is accessible

### Commands (Layer 1)

- [ ] `/task` creates tasks with correct formatting
- [ ] `/research` routes to correct skill
- [ ] `/plan` creates implementation plans
- [ ] `/implement` executes with build verification
- [ ] `/todo` archives completed tasks
- [ ] `/meta` launches meta-builder
- [ ] `/learn` scans for TODO tags
- [ ] `/review` analyzes codebase
- [ ] `/errors` processes error patterns
- [ ] `/revise` modifies plans

### Skills (Layer 2)

- [ ] skill-neovim-research validates neovim tasks
- [ ] skill-web-research validates web tasks
- [ ] skill-researcher handles general/meta tasks
- [ ] skill-planner creates valid plans
- [ ] skill-implementer coordinates implementation
- [ ] Each skill generates proper session IDs
- [ ] Skills pass correct delegation context

### Agents (Layer 3)

- [ ] neovim-research-agent loads neovim context
- [ ] web-research-agent loads web context
- [ ] Agents create artifacts in correct locations
- [ ] Agents return structured JSON results
- [ ] Agent results include status and artifact paths

### Context System

- [ ] Hierarchical loading works (core → project → repo)
- [ ] Context files are under 200 lines
- [ ] Context references resolve correctly
- [ ] Domain-specific context loads appropriately

### State Management

- [ ] state.json updates correctly
- [ ] TODO.md updates correctly
- [ ] Two-phase commit works (json first, markdown second)
- [ ] Status transitions follow workflow rules
- [ ] Dependencies are tracked correctly

### Build Verification

- [ ] Web implementation runs `pnpm check` successfully
- [ ] Web implementation runs `pnpm build` successfully
- [ ] Neovim implementation validates Lua syntax
- [ ] Build failures halt implementation
- [ ] Build success marks phase complete

### Git Integration

- [ ] Commits include session IDs
- [ ] Commit messages follow task format
- [ ] State changes are committed atomically

### Session Management

- [ ] Sessions created in .opencode/sessions/
- [ ] Session IDs are unique and timestamped
- [ ] Session context files are valid markdown
- [ ] Old sessions can be cleaned up

---

## Known Limitations

1. **TODO.md Management**: The system manages TODO.md manually. Status synchronization between TODO.md and state.json requires explicit updates.

2. **Session Persistence**: Sessions are runtime-only and not automatically cleaned up. Use `/refresh` or manual cleanup.

3. **Context Caching**: Currently no automatic cache invalidation. Manual cache refresh may be needed if context files change.

4. **Error Recovery**: If a command fails mid-execution, manual state cleanup may be required.

---

## Troubleshooting

### Issue: Command not recognized

**Symptoms**: `/task` or other commands show "unknown command"

**Solution**:

- Verify command exists in `.opencode/commands/`
- Check command file has valid markdown format
- Ensure command name matches filename (without .md)
- Restart Claude Code

### Issue: Skill not routing correctly

**Symptoms**: Research goes to wrong skill or "no skill found"

**Solution**:

- Check task language in state.json
- Verify skill directory exists: `.opencode/skills/skill-{language}-{action}/`
- Check skill SKILL.md has valid frontmatter
- Verify routing logic in command file

### Issue: Agent not executing

**Symptoms**: Skill runs but no agent output

**Solution**:

- Check agent file exists in `.opencode/agents/`
- Verify agent has required tools enabled
- Check agent description in frontmatter
- Review Task tool permissions in opencode.json

### Issue: Context not loading

**Symptoms**: "File not found" when loading context

**Solution**:

- Verify file path is correct (relative to project root)
- Check file exists and is readable
- Ensure no typos in {file:...} references
- Verify file is under 200 lines (MVI principle)

### Issue: State out of sync

**Symptoms**: TODO.md and state.json show different statuses

**Solution**:

- Manually sync using `/task --sync`
- Check for uncommitted changes
- Review recent commits for partial updates
- May need to manually correct state.json and TODO.md

### Issue: Build verification fails

**Symptoms**: Implementation stops at build step

**Solution**:

- Run `pnpm check` manually to see TypeScript errors
- Run `pnpm build` to see build errors
- Fix errors in generated code
- Re-run `/implement` with same task number

---

## Rollback Plan

If critical issues found during testing:

1. **Document issues**: Note specific failures and error messages
2. **Isolate problem**: Test individual layers (command → skill → agent)
3. **Check recent changes**: Review git history for breaking changes
4. **Verify configuration**: Ensure opencode.json matches schema
5. **Restart fresh**: Clear sessions/, restart Claude Code, retry tests
6. **Escalate**: Document reproducible failures for team review

---

## Success Criteria

✅ All pre-flight checks pass  
✅ All 8+ commands work correctly  
✅ All skills route appropriately  
✅ All agents execute and return results  
✅ Research → Plan → Implement workflow is functional  
✅ State management maintains consistency  
✅ Build verification passes for both web and neovim  
✅ Git commits include proper tracking  
✅ Documentation is complete and accurate  
✅ Team can use system for daily development

---

## Next Steps After Testing

1. **Archive test artifacts**: Clean up test tasks and sessions
2. **Document findings**: Update guides with any discovered issues
3. **Train team**: Share successful workflow patterns
4. **Monitor**: Watch for issues in production use
5. **Iterate**: Improve based on team feedback

---

## References

- [Architecture Overview](../architecture/system-overview.md)
- [User Guide](user-guide.md)
- [Installation Guide](user-installation.md)
- [Implementation Patterns](../reference/implementation-patterns.md)
- [Security and Permissions](../reference/security-permissions.md)

---

**Note**: This guide was migrated from testing-guide.md (2026-02-05) and updated to reflect the current 3-layer architecture (commands/skills/agents).
