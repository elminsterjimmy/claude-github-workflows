---
name: gw-review
description: Handle PR review feedback - address changes requested, merge approved PRs, and capture learnings.
---

# Review Cycle Workflow

Handle PR review feedback: address changes requested, merge approved PRs, and capture learnings.

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

validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid username: $1"; exit 1; }
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

# Ensure required label exists
ensure_label "claude-code" "7C3AED"
```

## Workflow

### Step 1: Detect Current PR

```bash
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

# Get PR info in single API call
PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,reviewDecision,reviews,body 2>/dev/null) || {
    echo "No PR found for branch: $BRANCH"
    echo "Create a PR first with /gw-work"
    exit 1
}

PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
validate_number "$PR_NUM"

PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
REVIEW_DECISION=$(echo "$PR_INFO" | jq -r '.reviewDecision // "NONE"')

echo "PR #${PR_NUM}: $PR_TITLE"
echo "Review status: $REVIEW_DECISION"
```

### Step 2: Branch on Review State

```bash
case "$REVIEW_DECISION" in
    "APPROVED")
        echo ""
        echo "PR approved! Ready to merge."
        # Continue to Step 3a: Handle Approved
        ;;
    "CHANGES_REQUESTED")
        echo ""
        echo "Changes requested. Let's address the feedback."
        # Continue to Step 3b: Handle Changes Requested
        ;;
    "REVIEW_REQUIRED"|"NONE"|"")
        echo ""
        echo "Awaiting review. No action needed yet."
        echo ""
        echo "Options:"
        echo "  - Wait for reviewer feedback"
        echo "  - Request review: gh pr edit $PR_NUM --add-reviewer <username>"
        exit 0
        ;;
    *)
        echo "Review state: $REVIEW_DECISION"
        ;;
esac
```

### Step 3a: Handle Approved (Merge + Compound)

When PR is approved:

```bash
# Confirm merge
echo "Ready to merge PR #${PR_NUM}"
echo "Merge method: squash (combines all commits)"
echo ""

# Merge PR
gh pr merge "$PR_NUM" --squash --delete-branch || {
    echo "Error: Merge failed. Check for conflicts or CI status."
    exit 1
}

echo "PR merged successfully!"
```

#### Extract Linked Issue

```bash
# Get issue from PR body (looks for "Closes #N")
PR_BODY=$(echo "$PR_INFO" | jq -r '.body')
ISSUE=$(echo "$PR_BODY" | grep -oE 'Closes #[0-9]+' | grep -oE '[0-9]+' | head -1)

if [ -n "$ISSUE" ]; then
    validate_number "$ISSUE"
    echo "Linked issue: #$ISSUE"
fi
```

#### Capture Learnings (Optional)

```bash
echo ""
echo "Any learnings to capture from this work? (y/n)"
# If user says yes:

# Generate solution doc path
SLUG=$(echo "$PR_TITLE" | sed 's/^feat: //' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SOLUTION_PATH="docs/solutions/${SLUG}.md"
```

Write learning document:

```markdown
# {Title} Learnings

**PR:** #{PR_NUM} | **Issue:** #{ISSUE} | **Date:** {DATE}

## Problem

{What challenge did we face?}

## Solution

{How did we solve it?}

## Gotchas

- {Important thing we learned}
- {Edge case we discovered}

## References

- PR: https://github.com/{owner}/{repo}/pull/{PR_NUM}
- Issue: https://github.com/{owner}/{repo}/issues/{ISSUE}
```

```bash
# Link learning from issue comment
if [ -n "$ISSUE" ]; then
    gh issue comment "$ISSUE" --body "Learnings captured: \`$SOLUTION_PATH\`"
fi
```

#### Close Issue

```bash
if [ -n "$ISSUE" ]; then
    gh issue close "$ISSUE" || {
        echo "Warning: Could not close issue #$ISSUE"
    }
    echo "Closed issue #$ISSUE"
fi
```

### Step 3b: Handle Changes Requested

When changes are requested:

```bash
# Get latest review comments
LATEST_REVIEW=$(echo "$PR_INFO" | jq -r '.reviews | map(select(.state == "CHANGES_REQUESTED")) | last')
REVIEW_BODY=$(echo "$LATEST_REVIEW" | jq -r '.body // "No comment body"')
REVIEWER=$(echo "$LATEST_REVIEW" | jq -r '.author.login')

# Validate reviewer username before using
validate_username "$REVIEWER"

echo "Feedback from @$REVIEWER:"
echo "---"
echo "$REVIEW_BODY"
echo "---"
```

#### Get PR Comments

```bash
# Also check for inline comments
COMMENTS=$(gh pr view "$PR_NUM" --json comments --jq '.comments[].body' 2>/dev/null)
if [ -n "$COMMENTS" ]; then
    echo ""
    echo "PR comments:"
    echo "$COMMENTS"
fi
```

#### Address Feedback

1. Analyze the review feedback
2. Make the requested changes
3. Commit with descriptive message:

```bash
git add <changed-files>
git commit -m "fix: address review feedback

- {Change 1}
- {Change 2}

Requested by @$REVIEWER in PR #${PR_NUM}"

git push
```

#### Request Re-review

```bash
gh pr edit "$PR_NUM" --add-reviewer "$REVIEWER" || {
    echo "Warning: Could not request re-review from @$REVIEWER"
}

echo ""
echo "Changes pushed and re-review requested from @$REVIEWER"
```

### Step 4: Output Results

For approved/merged:
```
PR #${PR_NUM} merged successfully!

Issue #${ISSUE} closed
Branch deleted
Learnings: {SOLUTION_PATH or "none captured"}

Workflow complete!
```

For changes addressed:
```
Changes pushed to PR #${PR_NUM}

Re-review requested from @{REVIEWER}

Next: Wait for review, then run /gw-review again
```

## Success Criteria

- [ ] PR detected from current branch
- [ ] Review state correctly identified
- [ ] **Approved**: PR merged, issue closed, learnings optionally captured
- [ ] **Changes Requested**: Feedback addressed, changes pushed, re-review requested
- [ ] **Awaiting Review**: User informed, no action taken

## Error Handling

| Error | Action |
|-------|--------|
| No PR found | "No PR for branch. Run /gw-work first" |
| Merge fails | "Merge failed. Check conflicts or CI status." |
| Can't close issue | Warning only, continue |
| Can't request re-review | Warning only, continue |

## Review States Reference

| State | Meaning | Action |
|-------|---------|--------|
| `APPROVED` | Ready to merge | Merge PR, close issue |
| `CHANGES_REQUESTED` | Feedback to address | Make changes, push, request re-review |
| `REVIEW_REQUIRED` | Waiting for review | No action, inform user |
| `NONE` / empty | No reviews yet | No action, inform user |
