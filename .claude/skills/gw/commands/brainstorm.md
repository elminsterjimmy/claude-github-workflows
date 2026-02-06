---
name: gw:brainstorm
description: Brainstorm a feature with GitHub issue creation. Wraps /workflows:brainstorm if compound-engineering available.
argument-hint: "[feature idea or problem to explore]"
---

# GitHub Workflow: Brainstorm

Explore a feature idea, then create a GitHub issue to track it.

## Arguments

<feature_description> #$ARGUMENTS </feature_description>

## Prerequisites

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Workflow

### Step 1: Check for compound-engineering

```bash
# Detect compound-engineering plugin
CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/brainstorm.md 2>/dev/null | head -1)
```

### Step 2: Run Core Brainstorm

**If compound-engineering is available:**

Run `/workflows:brainstorm` with the feature description. This will:
- Conduct collaborative dialogue to understand the idea
- Explore approaches with the user
- Write brainstorm document to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

After it completes, note the output file path for GitHub integration.

**If compound-engineering is NOT available:**

Run the built-in brainstorm workflow:

#### 2a. Gather Feature Description

If no feature description provided, ask:
- What problem does this solve?
- Who is this for?
- What's the expected scope?

Continue asking until the idea is clear OR user says "proceed".

#### 2b. Explore Approaches

Propose 2-3 concrete approaches. For each:
- Brief description
- Pros and cons
- When it's best suited

Ask user which approach they prefer.

#### 2c. Write Brainstorm Document

```bash
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)
DATE=$(date +%Y-%m-%d)
DOC_PATH="docs/brainstorms/${DATE}-${SLUG}-brainstorm.md"
```

Write to `$DOC_PATH` with sections:
- What We're Building
- Why (problem/value)
- Scope (deliverables, out of scope)
- Key Decisions
- Open Questions
- Next Steps

### Step 3: GitHub Integration

After brainstorm document is created:

#### 3a. Create GitHub Issue

```bash
# Validate inputs
validate_slug() {
    [[ "$1" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid slug: $1"; exit 1; }
}

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
```

#### 3b. Update Local Document

Add issue reference to the brainstorm document:

```markdown
---
(existing frontmatter)
github_issue: {ISSUE_NUM}
---
```

### Step 4: Output

```
Brainstorm complete!

Local doc: {DOC_PATH}
GitHub Issue: #{ISSUE_NUM}
URL: {ISSUE_URL}

Next: Run /gw:plan to create implementation plan
```

## Success Criteria

- [ ] Feature idea explored through dialogue (via compound-engineering or built-in)
- [ ] Local brainstorm document created
- [ ] GitHub issue created with brainstorm content
- [ ] Issue number linked in local document
- [ ] User knows next step is `/gw:plan`

## Error Handling

| Error | Action |
|-------|--------|
| `gh` not authenticated | "Error: Run 'gh auth login' first" |
| Issue creation fails | Show gh error, suggest checking auth |
| compound-engineering not found | Use built-in workflow (not an error) |
