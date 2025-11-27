# Topic Naming Tests

Tests for the LLM-based topic naming system used by directory-creating commands.

## Overview

The topic naming system generates semantic directory names for spec topics using the `topic-naming-agent` (Haiku LLM). These tests validate:

1. **Format Validation**: Topic names match `^[a-z0-9_]{5,40}$`
2. **Agent Integration**: Commands properly invoke the topic-naming-agent
3. **Fallback Mechanisms**: `no_name_error` fallback triggers on agent failures
4. **Topic Allocation**: Atomic topic number allocation and idempotency

## Test Files

| File | Purpose | Tests |
|------|---------|-------|
| `test_topic_naming_agent.sh` | Unit tests for `validate_topic_name_format()` | 28 |
| `test_topic_naming_fallback.sh` | Fallback scenario edge cases | 35 |
| `test_topic_naming_integration.sh` | End-to-end command integration | 22 |
| `test_atomic_topic_allocation.sh` | Topic number allocation atomicity | - |
| `test_command_topic_allocation.sh` | Command-level topic creation | - |
| `test_topic_slug_validation.sh` | Slug format validation | - |
| `test_topic_filename_generation.sh` | Filename pattern generation | - |

## Running Tests

```bash
# Run all topic-naming tests
./run_all_tests.sh --category topic-naming

# Run individual test
bash tests/topic-naming/test_topic_naming_agent.sh

# Run with verbose output
bash tests/topic-naming/test_topic_naming_agent.sh --verbose
```

## Architecture

The topic naming system uses a three-tier approach:

1. **Tier 1**: LLM-generated topic name (via `topic-naming-agent`)
2. **Tier 2**: `validate_topic_name_format()` validation
3. **Tier 3**: Fallback to `no_name_error` on any failure

## Related Documentation

- [Topic Naming with LLM](../../docs/guides/development/topic-naming-with-llm.md)
- [Directory Protocols](../../docs/concepts/directory-protocols.md)
- [Topic Naming Agent](../../agents/topic-naming-agent.md)

## Changelog

- **2025-11-22**: Removed 4 deprecated tests for never-implemented `sanitize_topic_name()` features
  - `test_topic_name_sanitization.sh` - tested non-existent `strip_artifact_references()`
  - `test_topic_naming.sh` - tested enhanced stopwords never implemented
  - `test_directory_naming_integration.sh` - tested deprecated sanitization
  - `test_semantic_slug_commands.sh` - had path resolution bugs
- **2025-11-22**: Fixed path resolution bugs in 3 remaining tests
