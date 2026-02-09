# CLAUDE.md

This repository provides Claude Code skills for GitHub-integrated development workflows.

## Overview

These skills connect the brainstorm → plan → work → review lifecycle with GitHub issues and PRs, enabling compound knowledge capture.

## Available Skills

Run these commands in any project that has adopted these skills:

- `/gw-brainstorm` - Explore a feature idea, creates GitHub issue with `claude-code` label
- `/gw-plan` - Create implementation plan, updates issue
- `/gw-work` - Begin implementation, creates PR
- `/gw-review` - Handle PR review feedback

## Labels

All issues and PRs created by these skills are automatically labeled with `claude-code` for traceability. Additional labels:

| Label | Applied by | Purpose |
|-------|-----------|---------|
| `claude-code` | All skills | Identifies Claude Code-created artifacts |
| `brainstorm` | `/gw-brainstorm` | Initial exploration phase |
| `planned` | `/gw-plan` | Implementation plan complete |
| `in-progress` | `/gw-work` | Work has begun |
| Custom labels | `/gw-brainstorm` | User-provided function labels |

## Requirements

- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth login` if not authenticated

## Adding to a Project

Copy the skill directories to your project:

```bash
cp -r .claude/skills/gw-* /path/to/your/project/.claude/skills/
```

## GitHub Actions Automation

This repository includes GitHub Actions that automatically:

- **Issue automation**: Auto-assigns creators, validates structure, manages label transitions
- **PR automation**: Validates linked issues, auto-labels, cleans up on merge

Labels transition automatically: `brainstorm` → `planned` → `in-progress` → closed.

See `.github/workflows/` for implementation details.
