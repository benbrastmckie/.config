# Adaptive Learning System

This directory contains workflow pattern data collected from successful and failed implementations to enable continuous improvement through recommendation.

## Overview

The adaptive learning system automatically captures workflow patterns, identifies successful approaches, and provides intelligent recommendations for similar future tasks.

## Data Structure

### Pattern Files (JSONL Format)

**patterns.jsonl** - Successful workflow patterns
```jsonl
{"timestamp":"2025-10-03T23:00:00Z","workflow_type":"feature","feature_keywords":["auth","security","user"],"plan_phases":5,"research_topics":["OAuth patterns","Security best practices"],"implementation_time":3600,"test_success_rate":1.0,"error_count":0,"agent_selection":{"phase_1":"code-writer","phase_2":"test-specialist"},"parallelization_used":true,"outcome":"success","lessons":"Research phase saved time by finding existing patterns"}
```

**antipatterns.jsonl** - Failed or problematic patterns
```jsonl
{"timestamp":"2025-10-03T22:00:00Z","workflow_type":"refactor","feature_keywords":["database","optimization"],"plan_phases":3,"implementation_time":7200,"test_success_rate":0.4,"error_count":12,"outcome":"partial","lessons":"Skipping research led to incompatible approach, required rework"}
```

**optimizations.jsonl** - Performance improvements discovered
```jsonl
{"timestamp":"2025-10-03T21:00:00Z","optimization_type":"parallelization","workflow_type":"feature","time_saved":900,"description":"Parallel backend/frontend phases reduced implementation time by 25%"}
```

### Privacy Filter Configuration

**privacy-filter.yaml** - Sensitive data patterns to exclude
```yaml
filters:
  file_paths:
    - pattern: "/home/[^/]+/"
      replacement: "/home/user/"
    - pattern: "/Users/[^/]+/"
      replacement: "/Users/user/"
  keywords:
    - password
    - secret
    - token
    - key
    - credential
    - api_key
  error_messages:
    - pattern: "in file .*/([^/]+\\.lua)"
      replacement: "in file $1"
```

## Schema Definitions

### Pattern Schema

**Required Fields**:
- `timestamp`: ISO 8601 datetime of workflow completion
- `workflow_type`: One of: feature, refactor, debug, investigation
- `feature_keywords`: Array of 3-10 descriptive keywords
- `outcome`: success, partial, or failed

**Performance Fields**:
- `plan_phases`: Number of implementation phases
- `implementation_time`: Total time in seconds
- `test_success_rate`: 0.0 to 1.0
- `error_count`: Number of errors encountered

**Strategy Fields**:
- `research_topics`: Array of research topics used (if any)
- `agent_selection`: Map of phase number to agent type
- `parallelization_used`: Boolean

**Learning Field**:
- `lessons`: Free-form string (max 200 chars) of key insights

### Antipattern Schema

Same as Pattern schema, but with `outcome` of "partial" or "failed".

### Optimization Schema

**Fields**:
- `timestamp`: ISO 8601 datetime
- `optimization_type`: parallelization, agent_selection, research, etc.
- `workflow_type`: feature, refactor, debug, investigation
- `time_saved`: Seconds saved by optimization
- `description`: Brief explanation of optimization

## Data Collection

### Automatic Collection

Learning data is collected automatically at workflow completion by:
- `/orchestrate` command (full workflow patterns)
- `/implement` command (implementation-specific patterns)
- Agent completion hooks (agent performance data)

### Manual Collection

Disable automatic collection:
```bash
export CLAUDE_LEARNING_DISABLED=1
```

Enable selective collection:
```bash
export CLAUDE_LEARNING_OPT_IN=1  # Must confirm before collecting
```

## Privacy Controls

### Data Minimization

Only essential workflow metadata is collected:
- ✓ Workflow type, phase count, time duration
- ✓ Generic feature keywords (e.g., "auth", "database")
- ✓ Success/failure outcomes
- ✗ File contents, variable names, user data
- ✗ Full file paths (anonymized to filename only)
- ✗ Error messages with sensitive data

### Privacy Filters

All data passes through privacy filters before storage:
1. **Path Anonymization**: Remove usernames from file paths
2. **Keyword Filtering**: Remove sensitive keywords (password, key, token)
3. **Error Sanitization**: Strip file paths from error messages
4. **Manual Review**: User can review before data is stored (opt-in mode)

