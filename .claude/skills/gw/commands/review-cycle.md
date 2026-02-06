---
name: gw:review-cycle
description: Handle PR review status - address feedback, merge approved PRs, capture learnings.
argument-hint: "[PR number - optional, auto-detected from branch]"
---

# GitHub Workflow: Review Cycle

Check PR review status and take appropriate action: address feedback, merge, or wait.

## Arguments

<pr_number> #$ARGUMENTS </pr_number>

## Prerequisites

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Input Validation

```bash
validate_branch() {
    [[ "$1" =~ ^[a-zA-Z0-9/_-]+$ ]] || { echo "Invalid branch: $1"; exit 1; }
}

validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}

validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid username: $1"; exit 1; }
}
```

## Workflow

### Step 1: Detect Current PR

```bash
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

# Get PR info
PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,reviewDecision,reviews,body 2>/dev/null) || {
    echo "No PR found for branch: $BRANCH"
    echo "Create a PR first with /gw:work"
    exit 1
}

PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
validate_number "$PR_NUM"

PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
REVIEW_DECISION=$(echo "$PR_INFO" | jq -r '.reviewDecision // "NONE"')

echo "PR #${PR_NUM}: $PR_TITLE"
echo "Review status: $REVIEW_DECISION"
```

### Step 2: Extract Linked Issue

```bash
PR_BODY=$(echo "$PR_INFO" | jq -r '.body')
ISSUE=$(echo "$PR_BODY" | grep -oE 'Closes #[0-9]+' | grep -oE '[0-9]+' | head -1)

if [ -n "$ISSUE" ]; then
    validate_number "$ISSUE"
    echo "Linked issue: #$ISSUE"
fi
```

### Step 3: Branch on Review State

```bash
case "$REVIEW_DECISION" in
    "APPROVED")
        echo ""
        echo "PR approved! Ready to merge."
        # Continue to Step 4a
        ;;
    "CHANGES_REQUESTED")
        echo ""
        echo "Changes requested. Analyzing feedback..."
        # Continue to Step 4b
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
esac
```

### Step 4a: Handle Approved

When PR is approved, merge and optionally capture learnings:

#### Merge PR

```bash
gh pr merge "$PR_NUM" --squash --delete-branch || {
    echo "Error: Merge failed. Check for conflicts or CI status."
    exit 1
}

echo "PR #$PR_NUM merged!"
```

#### Close Linked Issue

```bash
if [ -n "$ISSUE" ]; then
    gh issue close "$ISSUE" 2>/dev/null && echo "Closed issue #$ISSUE"
fi
```

#### Capture Learnings (Optional)

Ask if there are learnings to capture. If yes:

```bash
SLUG=$(echo "$PR_TITLE" | sed 's/^feat: //' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SOLUTION_PATH="docs/solutions/${SLUG}.md"
```

**If compound-engineering is available:**

Run `/workflows:compound` to capture learnings with proper structure.

**If compound-engineering is NOT available:**

Create learning document manually:

```markdown
# {Title} Learnings

**PR:** #{PR_NUM} | **Issue:** #{ISSUE} | **Date:** {DATE}

## Problem

{What challenge was faced?}

## Solution

{How was it solved?}

## Gotchas

- {Important lesson learned}

## References

- PR: {PR_URL}
- Issue: #{ISSUE}
```

Link from issue:

```bash
if [ -n "$ISSUE" ]; then
    gh issue comment "$ISSUE" --body "Learnings captured: \`$SOLUTION_PATH\`" 2>/dev/null
fi
```

### Step 4b: Handle Changes Requested

Get feedback and address it:

#### Get Review Comments

```bash
LATEST_REVIEW=$(echo "$PR_INFO" | jq -r '.reviews | map(select(.state == "CHANGES_REQUESTED")) | last')
REVIEW_BODY=$(echo "$LATEST_REVIEW" | jq -r '.body // "No comment body"')
REVIEWER=$(echo "$LATEST_REVIEW" | jq -r '.author.login')

if [ -n "$REVIEWER" ]; then
    validate_username "$REVIEWER"
fi

echo "Feedback from @$REVIEWER:"
echo "---"
echo "$REVIEW_BODY"
echo "---"

# Also get inline comments
gh api "repos/{owner}/{repo}/pulls/$PR_NUM/comments" --jq '.[].body' 2>/dev/null
```

#### Address Feedback

Analyze the feedback and make the requested changes:
1. Understand what changes are requested
2. Implement the fixes
3. Verify the changes address the feedback

#### Commit and Push

```bash
git add <changed-files>
git commit -m "fix: address review feedback

Requested by @$REVIEWER in PR #${PR_NUM}"

git push
```

#### Request Re-review

```bash
if [ -n "$REVIEWER" ]; then
    gh pr edit "$PR_NUM" --add-reviewer "$REVIEWER" 2>/dev/null || true
    echo "Re-review requested from @$REVIEWER"
fi
```

### Step 5: Output

**For approved/merged:**

```
PR #${PR_NUM} merged successfully!

Issue: #{ISSUE} (closed)
Branch: deleted
Learnings: {SOLUTION_PATH or "none captured"}

Workflow complete!
```

**For changes addressed:**

```
Changes pushed to PR #${PR_NUM}

Re-review requested from @{REVIEWER}

Next: Wait for review, then run /gw:review-cycle again
```

## Success Criteria

- [ ] PR status correctly detected
- [ ] **Approved**: PR merged, issue closed, learnings optionally captured
- [ ] **Changes Requested**: Feedback addressed, changes pushed, re-review requested
- [ ] **Awaiting Review**: User informed, no action taken

## Error Handling

| Error | Action |
|-------|--------|
| No PR found | "Create a PR with /gw:work first" |
| Merge fails | "Check for conflicts or CI status" |
| Can't close issue | Warning only, continue |
| Invalid reviewer username | Skip re-review request |
