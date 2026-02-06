# Brainstorm Workflow

Explore a feature idea through collaborative dialogue, then create a GitHub issue and local brainstorm document.

## Prerequisites

Check GitHub CLI authentication:

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Input Validation

```bash
# Validate inputs before shell use
validate_slug() {
    [[ "$1" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid slug: $1"; exit 1; }
}

validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}
```

## Workflow

### Step 1: Gather Feature Description

Ask the user through collaborative dialogue:

1. **What problem does this solve?** - Understand the pain point or opportunity
2. **Who is this for?** - Identify the target user or system
3. **What's the expected scope?** - Get a sense of size (small tweak vs. major feature)
4. **What's the desired outcome?** - Understand success criteria

Continue asking clarifying questions until the feature is well-understood.

### Step 2: Generate Document

Create a brainstorm title and slug:

```bash
# Sanitize title to slug (lowercase, alphanumeric and hyphens only)
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)
DATE=$(date +%Y-%m-%d)
DOC_PATH="docs/brainstorms/${DATE}-${SLUG}-brainstorm.md"
```

### Step 3: Create Local Brainstorm Document

Write brainstorm to `$DOC_PATH` with this structure:

```markdown
# Brainstorm: {Title}

**Date:** {DATE}
**Status:** Ready for planning

## What We're Building

{Description of the feature/solution}

## Why

{Problem being solved, value proposition}

## Scope

### Deliverables
- {Deliverable 1}
- {Deliverable 2}

### Out of Scope
- {What we're NOT building}

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| {Decision 1} | {Choice} | {Why} |

## Open Questions

1. {Question that needs resolution}

## Next Steps

Run `/workflows:plan` to create implementation plan.
```

### Step 4: Create GitHub Issue

```bash
# Create issue with brainstorm content
ISSUE_URL=$(gh issue create \
    --title "brainstorm: $TITLE" \
    --label "brainstorm" \
    --body-file "$DOC_PATH") || {
    echo "Error: Failed to create issue. Check: gh auth status"
    exit 1
}

# Extract and validate issue number
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '/issues/[0-9]+' | grep -oE '[0-9]+')
validate_number "$ISSUE_NUM"
```

**Note:** If the `brainstorm` label doesn't exist, it will be created automatically.

### Step 5: Output Results

```
Created brainstorm:

GitHub Issue: #{ISSUE_NUM}
URL: {ISSUE_URL}
Local doc: {DOC_PATH}

Next step: Run /workflows:plan to create implementation plan
```

## Success Criteria

- [ ] User's feature idea is well-understood through dialogue
- [ ] Local brainstorm document created at `docs/brainstorms/`
- [ ] GitHub issue created with `brainstorm` label
- [ ] User knows next step is `/workflows:plan`

## Error Handling

| Error | Action |
|-------|--------|
| `gh` not authenticated | "Error: Run 'gh auth login' first" |
| Issue creation fails | Show gh error, suggest checking auth |
| Label doesn't exist | gh creates it automatically |