### Opt-Out Mechanism

Completely disable learning:
```bash
echo "export CLAUDE_LEARNING_DISABLED=1" >> ~/.bashrc
```

Or create opt-out file:
```bash
touch .claude/learning/.opt-out
```

### Data Retention

**Default Policy**: 6 months
- Patterns older than 6 months are automatically deleted
- Configurable via `.claude/learning/retention-policy.txt`

**Manual Cleanup**:
```bash
# Delete all learning data
rm .claude/learning/patterns.jsonl
rm .claude/learning/antipatterns.jsonl
rm .claude/learning/optimizations.jsonl
```

## Similarity Matching

### Algorithm

Patterns are matched using multi-factor similarity scoring:

**Keyword Similarity** (Jaccard Index):
```
similarity = |keywords_A ∩ keywords_B| / |keywords_A ∪ keywords_B|
```

**Workflow Type Match** (Exact):
```
match = workflow_type_A == workflow_type_B
```

**Phase Count Similarity** (Tolerance ±2):
```
match = |phases_A - phases_B| <= 2
```

**Combined Score**:
```
score = (keyword_similarity × 0.6) + (type_match × 0.3) + (phase_match × 0.1)
```

**Recommendation Threshold**: 70% (0.7)

### Example Matching

Current Workflow:
- Keywords: ["user", "authentication", "session"]
- Type: feature
- Phases: 4

Past Pattern:
- Keywords: ["auth", "security", "user", "login"]
- Type: feature
- Phases: 5

Similarity Calculation:
- Keyword overlap: {user} = 1/6 = 0.167
- Type match: feature == feature = 1.0
- Phase match: |4 - 5| = 1 <= 2 = 1.0
- Combined: (0.167 × 0.6) + (1.0 × 0.3) + (1.0 × 0.1) = 0.50

Result: 50% similarity (below 70% threshold, no recommendation)

## Recommendation Engine

### When Recommendations Appear

Recommendations are shown:
1. **At Workflow Start** (/orchestrate, /plan)
   - "Based on 3 similar workflows..."
   - Suggests research topics, phase structure, time estimate
2. **During Planning** (/plan-wizard)
   - "Similar features used these components..."
   - Helps identify modules and dependencies
3. **Before Implementation** (/implement)
   - "Workflows like this succeeded with..."
   - Suggests agent selections, parallelization opportunities

### Recommendation Format

```
📊 Learning Recommendation (based on 3 similar workflows)

Similarity: 85% match to previous auth/security features

Research Topics:
- OAuth patterns (used in 3/3 workflows, avg 15min)
- Security best practices (used in 2/3 workflows, avg 10min)

Plan Structure:
- Recommended phases: 5 (database → backend → frontend → testing → docs)
- Successful pattern: Implement auth backend before frontend
- Parallelization opportunity: Backend + frontend can overlap after phase 2

Time Estimate:
- Similar workflows: 3-4 hours average
- Your complexity: Medium (est. 3.5 hours)

Agent Selection:
- code-writer for phases 1-3 (100% success rate)
- test-specialist for phase 4 (recommended)

Apply these recommendations? [y/n]
```

### Applying Recommendations

**Automatic Application** (with confirmation):
- Pre-populate /plan with suggested structure
- Pre-select agents for /implement
- Enable parallelization flags

**Manual Application**:
- User reviews and applies selectively
- Can override any recommendations
- Recommendations are suggestions, not requirements

## Data Export and Deletion

### Export Learning Data

```bash
# Export all data
.claude/utils/export-learning-data.sh

# Creates: learning-data-export-YYYY-MM-DD.tar.gz
# Contains: patterns.jsonl, antipatterns.jsonl, optimizations.jsonl
```

### Delete Learning Data

```bash
# Delete all data
.claude/utils/delete-learning-data.sh

# Confirmation required
# Irreversible operation
```

## Performance Characteristics

- **Data Collection**: <100ms per workflow
- **Pattern Matching**: <1 second for 1000 patterns
- **Recommendation Generation**: <2 seconds
- **Storage**: ~1KB per pattern (1000 patterns = 1MB)


## References

- [Adaptive Learning Guide](../docs/adaptive-learning-guide.md)
- [Privacy Guide](../docs/privacy-guide.md)
- [Pattern Analysis Command](/commands/analyze-patterns.md)
- [Learning Data Collection](../utils/collect-learning-data.sh)
