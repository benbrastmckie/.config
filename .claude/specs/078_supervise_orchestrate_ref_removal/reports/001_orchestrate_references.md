# /orchestrate References in /supervise Command

## Summary

Found **4 distinct references** to `/orchestrate` in the `/supervise` command file (`/home/benjamin/.config/.claude/commands/supervise.md`). These references serve documentation and comparison purposes, explaining the relationship between the two commands and their respective use cases.

## Reference Catalog

### 1. Performance Comparison (Line 162)
**Context**: Performance Targets section
**Type**: Speed comparison metric
**Content**: "15-25% faster than /orchestrate for non-implementation workflows"
**Purpose**: Quantify performance advantage for specific workflow types

### 2. Relationship Section Header (Line 166)
**Context**: Section dedicated to command comparison
**Type**: Structural header
**Content**: "### Relationship with /orchestrate"
**Purpose**: Introduce comprehensive comparison section

### 3. Relationship Section Body (Lines 168-184)
**Context**: Multi-paragraph comparison section
**Type**: Feature comparison and use case guidance
**Content**: Detailed breakdown of when to use /supervise vs /orchestrate, including:
- Use case lists for both commands
- Current status statement
- Auto-recovery feature comparison
**Purpose**: Help users choose appropriate command for their workflow

### 4. Performance Targets Comparison (Line 2090)
**Context**: Success Criteria section (near end of file)
**Type**: Speed comparison metric (duplicate)
**Content**: "15-25% faster than /orchestrate for research-and-plan"
**Purpose**: Reiterate performance benefit in success criteria

## Assessment

**Removal Candidates** (references that compare features):
- Line 162: Performance comparison in Performance Targets section
- Lines 166-184: Entire "Relationship with /orchestrate" section
- Line 2090: Performance comparison in Success Criteria section

**Replacement Needs**:
- Performance metrics should be reframed as absolute values or compared against generic baselines
- Use case guidance could be rewritten to focus on /supervise's strengths without explicit /orchestrate comparisons
- Success criteria should stand alone without comparative language

**Total Impact**: Removing these references requires editing 3 distinct sections, affecting approximately 20 lines of documentation content.
