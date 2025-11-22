#!/usr/bin/env python3
"""Gemini API PDF to Markdown converter for /convert-docs.

Uses google-genai SDK with gemini-2.5-flash-lite model.
Free tier: 60 req/min, 1000 req/day.
Cost per document: ~$0.003 with gemini-2.5-flash-lite

Usage:
    python3 convert_gemini.py <pdf_path>

Environment Variables:
    GEMINI_API_KEY: Required. Gemini API key from https://aistudio.google.com/
"""

import sys
import os
import time


def convert_pdf_to_markdown(pdf_path: str) -> str:
    """Convert PDF to markdown using Gemini API.

    Args:
        pdf_path: Path to the PDF file to convert

    Returns:
        Markdown string of the converted document

    Raises:
        SystemExit: On import error, client init error, or conversion failure
    """
    try:
        from google import genai
    except ImportError:
        print("Error: google-genai not installed. Run: pip install google-genai", file=sys.stderr)
        sys.exit(1)

    # Initialize client (uses GEMINI_API_KEY env var automatically)
    try:
        client = genai.Client()
    except Exception as e:
        print(f"Error: Failed to initialize Gemini client: {e}", file=sys.stderr)
        sys.exit(1)

    # Upload and convert
    try:
        file = client.files.upload(file=pdf_path)
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[
                file,
                "Convert this PDF to well-formatted markdown. Preserve: "
                "heading hierarchy (# ## ###), "
                "code blocks with language hints (```python, ```bash), "
                "tables as markdown tables using | separators, "
                "ordered and unordered lists, "
                "bold, italic, and inline code formatting."
            ]
        )
        return response.text
    except Exception as e:
        print(f"Error: Gemini conversion failed: {e}", file=sys.stderr)
        sys.exit(1)


def convert_with_retry(pdf_path: str, max_retries: int = 3) -> str:
    """Convert PDF with exponential backoff retry on rate limiting.

    Args:
        pdf_path: Path to the PDF file to convert
        max_retries: Maximum number of retry attempts

    Returns:
        Markdown string of the converted document, or None if all retries fail
    """
    try:
        from google import genai
    except ImportError:
        print("Error: google-genai not installed. Run: pip install google-genai", file=sys.stderr)
        sys.exit(1)

    for attempt in range(max_retries):
        try:
            return convert_pdf_to_markdown(pdf_path)
        except SystemExit as e:
            # Check if it's a rate limit error (429)
            if attempt < max_retries - 1:
                wait = 2 ** attempt  # 1, 2, 4 seconds
                print(f"Retrying in {wait}s (attempt {attempt + 1}/{max_retries})...", file=sys.stderr)
                time.sleep(wait)
            else:
                raise
    return None


def main():
    """Main entry point for CLI usage."""
    if len(sys.argv) < 2:
        print("Usage: convert_gemini.py <pdf_path>", file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]

    if not os.path.exists(pdf_path):
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    if not pdf_path.lower().endswith('.pdf'):
        print(f"Error: File is not a PDF: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    # Check file size (warn if large)
    file_size_mb = os.path.getsize(pdf_path) / (1024 * 1024)
    if file_size_mb > 50:
        print(f"Warning: Large file ({file_size_mb:.1f}MB) may take longer to process", file=sys.stderr)

    # Use retry logic for robustness
    result = convert_with_retry(pdf_path)
    if result:
        print(result)
    else:
        print("Error: Conversion failed after all retry attempts", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
