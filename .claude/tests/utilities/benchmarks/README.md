# Performance Benchmarks

Performance benchmarking tests for workflow components.

## Purpose

This directory contains benchmarking scripts that measure performance characteristics of workflow features. Benchmarks help identify performance regressions and validate optimization efforts.

## Test Organization

Benchmarks measure:
- Workflow classification algorithm performance
- LLM response time and token usage
- Classification accuracy metrics

## Running Tests

```bash
# Run all benchmarks
cd /home/benjamin/.config/.claude/tests/utilities/benchmarks
for bench in bench_*.sh; do bash "$bench"; done

# Run specific benchmark
bash bench_workflow_classification.sh
```

## Files in This Directory

### bench_workflow_classification.sh
**Purpose**: Benchmark workflow classification performance
**Coverage**: Classification speed, accuracy, LLM token usage
**Dependencies**: Sample workflows for classification

**Metrics Reported**:
- Classification time per workflow
- Token consumption per classification
- Accuracy vs ground truth labels
- Throughput (workflows/second)

## Navigation

- [← Parent Directory](../README.md)
- [Related: manual/](../manual/README.md)
