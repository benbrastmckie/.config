# Documentation Archive

This directory contains historical documentation preserved for reference purposes.

## Purpose

These documents represent previous implementations, migration guides, or architectural approaches that have been superseded by current documentation. They are retained for:

- Historical context
- Understanding past design decisions
- Reference during troubleshooting
- Audit trail of system evolution

## Important Notice

**These documents are historical references. See main docs for current implementation.**

For current, up-to-date documentation, refer to the main documentation directory at [.claude/docs/README.md](../README.md).

## Archived Documents

### Documentation Consolidation (2025-10-17)

- **topic_based_organization.md** - Topic-based organization guide (consolidated into directory-protocols.md)
- **artifact_organization.md** - Artifact organization guide (consolidated into directory-protocols.md)
- **development-philosophy.md** - Development philosophy and refactoring principles (consolidated into writing-standards.md)
- **timeless_writing_guide.md** - Timeless writing patterns and examples (consolidated into writing-standards.md)

### Migration Guides

- **migration-guide-adaptive-plans.md** - Migration guide for adaptive planning tier system (superseded by integrated documentation)

### Historical Architecture

- **orchestration_enhancement_guide.md** - Early orchestration enhancements (integrated into orchestration-guide.md)

### Removed (2025-10-21)

The following documents were removed as obsolete during Plan 082 refactoring:
- **specs_migration_guide.md** - Specs directory migration guide (topic-based structure now standard, migration complete)
- **architecture.md** - Phase 7 modularization architecture (superseded by current concepts/ documentation)

## Retention Policy

### Retention Period

Archived documentation follows these retention guidelines:

- **Migration Guides**: 12 months after migration completion
- **Consolidated Content**: 12 months after consolidation date
- **Historical Architecture**: Permanent (or until system fully deprecated)
- **Removed Features**: 12 months after feature removal

### Review Process

The archive undergoes periodic review:

1. **Annual Review** (October): Evaluate all archived content for continued relevance
2. **Criteria for Retention**:
   - Provides unique historical context not available elsewhere
   - Contains architectural insights valuable for future decisions
   - Documents critical design rationale for major features
   - Serves as audit trail for compliance or troubleshooting
3. **Criteria for Removal**:
   - Content fully consolidated into current documentation
   - No unique information beyond current docs
   - Migration/feature fully deprecated >12 months
   - No references or queries in past 12 months

### Archive Workflow

**Adding to Archive**:
1. Move file to appropriate archive subdirectory
2. Update archive README with entry (date, reason, superseding doc)
3. Add redirect stub at old location (optional, for critical docs)
4. Update main docs README to remove references

**Removing from Archive**:
1. Verify content is fully consolidated or obsolete
2. Remove file from archive directory
3. Update archive README to note removal
4. Document removal date in commit message

## When to Use Archive

Use archived documents when:
- Investigating historical implementation details
- Understanding why certain design decisions were made
- Troubleshooting issues related to legacy systems
- Researching system evolution for documentation purposes

## Navigation

- [Return to Main Documentation](../README.md)
- [Claude Code Documentation Index](../../../README.md)
