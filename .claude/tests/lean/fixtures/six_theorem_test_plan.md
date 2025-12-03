# Test Plan: Six Theorem MCP Rate Limit Coordination

## Metadata
- **Date**: 2025-12-03
- **Feature**: MCP rate limit coordination test with 6 theorems in 2 waves
- **Status**: [NOT STARTED]
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: none
- **Lean File**: /home/benjamin/.config/.claude/tests/lean/fixtures/six_theorem_test.lean

---

## Implementation Phases

### Phase 1: Prove add_comm_test [NOT STARTED]

**Dependencies**: depends_on: []

**Theorem**: add_comm_test
**Location**: six_theorem_test.lean:8
**Goal**: ⊢ a + b = b + a

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

### Phase 2: Prove mul_comm_test [NOT STARTED]

**Dependencies**: depends_on: []

**Theorem**: mul_comm_test
**Location**: six_theorem_test.lean:11
**Goal**: ⊢ a * b = b * a

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

### Phase 3: Prove add_zero_test [NOT STARTED]

**Dependencies**: depends_on: []

**Theorem**: add_zero_test
**Location**: six_theorem_test.lean:14
**Goal**: ⊢ a + 0 = a

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

### Phase 4: Prove add_assoc_test [NOT STARTED]

**Dependencies**: depends_on: [Phase 1, Phase 3]

**Theorem**: add_assoc_test
**Location**: six_theorem_test.lean:19
**Goal**: ⊢ a + (b + c) = (a + b) + c

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

### Phase 5: Prove mul_one_test [NOT STARTED]

**Dependencies**: depends_on: [Phase 2]

**Theorem**: mul_one_test
**Location**: six_theorem_test.lean:22
**Goal**: ⊢ a * 1 = a

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

### Phase 6: Prove zero_mul_test [NOT STARTED]

**Dependencies**: depends_on: [Phase 2]

**Theorem**: zero_mul_test
**Location**: six_theorem_test.lean:25
**Goal**: ⊢ 0 * a = 0

**Tasks**:
- [ ] Extract proof goal with lean_goal
- [ ] Search Mathlib for applicable theorems
- [ ] Generate candidate tactics
- [ ] Test tactics with lean_multi_attempt
- [ ] Apply successful tactic
- [ ] Verify compilation with lean_build

---

## Expected Wave Structure

### Wave 1: Independent Theorems (3 parallel)
- Phase 1: add_comm_test
- Phase 2: mul_comm_test
- Phase 3: add_zero_test

**Expected Budget Allocation**: 3 agents, 1 request each (total: 3 at limit)

### Wave 2: Dependent Theorems (3 parallel)
- Phase 4: add_assoc_test (depends on Phase 1, 3)
- Phase 5: mul_one_test (depends on Phase 2)
- Phase 6: zero_mul_test (depends on Phase 2)

**Expected Budget Allocation**: 3 agents, 1 request each (total: 3 at limit)

---

## Rate Limit Testing Objectives

1. **Budget Allocation Verification**: Each agent in Wave 1 receives budget=1 (3/3 split)
2. **External Search Limit**: Total external search calls ≤ 3 per wave
3. **Local Search Priority**: Agents prioritize lean_local_search before budget consumption
4. **Budget Exhaustion Handling**: Agents fall back to lean_local_search when budget=0
5. **Wave Coordination**: 30-second window resets between waves

---

## Success Criteria

- ✅ All 6 theorems proven successfully
- ✅ Wave 1 completes with total external searches ≤ 3
- ✅ Wave 2 completes with total external searches ≤ 3
- ✅ Budget allocation per agent verified (1 request each in 3-agent waves)
- ✅ lean_local_search prioritization logged and verified
- ✅ No rate limit errors observed
- ✅ Time savings achieved vs sequential execution
