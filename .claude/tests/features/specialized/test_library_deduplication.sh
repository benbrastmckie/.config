#!/usr/bin/env bash
# test_library_deduplication.sh - Test library deduplication logic
# This test verifies the array deduplication functionality in library-sourcing.sh

echo "Library Deduplication Tests"
echo "============================"

test_count=0
pass_count=0
fail_count=0

# Helper: run test and check result
run_test() {
  local name="$1"
  local expected="$2"
  shift 2
  local args=("$@")

  ((test_count++))

  # Deduplication logic
  local unique_libs=()
  local seen=" "
  for lib in "${args[@]}"; do
    if [[ ! " $seen " =~ " $lib " ]]; then
      unique_libs+=("$lib")
      seen="$seen$lib "
    fi
  done

  local result="${unique_libs[*]}"
  if [[ "$result" == "$expected" ]]; then
    echo "  ✓ Test $test_count: $name"
    ((pass_count++))
  else
    echo "  ✗ Test $test_count: $name"
    echo "    Expected: $expected"
    echo "    Got: $result"
    ((fail_count++))
  fi
}

# Run all tests
run_test "Removes exact duplicates" "lib1 lib2 lib3" "lib1" "lib2" "lib1" "lib3" "lib2"
run_test "Preserves load order" "libA libB libC" "libA" "libB" "libA" "libC"
run_test "All unique preserved" "one two three" "one" "two" "three"
run_test "Mixed duplicates" "a b c d e" "a" "b" "c" "b" "d" "a" "e"
run_test "Empty list" ""
run_test "Single library" "single" "single"
run_test "All duplicates" "same" "same" "same" "same" "same" "same"

echo ""
echo "Summary"
echo "======"
echo "Passed: $pass_count/$test_count"
echo "Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
