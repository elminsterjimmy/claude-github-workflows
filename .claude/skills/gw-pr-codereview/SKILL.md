# PR Code Review Workflow

Perform comprehensive code review on the current PR: fetch all changes, analyze code quality, check conventions, and add inline review comments.

## Prerequisites

Check GitHub CLI authentication:

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Input Validation

```bash
# Validate inputs before shell use
validate_branch() {
    [[ "$1" =~ ^[a-zA-Z0-9/_-]+$ ]] || { echo "Invalid branch name: $1"; exit 1; }
}

validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}

validate_path() {
    [[ "$1" =~ ^[a-zA-Z0-9/_.-]+$ ]] || { echo "Invalid path: $1"; exit 1; }
}
```

## Workflow

### Step 1: Detect Current PR

```bash
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

# Get PR info
PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,additions,deletions,changedFiles 2>/dev/null) || {
    echo "No PR found for branch: $BRANCH"
    echo "Create a PR first with /gw-work"
    exit 1
}

PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
validate_number "$PR_NUM"

PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
ADDITIONS=$(echo "$PR_INFO" | jq -r '.additions')
DELETIONS=$(echo "$PR_INFO" | jq -r '.deletions')
CHANGED_FILES=$(echo "$PR_INFO" | jq -r '.changedFiles')

echo "Reviewing PR #${PR_NUM}: $PR_TITLE"
echo "Changes: +${ADDITIONS} -${DELETIONS} across ${CHANGED_FILES} files"
```

### Step 2: Get Changed Files

```bash
# Get list of changed files with their status
FILES=$(gh pr diff "$PR_NUM" --name-only 2>/dev/null)

if [ -z "$FILES" ]; then
    echo "No files changed in PR"
    exit 0
fi

echo ""
echo "Changed files:"
echo "$FILES"
```

### Step 3: Get Full Diff

```bash
# Get the full diff for analysis
DIFF=$(gh pr diff "$PR_NUM" 2>/dev/null)

# Save diff to temporary file for analysis
DIFF_FILE="/tmp/pr-${PR_NUM}-diff.patch"
echo "$DIFF" > "$DIFF_FILE"
echo ""
echo "Diff saved to: $DIFF_FILE"
```

### Step 4: Analyze Each Changed File

For each changed file, perform code review checks:

#### Review Checklist

**General Code Quality:**
- [ ] Code follows project conventions (see CLAUDE.md, GUIDELINES.md)
- [ ] No hardcoded values that should be constants/config
- [ ] No commented-out code
- [ ] No debug print statements (unless intentional logging)
- [ ] Proper error handling
- [ ] No security vulnerabilities (SQL injection, XSS, etc.)

