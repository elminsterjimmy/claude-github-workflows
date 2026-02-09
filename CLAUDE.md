# CLAUDE.md

This repository provides Claude Code skills for GitHub-integrated development workflows.

## Overview

These skills connect the brainstorm → plan → work → review lifecycle with GitHub issues and PRs, enabling compound knowledge capture.

## Available Skills

Run these commands in any project that has adopted these skills:

- `/workflows:brainstorm` - Explore a feature idea, creates GitHub issue
- `/workflows:plan` - Create implementation plan, updates issue
- `/workflows:work` - Begin implementation, creates PR
- `/workflows:review-cycle` - Handle PR review feedback

## Configuration

Edit `workflows.json` to customize labels, branch patterns, and paths.

## Requirements

- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth login` if not authenticated

## Adding to a Project

Copy `.claude/skills/github-workflows/` to your project's `.claude/skills/` directory.

## GitHub Actions Automation

This repository includes GitHub Actions that automatically:

- **Issue automation**: Auto-assigns creators, validates structure, manages label transitions
- **PR automation**: Validates linked issues, auto-labels, cleans up on merge

Labels transition automatically: `brainstorm` → `planned` → `in-progress` → closed.

See `.github/workflows/` for implementation details.
