# Plan Workflow

Create an implementation plan for a brainstormed feature, then update the GitHub issue with the plan.

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

validate_slug() {
    [[ "$1" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid slug: $1"; exit 1; }
}
```

## Workflow

### Step 1: Detect Active Issue

Find the issue to plan for:

```bash
# Try branch name first
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")

# If no issue from branch, check for recent brainstorm issues
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label brainstorm --limit 1 --json number --jq '.[0].number' 2>/dev/null)
fi

# Still nothing? Ask user
if [ -z "$ISSUE" ]; then
    echo "No active issue found."
    echo "Provide issue number or run /workflows:brainstorm first."
    exit 1
fi

# Validate issue number format
validate_number "$ISSUE"

# Validate issue exists on GitHub
if ! gh issue view "$ISSUE" &>/dev/null; then
    echo "Issue #$ISSUE not found on GitHub"
    exit 1
fi
```

### Step 2: Read Brainstorm Content

```bash
# Get issue details
ISSUE_TITLE=$(gh issue view "$ISSUE" --json title --jq '.title')
ISSUE_BODY=$(gh issue view "$ISSUE" --json body --jq '.body')

echo "Planning for: $ISSUE_TITLE"
```

### Step 3: Run Planning Process

Generate a comprehensive implementation plan covering:

1. **Overview** - What we're building and why
2. **Technical Approach** - Architecture, patterns, key decisions
3. **Implementation Phases** - Break into logical phases with deliverables
4. **Acceptance Criteria** - Checkboxes for functional and non-functional requirements
5. **Dependencies** - What needs to be in place first
6. **Risk Analysis** - What could go wrong and mitigation

### Step 4: Create Local Plan Document

```bash
DATE=$(date +%Y-%m-%d)
TYPE="feat"  # Determine from issue: feat, fix, refactor

# Generate slug from title
SLUG=$(echo "$ISSUE_TITLE" | sed 's/^brainstorm: //' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)

PLAN_PATH="docs/plans/${DATE}-${TYPE}-${SLUG}-plan.md"
```

Write plan to `$PLAN_PATH` with this structure:

```markdown
---
title: "{TYPE}: {Title}"
type: {TYPE}
date: {DATE}
issue: {ISSUE}
---

# {TYPE}: {Title}

## Overview

{Brief description of what we're building}

## Technical Approach

{Architecture, patterns, key technical decisions}

## Implementation Phases

### Phase 1: {Name}

- [ ] Deliverable 1
- [ ] Deliverable 2

### Phase 2: {Name}

- [ ] Deliverable 1
- [ ] Deliverable 2

## Acceptance Criteria

### Functional Requirements

- [ ] Requirement 1
- [ ] Requirement 2

### Non-Functional Requirements

- [ ] Performance target
- [ ] Security requirement

## Dependencies

- {Dependency 1}
- {Dependency 2}

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {Risk} | {L/M/H} | {L/M/H} | {Action} |
```

### Step 5: Update GitHub Issue

```bash
# Combine brainstorm + plan content
COMBINED=$(cat <<EOF
$ISSUE_BODY

---

## Implementation Plan

**Plan document:** \`$PLAN_PATH\`

$(cat "$PLAN_PATH")
EOF
)

# Check content size (GitHub limit is 65KB, truncate at 60KB for safety)
if [ ${#COMBINED} -gt 60000 ]; then
    echo "Warning: Content truncated. Full plan in local doc."
    COMBINED="${COMBINED:0:60000}

... [Content truncated. See local doc: $PLAN_PATH]"
fi

# Update issue with plan content and labels
gh issue edit "$ISSUE" \
    --add-label "planned" \
    --body "$COMBINED" || {
    echo "Error: Failed to update issue. Check: gh auth status"
    exit 1
}

# Remove brainstorm label if present
gh issue edit "$ISSUE" --remove-label "brainstorm" 2>/dev/null || true
```

### Step 6: Output Results

```
Updated issue #${ISSUE} with implementation plan

GitHub Issue: #{ISSUE}
URL: https://github.com/{owner}/{repo}/issues/{ISSUE}
Local plan: {PLAN_PATH}

Labels: planned

Next step: Run /workflows:work to begin implementation
```

## Success Criteria

- [ ] Issue detected from branch or user input
- [ ] Comprehensive plan generated covering all sections
- [ ] Local plan document created at `docs/plans/`
- [ ] GitHub issue updated with plan content
- [ ] Labels updated: `planned` added, `brainstorm` removed
- [ ] User knows next step is `/workflows:work`

## Error Handling

| Error | Action |
|-------|--------|
| No issue found | "No active issue. Provide number or run /workflows:brainstorm" |
| Issue not on GitHub | "Issue #N not found on GitHub" |
| Update fails | Show gh error, suggest checking auth |
| Content too large | Truncate with note pointing to local doc |
