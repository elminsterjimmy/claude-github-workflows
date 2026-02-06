# CLAUDE.md

This repository provides Claude Code skills for GitHub-integrated development workflows.

## Overview

The `/gw:*` commands wrap compound-engineering's `/workflows:*` commands with automatic GitHub issue/PR integration. If compound-engineering is not installed, built-in workflows are used instead.

## Available Commands

| Command | Description |
|---------|-------------|
| `/gw:brainstorm` | Explore a feature idea, create GitHub issue |
| `/gw:plan` | Create implementation plan, update issue |
| `/gw:work` | Implement feature, create PR linked to issue |
| `/gw:review-cycle` | Handle PR review feedback |
| `/gw:compound` | Capture learnings, link to issue/PR |

## Workflow

```
/gw:brainstorm → /gw:plan → /gw:work → /gw:review-cycle
      ↓              ↓           ↓            ↓
   Issue #N     Update #N    PR → #N    Merge or iterate
```

## Requirements

- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth login` if not authenticated

## Configuration

Edit `workflows.json` to customize labels, branch patterns, and paths.

## Adding to a Project

Copy `.claude/skills/gw/` to your project's `.claude/skills/` directory.
