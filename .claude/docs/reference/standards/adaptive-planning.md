## Adaptive Planning Configuration
[Used by: /plan, /expand, /implement, /revise]

### Complexity Thresholds

The following thresholds control when plans are automatically expanded or revised during creation and implementation.

- **Expansion Threshold**: 8.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 10 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 10 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)

### Adjusting Thresholds

Different projects have different complexity needs. Adjust thresholds to match your project:

**Research-Heavy Project** (detailed documentation preferred):
- Expansion Threshold: 5.0
- Task Count Threshold: 7
- File Reference Threshold: 8

**Simple Web Application** (larger inline phases acceptable):
- Expansion Threshold: 10.0
- Task Count Threshold: 15
- File Reference Threshold: 15

**Mission-Critical System** (maximum organization):
- Expansion Threshold: 3.0
- Task Count Threshold: 5
- File Reference Threshold: 5

### Threshold Ranges

- **Expansion Threshold**: 0.0 - 15.0 (recommended: 3.0 - 12.0)
- **Task Count Threshold**: 5 - 20 (recommended: 5 - 15)
- **File Reference Threshold**: 5 - 30 (recommended: 5 - 20)
- **Replan Limit**: 1 - 5 (recommended: 1 - 3)
