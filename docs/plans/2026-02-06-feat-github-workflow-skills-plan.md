---
title: "feat: GitHub Workflow Integration Skills"
type: feat
date: 2026-02-06
brainstorm: docs/brainstorms/2026-02-06-github-workflow-integration-brainstorm.md
deepened: 2026-02-06
github_issue: 1
status: implemented
---

# feat: GitHub Workflow Integration Skills

## Implementation Status

**Completed:** 2026-02-06

### Final Architecture Decision

**Changed from `/workflows:*` to `/gw:*`** to avoid naming collision with compound-engineering plugin.

The `/gw:*` commands:
- Wrap compound-engineering's `/workflows:*` if available
- Fall back to built-in workflow if not
- Add GitHub issue/PR integration after core workflow

### Commands Implemented

| Command | File | Status |
|---------|------|--------|
| `/gw:brainstorm` | `.claude/skills/gw/commands/brainstorm.md` | Done |
| `/gw:plan` | `.claude/skills/gw/commands/plan.md` | Done |
| `/gw:work` | `.claude/skills/gw/commands/work.md` | Done |
| `/gw:review-cycle` | `.claude/skills/gw/commands/review-cycle.md` | Done |
| `/gw:compound` | `.claude/skills/gw/commands/compound.md` | Done |

---

## Enhancement Summary

**Deepened on:** 2026-02-06
**Reviewed by:** DHH Rails Reviewer, Kieran Rails Reviewer, Code Simplicity Reviewer
**Research agents used:** 9 (agent-native, architecture, simplicity, security, performance, patterns, skill-creation, gh-best-practices, hooks-research)

### Key Improvements
1. **Simplified architecture**: Removed helper files anti-pattern, inline commands in skills
2. **Security hardening**: Added input validation, command injection prevention, credential handling
3. **Standardized error handling**: Consistent fail-fast pattern with clear error messages
4. **Validation everywhere**: All inputs and GitHub outputs validated before shell use

### Critical Changes from Review
- **Standardize error handling**: Use simple fail-fast pattern, not complex retry wrapper
- **Validate all inputs**: Branch names, issue numbers, GitHub API outputs before shell interpolation
- **Accept duplication**: Inline validation/error patterns in each skill (simplicity > DRY)
- **Remove YAGNI**: No optional state file, no primitives section, no hooks (use GitHub notifications)
- **Renamed to /gw:*** to avoid collision with compound-engineering /workflows:*

---

## Overview

Build a template repository containing Claude Code skills that integrate the **brainstorm → plan → work → review** lifecycle with GitHub issues and PRs. The system creates issues during brainstorming, updates them with plans, creates linked PRs for implementation, and handles review feedback through event-driven hooks.

**Key value proposition**: Compound knowledge by capturing learnings in `docs/solutions/` and maintaining full context in GitHub issues throughout the development lifecycle.

## Problem Statement

Current development workflows with Claude Code lack GitHub integration:
- Brainstorms and plans exist only as local markdown files
- No automatic issue/PR creation or tracking
- Review feedback requires manual context gathering
- Learnings are lost after features ship

This creates friction in team environments and loses valuable institutional knowledge.

---

## Proposed Solution

A template repository with four interconnected skills:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Brainstorm │────▶│    Plan     │────▶│    Work     │────▶│   Review    │
│             │     │             │     │             │     │   Cycle     │
│ Creates     │     │ Updates     │     │ Creates PR  │     │ Addresses   │
│ GitHub      │     │ issue with  │     │ linked to   │     │ feedback    │
│ Issue       │     │ plan        │     │ issue       │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                                    ┌──────────────┼──────────────┐
                                                    ▼              ▼              ▼
                                              ┌──────────┐  ┌──────────┐  ┌──────────┐
                                              │ Approved │  │ Changes  │  │ Rejected │
                                              │          │  │ Requested│  │          │
                                              │ Merge +  │  │ Iterate  │  │ Re-plan  │
                                              │ Compound │  │ same PR  │  │ same     │
                                              │ learning │  │          │  │ issue    │
                                              └──────────┘  └──────────┘  └──────────┘
```

## Technical Approach

### State Management (Simplified)

**Research Finding:** State file adds complexity. Query git and GitHub directly:

```bash
# Get issue from branch name (convention-based)
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oP 'feat/\K\d+' || echo "")

# Get PR for current branch
PR=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")

