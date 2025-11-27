#!/usr/bin/env bash
#
# test_convert_docs_validation.sh - Test input validation in convert-core.sh
#
# Tests validation features:
#   - Magic number verification (DOCX, PDF, Markdown)
#   - Empty file detection
#   - Wrong extension handling
#   - Corrupted file detection
#   - Binary file rejection for text formats
#   - Validation counter tracking
#

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Detect project root using git or walk-up pattern
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi

# Script path
SCRIPT_PATH="${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"

# Test directory
TEST_DIR="/tmp/convert-docs-test-$$"
TEST_INPUT="$TEST_DIR/input"
TEST_OUTPUT="$TEST_DIR/output"

#
# setup_test_env - Create test environment
#
setup_test_env() {
  mkdir -p "$TEST_INPUT"
  mkdir -p "$TEST_OUTPUT"
}

#
# cleanup_test_env - Remove test environment
#
cleanup_test_env() {
  rm -rf "$TEST_DIR"
}

#
# run_test - Run a single test
#
# Arguments:
#   $1 - Test description
#   $2 - Test function name
#
run_test() {
  local description="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_func; then
    echo -e "${GREEN}✓${NC} PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAIL: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

#
# create_empty_file - Create empty file with extension
#
# Arguments:
#   $1 - Filename with extension
#
create_empty_file() {
  local filename="$1"
  touch "$TEST_INPUT/$filename"
}

#
# create_valid_docx - Create minimal valid DOCX file
#
# Arguments:
#   $1 - Filename (without extension)
#
create_valid_docx() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.docx"

  # Create minimal DOCX structure (ZIP file)
  mkdir -p "$TEST_DIR/docx_temp"
  echo '<?xml version="1.0"?><document><body><p>Test</p></body></document>' > "$TEST_DIR/docx_temp/document.xml"
  (cd "$TEST_DIR/docx_temp" && zip -q "$filepath" document.xml)
  rm -rf "$TEST_DIR/docx_temp"
}

#
# create_valid_pdf - Create minimal valid PDF file
#
# Arguments:
#   $1 - Filename (without extension)
#
create_valid_pdf() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.pdf"

  # Create minimal PDF with correct magic number
  cat > "$filepath" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Count 1 /Kids [3 0 R] >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT
/F1 12 Tf
100 700 Td
(Test content) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000190 00000 n
trailer
<< /Size 5 /Root 1 0 R >>
startxref
283
%%EOF
EOF
}

#
# create_valid_markdown - Create valid Markdown file
#
# Arguments:
#   $1 - Filename (without extension)
#
create_valid_markdown() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.md"

  cat > "$filepath" << 'EOF'
# Test Document

This is a test markdown file.

## Features

- Item 1
- Item 2
- Item 3
EOF
}

#
# create_corrupted_pdf - Create PDF with wrong magic number
#
# Arguments:
#   $1 - Filename (without extension)
#
create_corrupted_pdf() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.pdf"

  # Write invalid magic number (should be %PDF-)
  echo "INVALID PDF CONTENT" > "$filepath"
}

#
# create_wrong_extension_file - Create DOCX file named as PDF
#
# Arguments:
#   $1 - Filename (without extension)
#
create_wrong_extension_file() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.pdf"

  # Create valid DOCX but with .pdf extension
  mkdir -p "$TEST_DIR/docx_temp"
  echo '<?xml version="1.0"?><document><body><p>Test</p></body></document>' > "$TEST_DIR/docx_temp/document.xml"
  (cd "$TEST_DIR/docx_temp" && zip -q "$filepath" document.xml)
  rm -rf "$TEST_DIR/docx_temp"
}

#
# create_binary_as_markdown - Create binary file with .md extension
#
# Arguments:
#   $1 - Filename (without extension)
#
create_binary_as_markdown() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.md"

  # Write binary content to .md file
  dd if=/dev/urandom bs=1024 count=1 of="$filepath" 2>/dev/null
}

#
# test_empty_file_rejection - Test that empty files are rejected
#
test_empty_file_rejection() {
  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create empty DOCX file
  create_empty_file "empty.docx"

  # Run conversion
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that empty file was skipped
  echo "$output" | grep -q "Skipping invalid DOCX file: empty.docx" || \
  echo "$output" | grep -q "Empty file"
}

#
# test_corrupted_pdf_rejection - Test that corrupted PDFs are rejected
#
test_corrupted_pdf_rejection() {
  # Skip if validation tools not available
  if ! command -v xxd &>/dev/null && ! command -v file &>/dev/null; then
    echo "  (Skipping - no validation tools available)"
    return 0
  fi

  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create corrupted PDF
  create_corrupted_pdf "corrupted"

  # Run conversion
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that corrupted PDF was skipped
  echo "$output" | grep -q "Skipping invalid PDF file: corrupted.pdf" || \
  echo "$output" | grep -q "Invalid PDF magic number"
}

