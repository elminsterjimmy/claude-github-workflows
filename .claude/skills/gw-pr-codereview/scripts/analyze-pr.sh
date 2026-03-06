#!/bin/bash
# Code review helper script for analyzing PR changes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check for common anti-patterns
check_antipatterns() {
    local diff_file="$1"
    local issues=0

    echo -e "${BLUE}Checking for common anti-patterns...${NC}"

    # Debug statements
    if grep -n "System.out.println\|System.err.println" "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Found debug print statements:${NC}"
        grep -n "System.out.println\|System.err.println" "$diff_file" | head -5
        issues=$((issues + 1))
    fi

    # TODO/FIXME comments
    if grep -n "TODO\|FIXME\|XXX" "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}ℹ️  Found TODO/FIXME comments:${NC}"
        grep -n "TODO\|FIXME\|XXX" "$diff_file" | head -5
    fi

    # Generic exception catching
    if grep -n "catch (Exception" "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Catching generic Exception:${NC}"
        grep -n "catch (Exception" "$diff_file" | head -5
        issues=$((issues + 1))
    fi

    # Suppressed warnings
    if grep -n "@SuppressWarnings" "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Suppressed warnings found:${NC}"
        grep -n "@SuppressWarnings" "$diff_file" | head -5
    fi

    # Raw types
    if grep -n "new ArrayList<>()\|new HashMap<>()" "$diff_file" | grep -v "List<\|Map<" > /dev/null 2>&1; then
        echo -e "${YELLOW}ℹ️  Consider using interface types (List/Map) instead of implementations:${NC}"
        grep -n "new ArrayList<>()\|new HashMap<>()" "$diff_file" | grep -v "List<\|Map<" | head -5
    fi

    # Null checks (suggest Optional)
    if grep -n "== null\|!= null" "$diff_file" > /dev/null 2>&1; then
        local null_checks=$(grep -c "== null\|!= null" "$diff_file" || echo 0)
        if [ "$null_checks" -gt 5 ]; then
            echo -e "${YELLOW}ℹ️  Many null checks found ($null_checks). Consider using Optional:${NC}"
            grep -n "== null\|!= null" "$diff_file" | head -3
        fi
    fi

    return $issues
}

# Function to check code complexity
check_complexity() {
    local diff_file="$1"
    local issues=0

    echo -e "${BLUE}Checking code complexity...${NC}"

    # Deep nesting (more than 3 levels = 12 spaces)
    if grep -E '^\+\s{12,}' "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Deep nesting detected (>3 levels):${NC}"
        grep -n -E '^\+\s{12,}' "$diff_file" | head -5
        issues=$((issues + 1))
    fi

    # Very long methods (heuristic: many added lines in sequence)
    local max_consecutive=0
    local current_consecutive=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\+ ]]; then
            current_consecutive=$((current_consecutive + 1))
            if [ $current_consecutive -gt $max_consecutive ]; then
                max_consecutive=$current_consecutive
            fi
        else
            current_consecutive=0
        fi
    done < "$diff_file"

    if [ $max_consecutive -gt 50 ]; then
        echo -e "${YELLOW}⚠️  Very long method detected (~$max_consecutive lines). Consider extracting methods.${NC}"
        issues=$((issues + 1))
    fi

    # Overly complex class names
    if grep -n "AbstractFactoryBuilderSingleton\|ManagerHelperUtilityFactory" "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Overly complex class names found${NC}"
        issues=$((issues + 1))
    fi

    return $issues
}

# Function to check naming conventions
check_naming() {
    local diff_file="$1"
    local issues=0

    echo -e "${BLUE}Checking naming conventions...${NC}"

    # Constants should be UPPER_SNAKE_CASE
    if grep -E '^\+.*private static final [a-z]' "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Constants should use UPPER_SNAKE_CASE:${NC}"
        grep -n -E '^\+.*private static final [a-z]' "$diff_file" | head -3
        issues=$((issues + 1))
    fi

    # Single letter variables (except i, j, k in loops)
    if grep -E '^\+.*(int|String|boolean) [a-hln-z] =' "$diff_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}ℹ️  Single-letter variable names found (consider more descriptive names):${NC}"
        grep -n -E '^\+.*(int|String|boolean) [a-hln-z] =' "$diff_file" | head -3
    fi

    return $issues
}

# Function to check for security issues
check_security() {
    local diff_file="$1"
    local issues=0

    echo -e "${BLUE}Checking for security issues...${NC}"

    # SQL concatenation (potential SQL injection)
    if grep -n "\"SELECT.*\+\|\"INSERT.*\+\|\"UPDATE.*\+\|\"DELETE.*\+" "$diff_file" > /dev/null 2>&1; then
        echo -e "${RED}❌ Potential SQL injection risk (string concatenation in SQL):${NC}"
        grep -n "\"SELECT.*\+\|\"INSERT.*\+\|\"UPDATE.*\+\|\"DELETE.*\+" "$diff_file" | head -3
        issues=$((issues + 1))
    fi

    # Hardcoded credentials
    if grep -ni "password.*=.*\"\|api.*key.*=.*\"\|secret.*=.*\"" "$diff_file" > /dev/null 2>&1; then
        echo -e "${RED}❌ Potential hardcoded credentials:${NC}"
        grep -n -i "password.*=.*\"\|api.*key.*=.*\"\|secret.*=.*\"" "$diff_file" | head -3
        issues=$((issues + 1))
    fi

    # eval() usage
    if grep -n "eval(" "$diff_file" > /dev/null 2>&1; then
        echo -e "${RED}❌ Use of eval() detected (security risk):${NC}"
        grep -n "eval(" "$diff_file"
        issues=$((issues + 1))
    fi

    return $issues
}

# Function to check test coverage
check_tests() {
    local files="$1"
    local test_files=$(echo "$files" | grep -E '(Test\.java|test/)' || echo "")

    echo -e "${BLUE}Checking test coverage...${NC}"

    if [ -z "$test_files" ]; then
        echo -e "${YELLOW}⚠️  No test files modified${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Test files modified:${NC}"
        echo "$test_files"
        return 0
    fi
}

# Main execution
main() {
    local diff_file="${1:-/tmp/pr-diff.patch}"
    local changed_files="${2:-}"

    if [ ! -f "$diff_file" ]; then
        echo -e "${RED}Error: Diff file not found: $diff_file${NC}"
        exit 1
    fi

    echo "======================================"
    echo "       PR Code Review Analysis        "
    echo "======================================"
    echo ""

    local total_issues=0

    # Run all checks
    check_antipatterns "$diff_file" || total_issues=$((total_issues + $?))
    echo ""

    check_complexity "$diff_file" || total_issues=$((total_issues + $?))
    echo ""

    check_naming "$diff_file" || total_issues=$((total_issues + $?))
    echo ""

    check_security "$diff_file" || total_issues=$((total_issues + $?))
    echo ""

    if [ -n "$changed_files" ]; then
        check_tests "$changed_files" || total_issues=$((total_issues + $?))
        echo ""
    fi

    # Summary
    echo "======================================"
    echo "           Review Summary             "
    echo "======================================"

    if [ $total_issues -eq 0 ]; then
        echo -e "${GREEN}✅ No critical issues found!${NC}"
        exit 0
    elif [ $total_issues -le 3 ]; then
        echo -e "${YELLOW}⚠️  Minor issues found: $total_issues${NC}"
        exit 0
    else
        echo -e "${RED}❌ Issues found: $total_issues${NC}"
        exit 1
    fi
}

# Run main with arguments
main "$@"