# Get workflow phase from issue labels
PHASE=$(gh issue view "$ISSUE" --json labels --jq '.labels[].name' 2>/dev/null | grep -E 'brainstorm|planned|in-progress' | head -1)
```

**Benefits:**
- No state file to corrupt or get stale
- Git and GitHub are source of truth
- Works across machines without syncing state

### Validation Functions (Inline in Each Skill)

Each skill inlines these validation patterns (accept duplication for simplicity):

```bash
# Validate branch name (CRITICAL: prevents command injection)
validate_branch() {
    [[ "$1" =~ ^[a-zA-Z0-9/_-]+$ ]] || { echo "Invalid branch name: $1"; exit 1; }
}

# Validate issue/PR number
validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}

# Validate GitHub username (from API output)
validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid username: $1"; exit 1; }
}

# Standard error handling (fail fast, clear message)
gh_check() {
    if ! "$@" 2>&1; then
        echo "Error: Command failed. Check: gh auth status"
        exit 1
    fi
}
```

---

### Skill Implementations

#### SKILL.md Structure (Router)

**Research Finding:** SKILL.md should be a router with essential principles, not documentation.

```markdown
---
name: github-workflows
description: GitHub-integrated development lifecycle. Manages brainstorm → plan → work → review cycle with automatic issue/PR creation. Use when starting features, planning, creating PRs, or handling reviews.
---

# GitHub Workflows

## Essential Principles

### GitHub CLI Required
All operations use `gh` CLI. Check authentication:
```bash
gh auth status || { echo "Run: gh auth login"; exit 1; }
```

### Branch Naming Convention
Branches follow: `feat/{issue-number}-{slug}`
Issue number extracted from branch for automatic linking.

### Input Validation
All user inputs validated before shell use:
```bash
validate_input() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid input"; return 1; }
}
```

## Available Workflows

1. **Brainstorm** - Explore feature, create GitHub issue
2. **Plan** - Create implementation plan, update issue
3. **Work** - Implement feature, create PR
4. **Review cycle** - Handle PR feedback

## Routing

| User says | Load workflow |
|-----------|---------------|
| brainstorm, idea, explore | workflows/brainstorm.md |
| plan, implement | workflows/plan.md |
| work, code, build | workflows/work.md |
| review, feedback, iterate | workflows/review-cycle.md |
```

#### 1. `/workflows:brainstorm`

**Trigger**: User invokes with feature description
**Input**: Free-form text or interactive Q&A
**Output**: GitHub issue + local brainstorm doc

```markdown
# workflows/brainstorm.md

## Prerequisites

Check GitHub CLI:
```bash
if ! gh auth status &>/dev/null; then
    echo "Error: Run 'gh auth login' first"
    exit 1
fi
```

## Workflow

### Step 1: Gather Feature Description

Ask user:
- What problem does this solve?
- Who is this for?
- What's the expected scope?

### Step 2: Generate Slug

```bash
# Sanitize title to slug
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-50)
DATE=$(date +%Y-%m-%d)
DOC_PATH="docs/brainstorms/${DATE}-${SLUG}-brainstorm.md"
```

### Step 3: Create Local Document

Write brainstorm to `$DOC_PATH` with sections:
- What We're Building
- Why (problem/value)
- Scope (deliverables)
- Key Decisions
- Open Questions

### Step 4: Create GitHub Issue

```bash
# Fail fast on gh errors
ISSUE_URL=$(gh issue create \
    --title "brainstorm: $TITLE" \
    --label "brainstorm" \
    --label "feature" \
    --body-file "$DOC_PATH") || {
    echo "Error: Failed to create issue. Check: gh auth status"
    exit 1
}

# Extract and validate issue number
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oP '/issues/\K\d+')
validate_number "$ISSUE_NUM"
```

### Step 5: Output

```
Created issue #${ISSUE_NUM}: ${ISSUE_URL}
Local doc: ${DOC_PATH}

Next: Run /workflows:plan to create implementation plan
```

## Success Criteria

- [ ] Local brainstorm doc exists
- [ ] GitHub issue created with labels
- [ ] User knows next step
```

#### 2. `/workflows:plan`

**Input**: Brainstorm doc path or issue number (auto-detected from branch)
**Output**: Updated GitHub issue + local plan doc

```markdown
# workflows/plan.md

## Prerequisites

```bash
gh auth status &>/dev/null || { echo "Run: gh auth login"; exit 1; }
```

## Workflow

### Step 1: Detect and Validate Active Issue

