# Phase 7 Remaining Tasks

## Completed Infrastructure (2025-10-17)

### ✅ Checkpoint Schema v1.3
- Updated `CHECKPOINT_SCHEMA_VERSION` to "1.3" in checkpoint-utils.sh
- Added 6 new field groups to save_checkpoint():
  - `topic_directory`, `topic_number`
  - `context_preservation` (pruning_log, artifact_metadata_cache, subagent_output_references)
  - `template_source`, `template_variables`
  - `spec_maintenance` (parent_plan_path, spec_updater_invocations, checkbox_propagation_log)

### ✅ Migration Support
- Updated `migrate_checkpoint_format()` with v1.2 → v1.3 migration case
- Created standalone migration script: `.claude/lib/migrate-checkpoint-v1.3.sh`
- Migration script supports `--dry-run` for safe preview
- Automatic backup creation before migration

### ✅ Unified Documentation
- Created comprehensive `checkpoint_template_guide.md` (600+ lines)
- 7 sections: Overview, Checkpoint System, Template System, Integration Workflows, Best Practices, Troubleshooting, API Reference
- Consolidates 22 scattered checkpoint/template references
- Cross-references to related documentation

## Remaining Integration Work

### 1. Template-Checkpoint Integration in /plan-from-template

**File**: `.claude/commands/plan-from-template.md`

**Changes Needed**:
```bash
# After plan generation, create initial checkpoint
workflow_state=$(jq -n \
  --arg plan_path "$generated_plan_path" \
  --arg template "$template_name" \
  --argjson vars "$template_variables_json" \
  --arg topic_dir "$topic_directory" \
  --arg topic_num "$topic_number" \
  '{
    workflow_description: "Plan generated from template",
    status: "planning_complete",
    plan_path: $plan_path,
    template_source: $template,
    template_variables: $vars,
    topic_directory: $topic_dir,
    topic_number: ($topic_num | tonumber)
  }')

checkpoint_path=$(save_checkpoint "plan_generated" "${topic_number}_${feature_name}" "$workflow_state")

echo ""
echo "Checkpoint created: $checkpoint_path"
echo "Run /implement $generated_plan_path to begin implementation."
```

**Integration Points**:
- After successful plan generation
- Before displaying success message
- Populate template_source, template_variables, topic_directory, topic_number

### 2. Update /implement to Populate v1.3 Fields

**File**: `.claude/commands/implement.md`

**Changes Needed**:
```bash
# Extract topic info from plan path
topic_dir=$(dirname $(dirname "$plan_path"))  # specs/042_auth/plans/001.md → specs/042_auth
topic_num=$(basename "$topic_dir" | grep -oE '^[0-9]+')

# Check if plan was template-generated
template_source=$(checkpoint_get_field "$checkpoint_file" ".template_source" 2>/dev/null || echo "null")
template_vars=$(checkpoint_get_field "$checkpoint_file" ".template_variables" 2>/dev/null || echo "null")

# Build workflow state with v1.3 fields
workflow_state=$(jq -n \
  --arg plan "$plan_path" \
  --arg phase "$current_phase" \
  --arg topic_dir "$topic_dir" \
  --arg topic_num "$topic_num" \
  --arg template "$template_source" \
  --argjson template_vars "${template_vars:-null}" \
  '{
    plan_path: $plan,
    current_phase: ($phase | tonumber),
    status: "in_progress",
    topic_directory: $topic_dir,
    topic_number: (if $topic_num != "" then ($topic_num | tonumber) else null end),
    template_source: (if $template != "null" then $template else null end),
    template_variables: $template_vars,
    spec_maintenance: {
      parent_plan_path: null,  # Detect from plan hierarchy
      spec_updater_invocations: [],
      checkbox_propagation_log: []
    }
  }')

# On spec-updater invocation
spec_maintenance_update=$(jq -n \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg phase "$current_phase" \
  '{
    timestamp: $timestamp,
    phase: ($phase | tonumber),
    operation: "checkbox_propagation"
  }')

checkpoint_set_field "$checkpoint_file" \
  ".spec_maintenance.spec_updater_invocations" \
  "$(jq '.spec_maintenance.spec_updater_invocations += [$update]' --argjson update "$spec_maintenance_update" "$checkpoint_file")"
```

