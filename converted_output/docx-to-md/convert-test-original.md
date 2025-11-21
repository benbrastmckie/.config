# Complex Document Conversion Test

## Purpose

This document tests bidirectional conversion between Markdown, PDF, and DOCX formats. It includes various formatting elements to verify conversion fidelity.

## Text Formatting

This paragraph includes **bold text**, *italic text*, ***bold and italic***, inline code, and ~~strikethrough~~ formatting.

### Lists

#### Unordered List

* First item
* Second item with **bold**
  + Nested item one
  + Nested item two
    - Deep nested item
* Third item with code

#### Ordered List

1. First numbered item
2. Second numbered item
   1. Nested numbered item
   2. Another nested item
3. Third numbered item

### Code Blocks

Here’s a bash code block:

#!/bin/bash
source "$CLAUDE\_LIB/core/error-handling.sh"

function test\_conversion() {
 local input\_file="$1"
 echo "Processing: $input\_file"
 return 0
}

And a Python example:

def calculate\_complexity(code\_lines):
 """Calculate cyclomatic complexity."""
 complexity = 1
 for line in code\_lines:
 if line.strip().startswith('if '):
 complexity += 1
 return complexity

### Tables

| Feature | Markdown | PDF | DOCX |
| --- | --- | --- | --- |
| Headers | ✓ | ✓ | ✓ |
| Lists | ✓ | ✓ | ✓ |
| Code | ✓ | ~ | ~ |
| Tables | ✓ | ✓ | ✓ |

### Blockquotes

This is a blockquote with **bold text**.

It can span multiple paragraphs.

And even be nested.

### Horizontal Rules

Below is a horizontal rule:

Above was a horizontal rule.

### Links and References

Here’s an inline link to [Claude Code Documentation](.claude/docs/README.md).

Here’s a reference-style link to [Google](https://www.google.com).

### Special Characters and Escaping

Special characters: & < > ” ’

Escaped characters: \* \_ ` [ ]

Mathematical notation: E = mc²

Unicode symbols: → ← ↔ ✓ ✗ ⚠

### Nested Formatting

This paragraph contains **bold with *italic inside* and code** as well as *italic with* ***bold inside*** *and code*.

## Complex Scenarios

### Mixed Content Block

1. **Step One**: Initialize the system

* ./initialize.sh --verbose
* This command sets up the environment.

1. **Step Two**: Run tests
   * Unit tests
   * Integration tests
   * E2E tests
2. **Step Three**: Review results

| Test Type | Passed | Failed |
| --- | --- | --- |
| Unit | 45 | 2 |
| Integration | 23 | 1 |
| E2E | 12 | 0 |

### Definition Lists

Term 1

Definition for term 1

Term 2

Definition for term 2 with **bold**

Alternative definition

## Edge Cases

### Empty Lines and Spacing

This paragraph has normal spacing.

This paragraph has extra spacing above.

### Long Lines

This is a very long line that should wrap properly in all formats and maintain readability regardless of the output format whether it’s PDF, DOCX, or Markdown and should handle various screen sizes and page widths appropriately.

### Inline HTML (if supported)

This is HTML content

### Special List Scenarios

* Item with continuation on multiple lines
* Another item

## Conclusion

This document tests comprehensive conversion scenarios including:

1. Text formatting (bold, italic, code, strikethrough)
2. Lists (ordered, unordered, nested)
3. Code blocks with syntax highlighting
4. Tables with alignment
5. Blockquotes (simple and nested)
6. Links (inline and reference)
7. Special characters and Unicode
8. Horizontal rules
9. Mixed content blocks
10. Edge cases and spacing

**End of Test Document**