```bash
# Try branch name first
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

ISSUE=$(echo "$BRANCH" | grep -oP 'feat/\K\d+' || echo "")

# If no issue from branch, check for recent brainstorm issues
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label brainstorm --limit 1 --json number --jq '.[0].number') || {
        echo "Error: Failed to list issues. Check: gh auth status"
        exit 1
    }
fi

# Still nothing? Ask user
if [ -z "$ISSUE" ]; then
    echo "No active issue found. Provide issue number or run /workflows:brainstorm first."
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

### Step 3: Run Planning Process

Execute standard planning workflow to generate plan content.

### Step 4: Create Local Plan Document

```bash
DATE=$(date +%Y-%m-%d)
TYPE="feat"  # or fix, refactor based on issue
SLUG=$(gh issue view "$ISSUE" --json title --jq '.title' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-50)
PLAN_PATH="docs/plans/${DATE}-${TYPE}-${SLUG}-plan.md"
```

### Step 5: Update GitHub Issue

```bash
# Combine brainstorm + plan content
COMBINED=$(cat <<EOF
$(gh issue view "$ISSUE" --json body --jq '.body')

---

## Implementation Plan

$(cat "$PLAN_PATH")
EOF
)

# Update issue - truncate if > 60KB (GitHub limit is 65KB)
if [ ${#COMBINED} -gt 60000 ]; then
    echo "Warning: Content truncated. Full plan in local doc."
    COMBINED="${COMBINED:0:60000}

... [Content truncated. See local doc: $PLAN_PATH]"
fi

gh issue edit "$ISSUE" \
    --add-label "planned" \
    --remove-label "brainstorm" \
    --body "$COMBINED"
```

### Step 6: Output

```
Updated issue #${ISSUE} with plan
Local doc: ${PLAN_PATH}

Next: Run /workflows:work to begin implementation
```
```

#### 3. `/workflows:work`

**Input**: Plan doc path or issue number (auto-detected)
**Output**: PR linked to issue + implementation

```markdown
# workflows/work.md

## Prerequisites

```bash
gh auth status &>/dev/null || { echo "Run: gh auth login"; exit 1; }

# Check for clean working tree
if ! git diff --quiet HEAD; then
    echo "Error: Uncommitted changes. Commit or stash first."
    exit 1
fi
```

## Workflow

### Step 1: Detect Active Issue

```bash
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oP 'feat/\K\d+' || echo "")

if [ -z "$ISSUE" ]; then
    # Check for planned issues
    ISSUE=$(gh issue list --label planned --limit 1 --json number --jq '.[0].number')
fi

if [ -z "$ISSUE" ]; then
    echo "No planned issue found. Run /workflows:plan first."
    exit 1
fi
```

### Step 2: Create Feature Branch (if needed)

```bash
# Generate and validate branch name
SLUG=$(gh issue view "$ISSUE" --json title --jq '.title' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-30)
EXPECTED_BRANCH="feat/${ISSUE}-${SLUG}"

# CRITICAL: Validate branch name before git operations
validate_branch "$EXPECTED_BRANCH"

if [ "$BRANCH" != "$EXPECTED_BRANCH" ]; then
    git checkout -b "$EXPECTED_BRANCH" || {
        echo "Error: Failed to create branch. Check for conflicts."
        exit 1
    }
    BRANCH="$EXPECTED_BRANCH"
fi
```

### Step 3: Implement Feature

Execute standard implementation workflow.

### Step 4: Commit and Push

```bash
git add -A
git commit -m "feat: implement #${ISSUE}"
git push -u origin "$BRANCH"
```

### Step 5: Create PR

```bash
ISSUE_TITLE=$(gh issue view "$ISSUE" --json title --jq '.title')

PR_URL=$(gh pr create \
    --title "feat: ${ISSUE_TITLE}" \
    --body "Closes #${ISSUE}

## Summary
[Implementation summary]

## Changes
[List of changes]

## Testing
- [ ] Tests pass locally
- [ ] Manual verification completed" \
    --head "$BRANCH" \
    2>&1)

if [ $? -ne 0 ]; then
    echo "Error creating PR: $PR_URL"
    exit 1
fi

PR_NUM=$(echo "$PR_URL" | grep -oP '/pull/\K\d+')
```

### Step 6: Update Issue Labels

```bash
gh issue edit "$ISSUE" --add-label "in-progress"
```

### Step 7: Output

```
Created PR #${PR_NUM}: ${PR_URL}
Linked to issue #${ISSUE}

Next: Wait for review, then run /workflows:review-cycle
```
```

#### 4. `/workflows:review-cycle`

**Input**: PR number (auto-detected from branch)
**Output**: Updated PR addressing feedback, or merge + knowledge capture

```markdown
# workflows/review-cycle.md

## Prerequisites

```bash
gh auth status &>/dev/null || { echo "Run: gh auth login"; exit 1; }
```

## Workflow

### Step 1: Detect and Validate Current PR

```bash
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

# Get PR info in single call
PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,reviewDecision,reviews) || {
    echo "No PR found for branch $BRANCH"
    exit 1
}

PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
validate_number "$PR_NUM"

REVIEW_DECISION=$(echo "$PR_INFO" | jq -r '.reviewDecision // "NONE"')
```

### Step 2: Branch on Review State

```bash
case "$REVIEW_DECISION" in
    "APPROVED")
        echo "PR approved! Proceeding to merge and compound knowledge."
        # Continue to Step 3a
        ;;
    "CHANGES_REQUESTED")
        echo "Changes requested. Analyzing feedback..."
        # Continue to Step 3b
        ;;
    "REVIEW_REQUIRED"|"NONE")
        echo "Awaiting review. No action needed yet."
        exit 0
        ;;
    *)
        echo "Review state: $REVIEW_DECISION"
        ;;