**Integration Points**:
- During checkpoint creation/restore
- When invoking spec-updater agent
- When propagating checkbox updates
- On parent/grandparent plan detection

### 3. Update /orchestrate to Populate Context Preservation Fields

**File**: `.claude/commands/orchestrate.md`

**Changes Needed**:
```bash
# After metadata extraction
metadata_cache_entry=$(jq -n \
  --arg artifact_path "$report_path" \
  --arg title "$report_title" \
  --arg summary "$report_summary" \
  '{
    ($artifact_path): {
      title: $title,
      summary: $summary,
      extracted_at: (now | todate)
    }
  }')

checkpoint_set_field "$checkpoint_file" \
  ".context_preservation.artifact_metadata_cache" \
  "$(jq ".context_preservation.artifact_metadata_cache += $cache" --argjson cache "$metadata_cache_entry" "$checkpoint_file")"

# After subagent completion
subagent_ref=$(jq -n \
  --arg agent_type "$agent_type" \
  --arg output_path "$agent_output_path" \
  '{
    agent_type: $agent_type,
    output_reference: $output_path,
    completed_at: (now | todate)
  }')

checkpoint_set_field "$checkpoint_file" \
  ".context_preservation.subagent_output_references" \
  "$(jq '.context_preservation.subagent_output_references += [$ref]' --argjson ref "$subagent_ref" "$checkpoint_file")"

# After context pruning
pruning_log_entry=$(jq -n \
  --arg phase "$current_phase" \
  --arg policy "$pruning_policy" \
  --arg tokens_before "$context_before" \
  --arg tokens_after "$context_after" \
  '{
    phase: ($phase | tonumber),
    policy: $policy,
    tokens_before: ($tokens_before | tonumber),
    tokens_after: ($tokens_after | tonumber),
    reduction_pct: ((($tokens_before | tonumber) - ($tokens_after | tonumber)) / ($tokens_before | tonumber) * 100 | floor),
    timestamp: (now | todate)
  }')

checkpoint_set_field "$checkpoint_file" \
  ".context_preservation.pruning_log" \
  "$(jq '.context_preservation.pruning_log += [$entry]' --argjson entry "$pruning_log_entry" "$checkpoint_file")"
```

**Integration Points**:
- After `extract_report_metadata()` or `extract_plan_metadata()` calls
- After subagent completion
- After `apply_pruning_policy()` calls

### 4. Add Cross-References to Existing Docs

#### directory-protocols.md
```markdown
## Checkpoint Integration

When creating artifacts in topic directories, commands can create checkpoints to track progress:

- Checkpoints store `topic_directory` and `topic_number` for context
- Enables auto-resume of interrupted workflows
- See [Checkpoint-Template System Guide](checkpoint_template_guide.md) for details
```

#### development-workflow.md
```markdown
## Workflow State Management

The development workflow supports checkpoint-based state management:

1. **Research** → Report created
2. **Plan** → Plan created, checkpoint initialized
3. **Implement** → Checkpoint tracks progress
4. **Test** → Test results recorded in checkpoint
5. **Commit** → Checkpoint marked complete

See [Checkpoint-Template System Guide](checkpoint_template_guide.md#integration-workflows) for end-to-end workflow details.
```

#### README.md (in .claude/docs/)
```markdown
### Checkpoint-Template System

Seamless workflow state management and plan generation:

- **Checkpoints**: Auto-resume interrupted workflows, track progress, recover from errors
- **Templates**: Generate plans 60-80% faster with 50+ templates across 11 categories
- **Integration**: Template → Plan → Checkpoint → Implement → Resume workflow

See [Checkpoint-Template System Guide](checkpoint_template_guide.md) for comprehensive documentation.
```

