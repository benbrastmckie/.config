#!/usr/bin/env bash
#
# test_convert_docs_filenames.sh - Test filename safety in convert-core.sh
#
# Tests that special characters in filenames are handled correctly:
#   - Spaces
#   - Single quotes
#   - Double quotes (escaped)
#   - Semicolons
#   - Dollar signs
#   - Unicode characters
#   - Emoji
#

set -eu

# Check for required dependencies
if ! command -v zip >/dev/null 2>&1; then
  echo "SKIP: zip command not available (required for DOCX file creation)"
  exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script path
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/convert/convert-core.sh"

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
# create_test_docx - Create minimal valid DOCX file
#
# Arguments:
#   $1 - Filename (without .docx extension)
#
create_test_docx() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.docx"

  # Create a minimal ZIP file that mimics DOCX structure
  # Real DOCX is a ZIP with specific XML files, but for testing we just need
  # a file that can be detected as DOCX-like
  mkdir -p "$TEST_DIR/docx_temp"
  echo '<?xml version="1.0"?><document><body><p>Test content</p></body></document>' > "$TEST_DIR/docx_temp/document.xml"

  # Create ZIP (DOCX is a ZIP file)
  (cd "$TEST_DIR/docx_temp" && zip -q "$filepath" document.xml)
  rm -rf "$TEST_DIR/docx_temp"
}

#
# create_test_pdf - Create minimal PDF file
#
# Arguments:
#   $1 - Filename (without .pdf extension)
#
create_test_pdf() {
  local filename="$1"
  local filepath="$TEST_INPUT/${filename}.pdf"

  # Create minimal PDF header
  cat > "$filepath" << 'EOF'
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Count 1
/Kids [3 0 R]
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Contents 4 0 R
>>
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
<<
/Size 5
/Root 1 0 R
>>
startxref
283
%%EOF
EOF
}

#
# run_test - Run a single filename test
#
# Arguments:
#   $1 - Test description
#   $2 - Filename (without extension)
#   $3 - File extension (docx or pdf)
#
run_test() {
  local description="$1"
  local filename="$2"
  local extension="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  # Clean output directory
  rm -rf "$TEST_OUTPUT"
  mkdir -p "$TEST_OUTPUT"

  # Create test file
  if [[ "$extension" == "docx" ]]; then
    create_test_docx "$filename"
  elif [[ "$extension" == "pdf" ]]; then
    create_test_pdf "$filename"
  fi

  # Run conversion (capture output and errors)
  local exit_code=0
  "$SCRIPT_PATH" "$TEST_INPUT" "$TEST_OUTPUT" > "$TEST_DIR/output.log" 2>&1 || exit_code=$?

  # Check if conversion succeeded
  local expected_output="$TEST_OUTPUT/${filename}.md"

  if [[ -f "$expected_output" ]]; then
    echo -e "${GREEN}✓${NC} PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAIL: $description"
    echo "  Expected output: $expected_output"
    echo "  Output directory contents:"
    ls -la "$TEST_OUTPUT" 2>&1 | sed 's/^/    /'
    echo "  Conversion log:"
    tail -10 "$TEST_DIR/output.log" 2>&1 | sed 's/^/    /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

#
# main - Run all tests
#
main() {
  echo "======================================"
  echo "Filename Safety Tests"
  echo "======================================"
  echo ""

  # Setup
  setup_test_env
  trap cleanup_test_env EXIT

  # Test 1: Simple filename (baseline)
  run_test "Simple filename" "simple" "docx"

  # Test 2: Filename with spaces
  run_test "Filename with spaces" "with spaces" "docx"

  # Test 3: Filename with single quote
  run_test "Filename with single quote" "with'quote" "docx"

  # Test 4: Filename with semicolon
  run_test "Filename with semicolon" "with;semicolon" "docx"

  # Test 5: Filename with dollar sign
  run_test "Filename with dollar sign" "with\$dollar" "docx"

  # Test 6: Filename with parentheses
  run_test "Filename with parentheses" "with(parens)" "docx"

  # Test 7: Filename with ampersand
  run_test "Filename with ampersand" "with&ampersand" "docx"

  # Test 8: Unicode filename (Chinese characters)
  run_test "Unicode filename (Chinese)" "文档" "docx"

  # Test 9: Unicode filename (Japanese characters)
  run_test "Unicode filename (Japanese)" "書類" "docx"

  # Test 10: Filename with emoji
  run_test "Filename with emoji" "document_🎉" "docx"

  # Test 11: PDF with spaces
  run_test "PDF with spaces" "pdf with spaces" "pdf"

  # Test 12: PDF with special characters
  run_test "PDF with special chars" "report_2024(final)" "pdf"

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
    echo -e "${GREEN}All tests passed!${NC}"
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
