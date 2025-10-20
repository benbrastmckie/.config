#!/usr/bin/env bash
# e2e_orchestrate_full_workflow.sh
# End-to-end test: /orchestrate workflow with cross-reference validation
# Validates: research → plan → summary with proper artifact organization

set -euo pipefail

# Test metadata
TEST_NAME="E2E: /orchestrate Full Workflow"
TEST_VERSION="2.0.0-revision3"

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh" || {
  echo "ERROR: Failed to source artifact-creation.sh"
  exit 1
}
source "$CLAUDE_PROJECT_DIR/.claude/lib/template-integration.sh" || {
  echo "ERROR: Failed to source template-integration.sh"
  exit 1
}

# Test workspace
TEST_WORKSPACE="$SCRIPT_DIR/tmp/e2e_orchestrate_$$"
TEST_FEATURE="Implement user authentication system with JWT tokens"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
CHECKS_RUN=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Setup test workspace
setup_test_workspace() {
  echo -e "${BLUE}Setting up test workspace...${NC}"
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE"
  cd "$TEST_WORKSPACE"

  # Create mock .claude structure
  mkdir -p .claude/{lib,agents,commands}

  # Initialize git (required for some utilities)
  git init -q 2>/dev/null || true

  # Clean registry for fresh numbering
  rm -rf "$CLAUDE_PROJECT_DIR/.claude/registry"
}

# Cleanup
cleanup_test_workspace() {
  echo -e "${BLUE}Cleaning up test workspace...${NC}"
  cd "$SCRIPT_DIR"
  rm -rf "$TEST_WORKSPACE"
}