#### templates/README.md
```markdown
## Template-Checkpoint Integration

Templates now create initial checkpoints automatically:

- `/plan-from-template` creates checkpoint with template context
- Template source and variables preserved for intelligent defaults
- `/implement` uses template context for smarter execution

See [Checkpoint-Template System Guide](../docs/checkpoint_template_guide.md#template-checkpoint-integration) for details.
```

### 5. Testing

**Test Coverage Needed**:

```bash
# Test 1: Schema v1.3 validation
echo "=== Test 1: Schema Validation ==="
grep -n "CHECKPOINT_SCHEMA_VERSION.*1.3" .claude/lib/checkpoint-utils.sh
grep -n "topic_directory\|context_preservation\|template_source\|spec_maintenance" .claude/lib/checkpoint-utils.sh

# Test 2: Migration script
echo "=== Test 2: Migration Script ==="
test -f .claude/lib/migrate-checkpoint-v1.3.sh && echo "✓ Migration script exists"
test -x .claude/lib/migrate-checkpoint-v1.3.sh && echo "✓ Migration script executable"

# Test 3: Unified guide
echo "=== Test 3: Unified Guide ==="
test -f .claude/docs/checkpoint_template_guide.md && echo "✓ Unified guide exists"
grep -c "^## " .claude/docs/checkpoint_template_guide.md  # Should be 7 main sections
grep -c "^### " .claude/docs/checkpoint_template_guide.md  # Should be 50+ subsections

# Test 4: Migration dry-run (requires test checkpoint)
# Create test v1.2 checkpoint first, then:
# .claude/lib/migrate-checkpoint-v1.3.sh test_checkpoint.json --dry-run

# Test 5: Cross-references
echo "=== Test 5: Cross-References ==="
grep -r "checkpoint_template_guide.md" .claude/docs/*.md | wc -l
# Expected: 0 currently (cross-references not yet added)
```

### 6. Plan Updates

Mark Phase 7 tasks with partial completion:

```markdown
### Phase 7: Checkpoint-Template System Integration (NEW from Report 052) [PARTIAL COMPLETION]

**Completed**:
- [x] Upgrade checkpoint schema to v1.3
- [x] Create checkpoint migration script v1.2 → v1.3
- [x] Update migrate_checkpoint_format() in checkpoint-utils.sh
- [x] Create unified checkpoint_template_guide.md

**Remaining** (deferred to separate implementation):
- [ ] Implement template-checkpoint integration in plan-from-template
- [ ] Update commands to populate checkpoint v1.3 fields
- [ ] Add checkpoint-template integration references to existing docs

**Status**: Core infrastructure complete, command integration deferred
**Commit**: <commit-hash> (infrastructure only)
```

## Implementation Priority

**Immediate** (completed):
1. Schema v1.3 upgrade ✅
2. Migration support ✅
3. Unified documentation ✅

**High Priority** (next session):
1. /plan-from-template checkpoint creation
2. /implement v1.3 field population
3. Cross-reference documentation updates

**Medium Priority** (after command integration):
1. /orchestrate context preservation tracking
2. Testing and validation
3. Plan completion markers

## Rationale for Partial Completion

**Why Infrastructure First:**
- Schema changes are foundational for all other work
- Migration enables existing checkpoints to be upgraded
- Documentation consolidation provides implementation guidance
- Backward compatible (commands work without v1.3 field population)

**Why Defer Command Integration:**
- Command files are complex (100-500 lines each)
- Requires careful integration to avoid breaking existing workflows
- Need thorough testing of checkpoint creation/population logic
- Better done in focused session with dedicated testing

**Benefit of Approach:**
- v1.3 schema available immediately for new checkpoints
- Existing checkpoints can be migrated on-demand
- Documentation ready for command implementers
- No breaking changes to existing workflows
