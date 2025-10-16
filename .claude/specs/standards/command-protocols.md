# Command Coordination Protocol Standards

Date: 2025-01-15

## Overview

This document defines standardized coordination protocols for all helper commands in the orchestration ecosystem. These protocols ensure consistent communication, coordination, and resource management across all command implementations.

## Message Format Standards

### Event Message Schema

All event messages MUST follow the standardized format:

```
EVENT_TYPE:workflow_id:phase:data
```

#### Event Message Components

1. **EVENT_TYPE**: Predefined event type (see Event Types section)
2. **workflow_id**: Unique workflow identifier (e.g., `wf_001`, `workflow_123`)
3. **phase**: Current workflow phase or `global` for system-wide events
4. **data**: JSON-encoded event payload

#### Event Message Examples

```bash
# Phase completion event
"PHASE_COMPLETED:wf_001:implementation:{'duration':'45m','tasks_completed':15,'success_rate':94.2}"

# Resource allocation event
"RESOURCE_ALLOCATED:wf_001:setup:{'agents':3,'memory_gb':8,'allocation_id':'alloc_456'}"

# Error encountered event
"ERROR_ENCOUNTERED:wf_001:testing:{'error_type':'timeout','agent':'agent_003','task':'test_integration'}"

# System-wide event
"SYSTEM_THRESHOLD:global:global:{'metric':'memory','current':85.2,'threshold':80.0,'severity':'warning'}"
```

### Resource Allocation Schema

#### Request Format

```json
{
  "allocation_request": {
    "request_id": "req_<uuid>",
    "workflow_id": "workflow_123",
    "requester": "coordination-hub|subagents|other",
    "timestamp": "2025-01-15T12:00:00Z",
    "priority": "critical|high|medium|low",
    "resources": {
      "agents": 5,
      "memory_gb": 12,
      "cpu_cores": 4,
      "duration_hours": 2.5,
      "exclusive_files": ["config.nix", "home.nix"],
      "tool_instances": {
        "bash": 3,
        "file_ops": 5,
        "search": 2,
        "web": 1
      }
    },
    "constraints": {
      "max_wait_time": "10m",
      "min_performance": "standard",
      "conflict_tolerance": "none|low|medium|high",
      "isolation_level": "strict|moderate|relaxed"
    },
    "fallback_options": {
      "reduce_agents": true,
      "extend_duration": false,
      "accept_shared_resources": true,
      "queue_if_unavailable": true
    }
  }
}
```

#### Response Format

```json
{
  "allocation_response": {
    "response_id": "resp_<uuid>",
    "request_id": "req_<uuid>",
    "status": "approved|denied|queued|partial",
    "timestamp": "2025-01-15T12:00:05Z",
    "allocated_resources": {
      "allocation_id": "alloc_789",
      "agents": 4,
      "memory_gb": 10,
      "cpu_cores": 3,
      "duration_hours": 2.5,
      "exclusive_files": ["config.nix"],
      "tool_instances": {
        "bash": 3,
        "file_ops": 4,
        "search": 2,
        "web": 1
      }
    },
    "restrictions": {
      "monitoring_required": true,
      "performance_limits": {"memory_per_agent": "2.5GB"},
      "auto_release_timeout": "3h",
      "exclusive_access_windows": ["12:30-13:00"]
    },
    "alternatives": [
      {
        "option": "delayed_allocation",
        "available_at": "2025-01-15T14:00:00Z",
        "full_resources": true
      }
    ]
  }
}
```

### State Synchronization Protocols

#### Workflow State Message

```json
{
  "workflow_state": {
    "message_type": "state_sync",
    "workflow_id": "workflow_123",
    "timestamp": "2025-01-15T12:00:00Z",
    "state_version": 15,
    "checkpoint_id": "ckpt_456",
    "current_phase": {
      "phase_id": 3,
      "name": "implementation",
      "progress": 67.5,
      "started_at": "2025-01-15T11:30:00Z",
      "estimated_completion": "2025-01-15T12:45:00Z"
    },
    "agent_states": {
      "agent_001": {
        "status": "active",
        "current_task": "task_789",
        "progress": 45.2,
        "performance_score": 92.1
      }
    },
    "resource_usage": {
      "memory_current": 8.7,
      "cpu_utilization": 73.2,
      "storage_used": 2.1
    },
    "validation_required": ["state_integrity", "dependency_consistency"],
    "metadata": {
      "last_update_source": "coordination-hub",
      "synchronization_confidence": 0.97,
      "conflict_detected": false
    }
  }
}
```

