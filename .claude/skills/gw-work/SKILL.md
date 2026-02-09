---
name: gw-work
description: Implement a planned feature, creating a feature branch and PR linked to the tracking issue.
---

# Work Workflow

Implement a planned feature, creating a feature branch and PR linked to the tracking issue.

## Prerequisites

Check GitHub CLI authentication and working tree:

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }

# Check for clean working tree (optional - can skip if user wants)
if ! git diff --quiet HEAD 2>/dev/null; then
    echo "Warning: Uncommitted changes detected."
    echo "Consider committing or stashing before starting new work."
fi
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

validate_slug() {
    [[ "$1" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid slug: $1"; exit 1; }
}
```

## Label Helpers

```bash
# Create label if it doesn't exist
ensure_label() {
    local label="$1"
    local color="${2:-ededed}"
    gh label list --search "$label" --json name --jq '.[].name' 2>/dev/null | grep -qx "$label" || \
        gh label create "$label" --color "$color" 2>/dev/null || true
}

# Ensure required labels exist
ensure_label "in-progress" "FBCA04"
ensure_label "claude-code" "7C3AED"
```

## Workflow

### Step 1: Detect Active Issue

Find the issue to implement:

```bash
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")

# If no issue from branch, check for planned issues
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label planned --limit 1 --json number --jq '.[0].number' 2>/dev/null)
fi

if [ -z "$ISSUE" ]; then
    echo "No planned issue found."
    echo "Provide issue number or run /gw-plan first."
    exit 1
fi

validate_number "$ISSUE"

# Verify issue exists
if ! gh issue view "$ISSUE" &>/dev/null; then
    echo "Issue #$ISSUE not found on GitHub"
    exit 1
fi

ISSUE_TITLE=$(gh issue view "$ISSUE" --json title --jq '.title')
echo "Working on: $ISSUE_TITLE"
```

### Step 2: Create Feature Branch (if needed)

```bash
# Generate branch name from issue
CLEAN_TITLE=$(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //' | sed 's/^feat: //')
SLUG=$(echo "$CLEAN_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-30)
EXPECTED_BRANCH="feat/${ISSUE}-${SLUG}"

# Validate branch name before git operations
validate_branch "$EXPECTED_BRANCH"

# Check if already on correct branch
if [ "$BRANCH" = "$EXPECTED_BRANCH" ]; then
    echo "Already on branch: $BRANCH"
elif [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    # Create new branch from main
    git checkout -b "$EXPECTED_BRANCH" || {
        echo "Error: Failed to create branch."
        exit 1
    }
    echo "Created branch: $EXPECTED_BRANCH"
else
    echo "Currently on: $BRANCH"
    echo "Expected: $EXPECTED_BRANCH"
    echo "Continue on current branch or switch?"
fi
```

### Step 3: Implement Feature

Execute the implementation based on the plan:

1. Read the plan document from `docs/plans/` for implementation details
2. Follow the implementation phases defined in the plan
3. Write code following existing patterns in the codebase
4. Add tests for new functionality
5. Run tests to verify changes

### Step 4: Commit Changes

```bash
# Stage changes (be specific, don't use -A blindly)
git add <relevant-files>

# Commit with conventional message
git commit -m "feat: implement #${ISSUE}

Implements the feature as specified in the plan.

Closes #${ISSUE}"
```

### Step 5: Push to Remote

```bash
git push -u origin "$BRANCH" || {
    echo "Error: Failed to push. Check remote access."
    exit 1
}
```

### Step 6: Create Pull Request

```bash
# Get clean title for PR
PR_TITLE="feat: $(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //' | sed 's/^feat: //')"

PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --label "claude-code" \
    --body "Closes #${ISSUE}

## Summary

[Describe what was implemented]

## Changes

- [List key changes]

## Testing

- [ ] Tests pass locally
- [ ] Manual verification completed

## Checklist

- [ ] Code follows project conventions
- [ ] Tests added for new functionality
- [ ] Documentation updated if needed" \
    --head "$BRANCH") || {
    echo "Error: Failed to create PR. Check: gh auth status"
    exit 1
}

# Extract PR number
PR_NUM=$(echo "$PR_URL" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+')
validate_number "$PR_NUM"

echo "Created PR #${PR_NUM}: $PR_URL"
```

### Step 7: Update Issue Labels

```bash
# Add in-progress label to issue
gh issue edit "$ISSUE" --add-label "in-progress" --add-label "claude-code" 2>/dev/null || true

# Remove planned label
gh issue edit "$ISSUE" --remove-label "planned" 2>/dev/null || true
```

### Step 8: Output Results

```
Implementation complete!

PR: #{PR_NUM}
URL: {PR_URL}
Issue: #{ISSUE}
Branch: {BRANCH}

Labels: in-progress, claude-code

Next step: Wait for review, then run /gw-review
```

## Success Criteria

- [ ] Issue detected from branch or user input
- [ ] Feature branch created following naming convention
- [ ] Implementation completed per plan
- [ ] Changes committed with conventional message
- [ ] PR created with `claude-code` label and linked to issue
- [ ] Issue labels updated to `in-progress`
- [ ] User knows next step is `/gw-review`

## Error Handling

| Error | Action |
|-------|--------|
| No issue found | "No planned issue. Provide number or run /gw-plan" |
| Branch creation fails | "Error: Failed to create branch. Check for conflicts." |
| Push fails | "Error: Failed to push. Check remote access." |
| PR creation fails | Show gh error, suggest checking auth |