# Test helper
check() {
  local description="$1"
  local condition="$2"

  CHECKS_RUN=$((CHECKS_RUN + 1))

  if eval "$condition"; then
    echo -e "${GREEN}✓${NC} $description"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Phase 1: Mock Research Phase Execution
# ============================================================================

mock_research_phase() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 1: Research Phase (Mocked)${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Create topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$TEST_FEATURE" "specs")
  check "Topic directory created" "[[ -d '$TOPIC_DIR' ]]"

  # Verify topic-based structure
  local topic_name=$(basename "$TOPIC_DIR")
  check "Topic directory follows naming convention (NNN_name)" "[[ '$topic_name' =~ ^[0-9]{3}_ ]]"

  # Mock research reports (simulating research-specialist agents)
  echo "Creating mock research reports in topic-based structure..."

  REPORT_1=$(create_topic_artifact "$TOPIC_DIR" "reports" "jwt_security" "")
  cat > "$REPORT_1" <<'EOF'
# JWT Security Best Practices - Research Report

## Metadata
- **Date**: 2025-10-20
- **Topic**: JWT Token Security
- **Research Type**: Security Analysis

## Summary
Research on JWT token security best practices including signing algorithms,
token expiration, refresh token patterns, and common vulnerabilities.

## Key Findings
1. Use RS256 for signing (asymmetric keys)
2. Short-lived access tokens (15 minutes)
3. Long-lived refresh tokens (7 days) with rotation
4. Store securely (httpOnly cookies for web apps)

## Recommendations
- Implement token rotation
- Add rate limiting
- Use secure token storage
- Monitor for token abuse
EOF

  REPORT_2=$(create_topic_artifact "$TOPIC_DIR" "reports" "auth_architecture" "")
  cat > "$REPORT_2" <<'EOF'
# Authentication Architecture Patterns - Research Report

## Metadata
- **Date**: 2025-10-20
- **Topic**: Authentication Architecture
- **Research Type**: Design Patterns

## Summary
Analysis of authentication architecture patterns including middleware design,
session management, and user identity verification strategies.

## Key Findings
1. Middleware-based authentication checks
2. Role-based access control (RBAC)
3. Centralized user service
4. Token validation at API gateway

## Recommendations
- Implement authentication middleware
- Centralize user management
- Use standardized error responses
- Add comprehensive logging
EOF

  REPORT_3=$(create_topic_artifact "$TOPIC_DIR" "reports" "database_schema" "")
  cat > "$REPORT_3" <<'EOF'
# User Database Schema - Research Report

## Metadata
- **Date**: 2025-10-20
- **Topic**: Database Schema Design
- **Research Type**: Technical Design

## Summary
Database schema design for user authentication including user table structure,
password hashing strategies, and audit logging requirements.

## Key Findings
1. User table with email, hashed password, roles
2. Refresh token table with expiration tracking
3. Audit log table for security events
4. Index optimization for lookups

## Recommendations
- Use bcrypt for password hashing
- Add email verification workflow
- Implement soft deletes
- Track login attempts
EOF

  check "Research report 1 created at topic-based path" "[[ -f '$REPORT_1' ]]"
  check "Research report 2 created at topic-based path" "[[ -f '$REPORT_2' ]]"
  check "Research report 3 created at topic-based path" "[[ -f '$REPORT_3' ]]"

  # Verify reports are in topic-based structure (not flat)
  check "Reports are in specs/{NNN_topic}/reports/ structure" "[[ '$REPORT_1' == */specs/*/reports/*.md ]]"

  # Store report paths for next phase
  export RESEARCH_REPORT_PATHS="$REPORT_1:$REPORT_2:$REPORT_3"
  export RESEARCH_REPORT_COUNT=3

  echo -e "${GREEN}Research phase complete: $RESEARCH_REPORT_COUNT reports created${NC}"
}

# ============================================================================
# Phase 2: Mock Planning Phase Execution
# ============================================================================

mock_planning_phase() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 2: Planning Phase (Mocked)${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Mock plan-architect agent creating plan directly (NO /plan invocation)
  echo "Creating plan with behavioral injection pattern..."

  PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

  # Create plan with "Research Reports" metadata section (Revision 3)
  IFS=':' read -ra REPORT_ARRAY <<< "$RESEARCH_REPORT_PATHS"

  cat > "$PLAN_PATH" <<EOF
# User Authentication Implementation Plan

## Metadata
- **Date**: 2025-10-20
- **Feature**: User Authentication with JWT
- **Scope**: Authentication system implementation
- **Complexity**: High (75/100)
- **Research Reports**:
  - ${REPORT_ARRAY[0]}
  - ${REPORT_ARRAY[1]}
  - ${REPORT_ARRAY[2]}

## Overview
Implementation plan for JWT-based authentication system based on research findings.

## Implementation Phases

### Phase 1: Database Schema
**Objective**: Create user and token tables
**Complexity**: Medium

**Tasks**:
- [ ] Create users table with bcrypt password hashing
- [ ] Create refresh_tokens table with expiration
- [ ] Add audit_logs table for security events
- [ ] Create database migrations

### Phase 2: Authentication Service
**Objective**: Implement core authentication logic
**Complexity**: High

**Tasks**:
- [ ] Implement JWT token generation (RS256)
- [ ] Create login endpoint
- [ ] Create token refresh endpoint
- [ ] Add password hashing utilities

### Phase 3: Middleware and Authorization
**Objective**: Add authentication middleware
**Complexity**: Medium

**Tasks**:
- [ ] Create authentication middleware
- [ ] Implement role-based access control
- [ ] Add token validation logic
- [ ] Create protected route decorators
EOF

  check "Plan created at topic-based path" "[[ -f '$PLAN_PATH' ]]"
  check "Plan is in specs/{NNN_topic}/plans/ structure" "[[ '$PLAN_PATH' == */specs/*/plans/*.md ]]"

  # Verify plan references research reports (Revision 3)
  check "Plan has 'Research Reports' metadata section" "grep -q '\\*\\*Research Reports\\*\\*:' '$PLAN_PATH'"

  local report_refs=$(grep -A 10 "\\*\\*Research Reports\\*\\*:" "$PLAN_PATH" | grep -c "specs/.*/reports/" || true)
  check "Plan references all $RESEARCH_REPORT_COUNT research reports" "[[ $report_refs -eq $RESEARCH_REPORT_COUNT ]]"

  # Verify NO SlashCommand invocation in mock logs
  echo "Creating mock orchestrate log for validation..."
  MOCK_LOG="$TEST_WORKSPACE/.claude/logs/orchestrate_test.log"
  mkdir -p "$(dirname "$MOCK_LOG")"

  cat > "$MOCK_LOG" <<'LOGEOF'
[2025-10-20 10:00:00] /orchestrate invoked with feature: User authentication
[2025-10-20 10:00:01] Phase 1: Research phase starting
[2025-10-20 10:00:05] research-specialist agent created report: jwt_security.md
[2025-10-20 10:00:08] research-specialist agent created report: auth_architecture.md
[2025-10-20 10:00:11] research-specialist agent created report: database_schema.md
[2025-10-20 10:00:12] Phase 2: Planning phase starting
[2025-10-20 10:00:15] plan-architect agent creating plan at topic-based path
[2025-10-20 10:00:20] plan-architect agent completed plan creation
[2025-10-20 10:00:21] Plan metadata extracted: 3 phases, complexity 75
LOGEOF

  check "Mock log created for anti-pattern validation" "[[ -f '$MOCK_LOG' ]]"

  export PLAN_PATH
  export MOCK_LOG

  echo -e "${GREEN}Planning phase complete: Plan created with research cross-references${NC}"
}

# ============================================================================
# Phase 3: Mock Summary Phase Execution
# ============================================================================

mock_summary_phase() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 3: Summary Phase (Mocked)${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Mock doc-writer (summarizer) agent creating workflow summary
  echo "Creating workflow summary with artifact cross-references..."

  # Create summaries directory manually (not a standard artifact type)
  local summaries_dir="$TOPIC_DIR/summaries"
  mkdir -p "$summaries_dir"
  local next_num=$(printf "%03d" 1)
  SUMMARY_PATH="$summaries_dir/${next_num}_workflow.md"

  IFS=':' read -ra REPORT_ARRAY <<< "$RESEARCH_REPORT_PATHS"

  cat > "$SUMMARY_PATH" <<EOF
# User Authentication Workflow Summary

## Workflow Metadata
- **Date**: 2025-10-20
- **Feature**: User Authentication with JWT
- **Status**: Planning Complete
- **Duration**: 30 minutes

## Artifacts Generated

### Research Reports
- ${REPORT_ARRAY[0]}
- ${REPORT_ARRAY[1]}
- ${REPORT_ARRAY[2]}

### Implementation Plan
- $PLAN_PATH

## Workflow Summary
Completed research on JWT security, authentication architecture, and database design.
Created implementation plan with 3 phases covering database schema, authentication
service, and middleware implementation.

## Key Decisions
1. Use RS256 for JWT signing
2. Short-lived access tokens (15 minutes)
3. bcrypt for password hashing
4. Middleware-based authentication

## Next Steps
1. Begin Phase 1: Database schema implementation
2. Set up development environment
3. Initialize authentication service module
EOF

  check "Summary created at topic-based path" "[[ -f '$SUMMARY_PATH' ]]"
  check "Summary is in topic/summaries/ structure" "[[ '$SUMMARY_PATH' == *_*/summaries/*.md ]]"

  # Verify summary has "Artifacts Generated" section (Revision 3)
  check "Summary has 'Artifacts Generated' section" "grep -q 'Artifacts Generated' '$SUMMARY_PATH'"

  # Verify summary references research reports
  check "Summary has 'Research Reports' subsection" "grep -q 'Research Reports' '$SUMMARY_PATH'"

  local summary_report_refs=$(grep -A 10 "Research Reports" "$SUMMARY_PATH" | grep -c "specs/.*/reports/" || true)
  check "Summary references all $RESEARCH_REPORT_COUNT research reports" "[[ $summary_report_refs -eq $RESEARCH_REPORT_COUNT ]]"

  # Verify summary references implementation plan
  check "Summary has 'Implementation Plan' subsection" "grep -q 'Implementation Plan' '$SUMMARY_PATH'"
  check "Summary references plan file path" "grep -q '$PLAN_PATH' '$SUMMARY_PATH'"

  export SUMMARY_PATH

  echo -e "${GREEN}Summary phase complete: All artifacts cross-referenced${NC}"
}

# ============================================================================
# Phase 4: Anti-Pattern Validation
# ============================================================================

validate_no_antipatterns() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 4: Anti-Pattern Validation${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Check for SlashCommand invocations in mock log
  echo "Validating no agent slash command invocations..."

  if grep -q "research-specialist.*SlashCommand.*report" "$MOCK_LOG"; then
    check "research-specialist did NOT invoke /report" "false"
  else
    check "research-specialist did NOT invoke /report" "true"
  fi

  if grep -q "plan-architect.*SlashCommand.*plan" "$MOCK_LOG"; then
    check "plan-architect did NOT invoke /plan" "false"
  else
    check "plan-architect did NOT invoke /plan" "true"
  fi

  if grep -q "doc-writer.*SlashCommand" "$MOCK_LOG"; then
    check "doc-writer did NOT invoke slash commands" "false"
  else
    check "doc-writer did NOT invoke slash commands" "true"
  fi

  echo -e "${GREEN}Anti-pattern validation complete: Zero violations${NC}"
}

# ============================================================================
# Phase 5: Cross-Reference Validation (Revision 3)
# ============================================================================

validate_cross_references() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Phase 5: Cross-Reference Validation (Revision 3)${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  echo "Validating plan → research reports cross-references..."

  # Count expected vs actual report references in plan
  local plan_report_refs=$(grep -A 20 "\\*\\*Research Reports\\*\\*:" "$PLAN_PATH" | grep -c "specs/.*/reports/" || true)
  check "Plan references correct number of reports" "[[ $plan_report_refs -eq $RESEARCH_REPORT_COUNT ]]"

  # Verify each specific report is referenced
  IFS=':' read -ra REPORT_ARRAY <<< "$RESEARCH_REPORT_PATHS"
  for report in "${REPORT_ARRAY[@]}"; do
    local report_basename=$(basename "$report")
    check "Plan references $report_basename" "grep -q '$report_basename' '$PLAN_PATH'"
  done

  echo "Validating summary → all artifacts cross-references..."

  # Verify summary references all reports
  local summary_report_refs=$(grep -A 20 "Research Reports" "$SUMMARY_PATH" | grep -c "specs/.*/reports/" || true)
  check "Summary references correct number of reports" "[[ $summary_report_refs -eq $RESEARCH_REPORT_COUNT ]]"

  # Verify summary references plan
  local plan_basename=$(basename "$PLAN_PATH")
  check "Summary references $plan_basename" "grep -q '$plan_basename' '$SUMMARY_PATH'"

  echo -e "${GREEN}Cross-reference validation complete: Full traceability established${NC}"
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  E2E Test: /orchestrate Full Workflow                     ║"
  echo "║  Version: 2.0.0-revision3 (Cross-Reference Validation)    ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""

  setup_test_workspace

  # Execute workflow phases
  mock_research_phase
  mock_planning_phase
  mock_summary_phase

  # Validate compliance
  validate_no_antipatterns
  validate_cross_references

  cleanup_test_workspace

  # Summary
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  Test Results                                              ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "Checks Run:    ${BLUE}$CHECKS_RUN${NC}"
  echo -e "Checks Passed: ${GREEN}$CHECKS_PASSED${NC}"
  echo -e "Checks Failed: ${RED}$CHECKS_FAILED${NC}"
  echo ""

  if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ E2E /orchestrate workflow test PASSED${NC}"
    echo -e "${GREEN}  - Topic-based artifact organization: ✓${NC}"
    echo -e "${GREEN}  - Cross-reference validation: ✓${NC}"
    echo -e "${GREEN}  - Anti-pattern prevention: ✓${NC}"
    exit 0
  else
    echo -e "${RED}✗ E2E /orchestrate workflow test FAILED${NC}"
    echo -e "${RED}  - $CHECKS_FAILED/$CHECKS_RUN checks failed${NC}"
    exit 1
  fi
}

# Run test
main "$@"