**Java-Specific (if applicable):**
- [ ] Follows SOLID principles
- [ ] Proper exception handling (don't catch generic Exception)
- [ ] No raw types or unchecked warnings
- [ ] Proper use of Optional instead of null checks
- [ ] Stream API used appropriately (not overused)
- [ ] Proper resource management (try-with-resources)
- [ ] Unit tests added for new functionality
- [ ] Test coverage maintained (80%+ for this project)

**Naming and Style:**
- [ ] Clear, descriptive variable/method names
- [ ] No single-letter variables (except loop counters)
- [ ] Methods are focused and not too long (< 50 lines)
- [ ] Classes have single responsibility

**Documentation:**
- [ ] Public methods have Javadoc
- [ ] Complex logic has explanatory comments
- [ ] No redundant comments (code should be self-documenting)

**Performance and Best Practices:**
- [ ] No N+1 queries or performance issues
- [ ] Appropriate data structures used
- [ ] No premature optimization
- [ ] No code duplication

### Step 5: Automated Analysis

Use tools and pattern matching to detect common issues:

```bash
# Check for common anti-patterns in diff
grep -n "System.out.println" "$DIFF_FILE" && echo "⚠️  Found debug print statements"
grep -n "TODO\|FIXME\|XXX" "$DIFF_FILE" && echo "⚠️  Found TODO/FIXME comments"
grep -n "catch (Exception" "$DIFF_FILE" && echo "⚠️  Catching generic Exception"
grep -n "@SuppressWarnings" "$DIFF_FILE" && echo "⚠️  Suppressed warnings found"

# Check for potential issues
grep -n "== null\|!= null" "$DIFF_FILE" && echo "ℹ️  Consider using Optional instead of null checks"
grep -n "new ArrayList<>()" "$DIFF_FILE" | grep -v "List<" && echo "ℹ️  Consider using interface type (List) instead of implementation"
```

### Step 6: Review GUIDELINES.md Compliance

```bash
# Check if GUIDELINES.md exists
if [ -f "GUIDELINES.md" ]; then
    echo ""
    echo "Checking GUIDELINES.md compliance..."

    # Read guidelines and check for violations
    # Example checks:

    # KISS principle - check for overly complex code
    if grep -q "AbstractFactoryBuilderSingleton" "$DIFF_FILE"; then
        echo "⚠️  Potential violation: Overly complex class names"
    fi

    # Check for deep nesting (more than 3 levels)
    if grep -E '^\+\s{12,}' "$DIFF_FILE" | head -1; then
        echo "⚠️  Deep nesting detected (>3 levels)"
    fi
fi
```

### Step 7: Analyze Test Coverage

```bash
# Check if tests were added/modified
TEST_FILES=$(echo "$FILES" | grep -E '(Test\.java|test/)' || echo "")

if [ -z "$TEST_FILES" ]; then
    echo ""
    echo "⚠️  No test files modified. Consider adding tests for new functionality."
else
    echo ""
    echo "✅ Test files modified:"
    echo "$TEST_FILES"
fi

# Run tests to verify they pass
echo ""
echo "Running tests..."
mvn test -q || {
    echo "❌ Tests failed. Fix failing tests before review."
    exit 1
}
echo "✅ All tests passing"
```

### Step 8: Generate Review Comments

Based on the analysis, generate inline review comments:

```bash
# Function to add review comment to PR
add_review_comment() {
    local file="$1"
    local line="$2"
    local body="$3"

    validate_path "$file"
    validate_number "$line"

    # Get the commit SHA for the file
    COMMIT_SHA=$(gh pr view "$PR_NUM" --json headRefOid --jq '.headRefOid')

    # Add inline comment using GitHub API
    gh api repos/{owner}/{repo}/pulls/$PR_NUM/comments \
        --method POST \
        --field body="$body" \
        --field commit_id="$COMMIT_SHA" \
        --field path="$file" \
        --field line="$line" 2>/dev/null || {
        echo "Warning: Could not add comment on $file:$line"
    }
}

# Example: Add comments for issues found
if grep -n "System.out.println" "$DIFF_FILE"; then
    echo ""
    echo "Adding review comments for debug statements..."
    # Extract file, line, and add comment
    # (This is a simplified example - actual implementation would parse diff context)
fi
```

### Step 9: Add General Review Comment

```bash
# Create review summary
REVIEW_SUMMARY=$(cat <<EOF
## Code Review Summary

**Files reviewed:** $CHANGED_FILES
**Lines changed:** +$ADDITIONS -$DELETIONS

### ✅ Strengths

- [List positive aspects found during review]

### ⚠️  Issues Found

- [List issues that should be addressed]

### 💡 Suggestions

- [List optional improvements]

### 📋 Checklist

- [ ] Code follows project conventions
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No security issues
- [ ] No performance concerns

EOF
)

# Add general PR comment
gh pr comment "$PR_NUM" --body "$REVIEW_SUMMARY"
```

### Step 10: Request Changes (if issues found)

```bash
# If critical issues found, request changes
ISSUES_FOUND=false

# Check for critical issues
if grep -q "System.out.println" "$DIFF_FILE"; then
    ISSUES_FOUND=true
fi

if [ "$ISSUES_FOUND" = true ]; then
    echo ""
    echo "❌ Critical issues found. Requesting changes..."

    # Request changes via GitHub API
    gh api repos/{owner}/{repo}/pulls/$PR_NUM/reviews \
        --method POST \
        --field event="REQUEST_CHANGES" \
        --field body="Please address the review comments before merging." 2>/dev/null || {
        echo "Note: Could not create review. Please check comments manually."
    }
else
    echo ""
    echo "✅ No critical issues found. Code looks good!"

    # Optionally approve the PR
    read -p "Approve PR? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh pr review "$PR_NUM" --approve --body "LGTM! Code quality looks good. ✅"
        echo "✅ PR approved"
    fi
fi
```

### Step 11: Output Results

```
=== PR Code Review Complete ===

PR #${PR_NUM}: ${PR_TITLE}

Files reviewed: ${CHANGED_FILES}
Changes: +${ADDITIONS} -${DELETIONS}

Issues found:
- [List of issues with file:line references]

Comments added: [count]
Review status: [APPROVED / CHANGES_REQUESTED / COMMENTED]

Next steps:
- Review inline comments on GitHub
- Address any issues found
- Re-run /gw-pr-codereview after fixes
```

## Advanced Features

### Integration with Static Analysis Tools

```bash
# Run checkstyle
if [ -f "checkstyle.xml" ]; then
    mvn checkstyle:check || echo "⚠️  Checkstyle violations found"
fi

# Run PMD
if [ -f "pmd.xml" ]; then
    mvn pmd:check || echo "⚠️  PMD violations found"
fi

# Run SpotBugs
mvn spotbugs:check || echo "⚠️  SpotBugs issues found"
```

### Check for Common Patterns

```bash
# Check for proper logging
if ! grep -q "private static final Logger" "$DIFF_FILE"; then
    if grep -q "System.out.println\|System.err.println" "$DIFF_FILE"; then
        echo "💡 Consider using proper logging framework instead of System.out"
    fi
fi

# Check for proper constant naming
if grep -E '\+.*final\s+[a-z]' "$DIFF_FILE" | grep -v 'final String\|final int\|final boolean'; then
    echo "⚠️  Constants should be UPPER_SNAKE_CASE"
fi
```

## Success Criteria

- [ ] PR detected from current branch
- [ ] All changed files analyzed
- [ ] Code quality checks performed
- [ ] GUIDELINES.md compliance verified
- [ ] Tests run successfully
- [ ] Review comments added to PR
- [ ] Review summary posted
- [ ] Review status set (APPROVED / CHANGES_REQUESTED / COMMENTED)

## Error Handling

| Error | Action |
|-------|--------|
| No PR found | "No PR for branch. Run /gw-work first" |
| Tests fail | "Tests failed. Fix before review." |
| No changed files | "No files to review" |
| API rate limit | "GitHub API rate limited. Wait and retry." |
| Cannot add comment | "Warning: Could not add comment at [location]" |

## Configuration

Optional: Create `.claude/skills/gw-pr-codereview/config.json`:

```json
{
  "autoApprove": false,
  "strictMode": true,
  "checkStyle": true,
  "maxFilesReview": 50,
  "reviewRules": {
    "requireTests": true,
    "requireDocs": true,
    "maxMethodLength": 50,
    "maxNestingDepth": 3,
    "checkNaming": true,
    "checkComplexity": true
  }
}
```

## Example Usage

```bash
# Review current PR
/gw-pr-codereview

# Review with strict mode
/gw-pr-codereview --strict

# Review and auto-approve if no issues
/gw-pr-codereview --auto-approve
```
