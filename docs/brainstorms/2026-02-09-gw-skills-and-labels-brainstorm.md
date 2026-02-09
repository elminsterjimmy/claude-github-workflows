# Brainstorm: GW Skills Restructure and Enhanced Labels

**Date:** 2026-02-09
**Status:** Ready for planning

## What We're Building

Restructure GitHub workflow skills for better discoverability and add meaningful labels to issues created by Claude Code.

### 1. Standalone Skills for Auto-complete

Split the current `github-workflows` router into four standalone skills:
- `/gw-brainstorm` - Explore feature ideas
- `/gw-plan` - Create implementation plans
- `/gw-work` - Begin implementation
- `/gw-review` - Handle PR feedback

Each skill gets its own `SKILL.md` file so it appears in Claude Code CLI auto-complete.

### 2. Enhanced Issue Labels

Apply meaningful labels to all GitHub issues:

| Label Type | Example | Purpose |
|------------|---------|---------|
| Origin | `claude-code` | Mark issues created via Claude Code workflows |
| Function | User-provided (free input) | Describe what the issue is about (e.g., `auth`, `ui`, `api`) |
| Status | `brainstorm`, `planned`, `in-progress` | Current workflow phase |

## Why

- **Discoverability:** Current sub-workflows don't appear in CLI auto-complete, making them hard to find
- **Traceability:** No way to identify which issues were created via Claude Code
- **Organization:** Function labels help categorize and filter issues

## Scope

### Deliverables
- Restructure `.claude/skills/` with 4 separate skill directories
- Each skill has its own `SKILL.md` for auto-complete registration
- Update workflows to prompt for function labels (free-form input)
- Apply `claude-code` label automatically to all created issues
- Keep status labels (`brainstorm`, `planned`, `in-progress`) as-is

### Out of Scope
- Changing the workflow logic itself
- Automated label detection (staying with user input)
- Predefined function label list

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skill naming | `gw-*` prefix | Shorter, easier to remember |
| Function labels | Free-form input | Flexibility over consistency |
| Origin label | `claude-code` | Clear identification of automated issues |
| Keep router? | Remove | Four standalone skills are sufficient |

## Open Questions

1. Should shared workflow utilities be extracted to a common location?
2. What color should the `claude-code` label be in GitHub?

## Next Steps

Run `/gw-plan` to create implementation plan.