#### Checkpoint Synchronization

```json
{
  "checkpoint_sync": {
    "message_type": "checkpoint_update",
    "workflow_id": "workflow_123",
    "checkpoint_id": "ckpt_789",
    "timestamp": "2025-01-15T12:00:00Z",
    "checkpoint_type": "phase_complete|incremental|emergency|manual",
    "trigger": "automatic|manual|failure_prevention",
    "state_snapshot": {
      "workflow_state_hash": "sha256:abc123...",
      "file_system_hash": "sha256:def456...",
      "agent_state_hash": "sha256:ghi789...",
      "resource_state_hash": "sha256:jkl012..."
    },
    "validation_results": {
      "integrity_check": "passed|failed|unknown",
      "dependency_validation": "passed|failed|unknown",
      "resource_consistency": "passed|failed|unknown"
    },
    "storage_metadata": {
      "size_bytes": 15432,
      "compression_ratio": 0.67,
      "storage_location": ".claude/data/checkpoints/workflow_123/ckpt_789",
      "backup_locations": ["primary", "secondary"]
    }
  }
}
```

### Error Reporting Standards

#### Error Classification

Error messages MUST include standardized classification:

```json
{
  "error_report": {
    "error_id": "err_<uuid>",
    "workflow_id": "workflow_123",
    "timestamp": "2025-01-15T12:00:00Z",
    "classification": {
      "category": "execution|resource|dependency|state|system",
      "severity": "critical|high|medium|low|info",
      "type": "timeout|conflict|corruption|unavailable|limit_exceeded",
      "scope": "workflow|phase|task|agent|system",
      "recoverable": true
    },
    "context": {
      "component": "coordination-hub|resource-manager|agent_003",
      "operation": "task_execution|resource_allocation|state_sync",
      "phase": "implementation",
      "task": "task_789",
      "agent": "agent_003"
    },
    "details": {
      "error_message": "Task execution timeout after 15 minutes",
      "technical_details": "Agent agent_003 failed to respond to heartbeat for 15m",
      "stack_trace": "optional_stack_trace_data",
      "related_events": ["EVENT_001", "EVENT_002"]
    },
    "impact_assessment": {
      "affected_tasks": ["task_789", "task_790"],
      "affected_agents": ["agent_003"],
      "blocking_dependencies": ["task_791", "task_792"],
      "estimated_delay": "20m",
      "workflow_risk": "medium"
    },
    "recovery_suggestions": [
      {
        "strategy": "agent_reallocation",
        "description": "Reassign failed task to available agent",
        "estimated_time": "5m",
        "success_probability": 0.9
      },
      {
        "strategy": "checkpoint_rollback",
        "description": "Rollback to last stable checkpoint",
        "estimated_time": "3m",
        "success_probability": 0.95
      }
    ]
  }
}
```

## Event Types Registry

### Workflow Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `WORKFLOW_CREATED` | New workflow instantiated | workflow_definition, estimated_duration |
| `WORKFLOW_STARTED` | Workflow execution began | start_time, resource_allocation |
| `WORKFLOW_PAUSED` | Workflow execution paused | pause_reason, current_state |
| `WORKFLOW_RESUMED` | Workflow execution resumed | resume_time, state_validation |
| `WORKFLOW_COMPLETED` | Workflow finished successfully | completion_time, final_metrics |
| `WORKFLOW_FAILED` | Workflow failed and stopped | failure_reason, recovery_options |
| `WORKFLOW_CANCELLED` | Workflow cancelled by user | cancellation_reason, cleanup_status |

### Phase Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `PHASE_STARTED` | Phase execution began | phase_id, estimated_duration, resource_allocation |
| `PHASE_COMPLETED` | Phase finished successfully | phase_id, actual_duration, success_metrics |
| `PHASE_FAILED` | Phase failed | phase_id, failure_reason, partial_results |
| `PHASE_SKIPPED` | Phase skipped | phase_id, skip_reason, impact_assessment |
| `PHASE_PROGRESS` | Phase progress update | phase_id, progress_percentage, eta_update |

### Task Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `TASK_ASSIGNED` | Task assigned to agent | task_id, agent_id, estimated_duration |
| `TASK_STARTED` | Task execution began | task_id, agent_id, start_time |
| `TASK_COMPLETED` | Task finished successfully | task_id, agent_id, duration, results |
| `TASK_FAILED` | Task failed | task_id, agent_id, failure_reason, retry_count |
| `TASK_TIMEOUT` | Task exceeded time limit | task_id, agent_id, timeout_duration |
| `TASK_REASSIGNED` | Task moved to different agent | task_id, old_agent, new_agent, reason |

