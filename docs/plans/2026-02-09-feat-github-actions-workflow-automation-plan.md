---
title: "feat: Add GitHub Actions automation for workflow state management"
type: feat
date: 2026-02-09
github_issue: 3
brainstorm: docs/brainstorms/2026-02-09-github-actions-automation-brainstorm.md
---

# feat: Add GitHub Actions automation for workflow state management

## Overview

Implement GitHub Actions workflows that enhance the existing `/gw:*` skills with server-side automation. This creates a **Label-Driven State Machine** that automatically:

1. **Issue automations** - Auto-assign, validate structure, manage labels on issue events
2. **PR automations** - Verify linked issues, auto-transition labels, validate PR template compliance

## Problem Statement / Motivation

**Pain point:** The current workflow requires manual intervention at each step. Users must remember to:
- Assign issues to themselves
- Validate issue structure before planning
- Ensure PRs link to issues
- Update labels when PR opens
- Clean up labels when PR merges

**Goal:** Have GitHub itself enforce and automate state transitions, so `/gw:*` commands focus on content while GitHub handles logistics.

## Proposed Solution

Two GitHub Actions workflow files:

```
.github/workflows/
├── issue-automation.yml    # Triggers on issues events
└── pr-automation.yml       # Triggers on pull_request events
```

### Label State Machine

```
brainstorm  →  planned  →  in-progress  →  [closed]
    ↑             ↑            ↑              ↑
  Issue        Plan         PR opens       PR merges
  created      added        linked
```

## Technical Approach

### Security Requirements

All workflows must follow GitHub's security best practices:

