---
name: gw:work
description: Execute plan and create PR linked to issue. Wraps /workflows:work if compound-engineering available.
argument-hint: "[plan file path]"
---

# GitHub Workflow: Work

Implement a planned feature, creating a PR linked to the tracking issue.

## Arguments

<plan_path> #$ARGUMENTS </plan_path>

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
```

## Workflow

### Step 1: Detect Linked Issue

```bash
# Check plan document frontmatter
if [ -f "$PLAN_PATH" ]; then
    ISSUE=$(grep -E '^github_issue:' "$PLAN_PATH" | grep -oE '[0-9]+')
fi

# Or from branch name
if [ -z "$ISSUE" ]; then
    BRANCH=$(git branch --show-current)
    ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")
fi

# Or find recent planned issue
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label planned --limit 1 --json number --jq '.[0].number' 2>/dev/null)
fi

if [ -z "$ISSUE" ]; then
    echo "No linked issue found. Run /gw:plan first."
    exit 1
fi

validate_number "$ISSUE"
ISSUE_TITLE=$(gh issue view "$ISSUE" --json title --jq '.title')
echo "Working on issue #$ISSUE: $ISSUE_TITLE"
```

### Step 2: Create Feature Branch

```bash
CURRENT_BRANCH=$(git branch --show-current)

# Generate branch name from issue
CLEAN_TITLE=$(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //' | sed 's/^feat: //')
SLUG=$(echo "$CLEAN_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-30)
EXPECTED_BRANCH="feat/${ISSUE}-${SLUG}"

validate_branch "$EXPECTED_BRANCH"

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    git checkout -b "$EXPECTED_BRANCH" || {
        echo "Error: Failed to create branch"
        exit 1
    }
    echo "Created branch: $EXPECTED_BRANCH"
elif [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
    echo "On branch: $CURRENT_BRANCH (expected: $EXPECTED_BRANCH)"
    echo "Continuing on current branch..."
fi

BRANCH=$(git branch --show-current)
```

### Step 3: Check for compound-engineering

```bash
CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/work.md 2>/dev/null | head -1)
```

### Step 4: Run Core Implementation

**If compound-engineering is available:**

Run `/workflows:work` with the plan path. This will:
- Read plan and clarify any questions
- Create todo list from plan phases
- Execute implementation following existing patterns
- Run tests continuously
- Create incremental commits

After it completes, proceed to GitHub integration.

**If compound-engineering is NOT available:**

Run the built-in work workflow:

#### 4a. Read Plan

Read the plan document and understand:
- Implementation phases
- Acceptance criteria
- Dependencies

#### 4b. Implement

For each phase in the plan:
1. Implement the deliverables
2. Follow existing codebase patterns
3. Write tests for new functionality
4. Run tests to verify

#### 4c. Commit

```bash
git add <relevant-files>
git commit -m "feat: implement #${ISSUE}

$(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //')

Closes #${ISSUE}"
```

### Step 5: Push and Create PR

```bash
# Push branch
git push -u origin "$BRANCH" || {
    echo "Error: Failed to push"
    exit 1
}

# Create PR
PR_TITLE="feat: $(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //' | sed 's/^feat: //')"

PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "Closes #${ISSUE}

## Summary

Implements the plan from issue #${ISSUE}.

## Changes

[See commits for details]

## Testing

- [ ] Tests pass locally
- [ ] Manual verification completed

## Plan Reference

See: \`$PLAN_PATH\`") || {
    echo "Error: Failed to create PR"
    exit 1
}

PR_NUM=$(echo "$PR_URL" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+')
validate_number "$PR_NUM"
```

### Step 6: Update Issue Labels

```bash
gh issue edit "$ISSUE" --add-label "in-progress" 2>/dev/null || true
gh issue edit "$ISSUE" --remove-label "planned" 2>/dev/null || true
```

### Step 7: Output

```
Implementation complete!

Branch: {BRANCH}
PR: #{PR_NUM}
URL: {PR_URL}
Issue: #{ISSUE} (in-progress)

Next: Wait for review, then run /gw:review-cycle
```

## Success Criteria

- [ ] Feature branch created with proper naming
- [ ] Implementation complete per plan
- [ ] Changes committed and pushed
- [ ] PR created and linked to issue
- [ ] Issue labels updated to `in-progress`
- [ ] User knows next step is `/gw:review-cycle`

## Error Handling

| Error | Action |
|-------|--------|
| No issue found | "Run /gw:plan first" |
| Branch creation fails | Show error, check for conflicts |
| Push fails | Show error, check remote access |
| PR creation fails | Show gh error, suggest checking auth |