esac
```

### Step 3a: Handle Approved (Merge + Compound)

```bash
# Merge PR
gh pr merge "$PR_NUM" --squash --delete-branch

# Get linked issue
ISSUE=$(gh pr view "$PR_NUM" --json body --jq '.body' | grep -oP 'Closes #\K\d+')

# Prompt for learnings
echo "PR merged! Any learnings to capture? (y/n)"
read -r CAPTURE

if [ "$CAPTURE" = "y" ]; then
    # Create solution doc
    SLUG=$(gh pr view "$PR_NUM" --json title --jq '.title' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-30)
    SOLUTION_PATH="docs/solutions/${SLUG}.md"

    # Prompt user for learnings content
    echo "Creating solution doc at $SOLUTION_PATH"
    # ... create doc with user input

    # Link from issue
    gh issue comment "$ISSUE" --body "Learnings captured: $SOLUTION_PATH"
fi

# Close issue
gh issue close "$ISSUE"
```

### Step 3b: Handle Changes Requested

```bash
# Get review comments
COMMENTS=$(gh pr view "$PR_NUM" --json reviews --jq '.reviews[-1].body')

echo "Review feedback:"
echo "$COMMENTS"
echo ""
echo "Implementing requested changes..."

# Address comments (implementation details)
# ...

# Commit and push
git add -A
git commit -m "fix: address review feedback for PR #${PR_NUM}"
git push

# Request re-review (validate GitHub output before shell use)
REVIEWER=$(gh pr view "$PR_NUM" --json reviews --jq '.reviews[-1].author.login')
validate_username "$REVIEWER"
gh pr edit "$PR_NUM" --add-reviewer "$REVIEWER"

echo "Changes pushed. Re-review requested from @$REVIEWER"
```

### Step 4: Output

Based on action taken, output next steps.
```

### Knowledge Compounding (Simplified)

**Research Finding:** Over-structured templates add friction. Keep it simple.

**Trigger**: User says "yes" to learnings prompt after PR merge

**Process**:
1. Create `docs/solutions/{slug}.md` with free-form content
2. Link from issue comment
3. No required frontmatter or categories

```markdown
# docs/solutions/oauth-token-refresh.md

# OAuth Token Refresh Learnings

**PR:** #47 | **Issue:** #42 | **Date:** 2026-02-06

## Problem
Token refresh was failing silently when the refresh token itself expired.

## Solution
Added pre-emptive refresh 5 minutes before expiry, with exponential backoff on failures.

## Gotchas
- Google refresh tokens expire after 6 months of non-use
- Must store refresh timestamp, not just token
```

---

### Error Handling (Fail Fast)

Each skill uses simple, consistent error handling:

```bash
# Pattern: Fail immediately with clear message
gh issue create ... || {
    echo "Error: Failed to create issue. Check: gh auth status"
    exit 1
}
```

| Scenario | Behavior |
|----------|----------|
| `gh` not authenticated | "Error: Check: gh auth status" |
| Invalid input | "Invalid [field]: [value]" |
| Issue not found | "Issue #N not found on GitHub" |
| PR merge conflicts | "Error: Merge conflicts. Resolve manually." |
| Any `gh` failure | Show error output, suggest checking auth |

---

### Configuration (Simplified)

**Research Finding:** Reduce configuration by 75%. Use conventions and sensible defaults.

**workflows.json** (minimal):

