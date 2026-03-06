# Claude GitHub Workflows

Claude Code skills that integrate the complete **brainstorm → plan → review → work → code review → resolve** development lifecycle with GitHub issues and PRs.

## Features

- **Brainstorm** creates GitHub issues from feature exploration
- **Plan** updates issues with implementation plans
- **Plan Review** creates enhanced plans with improvements
- **Work** implements features and creates PRs linked to tracking issues
- **PR Code Review** reviews implementation quality
- **Resolve Reviews** addresses feedback systematically
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
3. Run `/gw-brainstorm` to start

### Option 2: Add to Existing Project

```bash
# Copy skills to your project
cp -r .claude/skills/gw-* YOUR_PROJECT/.claude/skills/
```

## Complete Workflow Lifecycle

```
1. /gw-brainstorm     → Explore idea & create issue
2. /gw-plan           → Create implementation plan
3. /gw-plan-review    → Review & enhance plan ⭐ NEW!
4. /gw-work           → Implement the feature
5. /gw-pr-codereview  → Review the PR code
6. /gw-resolve-reviews → Address review feedback
   └─→ (repeat 5-6 until approved, then merge)
```

### Visual Flow

```
┌─────────────────┐
│ gw-brainstorm   │ Explore idea
└────────┬────────┘
         │ Creates issue
         ↓
┌─────────────────┐
│    gw-plan      │ Plan implementation
└────────┬────────┘
         │ Updates issue with plan
         ↓
┌─────────────────┐
│ gw-plan-review  │ Review & enhance plan ⭐
└────────┬────────┘
         │ Creates enhanced plan
         ↓
┌─────────────────┐
│    gw-work      │ Implement feature
└────────┬────────┘
         │ Creates PR
         ↓
┌─────────────────┐
│ gw-pr-codereview│ Review code
└────────┬────────┘
         │ Request changes or approve
         ↓
┌─────────────────┐
│gw-resolve-reviews│ Address feedback
└────────┬────────┘
         │
         └─→ Loop back to review until approved
         ↓
       MERGE!
```

## Available Commands

| Command | Description | Output |
|---------|-------------|--------|
| `/gw-brainstorm` | Explore a feature idea through dialogue | GitHub issue with `brainstorm` label |
| `/gw-plan <issue>` | Create comprehensive implementation plan | Plan document + issue update with `planned` label |
| `/gw-plan-review <issue>` | Review plan quality & create enhanced version | Enhanced plan + review + `plan-reviewed` label |
| `/gw-work <issue>` | Implement feature following enhanced plan | Feature branch + PR linked to issue |
| `/gw-pr-codereview` | Review PR code quality and architecture | Review comments on PR |
| `/gw-resolve-reviews` | Systematically address all review feedback | Code changes + re-review requests |

## Example Usage

```bash
# 1. Start with an idea
/gw-brainstorm
> "Add user authentication with JWT"
# Creates issue #42 with brainstorm label

# 2. Create implementation plan
/gw-plan 42
# Creates plan document, updates issue #42 with planned label

# 3. Review & enhance plan
/gw-plan-review 42
# Reviews plan quality (9/10 score)
# Creates enhanced plan with improvements
# Updates issue #42 body with enhanced plan
# Adds plan-reviewed label

# 4. Implement the feature
/gw-work 42
# Creates branch: feat/42-jwt-authentication
# Implements feature following enhanced plan
# Creates PR #43 linked to issue #42

# 5. Review the code
/gw-pr-codereview
# Reviews code quality, architecture, tests
# Posts review comments on PR #43

# 6. Address review feedback
/gw-resolve-reviews
# Fetches all review comments
# Addresses each comment systematically
# Pushes changes, requests re-review

# Repeat 5-6 until approved, then:
gh pr merge 43 --squash
# PR merged, issue #42 closed
```

## What's New in v2.0

### Enhanced Plan Review Workflow

The `/gw-plan-review` skill now not only critiques plans but **creates an improved version**:

- **Reviews** plan quality with scoring (1-10)
- **Identifies** strengths and gaps
- **Creates** enhanced plan fixing all issues
- **Updates** GitHub issue with enhanced plan
- **Documents** all improvements made

**Files created:**
- `*-plan.md` - Original plan
- `*-plan-review.md` - Quality review
- `*-plan-enhanced.md` - Improved version ⭐

### Complete Code Review Cycle

New skills for systematic code review:

- `/gw-pr-codereview` - Comprehensive PR code review
- `/gw-resolve-reviews` - Systematic feedback resolution

## Configuration

Edit `workflows.json` to customize:

```json
{
  "version": "2.0.0",
  "branch-pattern": "feat/{issue}-{slug}",
  "labels": {
    "brainstorm": ["brainstorm"],
    "planned": ["planned"],
    "plan-reviewed": ["plan-reviewed"],
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
| `plan-reviewed` label added | Issue ready for implementation |

### PR Automation (`.github/workflows/pr-automation.yml`)

| Trigger | Action |
|---------|--------|
| PR opened | Checks for "Closes #N" link, warns if missing |
| PR opened | Adds `in-progress` label to linked issue |
| PR opened | Validates PR template sections |
| PR merged | Removes `in-progress` label |

### Label State Machine

```
brainstorm → planned → plan-reviewed → in-progress → [closed]
    ↑           ↑           ↑              ↑             ↑
  Issue       Plan      Plan Review     PR opens     PR merges
  created     added     enhanced        linked
```

Labels transition automatically as you use the workflow commands.

## Project Structure

```
.claude/skills/
├── gw-brainstorm/
│   └── SKILL.md          # Feature exploration
├── gw-plan/
│   └── SKILL.md          # Implementation planning
├── gw-plan-review/       # ⭐ NEW
│   └── SKILL.md          # Plan review & enhancement
├── gw-work/
│   └── SKILL.md          # Feature implementation & PR creation
├── gw-pr-codereview/     # ⭐ NEW
│   └── SKILL.md          # PR code review
└── gw-resolve-reviews/   # ⭐ NEW
    └── SKILL.md          # Review feedback resolution

.github/workflows/
├── issue-automation.yml  # Issue label/assignment automation
└── pr-automation.yml     # PR validation/label automation

docs/
├── brainstorms/          # Feature brainstorm docs
├── plans/                # Implementation plans (original + enhanced)
└── solutions/            # Captured learnings

workflows.json            # Configuration
```

## Labels Through the Cycle

| Stage | Labels |
|-------|--------|
| After brainstorm | `brainstorm`, `claude-code` |
| After plan | `planned`, `claude-code` |
| After plan-review | `planned`, `plan-reviewed`, `claude-code` |
| After PR created | (PR) `in-progress` |
| After PR approved | (PR) `approved` |
| After merge | Issue closed |

## Security

All skills validate inputs before shell use:
- Branch names: `^[a-zA-Z0-9/_-]+$`
- Issue/PR numbers: `^[0-9]+$`
- GitHub usernames: `^[a-zA-Z0-9_-]+$`
- File paths: `^[a-zA-Z0-9/_.-]+$`

## Benefits

1. **Structured** - Clear phases from idea to deployment
2. **Traceable** - Every decision documented in GitHub
3. **Quality** - Multiple review points (plan + code)
4. **Iterative** - Plan enhancement before coding saves time
5. **Automated** - Labels, branches, PRs managed automatically
6. **Compound** - Each cycle improves the next (learnings captured)

## License

MIT
