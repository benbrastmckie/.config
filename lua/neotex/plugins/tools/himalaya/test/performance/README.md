# Performance Tests

This directory contains performance and benchmarking tests for Himalaya components.

## Purpose

Performance tests measure and validate the efficiency of Himalaya operations. These tests ensure that the plugin remains responsive and efficient under various load conditions, helping identify performance bottlenecks and regressions.

## Test Files

### test_search_speed.lua
Tests email search performance and efficiency.

**What it tests:**
- **Basic search performance**: Simple search operations on large datasets
- **Complex search performance**: Advanced search queries with multiple criteria
- **Date range search performance**: Time-based filtering efficiency
- **Search cache performance**: Caching effectiveness for repeated searches
- **Search memory usage**: Memory efficiency during search operations

**Performance metrics:**
- Search speed for different dataset sizes (100, 500, 1000+ emails)
- Memory usage during search operations
- Cache hit rates and performance improvements
- Search response times under load

**Key functions tested:**
- `search.filter_emails()` - Core search functionality
- `search.search_by_date()` - Date-based filtering
- `search.cached_search()` - Cached search operations
- Search indexing and optimization

## System Under Test

Performance tests focus on critical performance aspects:

### Search Performance
- **Dataset Scaling**: How performance changes with email count
- **Query Complexity**: Impact of search criteria complexity
- **Caching Effectiveness**: Performance benefits of search caching
- **Memory Efficiency**: Memory usage patterns during search

### Key Performance Areas
- **Response Time**: Time to complete operations
- **Memory Usage**: Memory consumption patterns
- **Throughput**: Operations per second
- **Scalability**: Performance under increasing load

## Test Patterns

### Performance Measurement
```lua
-- Basic performance timing
local start_time = vim.loop.hrtime()
perform_operation()
local duration = (vim.loop.hrtime() - start_time) / 1e6 -- Convert to milliseconds
assert.performance(duration, max_duration, "Operation should complete within time limit")
```

### Memory Usage Testing
```lua
-- Memory usage measurement
collectgarbage("collect")
local initial_memory = collectgarbage("count")
perform_memory_intensive_operation()
collectgarbage("collect")
local final_memory = collectgarbage("count")
local memory_used = final_memory - initial_memory
assert.memory_usage(memory_used, max_memory, "Memory usage should stay within limits")
```

### Scalability Testing
```lua
-- Test with different dataset sizes
for size in {100, 500, 1000} do
  local dataset = create_test_dataset(size)
  local duration = time_operation(function()
    perform_operation(dataset)
  end)
  assert.scales_linearly(duration, size, "Performance should scale reasonably")
end
```

### Cache Performance Testing
```lua
-- Test cache effectiveness
local cold_duration = time_operation(function()
  perform_search_operation(query) -- Cold cache
end)
local warm_duration = time_operation(function()
  perform_search_operation(query) -- Warm cache
end)
assert.cache_improvement(cold_duration, warm_duration, "Cache should improve performance")
```

## Performance Benchmarks

### Search Performance Targets
- **Small dataset (< 100 emails)**: < 10ms response time
- **Medium dataset (100-500 emails)**: < 50ms response time
- **Large dataset (500+ emails)**: < 100ms response time
- **Memory usage**: < 5MB for search operations

### Expected Performance Characteristics
- **Linear scaling**: Search time should scale linearly with dataset size
- **Cache benefits**: 50%+ performance improvement for cached searches
- **Memory efficiency**: Memory usage should not grow unboundedly
- **Consistent performance**: Performance should not degrade over time

## Running Tests

### Run all performance tests:
```vim
:HimalayaTest performance
```

### Run specific performance test:
```vim
:HimalayaTest test_search_speed
```

### Performance test output includes:
- Execution time measurements
- Memory usage statistics
- Performance comparison across different scenarios
- Regression detection alerts

## Test Environment

Performance tests run with:
- Controlled test datasets of various sizes
- Memory usage monitoring
- Timing precision using `vim.loop.hrtime()`
- Garbage collection management
- Performance regression detection

## Performance Monitoring

### Metrics Tracked
- **Execution Time**: Precise timing of operations
- **Memory Usage**: Memory consumption patterns
- **Cache Hit Rates**: Effectiveness of caching systems
- **Scalability**: Performance under increasing load

### Regression Detection
- Performance tests fail if operations exceed expected time limits
- Memory usage tests fail if memory consumption is excessive
- Cache performance tests verify caching effectiveness

## Contributing

When adding new performance tests:

1. **Set realistic benchmarks**: Use achievable performance targets
2. **Test with realistic data**: Use representative dataset sizes
3. **Measure consistently**: Use consistent timing and memory measurement
4. **Test scalability**: Verify performance across different load levels
5. **Document expectations**: Clearly state performance expectations

## Troubleshooting Performance Issues

### Common Performance Problems
- **Memory leaks**: Unbounded memory growth
- **Inefficient algorithms**: Poor algorithmic complexity
- **Lack of caching**: Repeated expensive operations
- **Blocking operations**: Long-running synchronous operations

### Performance Optimization Strategies
- **Implement caching**: Cache expensive operations
- **Optimize algorithms**: Use efficient data structures and algorithms
- **Batch operations**: Group related operations together
- **Use async operations**: Avoid blocking the UI thread

## Navigation

- [← Test Overview](../README.md)
- [← Integration Tests](../integration/README.md)
- [Test Utils →](../utils/README.md)