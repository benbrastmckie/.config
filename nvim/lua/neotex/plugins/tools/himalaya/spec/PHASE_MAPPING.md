# Himalaya Implementation Phase Mapping Quick Reference

This document provides a quick reference for how all specification items map to implementation phases 6-10.

## ✅ Phase 6: Event System & Architecture Foundation (Week 1) - COMPLETED

### Primary Deliverables - COMPLETED
- ✓ Event bus system implementation (`orchestration/events.lua`)
- ✓ Core event definitions (`core/events.lua`)  
- ✓ Event integration with existing code (`orchestration/integration.lua`)

### Supporting Items from Other Specs - COMPLETED
- ✓ **Error Handling Standardization** (CLEANUP #1.3, TODOS #1.3, CODE_QUALITY #1)
- ✓ **State Management Improvements** (CLEANUP #1.2, TODOS #1.2)
- ✓ **Backward Compatibility** - All existing functions work unchanged

### Implementation Files
- `orchestration/events.lua` - Event bus with priority-based handlers
- `core/events.lua` - Standardized event constants
- `core/errors.lua` - Enhanced error handling with recovery strategies
- `orchestration/integration.lua` - Non-breaking event integration layer
- `core/state.lua` - Enhanced with versioning and migration support
- `test_phase6.lua` - Comprehensive test suite
- `test_compatibility.lua` - Backward compatibility verification

## ✅ Phase 7: Command System & API Consistency (Week 2) - COMPLETED

### Primary Deliverables - COMPLETED
- ✓ Command system refactoring (split commands.lua into ui, email, sync, setup, debug modules)
- ✓ Command orchestration layer (`orchestration/commands.lua`)
- ✓ API consistency layer implementation (`core/api.lua`)

### Supporting Items from Other Specs - COMPLETED
- ✓ **Command System Refactoring** (CLEANUP #1.1, TODOS #1.1, ARCHITECTURE Phase 7)
- ✓ **API Consistency Layer** (CODE_QUALITY #2)
- ✓ **Enhanced Logging System** (CLEANUP #3.1, TODOS #3.1, CODE_QUALITY #5)
- ✓ **Utility Function Enhancements** (CLEANUP #3.2, TODOS #3.2)
- **Setup System Automation** (CLEANUP #3.3, TODOS #3.3) - Partial

### Implementation Files
- `core/commands/init.lua` - Central command registry and setup
- `core/commands/ui.lua` - UI-related commands  
- `core/commands/email.lua` - Email operation commands
- `core/commands/sync.lua` - Synchronization commands
- `core/commands/setup.lua` - Setup and maintenance commands
- `core/commands/debug.lua` - Debug and diagnostic commands
- `orchestration/commands.lua` - Command execution orchestration
- `core/api.lua` - API consistency layer with validation
- `core/logger_enhanced.lua` - Structured logging with handlers
- `utils/enhanced.lua` - Enhanced utility functions

## ✅ Phase 8: Core Email Features (Weeks 3-4) - COMPLETED

### Primary Deliverables (EMAIL_MANAGEMENT_FEATURES_SPEC.md) - COMPLETED
1. ✓ **Multiple Account Support** (#6) - Foundation for many features
2. ✓ **Attachment Support** (#1) - View, download, send
3. ✓ **Local Trash System** (#4) - With recovery capabilities
4. ✓ **Custom Headers** (#5) - Full header support
5. ✓ **Image Display** (#2) - Terminal image rendering
6. ✓ **Address Autocomplete** (#3) - Contact management

### Supporting Items from Other Specs - COMPLETED
- ✓ **Email Composition Enhancements** (TODOS #2.1)
- ✓ **Email Preview Improvements** (TODOS #2.2)
- ✓ **Email List Management** (TODOS #2.3)
- ✓ **Missing Command Implementations** (TODOS #2.4)
- ✓ **Performance Optimizations** (CODE_QUALITY #3) - Applied during implementation

### Implementation Files
- `features/accounts.lua` - Multiple account support with unified views
- `features/attachments.lua` - Attachment handling with caching and viewers
- `features/trash.lua` - Local trash system with recovery
- `features/headers.lua` - Custom header management and validation
- `features/images.lua` - Terminal image display with multiple protocols
- `features/contacts.lua` - Contact management with autocomplete
- `core/commands/features.lua` - Command integration for all features
- `ui/features.lua` - UI components for Phase 8 features

## Phase 9: Advanced Features & UI Evolution (Weeks 5-6) - IN PROGRESS

### Completed Features (4/8)
1. ✓ **Undo Send System** (#2) - 60-second delay queue - COMPLETED
2. ✓ **Advanced Search** (#3) - Search operators and filters - COMPLETED  
3. ✓ **Email Templates** (#4) - Variable support - COMPLETED
4. ✓ **Notification System Integration** (CLEANUP #4.2, TODOS #4.2) - COMPLETED

### Next Implementation - Unified Email Scheduling
- **Specification**: [PHASE_9_NEXT_IMPLEMENTATION.md](PHASE_9_NEXT_IMPLEMENTATION.md)
- **Breaking Changes**: Remove send_queue.lua, no immediate send option
- **Key Features**: ALL emails scheduled, minimum 60s delay, full scheduling UI
- **Timeline**: 1 week

### Remaining Features - Not Implemented
- **Specification**: [PHASE_9_REMAINING_FEATURES.md](PHASE_9_REMAINING_FEATURES.md)
1. **Multiple Account Views** (#1) - Unified inbox, split, tabbed views
2. **Email Rules and Filters** (#7) - Automatic filtering and actions
3. **Integration Features** (#8) - Task management, calendar, notes

### Window Management - Separate Implementation
- **Specification**: [WINDOW_MANAGEMENT_SPEC.md](WINDOW_MANAGEMENT_SPEC.md)
- **Features**: Layouts, coordination, resize mode, persistence
- **Priority**: Medium

### Implementation Files
- `core/send_queue.lua` - Send queue with cancellation (to be replaced)
- `core/search.lua` - Advanced search with 23+ operators
- `core/templates.lua` - Template system with variables and conditionals
- `scripts/test_phase9.lua` - Comprehensive test suite
- `scripts/demo_phase9.lua` - Feature demonstrations
- `scripts/demo_unified_scheduler.lua` - Unified scheduling demo

## Phase 10: Security, Polish & Integration (Week 7)

### Primary Deliverables
- **OAuth 2.0 Implementation** (EMAIL_MANAGEMENT #7, TODOS #4.3)
- **PGP/GPG Encryption** (ADVANCED_FEATURES #6)
- **Testing Infrastructure** (CODE_QUALITY #4)
- **Documentation Updates** (CLEANUP #5.1, TODOS #5.1)

### Final Polish Items
- **Performance Optimization Final Pass** (CODE_QUALITY #3)
- **Further Modularization** (CODE_QUALITY #6)
- **Integration Testing** (ARCHITECTURE Phase 10)
- **Documentation Tooling** (CLEANUP Phase 5)

## Quick Navigation

### By Specification Document

**ARCHITECTURE_REFACTOR_SPEC.md**
- Phases 6-10: Complete implementation guide

**EMAIL_MANAGEMENT_FEATURES_SPEC.md**  
- Phase 8: Features 1-6
- Phase 10: Feature 7 (OAuth)

**ADVANCED_FEATURES_SPEC.md**
- Phase 9 Completed: Features 2, 3, 4 (Undo send, Search, Templates)
- Phase 9 Remaining: Features 1, 5, 7, 8 (Multiple views, Scheduling, Rules, Integration)
- Phase 10: Feature 6 (Encryption)

**PHASE_9_NEXT_IMPLEMENTATION.md** (New)
- Unified email scheduling system (breaking changes)

**PHASE_9_REMAINING_FEATURES.md** (New)
- Multiple account views, email rules, integration features

**WINDOW_MANAGEMENT_SPEC.md** (New)
- Window layouts and management improvements

**CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md**
- Phase 6: Section 1 (Error Handling)
- Phase 7: Sections 2, 5 (API, Logging)
- Phase 8: Section 3 (Performance)
- Phase 10: Sections 4, 6 (Testing, Modularization)

**CLEANUP_AND_REFINEMENT_SPEC.md**
- Phase 6: Sections 1.2, 1.3
- Phase 7: Sections 1.1, 3.1-3.3
- Phase 9: Sections 4.1, 4.2
- Phase 10: Section 5.1

**TODOS_TECH_DEBT_OVERVIEW.md**
- Phase 6: Priority 1 items (except 1.1)
- Phase 7: Item 1.1, Priority 3 items
- Phase 8: Priority 2 items
- Phase 9: Priority 4 items (4.1, 4.2)
- Phase 10: Priority 4 item (4.3), Priority 5 items

## Implementation Notes

1. **Dependencies**: Phase order is important - each phase builds on previous work
2. **Flexibility**: Some items can shift between adjacent phases if needed
3. **Parallel Work**: Within a phase, multiple items can be worked on concurrently
4. **Testing**: Each phase should include tests for new functionality
5. **No Breaking Changes**: All work must maintain backward compatibility