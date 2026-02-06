# Claude GitHub Workflows (gw)

Claude Code skills that add GitHub issue/PR integration to the development lifecycle.

**If compound-engineering plugin is installed:** Wraps `/workflows:*` commands with GitHub integration.

**If compound-engineering is not installed:** Provides standalone workflow with GitHub integration.

## Features

- `/gw:brainstorm` - Explore ideas, create GitHub issue
- `/gw:plan` - Create implementation plan, update issue
- `/gw:work` - Implement feature, create PR linked to issue
- `/gw:review-cycle` - Handle PR review status
- `/gw:compound` - Capture learnings, link to issue/PR

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
3. Run `/gw:brainstorm` to start

### Option 2: Add to Existing Project

```bash
# Copy skills to your project
cp -r .claude/skills/gw YOUR_PROJECT/.claude/skills/
cp workflows.json YOUR_PROJECT/
```

## Workflow Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│/gw:brainstorm────▶│  /gw:plan   │────▶│  /gw:work   │────▶│/gw:review-  │
│             │     │             │     │             │     │    cycle    │
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
                                              │/gw:compound │ + Push   │  │          │
                                              └──────────┘  └──────────┘  └──────────┘
```

## Commands

| Command | Wraps | GitHub Integration |
|---------|-------|-------------------|
| `/gw:brainstorm` | `/workflows:brainstorm` | Creates GitHub issue |
| `/gw:plan` | `/workflows:plan` | Updates issue with plan |
| `/gw:work` | `/workflows:work` | Creates PR linked to issue |
| `/gw:review-cycle` | (standalone) | Handles PR review status |
| `/gw:compound` | `/workflows:compound` | Links learning to issue/PR |

## Example Usage

```bash
# 1. Start with an idea
/gw:brainstorm add user authentication
# → Runs brainstorm workflow
# → Creates GitHub issue #42

# 2. Create implementation plan
/gw:plan
# → Runs planning workflow
# → Updates issue #42 with plan

# 3. Implement the feature
/gw:work
# → Creates branch feat/42-user-auth
# → Runs implementation
# → Creates PR linked to #42

# 4. Handle review feedback
/gw:review-cycle
# → Checks PR status
# → Addresses feedback or merges

# 5. Capture learnings (optional)
/gw:compound oauth token refresh
# → Documents learning
# → Links to issue/PR
```

## How It Works

Each `/gw:*` command:

1. **Checks for compound-engineering plugin**
   ```bash
   CE_AVAILABLE=$(ls ~/.claude/plugins/cache/*/compound-engineering/*/commands/workflows/*.md 2>/dev/null | head -1)
   ```

2. **If available:** Runs the compound-engineering workflow, then adds GitHub integration

3. **If not available:** Runs built-in workflow, then adds GitHub integration

This means you get the full power of compound-engineering (research agents, reviewers, etc.) when available, with graceful fallback when not.

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

## Project Structure

```
.claude/skills/gw/
├── SKILL.md              # Router and principles
└── commands/
    ├── brainstorm.md     # /gw:brainstorm
    ├── plan.md           # /gw:plan
    ├── work.md           # /gw:work
    ├── review-cycle.md   # /gw:review-cycle
    └── compound.md       # /gw:compound

docs/
├── brainstorms/          # Feature brainstorm docs
├── plans/                # Implementation plans
└── solutions/            # Captured learnings

workflows.json            # Configuration
```

## Security

All commands validate inputs before shell use:
- Branch names: `^[a-zA-Z0-9/_-]+$`
- Issue/PR numbers: `^[0-9]+$`
- GitHub usernames: `^[a-zA-Z0-9_-]+$`

## vs compound-engineering workflows

| Feature | `/workflows:*` | `/gw:*` |
|---------|---------------|---------|
| Local docs | Yes | Yes |
| GitHub issues | No | **Yes** |
| GitHub PRs | Manual | **Automatic** |
| Issue linking | No | **Yes** |
| Review handling | Code review | **PR status** |
| Requires compound-engineering | Yes | **Optional** |

## License

MIT
