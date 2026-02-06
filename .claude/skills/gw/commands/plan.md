---
name: gw:plan
description: Create implementation plan with GitHub issue update. Wraps /workflows:plan if compound-engineering available.
argument-hint: "[feature description or brainstorm file path]"
---

# GitHub Workflow: Plan

Create an implementation plan, then update the linked GitHub issue.

## Arguments

<feature_description> #$ARGUMENTS </feature_description>

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

Find the GitHub issue to update:

```bash
# Check for issue in brainstorm document frontmatter
if [ -f "$BRAINSTORM_PATH" ]; then
    ISSUE=$(grep -E '^github_issue:' "$BRAINSTORM_PATH" | grep -oE '[0-9]+')
fi

# Or extract from branch name
if [ -z "$ISSUE" ]; then
    BRANCH=$(git branch --show-current)
    ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")
fi

# Or find recent brainstorm issue
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label brainstorm --limit 1 --json number --jq '.[0].number' 2>/dev/null)
fi

if [ -n "$ISSUE" ]; then
    validate_number "$ISSUE"
    echo "Linked to issue #$ISSUE"
fi
```

### Step 2: Check for compound-engineering

```bash
CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/plan.md 2>/dev/null | head -1)
```

### Step 3: Run Core Planning

**If compound-engineering is available:**

Run `/workflows:plan` with the feature description. This will:
- Check for existing brainstorm documents
- Run research agents (repo-research-analyst, learnings-researcher)
- Optionally run external research (best-practices-researcher, framework-docs-researcher)
- Generate comprehensive plan document
- Write to `docs/plans/YYYY-MM-DD-<type>-<name>-plan.md`

After it completes, note the output file path for GitHub integration.

**If compound-engineering is NOT available:**

Run the built-in planning workflow:

#### 3a. Check for Brainstorm

```bash
# Look for recent brainstorm matching the feature
ls -la docs/brainstorms/*.md 2>/dev/null | head -5
```

If found, read and use as context. Skip idea refinement.

#### 3b. Research (Lightweight)

- Search codebase for similar patterns
- Check CLAUDE.md for conventions
- Look in docs/solutions/ for relevant learnings

#### 3c. Generate Plan

Write plan document with sections:
- Overview
- Technical Approach
- Implementation Phases (with checkboxes)
- Acceptance Criteria
- Dependencies
- Risk Analysis

```bash
DATE=$(date +%Y-%m-%d)
TYPE="feat"  # or fix, refactor
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-50)
PLAN_PATH="docs/plans/${DATE}-${TYPE}-${SLUG}-plan.md"
```

### Step 4: GitHub Integration

After plan document is created:

#### 4a. Update GitHub Issue

```bash
if [ -n "$ISSUE" ]; then
    # Get existing issue body
    EXISTING_BODY=$(gh issue view "$ISSUE" --json body --jq '.body')

    # Combine with plan
    COMBINED=$(cat <<EOF
$EXISTING_BODY

---

## Implementation Plan

**Plan document:** \`$PLAN_PATH\`

$(cat "$PLAN_PATH")
EOF
)

    # Truncate if too large (GitHub limit ~65KB)
    if [ ${#COMBINED} -gt 60000 ]; then
        COMBINED="${COMBINED:0:60000}

... [Truncated. See local doc: $PLAN_PATH]"
    fi

    # Update issue
    gh issue edit "$ISSUE" \
        --add-label "planned" \
        --body "$COMBINED" || {
        echo "Warning: Could not update issue #$ISSUE"
    }

    # Remove brainstorm label
    gh issue edit "$ISSUE" --remove-label "brainstorm" 2>/dev/null || true

    echo "Updated issue #$ISSUE with plan"
fi
```

#### 4b. Update Local Document

Add issue reference to plan frontmatter:

```yaml
---
github_issue: {ISSUE}
---
```

### Step 5: Output

```
Plan complete!

Local doc: {PLAN_PATH}
GitHub Issue: #{ISSUE} (updated)
Labels: planned

Next: Run /gw:work to begin implementation
```

## Success Criteria

- [ ] Plan created (via compound-engineering or built-in)
- [ ] Local plan document written
- [ ] GitHub issue updated with plan content
- [ ] Labels updated: `planned` added, `brainstorm` removed
- [ ] User knows next step is `/gw:work`

## Error Handling

| Error | Action |
|-------|--------|
| No issue found | Create plan locally, warn user to run /gw:brainstorm first |
| Issue update fails | Show error, plan still exists locally |
| Content too large | Truncate with pointer to local doc |