#
# test_wrong_extension_rejection - Test that files with wrong extensions are rejected
#
test_wrong_extension_rejection() {
  # Skip if validation tools not available
  if ! command -v xxd &>/dev/null && ! command -v file &>/dev/null; then
    echo "  (Skipping - no validation tools available)"
    return 0
  fi

  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create DOCX file with .pdf extension
  create_wrong_extension_file "wrong_ext"

  # Run conversion
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that wrong extension file was skipped
  echo "$output" | grep -q "Skipping invalid PDF file: wrong_ext.pdf" || \
  echo "$output" | grep -q "Invalid PDF magic number"
}

#
# test_binary_markdown_rejection - Test that binary files with .md extension are rejected
#
test_binary_markdown_rejection() {
  # Skip if file command not available
  if ! command -v file &>/dev/null; then
    echo "  (Skipping - file command not available)"
    return 0
  fi

  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create binary file with .md extension
  create_binary_as_markdown "binary"

  # Run conversion
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that binary markdown was skipped
  echo "$output" | grep -q "Skipping invalid Markdown file: binary.md" || \
  echo "$output" | grep -q "Non-text file for Markdown"
}

#
# test_valid_files_accepted - Test that valid files are accepted
#
test_valid_files_accepted() {
  # Skip if zip command not available (needed to create DOCX)
  if ! command -v zip &>/dev/null; then
    echo "  (Skipping - zip command not available)"
    return 0
  fi

  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create valid files
  create_valid_docx "valid_doc"
  create_valid_pdf "valid_pdf"
  create_valid_markdown "valid_md"

  # Run in dry-run mode to check file discovery
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" --dry-run 2>&1)

  # Check that all valid files are discovered
  echo "$output" | grep -q "valid_doc.docx" && \
  echo "$output" | grep -q "valid_pdf.pdf" && \
  echo "$output" | grep -q "valid_md.md"
}

#
# test_validation_counter - Test validation failure counter
#
test_validation_counter() {
  # Clean test environment
  rm -rf "$TEST_INPUT" "$TEST_OUTPUT"
  mkdir -p "$TEST_INPUT" "$TEST_OUTPUT"

  # Create 2 invalid files (empty files are always caught) and 1 valid file
  create_empty_file "empty.docx"
  create_empty_file "empty2.pdf"
  create_valid_markdown "valid"

  # Run conversion
  local output
  output=$("$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" 2>&1 || true)

  # Check that summary shows validation failures (at least 2 empty files skipped)
  echo "$output" | grep -q "Validation.*files skipped" || \
  echo "$output" | grep -q "2.*skipped" || \
  echo "$output" | grep -q "Skipping invalid"
}

#
# test_validate_function_exists - Test that validate_input_file function exists
#
test_validate_function_exists() {
  # Check that validate_input_file function is defined
  grep -q "^validate_input_file()" "$SCRIPT_PATH" || \
  grep -q "^validate_input_file ()" "$SCRIPT_PATH"
}

#
# test_validation_failures_variable - Test that validation_failures variable exists
#
test_validation_failures_variable() {
  # Check that validation_failures variable is initialized
  grep -q "validation_failures=" "$SCRIPT_PATH"
}

#
# test_magic_number_check_docx - Test DOCX magic number check
#
test_magic_number_check_docx() {
  # Check that DOCX validation includes magic number check
  grep -q "504B" "$SCRIPT_PATH"
}

#
# test_magic_number_check_pdf - Test PDF magic number check
#
test_magic_number_check_pdf() {
  # Check that PDF validation includes magic number check
  grep -q "25504446" "$SCRIPT_PATH" || grep -q "%PDF-" "$SCRIPT_PATH"
}

#
# main - Run all tests
#
main() {
  echo "======================================"
  echo "Input Validation Tests - Phase 3.1"
  echo "======================================"
  echo ""

  # Setup
  setup_test_env
  trap cleanup_test_env EXIT

  # Test 1: validate_input_file function exists
  run_test "validate_input_file function present" test_validate_function_exists

  # Test 2: validation_failures variable exists
  run_test "validation_failures variable initialized" test_validation_failures_variable

  # Test 3: DOCX magic number check
  run_test "DOCX magic number check (504B)" test_magic_number_check_docx

  # Test 4: PDF magic number check
  run_test "PDF magic number check (25504446)" test_magic_number_check_pdf

  # Test 5: Empty file rejection
  run_test "Empty file rejection" test_empty_file_rejection

  # Test 6: Corrupted PDF rejection
  run_test "Corrupted PDF rejection" test_corrupted_pdf_rejection

  # Test 7: Wrong extension rejection
  run_test "Wrong extension rejection" test_wrong_extension_rejection

  # Test 8: Binary markdown rejection
  run_test "Binary markdown rejection" test_binary_markdown_rejection

  # Test 9: Valid files accepted
  run_test "Valid files accepted" test_valid_files_accepted

  # Test 10: Validation counter tracking
  run_test "Validation counter tracking" test_validation_counter

  # Summary
  echo ""
  echo "======================================"
  echo "Test Summary"
  echo "======================================"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "Tests failed: $TESTS_FAILED"
    echo ""
    echo -e "${GREEN}All Phase 3.1 validation tests passed!${NC}"
    exit 0
  fi
}

# Check if convert-core.sh exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Error: convert-core.sh not found at $SCRIPT_PATH"
  exit 1
fi

# Run tests
main
