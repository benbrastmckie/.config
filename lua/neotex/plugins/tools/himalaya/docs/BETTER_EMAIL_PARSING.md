# Better Email Parsing Approach

## Current Problem
We're manually parsing himalaya's output to separate headers from body, which is fragile and complex.

## Better Solutions

### Option 1: Use --no-headers (Recommended)
Get headers from cache and body separately:
1. We already have headers in the email cache (from, to, subject, date)
2. Use `himalaya message read --no-headers` to get just the body
3. Display cached headers + separator + body

Benefits:
- No parsing needed
- Consistent separator placement
- Headers come from the same source as the email list

### Option 2: Use -H to control headers
Specify exact headers we want:
```bash
himalaya message read -H From -H To -H Cc -H Subject -H Date <id>
```

Benefits:
- Himalaya handles the formatting
- We know exactly what headers will appear
- Can still add our own separator after the standard empty line

### Option 3: Use JSON output
```bash
himalaya message read -o json <id>
```

Benefits:
- Structured data
- No parsing needed
- Can extract headers and body precisely

## Implementation Plan

1. Modify `load_full_content_async` to use `--no-headers`
2. Update `render_preview` to always show cached headers with separator
3. Remove all the complex header detection logic
4. Body will be clean without any headers