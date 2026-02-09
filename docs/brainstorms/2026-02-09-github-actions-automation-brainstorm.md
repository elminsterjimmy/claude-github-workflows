# GitHub Actions Automation Brainstorm

**Date:** 2026-02-09
**Status:** Ready for planning
**GitHub Issue:** [#3](https://github.com/elminsterjimmy/claude-github-workflows/issues/3)

## What We're Building

GitHub Actions workflows that enhance the existing `/gw:*` skills with server-side automation:

1. **Issue automations** - React to issue events (creation, labeling) to auto-assign, validate structure, and manage project boards
2. **PR automations** - React to PR events to verify linked issues, auto-transition labels, and validate PR template compliance

This is a **Label-Driven State Machine** approach where GitHub Actions complement (not replace) the Claude Code skills.

## Why

**Pain point:** Automation gaps in the current workflow require manual intervention at each step.

**Goal:** Have GitHub itself enforce and automate state transitions, so the `/gw:*` commands focus on content while GitHub handles the logistics.

## Scope

### In Scope

- [ ] Issue workflow: auto-assign creator when `brainstorm` label added
- [ ] Issue workflow: validate required sections present before accepting label
- [ ] PR workflow: verify "Closes #N" links to existing issue
- [ ] PR workflow: auto-add `in-progress` label to linked issue when PR opens
- [ ] PR workflow: validate PR follows template structure
- [ ] PR workflow: auto-transition on merge (close issue, cleanup labels)

### Out of Scope (for now)

- Project board automation (can add later)
- Scheduled stale-item checks
- Hard PR quality gates (blocking merge) - start with warnings first
- Validating local doc paths exist (GitHub can't see local files)

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Approach | Label-Driven State Machine | Simple, transparent, works with existing /gw:* flow |
| Enforcement | Soft (warnings) not hard (blocks) | Less friction to start, can tighten later |
| Integration | Enhance /gw:* commands | Don't duplicate, complement what Claude Code does |

## Open Questions

1. Should failed validations add a comment or just a check status?
2. Do we want Slack/Discord notifications for state transitions?
3. Should we use GitHub Projects for board automation, or keep it simple?

## Technical Notes

GitHub Actions to create in `.github/workflows/`:

```
.github/workflows/
├── issue-automation.yml    # Triggers on issues events
└── pr-automation.yml       # Triggers on pull_request events
```

Key events:
- `issues.labeled` - React to label changes
- `issues.opened` - New issue created
- `pull_request.opened` - New PR created
- `pull_request.closed` (merged) - PR merged

## Next Steps

Run `/workflows:plan` to create detailed implementation plan.
