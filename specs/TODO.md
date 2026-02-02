---
next_project_number: 32
---

# TODO

## Tasks

### 31. Fix plan file status update in /implement
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Research**: [research-001.md](specs/031_fix_plan_file_status_update_in_implement/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/031_fix_plan_file_status_update_in_implement/plans/implementation-001.md)

**Description**: Add plan file status verification to /implement GATE OUT checkpoint and make implementation skills more explicit about plan file updates. Currently plan files are not reliably updated to [COMPLETED] status after implementation finishes (documented in skills but not executed). Fix: (1) Add verification step in implement.md GATE OUT that checks plan file status matches task status and updates if needed (defensive backup), (2) Make the sed command in skills Stage 7 more explicit with error checking and verification output.


