---
name: gw
description: GitHub Workflow integration. Wraps compound-engineering workflows with GitHub issue/PR automation. Commands: /gw:brainstorm, /gw:plan, /gw:work, /gw:review-cycle, /gw:compound
---

# GitHub Workflow (gw)

Extends the development lifecycle with GitHub issue and PR integration.

**If compound-engineering plugin is available:** Wraps `/workflows:*` commands, then adds GitHub integration.

**If compound-engineering is not available:** Runs built-in workflow, then adds GitHub integration.

## Available Commands

| Command | Wraps | GitHub Integration |
|---------|-------|-------------------|
| `/gw:brainstorm` | `/workflows:brainstorm` | Creates GitHub issue |
| `/gw:plan` | `/workflows:plan` | Updates issue with plan |
| `/gw:work` | `/workflows:work` | Creates PR linked to issue |
| `/gw:review-cycle` | (standalone) | Handles PR review status |
| `/gw:compound` | `/workflows:compound` | Links learning to issue/PR |

## Prerequisites

GitHub CLI must be authenticated:

```bash
gh auth status || { echo "Run: gh auth login"; exit 1; }
```

## How Wrapping Works

Each command:
1. Checks if compound-engineering plugin exists
2. If yes: Runs the compound-engineering command, captures output paths
3. If no: Runs built-in workflow
4. Adds GitHub integration (create/update issue, create PR, etc.)

## Detection Logic

```bash
# Check for compound-engineering plugin
CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/*.md 2>/dev/null | head -1)

if [ -n "$CE_AVAILABLE" ]; then
    echo "compound-engineering detected, using wrapper mode"
else
    echo "compound-engineering not found, using standalone mode"
fi
```

## Input Validation

All commands validate inputs before shell use:

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

## Configuration

See `workflows.json` in repository root:
- `branch-pattern`: Branch naming (default: `feat/{issue}-{slug}`)
- `labels`: Labels for each phase
- `paths`: Directories for docs

## Routing

| User says | Load command |
|-----------|--------------|
| brainstorm, idea, explore | commands/brainstorm.md |
| plan, design, spec | commands/plan.md |
| work, implement, build | commands/work.md |
| review, feedback, pr status | commands/review-cycle.md |
| compound, learning, document | commands/compound.md |
