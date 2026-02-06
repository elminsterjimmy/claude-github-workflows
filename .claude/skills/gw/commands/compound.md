---
name: gw:compound
description: Capture learnings and link to GitHub issue/PR. Wraps /workflows:compound if compound-engineering available.
argument-hint: "[topic or problem solved]"
---

# GitHub Workflow: Compound

Document a recently solved problem to build institutional knowledge, then link it to the related GitHub issue/PR.

## Arguments

<topic> #$ARGUMENTS </topic>

## Prerequisites

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Input Validation

```bash
validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}
```

## Workflow

### Step 1: Detect Related Issue/PR

```bash
# From branch name
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")

# Get PR for branch
PR=$(gh pr view "$BRANCH" --json number --jq '.number' 2>/dev/null || echo "")

if [ -n "$ISSUE" ]; then
    validate_number "$ISSUE"
    echo "Related issue: #$ISSUE"
fi

if [ -n "$PR" ]; then
    validate_number "$PR"
    echo "Related PR: #$PR"
fi
```

### Step 2: Check for compound-engineering

```bash
CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/compound.md 2>/dev/null | head -1)
```

### Step 3: Capture Learning

**If compound-engineering is available:**

Run `/workflows:compound` with the topic. This will:
- Guide through documenting the problem and solution
- Create properly structured learning document
- Use YAML frontmatter with tags, category, symptoms
- Write to `docs/solutions/`

After it completes, note the output file path for GitHub integration.

**If compound-engineering is NOT available:**

Run the built-in compound workflow:

#### 3a. Gather Information

Ask about:
- What problem was solved?
- What was the root cause?
- How was it fixed?
- What gotchas or lessons were learned?

#### 3b. Generate Document

```bash
SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SOLUTION_PATH="docs/solutions/${SLUG}.md"
```

Write learning document:

```markdown
---
title: "{Topic}"
date: {DATE}
tags: [{relevant, tags}]
github_issue: {ISSUE}
github_pr: {PR}
---

# {Topic}

**PR:** #{PR} | **Issue:** #{ISSUE} | **Date:** {DATE}

## Problem

{Description of the problem encountered}

## Root Cause

{What caused the problem}

## Solution

{How it was fixed}

## Gotchas

- {Important lesson 1}
- {Important lesson 2}

## Prevention

{How to avoid this in the future}

## References

- PR: https://github.com/{owner}/{repo}/pull/{PR}
- Issue: https://github.com/{owner}/{repo}/issues/{ISSUE}
```

### Step 4: GitHub Integration

Link the learning document to the issue/PR:

```bash
# Comment on issue with link to learning
if [ -n "$ISSUE" ]; then
    gh issue comment "$ISSUE" --body "📚 **Learning captured:** \`$SOLUTION_PATH\`

This documents the lessons learned from this work for future reference." 2>/dev/null || true
    echo "Linked to issue #$ISSUE"
fi

# Comment on PR if different from issue
if [ -n "$PR" ]; then
    gh pr comment "$PR" --body "📚 **Learning captured:** \`$SOLUTION_PATH\`" 2>/dev/null || true
    echo "Linked to PR #$PR"
fi
```

### Step 5: Output

```
Learning captured!

Document: {SOLUTION_PATH}
Issue: #{ISSUE} (commented)
PR: #{PR} (commented)

This learning is now searchable in docs/solutions/ for future reference.
```

## Success Criteria

- [ ] Problem and solution documented
- [ ] Learning file created in `docs/solutions/`
- [ ] GitHub issue commented with link (if linked)
- [ ] GitHub PR commented with link (if linked)
- [ ] Document includes frontmatter with tags for searchability

## Error Handling

| Error | Action |
|-------|--------|
| No issue/PR found | Create learning locally without GitHub links |
| Comment fails | Warning only, learning still saved locally |
| Directory doesn't exist | Create `docs/solutions/` automatically |

## Best Practices

- Keep learnings focused on one problem
- Include specific code examples when relevant
- Tag with technologies and patterns for searchability
- Link to relevant documentation or external resources
- Write for your future self who forgot the context