### Agent Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `AGENT_ALLOCATED` | Agent assigned to workflow | agent_id, workflow_id, role, capabilities |
| `AGENT_DEALLOCATED` | Agent released from workflow | agent_id, workflow_id, reason |
| `AGENT_PERFORMANCE_ALERT` | Agent performance issue | agent_id, performance_metric, threshold |
| `AGENT_ERROR` | Agent encountered error | agent_id, error_type, error_details |
| `AGENT_TIMEOUT` | Agent unresponsive | agent_id, timeout_duration, last_response |

### Resource Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `RESOURCE_ALLOCATED` | Resources assigned | allocation_id, resource_details, requester |
| `RESOURCE_DEALLOCATED` | Resources released | allocation_id, release_reason |
| `RESOURCE_CONFLICT` | Resource conflict detected | conflict_id, conflicting_requests, severity |
| `RESOURCE_THRESHOLD` | Resource usage threshold breach | resource_type, current_usage, threshold |
| `RESOURCE_OPTIMIZED` | Resource allocation optimized | optimization_type, improvement_metrics |

### System Events

| Event Type | Description | Data Requirements |
|------------|-------------|-------------------|
| `SYSTEM_STARTUP` | System component started | component_name, version, capabilities |
| `SYSTEM_SHUTDOWN` | System component stopped | component_name, shutdown_reason |
| `SYSTEM_THRESHOLD` | System threshold exceeded | metric_name, current_value, threshold |
| `SYSTEM_ERROR` | System-level error | error_type, affected_components, severity |
| `SYSTEM_MAINTENANCE` | Maintenance operation | operation_type, estimated_duration, impact |

## Communication Patterns

### Request-Response Pattern

Standard request-response communication for synchronous operations:

1. **Request Message**: Include `request_id`, `correlation_id`, and `response_required: true`
2. **Response Message**: Include matching `request_id`, `correlation_id`, and `response_to`
3. **Timeout Handling**: 30-second default timeout with exponential backoff retry
4. **Error Responses**: Use standardized error format with recovery suggestions

### Publish-Subscribe Pattern

Event-driven communication for asynchronous notifications:

1. **Event Publishing**: Use standardized event format with routing keys
2. **Subscription Management**: Components register for specific event patterns
3. **Event Filtering**: Support pattern matching and conditional delivery
4. **Dead Letter Handling**: Failed deliveries sent to dead letter queue

### State Synchronization Pattern

Consistent state management across components:

1. **State Versioning**: Include state version in all state messages
2. **Conflict Detection**: Compare state versions to detect conflicts
3. **Merge Strategies**: Predefined rules for resolving state conflicts
4. **Consensus Protocol**: Multi-component agreement on state changes

## Coordination Protocols

### Workflow Coordination Protocol

1. **Workflow Registration**
   - Coordination-hub receives workflow definition
   - Resources pre-allocated via resource-manager
   - Initial state checkpoint created
   - Event subscriptions established

2. **Execution Coordination**
   - Phase transitions coordinated through coordination-hub
   - Resource allocation/deallocation managed by resource-manager
   - Progress monitoring via workflow-status
   - Performance tracking by performance-monitor

3. **Error Coordination**
   - Errors reported to coordination-hub for impact assessment
   - Recovery strategies coordinated across components
   - State rollback managed by workflow-recovery
   - Resource cleanup handled by resource-manager

### Resource Coordination Protocol

1. **Allocation Protocol**
   ```
   Request → Resource-Manager → Conflict-Check → Allocation/Queue → Response
   ```

2. **Monitoring Protocol**
   ```
   Usage-Tracking → Performance-Monitor → Threshold-Check → Alert/Optimize
   ```

3. **Optimization Protocol**
   ```
   Performance-Data → Analysis → Optimization-Suggestions → Implementation
   ```

### Recovery Coordination Protocol

1. **Failure Detection**
   ```
   Error-Event → Impact-Assessment → Recovery-Strategy → Coordination
   ```

2. **Checkpoint Coordination**
   ```
   Checkpoint-Trigger → State-Collection → Validation → Storage → Confirmation
   ```

3. **Rollback Coordination**
   ```
   Rollback-Request → Strategy-Selection → Coordination → Execution → Validation
   ```

## Integration Standards

### Component Registration

All components MUST register with the coordination system:

