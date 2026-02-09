# Claude GitHub Workflows

Claude Code skills that integrate the **brainstorm → plan → work → review** lifecycle with GitHub issues and PRs.

## Features

- **Brainstorm** creates GitHub issues from feature exploration
- **Plan** updates issues with implementation plans
- **Work** creates PRs linked to tracking issues
- **Review Cycle** handles feedback and merges
- **Compound Knowledge** captures learnings in `docs/solutions/`

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- Claude Code

```bash
# Check gh is ready
gh auth status || gh auth login
```

## Quick Start

### Option 1: Use as Template

1. Click "Use this template" on GitHub
2. Clone your new repository
3. Run `/workflows:brainstorm` to start

### Option 2: Add to Existing Project

```bash
# Copy skills to your project
cp -r .claude/skills/github-workflows YOUR_PROJECT/.claude/skills/
cp workflows.json YOUR_PROJECT/
```

## Workflow Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Brainstorm │────▶│    Plan     │────▶│    Work     │────▶│   Review    │
│             │     │             │     │             │     │   Cycle     │
│ Creates     │     │ Updates     │     │ Creates PR  │     │ Handles     │
│ GitHub      │     │ issue with  │     │ linked to   │     │ feedback    │
│ Issue       │     │ plan        │     │ issue       │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                                    ┌──────────────┼──────────────┐
                                                    ▼              ▼              ▼
                                              ┌──────────┐  ┌──────────┐  ┌──────────┐
                                              │ Approved │  │ Changes  │  │ Awaiting │
                                              │          │  │ Requested│  │ Review   │
                                              │ Merge +  │  │ Address  │  │ No action│
                                              │ Close    │  │ + Push   │  │          │
                                              └──────────┘  └──────────┘  └──────────┘
```

## Available Commands

| Command | Description |
|---------|-------------|
| `/workflows:brainstorm` | Explore a feature idea, create GitHub issue |
| `/workflows:plan` | Create implementation plan, update issue |
| `/workflows:work` | Implement feature, create PR |
| `/workflows:review-cycle` | Handle PR review feedback |

## Example Usage

```bash
# 1. Start with an idea
/workflows:brainstorm
# Claude asks about your feature, creates issue #42

# 2. Create implementation plan
/workflows:plan
# Claude creates detailed plan, updates issue #42

# 3. Implement the feature
/workflows:work
# Claude implements, creates PR linked to #42

# 4. Handle review feedback
/workflows:review-cycle
# Claude checks PR status, addresses feedback or merges
```

## Configuration

Edit `workflows.json` to customize:

```json
{
  "version": "1.0.0",
  "branch-pattern": "feat/{issue}-{slug}",
  "labels": {
    "brainstorm": ["brainstorm"],
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

## GitHub Actions Automation

This project includes GitHub Actions that automatically manage workflow state:

### Issue Automation (`.github/workflows/issue-automation.yml`)

| Trigger | Action |
|---------|--------|
| `brainstorm` label added | Auto-assigns issue to creator |
| `brainstorm` label added | Validates required sections (What, Why, Scope) |
| `planned` label added | Removes `brainstorm` label |

### PR Automation (`.github/workflows/pr-automation.yml`)

| Trigger | Action |
|---------|--------|
| PR opened | Checks for "Closes #N" link, warns if missing |
| PR opened | Adds `in-progress` label to linked issue |
| PR opened | Validates PR template sections |
| PR merged | Removes `in-progress` label |

### Label State Machine

```
brainstorm  →  planned  →  in-progress  →  [closed]
    ↑             ↑            ↑              ↑
  Issue        Plan         PR opens       PR merges
  created      added        linked
```

Labels transition automatically as you use the workflow commands.

## Project Structure

```
.claude/skills/github-workflows/
├── SKILL.md              # Router with principles
└── workflows/
    ├── brainstorm.md     # Feature exploration
    ├── plan.md           # Implementation planning
    ├── work.md           # PR creation
    └── review-cycle.md   # Review handling

.github/workflows/
├── issue-automation.yml  # Issue label/assignment automation
└── pr-automation.yml     # PR validation/label automation

docs/
├── brainstorms/          # Feature brainstorm docs
├── plans/                # Implementation plans
└── solutions/            # Captured learnings

workflows.json            # Configuration
```

## Security

All skills validate inputs before shell use:
- Branch names: `^[a-zA-Z0-9/_-]+$`
- Issue/PR numbers: `^[0-9]+$`
- GitHub usernames: `^[a-zA-Z0-9_-]+$`

## License

MIT
