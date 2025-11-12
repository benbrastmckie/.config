# Argument Passing Investigation: Issue #2 Deep Dive

## Metadata
- **Date**: 2025-11-09
- **Issue**: Positional parameters ($1) not passed to bash blocks
- **Status**: ⏳ IN PROGRESS - Multiple instruction attempts
- **Complexity**: Higher than initially expected

## Problem Statement

After fixing Issue #1 (bash `!` operator bug), Issue #2 emerged: `WORKFLOW_DESCRIPTION="$1"` evaluates to empty string because bash blocks executed via the Bash tool cannot receive positional parameters.

## Root Cause

**Technical**: The Bash tool accepts only a `command` string parameter. It has no mechanism to pass positional parameters (`$1`, `$2`, etc.) to the bash code being executed.

**Required Solution**: The AI executing the slash command must manually substitute `$1` in the bash code with the actual argument value BEFORE calling the Bash tool.

## Instruction Evolution: 3 Attempts

### Attempt #1: Simple Descriptive Instruction (FAILED)
**Commit**: `69132a53`

**Instruction Given**:
```markdown
**ARGUMENT CAPTURE**: When you execute the bash block below, you MUST substitute `$1`
with the actual workflow description argument that was passed to this /coordinate command.

For example, if the command was `/coordinate "research authentication patterns"`,
replace `WORKFLOW_DESCRIPTION="$1"` with `WORKFLOW_DESCRIPTION="research authentication patterns"`
```

**Result**: ❌ AI saw and understood the instruction but didn't execute it
**Evidence**: coordinate_output.md line 140-152 shows AI saying "But I never substituted $1 as instructed"

---

### Attempt #2: Step-by-Step Procedural Instruction (FAILED)
**Commit**: `bd2b8cc4`

**Instruction Given**:
```markdown
## CRITICAL: Argument Substitution Required

**BEFORE calling the Bash tool**, you MUST perform argument substitution:

**Step 1**: Identify the workflow description argument from the user's command
**Step 2**: In the bash block below, find this line: WORKFLOW_DESCRIPTION="$1"
**Step 3**: Replace "$1" with the actual quoted workflow description

**Example**: If user ran `/coordinate "research auth"`, change:
- FROM: WORKFLOW_DESCRIPTION="$1"
- TO: WORKFLOW_DESCRIPTION="research auth"

**Now execute** the bash block WITH THE SUBSTITUTION APPLIED:
```

**Result**: ❌ AI still didn't perform substitution in practice
**Evidence**: coordinate_output.md shows continued "WORKFLOW_DESCRIPTION requires first argument" errors

**Analysis**: Instructions were more explicit but still passive. The AI reads them while in "execution mode" and proceeds directly to calling Bash without stopping to do the substitution.

---

### Attempt #3: STOP Instruction with Forced Checkpoint (IN TESTING)
**Commit**: `ad1d4542`

**Instruction Given**:
```markdown
## 🚨 STOP: Capture Workflow Description First

**DO NOT proceed to the bash block until you complete this step.**

**REQUIRED ACTION (do this RIGHT NOW before reading the bash code)**:
1. Look at the user's command invocation (scroll up if needed)
2. They ran: `/coordinate "<some workflow description text>"`
3. Extract everything between the quotes after `/coordinate`
4. Write it down explicitly: "The workflow description is: [the actual text]"

---

## Now Execute Bash With Substitution

Copy the entire bash block below, make this ONE change (replace `"$1"` with
the actual description), then call the Bash tool with your modified code:
```

**Theory**: Interrupts the execution flow with a visual STOP sign and explicit "DO NOT proceed" command. Forces the AI to consciously identify and write down the argument before seeing the bash code.

**Status**: ⏳ Awaiting user testing

---

## Why This Is Difficult

### Behavioral Challenges

1. **Execution Mode**: When the AI reads a slash command file, it's in "execution mode" - trying to complete the task efficiently. Instructions about HOW to execute are often skimmed over.

2. **Template Expectation**: The AI sees the bash code block and naturally wants to execute it as-is, treating it as a template ready to run.