```json
{
  "component_registration": {
    "component_id": "resource-manager",
    "component_type": "utility",
    "version": "1.0.0",
    "capabilities": [
      "resource_allocation",
      "conflict_detection",
      "performance_monitoring"
    ],
    "dependencies": ["coordination-hub"],
    "event_subscriptions": [
      "workflow.*.resource_request",
      "system.*.resource_threshold"
    ],
    "event_publications": [
      "resource.*.allocated",
      "resource.*.conflict_detected"
    ],
    "health_check_endpoint": "/health",
    "performance_metrics": [
      "allocation_time",
      "conflict_resolution_time",
      "resource_utilization"
    ]
  }
}
```

### Health Monitoring

All components MUST implement health monitoring:

```json
{
  "health_status": {
    "component_id": "resource-manager",
    "timestamp": "2025-01-15T12:00:00Z",
    "status": "healthy|degraded|unhealthy|unknown",
    "uptime": "2h 30m",
    "last_activity": "2025-01-15T11:59:45Z",
    "performance_metrics": {
      "response_time_avg": "1.2s",
      "success_rate": 98.5,
      "error_rate": 1.5,
      "resource_usage": {
        "memory_mb": 256,
        "cpu_percent": 12.3
      }
    },
    "active_operations": 5,
    "queue_size": 2,
    "dependencies": {
      "coordination-hub": "healthy",
      "file-system": "healthy",
      "network": "healthy"
    }
  }
}
```

### Configuration Management

Standard configuration format for all components:

```json
{
  "component_config": {
    "component_id": "resource-manager",
    "coordination": {
      "hub_endpoint": "coordination-hub",
      "heartbeat_interval": "30s",
      "event_queue_size": 1000,
      "max_retry_attempts": 3,
      "timeout_default": "30s"
    },
    "performance": {
      "max_concurrent_operations": 50,
      "resource_pool_size": 20,
      "cache_size_mb": 128,
      "optimization_interval": "5m"
    },
    "monitoring": {
      "metrics_collection": true,
      "performance_tracking": true,
      "health_check_interval": "60s",
      "alert_thresholds": {
        "response_time": "5s",
        "error_rate": 5.0,
        "memory_usage": 80.0
      }
    }
  }
}
```

## Implementation Guidelines

### Message Validation

All components MUST validate incoming messages:

1. **Schema Validation**: Verify message structure against protocol schemas
2. **Content Validation**: Validate data types, ranges, and required fields
3. **Business Logic Validation**: Check message content against business rules
4. **Security Validation**: Verify message source and authorization

### Error Handling

Standard error handling across all components:

1. **Graceful Degradation**: Continue operating with reduced functionality
2. **Retry Logic**: Implement exponential backoff with jitter
3. **Circuit Breaker**: Prevent cascade failures
4. **Error Reporting**: Use standardized error format

### Performance Requirements

All components MUST meet performance standards:

1. **Response Time**: 95th percentile under 2 seconds
2. **Throughput**: Handle minimum 100 operations per minute
3. **Availability**: 99.9% uptime during normal operations
4. **Resource Usage**: Stay within allocated resource limits

### Testing Requirements

All protocol implementations MUST include:

1. **Unit Tests**: Individual message handling functions
2. **Integration Tests**: Cross-component communication
3. **Performance Tests**: Load and stress testing
4. **Failure Tests**: Error condition and recovery testing

## Version Management

### Protocol Versioning

- **Version Format**: `MAJOR.MINOR.PATCH` (e.g., `1.2.1`)
- **Backward Compatibility**: Minor versions maintain backward compatibility
- **Breaking Changes**: Require major version increment
- **Deprecation**: 90-day notice for protocol changes

### Migration Support

- **Version Negotiation**: Components negotiate protocol version
- **Graceful Transition**: Support multiple versions during migration
- **Compatibility Matrix**: Document version compatibility
- **Migration Tools**: Provide automated migration utilities

## Compliance Verification

### Automated Testing

Regular automated verification of protocol compliance:

1. **Schema Validation**: Automated schema compliance checking
2. **Message Format**: Validation of message format standards
3. **Performance Testing**: Automated performance benchmarking
4. **Integration Testing**: Cross-component communication validation

### Monitoring and Alerting

Continuous monitoring of protocol compliance:

1. **Message Format Monitoring**: Real-time validation of message formats
2. **Performance Monitoring**: Tracking of response times and throughput
3. **Error Monitoring**: Detection of protocol violations
4. **Compliance Reporting**: Regular compliance status reports

---

This specification ensures consistent, reliable, and efficient communication across all components in the orchestration ecosystem while maintaining flexibility for future enhancements and optimizations.