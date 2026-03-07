#!/bin/bash
# Main test runner for dotfiles

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result tracking
declare -a FAILED_TESTS

# Helper functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

assert_success() {
    local test_name="$1"
    local command="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_equals() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_contains() {
    local test_name="$1"
    local haystack="$2"
    local needle="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  '$needle' not found in output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_not_contains() {
    local test_name="$1"
    local haystack="$2"
    local needle="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if ! echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  '$needle' should not be in output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

assert_file_exists() {
    local test_name="$1"
    local file_path="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [ -f "$file_path" ] || [ -L "$file_path" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# Main test execution
main() {
    clear
    print_header "🧪 Dotfiles Test Suite"
    echo ""

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Source test files
    if [ -f "$SCRIPT_DIR/test_shell_loading.sh" ]; then
        echo -e "${YELLOW}Running shell loading tests...${NC}"
        source "$SCRIPT_DIR/test_shell_loading.sh"
        echo ""
    fi

    if [ -f "$SCRIPT_DIR/test_path.sh" ]; then
        echo -e "${YELLOW}Running PATH tests...${NC}"
        source "$SCRIPT_DIR/test_path.sh"
        echo ""
    fi

    if [ -f "$SCRIPT_DIR/test_env_vars.sh" ]; then
        echo -e "${YELLOW}Running environment variable tests...${NC}"
        source "$SCRIPT_DIR/test_env_vars.sh"
        echo ""
    fi

    if [ -f "$SCRIPT_DIR/test_commands.sh" ]; then
        echo -e "${YELLOW}Running command availability tests...${NC}"
        source "$SCRIPT_DIR/test_commands.sh"
        echo ""
    fi

    # Print summary
    print_header "📊 Test Summary"
    echo ""
    echo -e "Total tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}•${NC} $test"
        done
        echo ""
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ All tests passed!${NC}"
        echo ""
        exit 0
    fi
}

# Run tests
main "$@"