```json
{
  "version": "1.0.0",
  "branch-pattern": "feat/{issue}-{slug}",
  "labels": {
    "brainstorm": ["brainstorm", "feature"],
    "planned": ["planned"],
    "in-progress": ["in-progress"]
  },
  "paths": {
    "brainstorms": "docs/brainstorms/",
    "plans": "docs/plans/",
    "solutions": "docs/solutions/"
  }
}
```

**Hardcoded defaults** (don't need config):
- Base branch: `main`
- Stale detection: Not needed (query GitHub directly)
- Auto-create labels: Just create on first use
- Content sync: Always full (no alternative implemented)

---

## Implementation Phases (Simplified)

### Phase 1: Core Skills

**Deliverables**:
- [x] Create `SKILL.md` router with essential principles and validation functions
- [x] Implement `workflows/brainstorm.md` with issue creation
- [x] Implement `workflows/plan.md` with issue updates
- [x] Implement `workflows/work.md` with PR creation
- [x] Implement `workflows/review-cycle.md` with feedback handling

**Files**:
```
.claude/skills/github-workflows/
├── SKILL.md                    # Router + principles + validation (~250 lines)
└── workflows/
    ├── brainstorm.md           # ~80 lines
    ├── plan.md                 # ~100 lines
    ├── work.md                 # ~120 lines
    └── review-cycle.md         # ~150 lines
```

### Phase 2: Documentation

**Deliverables**:
- [x] Update README with usage guide and examples
- [ ] Mark repository as template on GitHub (manual step after PR merged)

**Files**:
- `README.md` (update)

---

## Acceptance Criteria

### Functional Requirements

- [ ] `/workflows:brainstorm` creates GitHub issue with content
- [ ] `/workflows:plan` updates issue with plan, manages labels
- [ ] `/workflows:work` creates PR linked to issue
- [ ] `/workflows:review-cycle` handles approved/changes-requested states
- [ ] Primitive GitHub commands work for ad-hoc operations
- [ ] Knowledge capture prompts after merge

### Non-Functional Requirements

- [ ] Input validation on all user-provided values and GitHub API outputs
- [ ] Clear error messages with fix suggestions
- [ ] Fail-fast error handling (no complex retry logic)
- [ ] No hardcoded credentials or tokens

### Security Requirements

- [ ] Branch names validated against `^[a-zA-Z0-9/_-]+$`
- [ ] Issue/PR numbers validated as numeric before use
- [ ] GitHub API outputs (usernames, etc.) validated before shell interpolation
- [ ] No command injection via user inputs or API responses

### Quality Gates

- [ ] All skills tested end-to-end
- [ ] README documents all skills and primitives
- [ ] Example workflow completed successfully
- [ ] Repository marked as template

---

## Dependencies & Prerequisites

**Required**:
- GitHub CLI (`gh`) version 2.20+ installed and authenticated
- Git repository with GitHub remote
- Write access to repository (issues, PRs)

**Token Scopes** (minimal):
- `repo` - Repository access
- `read:org` - Read organization (if org repo)

**Validation command**:
```bash
gh auth status && echo "Ready" || echo "Run: gh auth login"
```

---

## Risk Analysis & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Command injection via input | Medium | Critical | Validate all inputs with regex before shell use |
| Command injection via API output | Medium | Critical | Validate GitHub API outputs (usernames, etc.) |
| Large content sync | Medium | Low | If sync fails, suggest local doc only |
| Branch naming conflicts | Low | Low | Validate format, fail with clear error |

---

## Security Checklist

Before implementing skills, ensure:

- [ ] All user inputs validated (type, length, format)
- [ ] All file paths validated (no path traversal)
- [ ] All shell commands use proper quoting
- [ ] No direct string interpolation into commands
- [ ] GitHub token has minimal required scopes
- [ ] No tokens or credentials in logs
- [ ] File permissions are restrictive

---

## Future Considerations

**Not in scope but worth considering later**:
- GitHub Actions for always-on review detection
- Linear integration as alternative tracker
- Multi-workflow state for parallel features
- Team assignment and reviewer routing
- GraphQL queries for complex operations (more efficient)

---

## References

### Internal References

- Brainstorm: `docs/brainstorms/2026-02-06-github-workflow-integration-brainstorm.md`
- Configuration: `workflows.json`
- Templates: `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`

### External References

- GitHub CLI Manual: https://cli.github.com/manual/
- GitHub REST API Rate Limits: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- Claude Code Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks

### Research Documents

- Claude Code Hooks Research: `docs/research/claude-code-hooks-research.md`
