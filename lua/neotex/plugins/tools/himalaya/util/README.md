# Himalaya Utilities and Diagnostics

A comprehensive suite of diagnostic tools to help users understand and troubleshoot their Himalaya email client configuration.

## Overview

The `util/` directory contains modular diagnostic tools that can identify and help resolve common Himalaya configuration issues, particularly with Gmail IMAP settings, mbsync configuration, and email operations.

## Quick Start

### Most Common Commands

```vim
:HimalayaQuickHealthCheck      " Quick overview of system health
:HimalayaFullDiagnostics      " Complete diagnostic suite
:HimalayaTestDelete           " Test delete operation (most common issue)
```

### Focused Diagnostics

```vim
:HimalayaCheckGmailSettings   " Verify Gmail IMAP settings
:HimalayaAnalyzeMbsync        " Analyze mbsync configuration
:HimalayaTestFolderAccess     " Test folder detection
```

## Diagnostic Modules

### 1. Complete Diagnostics (`diagnostics.lua`)

**Purpose**: Master diagnostic orchestrator that runs comprehensive analysis.

**Key Functions**:
- `run_full_diagnostics()` - Complete 5-phase diagnostic suite
- `quick_health_check()` - Fast health status overview
- `show_diagnostic_commands()` - Reference guide for all commands

**When to Use**: 
- First-time setup issues
- General troubleshooting
- When multiple systems seem broken

**Commands**:
- `:HimalayaFullDiagnostics` - Run complete analysis
- `:HimalayaQuickHealthCheck` - Quick status check
- `:HimalayaDiagnosticCommands` - Show command reference

### 2. Gmail Settings (`gmail_settings.lua`)

**Purpose**: Guide users through Gmail web interface settings verification.

**Key Functions**:
- `check_gmail_settings()` - Step-by-step Gmail IMAP settings guide
- `explain_gmail_imap()` - Detailed explanation of Gmail IMAP behavior
- `interactive_troubleshooting()` - Interactive Q&A troubleshooting

**When to Use**:
- Missing trash/spam folders
- "Show in IMAP" setting issues
- Gmail-specific authentication problems
- Understanding Gmail's label system

**Commands**:
- `:HimalayaCheckGmailSettings` - Settings verification guide
- `:HimalayaExplainGmailIMAP` - Explain Gmail IMAP behavior
- `:HimalayaTroubleshootGmail` - Interactive troubleshooting

### 3. mbsync Analyzer (`mbsync_analyzer.lua`)

**Purpose**: Analyze and diagnose mbsync configuration files.

**Key Functions**:
- `analyze_mbsync_config()` - Parse and analyze ~/.mbsyncrc
- `show_example_config()` - Display example Gmail configuration
- `provide_recommendations()` - Suggest configuration fixes

**When to Use**:
- Configuration file errors
- Missing channel definitions
- Folder sync issues
- Pattern exclusion problems

**Commands**:
- `:HimalayaAnalyzeMbsync` - Analyze current configuration
- `:HimalayaShowExampleConfig` - Show example Gmail setup

**Analysis Features**:
- Detects Gmail stores and channels
- Identifies missing trash folder configuration
- Flags problematic exclusion patterns
- Provides specific configuration recommendations

### 4. Folder Diagnostics (`folder_diagnostics.lua`)

**Purpose**: Test folder access, detection, and structure analysis.

**Key Functions**:
- `test_folder_access()` - Test Himalaya's folder detection
- `compare_folder_structure()` - Compare expected vs actual Gmail folders
- `test_folder_operations()` - Test folder listing and email access

**When to Use**:
- Folders not appearing in Himalaya
- Sync status verification
- Expected folder structure validation

**Commands**:
- `:HimalayaTestFolderAccess` - Test folder detection
- `:HimalayaCompareFolders` - Compare folder structures
- `:HimalayaTestFolderOps` - Test folder operations

**Analysis Output**:
- Categorizes folders (system vs custom)
- Identifies missing standard folders
- Provides folder-specific recommendations

### 5. Operation Tester (`operation_tester.lua`)

**Purpose**: Test email operations like delete, move, flag, and retrieval.

**Key Functions**:
- `test_delete_operation()` - Test delete operation on current email
- `test_move_operation()` - Test moving emails to specific folders
- `test_flag_operations()` - Test read/star/flag operations
- `run_comprehensive_test()` - Test all operations systematically

**When to Use**:
- Delete operations failing
- Email operations not working
- Verifying functionality after fixes
- Performance testing

