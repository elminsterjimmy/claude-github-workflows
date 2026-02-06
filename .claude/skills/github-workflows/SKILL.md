---
name: github-workflows
description: GitHub-integrated development lifecycle. Manages brainstorm → plan → work → review cycle with automatic issue/PR creation. Use when starting features, planning, creating PRs, or handling reviews.
---

# GitHub Workflows

Integrate Claude Code workflows with GitHub issues and PRs. Each skill creates or updates GitHub artifacts automatically.

## Essential Principles

### GitHub CLI Required

All operations use `gh` CLI. Check authentication before any operation:

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

### Branch Naming Convention

Branches follow: `feat/{issue-number}-{slug}`

The issue number is extracted from the branch name for automatic linking. Example: `feat/42-user-auth` links to issue #42.

### Input Validation

All user inputs and GitHub API outputs MUST be validated before shell use to prevent command injection:

```bash
# Validate branch name (alphanumeric, slash, underscore, hyphen only)
validate_branch() {
    [[ "$1" =~ ^[a-zA-Z0-9/_-]+$ ]] || { echo "Invalid branch name: $1"; exit 1; }
}

# Validate issue/PR number (numeric only)
validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}

# Validate GitHub username (alphanumeric, underscore, hyphen only)
validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid username: $1"; exit 1; }
}
```

### Error Handling

Use fail-fast pattern with clear error messages:

```bash
gh issue create ... || {
    echo "Error: Failed to create issue. Check: gh auth status"
    exit 1
}
```

## Available Workflows

| Workflow | Purpose | Creates |
|----------|---------|---------|
| **Brainstorm** | Explore feature ideas | GitHub issue + local doc |
| **Plan** | Detail implementation | Updates issue with plan |
| **Work** | Implement feature | PR linked to issue |
| **Review Cycle** | Handle PR feedback | Iteration or merge |

## Routing

| User says | Load workflow |
|-----------|---------------|
| brainstorm, idea, explore, feature idea | workflows/brainstorm.md |
| plan, design, implement, spec | workflows/plan.md |
| work, code, build, develop | workflows/work.md |
| review, feedback, iterate, changes | workflows/review-cycle.md |

## State Management

No state file needed. Query git and GitHub directly:

```bash
# Get issue from branch name
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")

# Get PR for current branch
PR=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")

# Get workflow phase from issue labels
PHASE=$(gh issue view "$ISSUE" --json labels --jq '.labels[].name' 2>/dev/null | grep -E 'brainstorm|planned|in-progress' | head -1)
```

## Configuration

See `workflows.json` in repository root:
- `branch-pattern`: Branch naming convention
- `labels`: Labels for each workflow phase
- `paths`: Directories for brainstorms, plans, solutions

## Knowledge Compounding

When PRs are approved, capture learnings in `docs/solutions/` to build institutional knowledge.