1. **Never interpolate user input directly** - Always use intermediate env vars
2. **Minimal permissions** - Specify only required permissions per job
3. **Pin actions to SHA** - Not tags, to prevent supply chain attacks
4. **Use GITHUB_TOKEN** - Prevents workflow loops (actions taken with GITHUB_TOKEN don't trigger new runs)

### Workflow 1: Issue Automation

**File:** `.github/workflows/issue-automation.yml`

**Triggers:**
- `issues.opened` - New issue created
- `issues.labeled` - Label added to issue

**Jobs:**

| Job | Trigger | Actions |
|-----|---------|---------|
| `auto-assign` | `brainstorm` label added | Assign issue creator |
| `validate-structure` | `brainstorm` label added | Check required sections, comment if missing |
| `label-cleanup` | `planned` label added | Remove `brainstorm` label |

**Validation checks:**
- Required sections: "What We're Building", "Why", "Scope"
- Soft enforcement: Comment warning, don't block

### Workflow 2: PR Automation

**File:** `.github/workflows/pr-automation.yml`

**Triggers:**
- `pull_request.opened` - PR created
- `pull_request.closed` - PR merged or closed

**Jobs:**

| Job | Trigger | Actions |
|-----|---------|---------|
| `validate-linked-issue` | PR opened | Check for "Closes #N", comment if missing |
| `auto-label-issue` | PR opened | Add `in-progress` label to linked issue |
| `validate-template` | PR opened | Check PR has Summary, Changes sections |
| `cleanup-on-merge` | PR merged | Remove `in-progress` label from linked issue |

**Validation checks:**
- PR body contains "Closes #N" with valid issue number
- PR has required sections: Summary, Changes
- Linked issue exists

## Implementation Phases

### Phase 1: Issue Automation

Create `.github/workflows/issue-automation.yml`:

```yaml
name: Issue Automation
on:
  issues:
    types: [opened, labeled]

permissions:
  issues: write

jobs:
  auto-assign:
    if: github.event.action == 'labeled' && github.event.label.name == 'brainstorm'
    runs-on: ubuntu-latest
    steps:
      - name: Assign issue creator
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
          CREATOR: ${{ github.event.issue.user.login }}
        run: |
          gh issue edit "$ISSUE_NUMBER" --add-assignee "$CREATOR" \
            --repo "${{ github.repository }}"

  validate-structure:
    if: github.event.action == 'labeled' && github.event.label.name == 'brainstorm'
    runs-on: ubuntu-latest
    steps:
      - name: Validate required sections
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ISSUE_BODY: ${{ github.event.issue.body }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
        run: |
          missing=""

          if ! grep -qi "## What We're Building\|## What" <<< "$ISSUE_BODY"; then
            missing="$missing\n- \`## What We're Building\`"
          fi

          if ! grep -qi "## Why" <<< "$ISSUE_BODY"; then
            missing="$missing\n- \`## Why\`"
          fi

          if ! grep -qi "## Scope" <<< "$ISSUE_BODY"; then
            missing="$missing\n- \`## Scope\`"
          fi

          if [ -n "$missing" ]; then
            gh issue comment "$ISSUE_NUMBER" --repo "${{ github.repository }}" \
              --body "$(echo -e "⚠️ **Missing required sections:**\n$missing\n\nPlease update the issue to include these sections.")"
          fi

  label-cleanup:
    if: github.event.action == 'labeled' && github.event.label.name == 'planned'
    runs-on: ubuntu-latest
    steps:
      - name: Remove brainstorm label
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
        run: |
          gh issue edit "$ISSUE_NUMBER" --remove-label "brainstorm" \
            --repo "${{ github.repository }}" 2>/dev/null || true
```

- [x] Create `.github/workflows/issue-automation.yml`
- [ ] Test auto-assign on new brainstorm issue
- [ ] Test structure validation warnings
- [ ] Test label cleanup on planned transition

### Phase 2: PR Automation

Create `.github/workflows/pr-automation.yml`:

```yaml
name: PR Automation
on:
  pull_request:
    types: [opened, closed]

permissions:
  pull-requests: write
  issues: write

jobs:
  validate-linked-issue:
    if: github.event.action == 'opened'
    runs-on: ubuntu-latest
    steps:
      - name: Check for linked issue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_BODY: ${{ github.event.pull_request.body }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          # Extract issue number from "Closes #N" or "Fixes #N"
          if [[ "$PR_BODY" =~ (Closes|Fixes|Resolves)[[:space:]]*#([0-9]+) ]]; then
            ISSUE_NUMBER="${BASH_REMATCH[2]}"
            echo "✅ PR links to issue #$ISSUE_NUMBER"
            echo "LINKED_ISSUE=$ISSUE_NUMBER" >> "$GITHUB_ENV"
          else
            gh pr comment "$PR_NUMBER" --repo "${{ github.repository }}" \
              --body "⚠️ **No linked issue found.**\n\nPlease add \`Closes #N\` to the PR description to link this PR to an issue."
          fi

  auto-label-issue:
    if: github.event.action == 'opened'
    runs-on: ubuntu-latest
    steps:
      - name: Add in-progress label to linked issue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          if [[ "$PR_BODY" =~ (Closes|Fixes|Resolves)[[:space:]]*#([0-9]+) ]]; then
            ISSUE_NUMBER="${BASH_REMATCH[2]}"
            gh issue edit "$ISSUE_NUMBER" --add-label "in-progress" \
              --repo "${{ github.repository }}" 2>/dev/null || true
            gh issue edit "$ISSUE_NUMBER" --remove-label "planned" \
              --repo "${{ github.repository }}" 2>/dev/null || true
          fi

  validate-template:
    if: github.event.action == 'opened'
    runs-on: ubuntu-latest
    steps:
      - name: Validate PR template
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_BODY: ${{ github.event.pull_request.body }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          missing=""

          if ! grep -qi "## Summary" <<< "$PR_BODY"; then
            missing="$missing\n- \`## Summary\`"
          fi

          if ! grep -qi "## Changes" <<< "$PR_BODY"; then
            missing="$missing\n- \`## Changes\`"
          fi

          if [ -n "$missing" ]; then
            gh pr comment "$PR_NUMBER" --repo "${{ github.repository }}" \
              --body "$(echo -e "⚠️ **Missing PR template sections:**\n$missing\n\nPlease follow the PR template structure.")"
          fi

  cleanup-on-merge:
    if: github.event.action == 'closed' && github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - name: Remove in-progress label from linked issue
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          if [[ "$PR_BODY" =~ (Closes|Fixes|Resolves)[[:space:]]*#([0-9]+) ]]; then
            ISSUE_NUMBER="${BASH_REMATCH[2]}"
            gh issue edit "$ISSUE_NUMBER" --remove-label "in-progress" \
              --repo "${{ github.repository }}" 2>/dev/null || true
          fi
```

- [x] Create `.github/workflows/pr-automation.yml`
- [ ] Test linked issue validation
- [ ] Test auto-labeling of linked issue
- [ ] Test PR template validation
- [ ] Test cleanup on merge

### Phase 3: Documentation & Testing

- [x] Update README.md with GitHub Actions section
- [x] Update CLAUDE.md to mention automated validations
- [ ] End-to-end test: create issue → plan → PR → merge
- [ ] Verify all label transitions work correctly

## Acceptance Criteria

### Functional Requirements

- [ ] Issues with `brainstorm` label auto-assign to creator
- [ ] Issues missing required sections get comment warning
- [ ] Adding `planned` label removes `brainstorm` label
- [ ] PRs without "Closes #N" get comment warning
- [ ] PR opening adds `in-progress` label to linked issue
- [ ] PRs missing template sections get comment warning
- [ ] PR merge removes `in-progress` label from linked issue

### Non-Functional Requirements

- [ ] All user input accessed via env vars (security)
- [ ] Minimal permissions declared per job
- [ ] Soft enforcement (warnings, not blocks)
- [ ] Graceful handling of missing issues/labels

## Success Metrics

- Zero manual label management needed during workflow
- All PRs linked to issues (via warnings, compliance will increase)
- Reduced friction in the brainstorm → plan → work → merge cycle

## Dependencies & Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Workflow loops | High | Use GITHUB_TOKEN (doesn't trigger new runs) |
| Script injection | High | Always use env vars for user input |
| Rate limiting | Low | Actions are event-driven, not polling |
| Label conflicts | Low | Use 2>/dev/null for label operations |

## References

### Internal References
- Brainstorm: `docs/brainstorms/2026-02-09-github-actions-automation-brainstorm.md`
- Label config: `workflows.json` (labels section)
- Issue template: `.github/ISSUE_TEMPLATE/brainstorm.md`
- PR template: `.github/PULL_REQUEST_TEMPLATE.md`

### External References
- [GitHub Actions Security: Script Injections](https://docs.github.com/en/actions/concepts/security/script-injections)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions)
- [Issue Comment Automation](https://docs.github.com/en/actions/tutorials/manage-your-work/add-comments-with-labels)