3. **Context Switching**: The AI must switch from "reading instructions" mode to "editing code" mode before switching to "executing code" mode. This multi-step cognitive process is not natural.

4. **Instruction Fatigue**: The more instructions we add, the more the AI might skim over them to get to the "actual work."

### Technical Challenges

1. **No Direct Mechanism**: The Bash tool fundamentally cannot accept positional parameters. This is a tool limitation, not a code bug.

2. **Subprocess Isolation**: Each bash block runs in complete isolation. Variables, functions, and context don't persist between Bash tool calls.

3. **String Substitution Complexity**: The AI must locate specific text in a large bash block and perform precise string replacement.

## Alternative Approaches to Consider

If Attempt #3 fails, consider these alternatives:

### Option A: Pre-Substitution Text Block

Add a markdown section BEFORE the bash block where the AI writes out the substituted code:

```markdown
## Step 1: Write Your Substituted Bash Code Here

Copy the bash block below and make your substitution here (not in the template):

```bash
# Paste the entire bash block here with $1 replaced
WORKFLOW_DESCRIPTION="<paste the actual description>"
# ... rest of code
```

## Step 2: Execute What You Wrote Above

Now use the Bash tool to execute the code you wrote in Step 1 (not the template below).

## Template (DO NOT EXECUTE THIS DIRECTLY):
```bash
WORKFLOW_DESCRIPTION="$1"
...
```

### Option B: Two-Step Execution

Split into two bash blocks:

**Block 1: Capture argument** (AI substitutes here)
```bash
WORKFLOW_DESCRIPTION="<AI PASTE HERE>"
export WORKFLOW_DESCRIPTION
echo "$WORKFLOW_DESCRIPTION" > /tmp/coordinate_workflow.txt
```

**Block 2: Main logic** (reads from file)
```bash
WORKFLOW_DESCRIPTION=$(cat /tmp/coordinate_workflow.txt)
# ... rest of coordinate logic
```

### Option C: Environment Variable Instruction

Tell the AI to set an environment variable in a different way:

```markdown
Before calling the Bash tool, compose your bash command like this:

WORKFLOW_DESCRIPTION="<actual description>" bash -c '
set +H
set -euo pipefail
# ... rest of bash code using $WORKFLOW_DESCRIPTION (not $1)
'
```

### Option D: Eliminate Bash Blocks for Argument Handling

Move argument capture out of bash:

```markdown
## Capture Arguments

You invoked: `/coordinate "<description>"`

**Store this in your context**: WORKFLOW_DESCRIPTION = "<the actual description>"

## Initialize State Machine

Now call this bash block, which will read from a pre-written file:
```

Then have the AI write the description to a file using the Write tool before calling Bash.

### Option E: Request Tool Enhancement

File a feature request for the Bash tool to support argument passing:

```
Bash tool enhancement request:
- Add optional `arguments` parameter
- Arguments passed as $1, $2, etc. to the bash command
- Enables slash commands to use standard bash parameter patterns
```

## Current Recommendation

**Immediate**: Test Attempt #3 (STOP instruction approach)

**If Failed**: Implement Option B (Two-Step Execution) as it's the most pragmatic:
- Guaranteed to work (no instruction reliance)
- Minimal code changes
- Clear execution flow
- Uses proven file-based state pattern

**Long-term**: Request Option E (tool enhancement) to solve this architecturally

## Testing Validation

For any solution to be considered successful, the following must work:

```bash
/coordinate "research authentication patterns"
```

**Success Criteria**:
- ✅ No "WORKFLOW_DESCRIPTION requires first argument" error
- ✅ State machine initializes with correct workflow description
- ✅ Workflow proceeds to research phase
- ✅ Works consistently across multiple invocations

## Related Issues

- **Issue #1**: Bash `!` operator bug - ✅ FIXED
- **Issue #2**: Argument passing - ⏳ IN PROGRESS

## References

- Git commits: `69132a53`, `bd2b8cc4`, `ad1d4542`
- Output evidence: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- Original plan: `002_complete_diagnostic_and_fix.md`

---

**Status**: Iterating on instruction approaches, preparing fallback architectural solutions
**Next**: User testing of Attempt #3, consider Option B if failed
