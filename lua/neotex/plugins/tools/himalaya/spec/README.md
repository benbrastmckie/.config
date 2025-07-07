# Himalaya Plugin Specifications

This directory contains comprehensive specifications for the ongoing development and enhancement of the Himalaya email plugin for Neovim. These documents outline the current state, planned improvements, and implementation strategies.

## 📚 Specification Documents

### Primary Implementation Guides (By Phase)

1. **[ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md)** - Main Implementation Roadmap
   - ✅ Phases 1-5: Current architecture (complete)
   - 📋 Phase 6: Event System Foundation
   - 📋 Phase 7: Command System Refactoring  
   - 📋 Phase 8: Service Layer Enhancement
   - 📋 Phase 9: UI Layer Evolution
   - 📋 Phase 10: Integration and Polish

2. **[EMAIL_MANAGEMENT_FEATURES_SPEC.md](EMAIL_MANAGEMENT_FEATURES_SPEC.md)** - Phase 8 Core Features
   - Multiple account integration (priority 1)
   - Attachment support (view, download, send)
   - Local trash system with recovery
   - Custom email headers
   - Image display in terminal
   - Address autocomplete
   - OAuth security (Phase 10)

3. **[ADVANCED_FEATURES_SPEC.md](ADVANCED_FEATURES_SPEC.md)** - Phase 9 Advanced Features
   - Undo send system (60-second delay queue)
   - Advanced search with operators
   - Email templates with variables
   - Email scheduling and recurrence
   - Multiple account views (unified inbox, split, tabbed)
   - PGP/GPG encryption (Phase 10)
   - Email rules and filters
   - Integration features (calendar, tasks)

### Supporting Specifications (Cross-Phase)

4. **[PHASE_MAPPING.md](PHASE_MAPPING.md)** - Quick Reference Phase Mapping 🆕
   - Complete mapping of all spec items to phases 6-10
   - Quick navigation by phase or specification
   - Implementation dependencies and notes

5. **[CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md)** - Quality Improvements
   - Phase 6: Enhanced error handling system
   - Phase 7: API consistency layer
   - Phase 8: Performance optimization tools
   - Phase 10: Testing framework & observability
   - Cross-phase: Modularization guidelines

6. **[CLEANUP_AND_REFINEMENT_SPEC.md](CLEANUP_AND_REFINEMENT_SPEC.md)** - Technical Debt Items
   - Phase 6: Error handling patterns, performance
   - Phase 7: Command system refactoring strategy
   - Phase 8: State management improvements
   - Phase 9: Window management, UI polish
   - Phase 10: Documentation tooling

7. **[TODOS_TECH_DEBT_OVERVIEW.md](TODOS_TECH_DEBT_OVERVIEW.md)** - Comprehensive TODO Tracking
   - Analysis of 84 TODO comments across codebase
   - Items mapped to phases 6-10 by priority
   - Risk assessment and mitigation strategies

## 🗺️ Implementation Roadmap

### Current State
- **Completed**: Phases 1-5 of initial refactoring
  - ✅ UI layout refactoring
  - ✅ Enhanced UI/UX features
  - ✅ Unified state management
  - ✅ Centralized notification system
  - ✅ Email preview in sidebar

### Phase Overview

The implementation is organized into 10 phases, with phases 6-10 representing the future work:

#### ✅ Completed Phases (1-5)
- **Phase 1**: UI layout refactoring
- **Phase 2**: Enhanced UI/UX features
- **Phase 3**: Unified state management
- **Phase 4**: Centralized notification system  
- **Phase 5**: Email preview in sidebar

#### 🚀 Future Phases (6-10)

