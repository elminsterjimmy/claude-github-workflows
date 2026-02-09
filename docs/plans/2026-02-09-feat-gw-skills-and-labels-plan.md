---
title: "feat: GW Skills Restructure and Enhanced Labels"
type: feat
date: 2026-02-09
issue: 5
---

# feat: GW Skills Restructure and Enhanced Labels

## Overview

Restructure the `github-workflows` skill into four standalone skills (`gw-brainstorm`, `gw-plan`, `gw-work`, `gw-review`) that appear in Claude Code CLI auto-complete, and add meaningful labels to GitHub issues.

## Technical Approach

### Skill Structure

Each workflow becomes a standalone skill in its own directory:

```
.claude/skills/
├── gw-brainstorm/
│   └── SKILL.md
├── gw-plan/
│   └── SKILL.md
├── gw-work/
│   └── SKILL.md
└── gw-review/
    └── SKILL.md
```

Each SKILL.md contains:
1. Frontmatter with `name` and `description` for auto-complete registration
2. Complete workflow instructions (self-contained, no external references)
3. Enhanced label handling

### Label System

| Label | When Applied | Color |
|-------|--------------|-------|
| `claude-code` | All issues created by gw-* skills | Purple (#7C3AED) |
| User-provided function label | During brainstorm (free-form) | Default |
| `brainstorm` | After gw-brainstorm | - |
| `planned` | After gw-plan | - |
| `in-progress` | After gw-work | - |

### Label Creation Logic

```bash
# Create label if it doesn't exist
ensure_label() {
    local label="$1"
    gh label list --search "$label" --json name --jq '.[].name' | grep -qx "$label" || \
        gh label create "$label" --color "ededed" 2>/dev/null || true
}
```

## Implementation Phases

### Phase 1: Create New Skills Structure

- [ ] Create `gw-brainstorm/SKILL.md` with enhanced label prompting
- [ ] Create `gw-plan/SKILL.md`
- [ ] Create `gw-work/SKILL.md`
- [ ] Create `gw-review/SKILL.md`

### Phase 2: Migrate Workflow Content

- [ ] Copy and adapt brainstorm workflow content
- [ ] Copy and adapt plan workflow content
- [ ] Copy and adapt work workflow content
- [ ] Copy and adapt review-cycle workflow content

### Phase 3: Add Label Enhancements

- [ ] Add `claude-code` label to all issue creation commands
- [ ] Add function label prompt to gw-brainstorm
- [ ] Add label creation helper function to ensure labels exist

### Phase 4: Cleanup

- [ ] Remove old `github-workflows` directory
- [ ] Update CLAUDE.md with new skill names

## Acceptance Criteria

### Functional Requirements

- [ ] `/gw-brainstorm` appears in CLI auto-complete
- [ ] `/gw-plan` appears in CLI auto-complete
- [ ] `/gw-work` appears in CLI auto-complete
- [ ] `/gw-review` appears in CLI auto-complete
- [ ] All created issues have `claude-code` label
- [ ] User can provide custom function labels during brainstorm
- [ ] Status labels transition correctly: brainstorm → planned → in-progress

### Non-Functional Requirements

- [ ] Each skill is self-contained (no external file references)
- [ ] Skills follow existing naming/structure conventions
- [ ] Input validation preserved for security

## Dependencies

- GitHub CLI (`gh`) must be installed and authenticated
- Existing label `claude-code` (already created)

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Label creation fails | Low | Low | Use `|| true` to continue on error |
| Skills don't appear in auto-complete | Medium | High | Test each skill after creation |
| Content duplication across skills | Medium | Low | Accept duplication for self-containment |