**Commands**:
- `:HimalayaTestDelete` - Test delete on current email
- `:HimalayaTestMove <folder>` - Test move to specified folder
- `:HimalayaTestFlags` - Test flag operations
- `:HimalayaTestRetrieval` - Test email/folder retrieval
- `:HimalayaTestAll` - Comprehensive operation testing

## Troubleshooting Workflows

### 1. Delete Operation Not Working

```vim
:HimalayaTestDelete           " Identify specific error
:HimalayaTestFolderAccess     " Check if trash folder exists
:HimalayaCheckGmailSettings   " Verify Gmail IMAP settings
:HimalayaAnalyzeMbsync        " Check configuration
```

### 2. Missing Folders

```vim
:HimalayaCompareFolders       " See what's missing
:HimalayaCheckGmailSettings   " Check "Show in IMAP" settings
:HimalayaAnalyzeMbsync        " Check sync configuration
```

### 3. General Setup Issues

```vim
:HimalayaQuickHealthCheck     " Quick overview
:HimalayaFullDiagnostics      " Complete analysis if issues found
```

### 4. Gmail-Specific Problems

```vim
:HimalayaTroubleshootGmail    " Interactive Gmail troubleshooting
:HimalayaExplainGmailIMAP     " Understand Gmail's IMAP behavior
```

## Common Issues and Solutions

### Issue: "No trash folder found"
**Diagnostic**: `:HimalayaTestDelete`
**Likely Causes**:
1. Gmail "Show in IMAP" disabled for Trash
2. Missing trash channel in mbsync config
3. Folder named differently than expected

**Solutions**:
1. Enable "Show in IMAP" in Gmail settings
2. Add trash channel to mbsync configuration
3. Use All Mail as workaround

### Issue: No folders visible in Himalaya
**Diagnostic**: `:HimalayaTestFolderAccess`
**Likely Causes**:
1. Account not configured
2. mbsync hasn't been run
3. Authentication issues

**Solutions**:
1. Run `mbsync -a`
2. Check account configuration
3. Verify authentication credentials

### Issue: Some Gmail folders missing
**Diagnostic**: `:HimalayaCompareFolders`
**Likely Causes**:
1. Gmail "Show in IMAP" settings
2. mbsync patterns excluding folders
3. Non-standard Gmail setup

**Solutions**:
1. Check all "Show in IMAP" settings in Gmail
2. Review mbsync patterns
3. Add specific channels for missing folders

## Integration with Main Plugin

The diagnostic tools are automatically integrated with the main Himalaya plugin. All commands are available immediately after plugin load.

### Manual Setup (if needed)
```lua
local himalaya_util = require('neotex.plugins.tools.himalaya.util')
himalaya_util.setup_commands()
```

### Programmatic Access
```lua
local diagnostics = require('neotex.plugins.tools.himalaya.util.diagnostics')
local results = diagnostics.run_full_diagnostics()

-- Or use specific modules
local gmail = require('neotex.plugins.tools.himalaya.util.gmail_settings')
gmail.check_gmail_settings()
```

## Output Interpretation

### Diagnostic Symbols
- ✅ **Success/Found/Working**
- ❌ **Failed/Missing/Broken** 
- ⚠️  **Warning/Attention needed**
- 💡 **Recommendation/Tip**
- 🚨 **Critical issue requiring immediate attention**

### Health Check Scoring
- **75-100%**: Healthy - minor issues at most
- **50-74%**: Issues detected - some functionality impaired
- **0-49%**: Critical issues - major functionality problems

## Advanced Usage

### Custom Diagnostic Workflows
```lua
-- Focus on delete issues only
local util = require('neotex.plugins.tools.himalaya.util')
util.diagnose_delete_issues()

-- Gmail-specific analysis
util.diagnose_gmail_issues()
```

### Configuration Analysis
```lua
local mbsync = require('neotex.plugins.tools.himalaya.util.mbsync_analyzer')
local analysis = mbsync.analyze_mbsync_config()
-- Returns detailed configuration structure
```

### Folder Structure Validation
```lua
local folders = require('neotex.plugins.tools.himalaya.util.folder_diagnostics')
local current_folders = folders.test_folder_access()
-- Returns list of currently accessible folders
```

## Contributing

When adding new diagnostic features:

1. **Modular Design**: Create focused modules for specific functionality
2. **Clear Output**: Use consistent symbols and formatting
3. **Actionable Recommendations**: Always provide next steps
4. **Error Handling**: Gracefully handle missing files/permissions
5. **Documentation**: Update this README with new commands

## Navigation
- [← Back to Himalaya Main](../README.md)
- [Configuration Guide](../config.lua)
- [UI Documentation](../ui.lua)