##### ✅ Phase 6: Event System & Architecture Foundation (1 week) - COMPLETED
- **Goal**: Implement foundational architecture improvements
- **Key Deliverables**: ✅ Event bus system, ✅ Enhanced error handling, ✅ State management improvements
- **Implementation Date**: $(date +%Y-%m-%d)
- **Primary Spec**: [ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md#phase-6-event-system-foundation)
- **Supporting Specs**: 
  - [CLEANUP_AND_REFINEMENT_SPEC.md](CLEANUP_AND_REFINEMENT_SPEC.md) - Error handling patterns
  - [CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#1-enhanced-error-handling) - Error module design
- **Implementation Notes**: All modules pass tests, full backward compatibility maintained

##### Phase 7: Command System & API Consistency (1 week)
- **Goal**: Refactor command architecture and establish API patterns
- **Key Deliverables**: Split commands.lua, unified command system, API consistency layer
- **Primary Spec**: [ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md#phase-7-command-system-refactoring)
- **Supporting Specs**:
  - [CLEANUP_AND_REFINEMENT_SPEC.md](CLEANUP_AND_REFINEMENT_SPEC.md) - Command splitting strategy
  - [CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#2-api-consistency) - API patterns

##### Phase 8: Core Email Features (2 weeks)
- **Goal**: Implement essential email management functionality
- **Key Deliverables**: Attachments, multiple accounts, trash system, custom headers
- **Primary Spec**: [EMAIL_MANAGEMENT_FEATURES_SPEC.md](EMAIL_MANAGEMENT_FEATURES_SPEC.md)
- **Features by Priority**:
  1. Multiple account support (enables many other features)
  2. Attachment handling (view, download, send)
  3. Local trash system with recovery
  4. Custom email headers
  5. Image display capabilities

##### Phase 9: Advanced Features & UI Evolution (2 weeks)
- **Goal**: Add power user features and enhance UI components
- **Key Deliverables**: Advanced search, templates, scheduling, UI improvements
- **Primary Specs**: 
  - [ADVANCED_FEATURES_SPEC.md](ADVANCED_FEATURES_SPEC.md) - Feature implementations
  - [ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md#phase-9-ui-layer-evolution) - UI architecture
- **Features by Priority**:
  1. Undo send system (high user value)
  2. Advanced search with operators
  3. Email templates with variables
  4. Email scheduling
  5. Address autocomplete

##### Phase 10: Security, Polish & Integration (1 week)
- **Goal**: Security hardening, testing, and final polish
- **Key Deliverables**: OAuth, encryption, testing framework, documentation
- **Primary Specs**:
  - [EMAIL_MANAGEMENT_FEATURES_SPEC.md](EMAIL_MANAGEMENT_FEATURES_SPEC.md#7-oauth--security-improvements) - OAuth implementation
  - [ADVANCED_FEATURES_SPEC.md](ADVANCED_FEATURES_SPEC.md#6-pgpgpg-encryption) - Encryption support
  - [CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#4-testing-infrastructure) - Testing framework

## 🚀 Getting Started

### Where to Begin

1. **Review Current State**
   - Read [ARCHITECTURE_REFACTOR_SPEC.md](ARCHITECTURE_REFACTOR_SPEC.md) sections on "Current State Assessment"
   - Understand the existing architecture and completed work

2. **Understand Technical Debt**
   - Review [TECH_DEBT.md](TECH_DEBT.md) for priority items
   - Focus on Priority 1 items that block new features

3. **Start with Phase 6: Event System**
   - Begin with the event system foundation (see Architecture spec)
   - This enables all future improvements without breaking existing code

### Implementation Order

#### Week 1: Phase 6 - Event System & Architecture Foundation
- **Primary Reference**: [ARCHITECTURE_REFACTOR_SPEC.md - Phase 6](ARCHITECTURE_REFACTOR_SPEC.md#phase-6-event-system-foundation)
- Implement event bus system with core events
- Set up enhanced error handling module ([CODE_QUALITY spec](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#1-enhanced-error-handling))
- Apply performance optimizations from [CLEANUP spec](CLEANUP_AND_REFINEMENT_SPEC.md)
- Add events alongside existing calls (no breaking changes)

#### Week 2: Phase 7 - Command System & API Consistency  
- **Primary Reference**: [ARCHITECTURE_REFACTOR_SPEC.md - Phase 7](ARCHITECTURE_REFACTOR_SPEC.md#phase-7-command-system-refactoring)
- Split `commands.lua` using strategy from [CLEANUP spec](CLEANUP_AND_REFINEMENT_SPEC.md)
- Implement API consistency layer ([CODE_QUALITY spec](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#2-api-consistency))
- Create command orchestration layer
- Maintain full backward compatibility

#### Week 3-4: Phase 8 - Core Email Features
- **Primary Reference**: [EMAIL_MANAGEMENT_FEATURES_SPEC.md](EMAIL_MANAGEMENT_FEATURES_SPEC.md)
- Week 3 priorities:
  - Multiple account support ([Section 6](EMAIL_MANAGEMENT_FEATURES_SPEC.md#6-multiple-email-accounts-integration))
  - Attachment handling ([Section 1](EMAIL_MANAGEMENT_FEATURES_SPEC.md#1-attachment-support))
- Week 4 priorities:
  - Local trash system ([Section 4](EMAIL_MANAGEMENT_FEATURES_SPEC.md#4-local-trash-system))
  - Custom headers ([Section 5](EMAIL_MANAGEMENT_FEATURES_SPEC.md#5-custom-headers))
  - Address autocomplete ([Section 3](EMAIL_MANAGEMENT_FEATURES_SPEC.md#3-address-autocomplete))

#### Week 5-6: Phase 9 - Advanced Features & UI Evolution
- **Primary References**: 
  - [ADVANCED_FEATURES_SPEC.md](ADVANCED_FEATURES_SPEC.md)
  - [ARCHITECTURE_REFACTOR_SPEC.md - Phase 9](ARCHITECTURE_REFACTOR_SPEC.md#phase-9-ui-layer-evolution)
- Week 5 priorities:
  - Undo send system ([ADVANCED spec - Section 2](ADVANCED_FEATURES_SPEC.md#2-undo-send-email-system))
  - Advanced search ([ADVANCED spec - Section 3](ADVANCED_FEATURES_SPEC.md#3-advanced-search))
- Week 6 priorities:
  - Email templates ([ADVANCED spec - Section 4](ADVANCED_FEATURES_SPEC.md#4-email-templates))
  - UI layer improvements from architecture spec

#### Week 7: Phase 10 - Security, Polish & Integration
- **Primary References**:
  - [ARCHITECTURE_REFACTOR_SPEC.md - Phase 10](ARCHITECTURE_REFACTOR_SPEC.md#phase-10-integration-and-polish)
  - Security sections from various specs
- OAuth implementation ([EMAIL_MANAGEMENT spec - Section 7](EMAIL_MANAGEMENT_FEATURES_SPEC.md#7-oauth--security-improvements))
- Testing infrastructure ([CODE_QUALITY spec - Section 4](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#4-testing-infrastructure))
- Performance final pass ([CODE_QUALITY spec - Section 3](CODE_QUALITY_AND_DEVELOPER_EXPERIENCE_SPEC.md#3-performance-optimizations))
- Documentation updates

## 📋 Implementation Checklist

### ✅ Phase 6: Event System & Architecture Foundation (Week 1) - COMPLETED
- [✓] Event bus system implementation (`orchestration/events.lua`)
- [✓] Core event definitions (`core/events.lua`)
- [✓] Enhanced error handling module (`core/errors.lua`)
- [✓] Event integration layer (`orchestration/integration.lua`)
- [✓] State management improvements (versioning, migration, validation)
- [✓] Backward compatibility verified with comprehensive tests

### Phase 7: Command System & API Consistency (Week 2)
- [ ] Split commands.lua into logical modules
- [ ] Command orchestration layer
- [ ] API consistency layer
- [ ] Service layer enhancements
- [ ] Backward compatibility verification

### Phase 8: Core Email Features (Weeks 3-4)
- [ ] Multiple account support infrastructure
- [ ] Attachment handling (view, download, send)
- [ ] Local trash system with recovery
- [ ] Custom email headers support
- [ ] Image display in terminal
- [ ] Address autocomplete functionality

### Phase 9: Advanced Features & UI Evolution (Weeks 5-6)
- [ ] Undo send system (60-second queue)
- [ ] Advanced search with operators
- [ ] Email template management
- [ ] Email scheduling capabilities
- [ ] UI component improvements
- [ ] Enhanced window management

### Phase 10: Security, Polish & Integration (Week 7)
- [ ] OAuth 2.0 implementation
- [ ] PGP/GPG encryption support (optional)
- [ ] Comprehensive testing framework
- [ ] Performance optimization final pass
- [ ] Documentation updates
- [ ] Integration testing

## 🛠️ Development Guidelines

### Principles
1. **No Breaking Changes**: All improvements must maintain backward compatibility
2. **Incremental Progress**: Small, tested changes over big rewrites
3. **User First**: Features that provide immediate user value take priority
4. **Event-Driven**: New features should use the event system
5. **Well-Tested**: Each feature needs appropriate test coverage

### Working with Specs
1. Each spec is self-contained with implementation details
2. Cross-reference specs when features overlap
3. Update specs as implementation reveals new insights
4. Create GitHub issues from spec sections for tracking

### Code Organization
```
himalaya/
├── orchestration/   # New: Event system and coordination
├── core/           # Enhanced: Split commands, better errors
├── service/        # New: Feature services (accounts, search, etc.)
├── ui/            # Enhanced: Controllers, new components
└── test/          # New: Testing infrastructure
```

## 📊 Success Metrics

Track progress using these metrics:
- All 31+ existing commands continue working
- 15-20% reduction in code complexity
- 80%+ test coverage on new code
- < 100ms response time for common operations
- Zero breaking changes for users

## 🔗 Related Documentation

- Main plugin documentation: `../README.md`
- Architecture overview: `../ARCHITECTURE.md`
- User documentation: `../docs/`
- Neovim configuration guidelines: `/home/benjamin/.config/nvim/CLAUDE.md`

## 📝 Notes

- These specifications are living documents - update them as implementation progresses
- Priority may shift based on user feedback and technical discoveries
- Some features may be simplified or enhanced during implementation
- Always consider the impact on existing users

---

*Last Updated: Generated from current analysis*
*Total Implementation Timeline: 7 weeks*
*Phases Completed: 6/10*