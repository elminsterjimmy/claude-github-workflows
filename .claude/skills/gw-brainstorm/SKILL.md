---
name: gw-brainstorm
description: Explore a feature idea through collaborative dialogue, then create a GitHub issue with claude-code and custom labels.
---

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

validate_label() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid label: $1"; exit 1; }
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

# Ensure claude-code label exists (purple)
ensure_label "claude-code" "7C3AED"
```

## Workflow

### Step 1: Gather Feature Description

Ask the user through collaborative dialogue:

1. **What problem does this solve?** - Understand the pain point or opportunity
2. **Who is this for?** - Identify the target user or system
3. **What's the expected scope?** - Get a sense of size (small tweak vs. major feature)
4. **What's the desired outcome?** - Understand success criteria

Continue asking clarifying questions until the feature is well-understood.

### Step 2: Ask for Function Labels

Ask the user for optional function labels to categorize this issue:

```
What labels should we add to categorize this issue? (optional, comma-separated)

Examples: auth, ui, api, performance, refactor, documentation

Enter labels or press Enter to skip:
```

Parse and validate each label:

```bash
# Split by comma and validate each
IFS=',' read -ra LABELS <<< "$USER_INPUT"
VALID_LABELS=()
for label in "${LABELS[@]}"; do
    label=$(echo "$label" | xargs)  # trim whitespace
    if [ -n "$label" ]; then
        validate_label "$label"
        ensure_label "$label"
        VALID_LABELS+=("$label")
    fi
done
```

### Step 3: Generate Document

Create a brainstorm title and slug:

```bash
# Sanitize title to slug (lowercase, alphanumeric and hyphens only)
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)
DATE=$(date +%Y-%m-%d)
DOC_PATH="docs/brainstorms/${DATE}-${SLUG}-brainstorm.md"
```

### Step 4: Create Local Brainstorm Document

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

Run `/gw-plan` to create implementation plan.
```

### Step 5: Create GitHub Issue

```bash
# Build label arguments
LABEL_ARGS="--label claude-code --label brainstorm"
for label in "${VALID_LABELS[@]}"; do
    LABEL_ARGS="$LABEL_ARGS --label $label"
done

# Create issue with all labels
ISSUE_URL=$(gh issue create \
    --title "brainstorm: $TITLE" \
    $LABEL_ARGS \
    --body-file "$DOC_PATH") || {
    echo "Error: Failed to create issue. Check: gh auth status"
    exit 1
}

# Extract and validate issue number
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '/issues/[0-9]+' | grep -oE '[0-9]+')
validate_number "$ISSUE_NUM"
```

**Note:** Labels are created automatically if they don't exist.

### Step 6: Output Results

```
Created brainstorm:

GitHub Issue: #{ISSUE_NUM}
URL: {ISSUE_URL}
Local doc: {DOC_PATH}
Labels: claude-code, brainstorm{, user-provided-labels}

Next step: Run /gw-plan to create implementation plan
```

## Success Criteria

- [ ] User's feature idea is well-understood through dialogue
- [ ] User prompted for function labels (optional)
- [ ] Local brainstorm document created at `docs/brainstorms/`
- [ ] GitHub issue created with `claude-code` and `brainstorm` labels
- [ ] User-provided labels applied to issue
- [ ] User knows next step is `/gw-plan`

## Error Handling

| Error | Action |
|-------|--------|
| `gh` not authenticated | "Error: Run 'gh auth login' first" |
| Issue creation fails | Show gh error, suggest checking auth |
| Label doesn't exist | Create it automatically |
| Invalid label format | Warn and skip that label |
