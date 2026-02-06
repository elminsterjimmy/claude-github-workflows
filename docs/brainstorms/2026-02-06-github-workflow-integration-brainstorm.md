# GitHub Workflow Integration Brainstorm

**Date:** 2026-02-06
**Status:** Ready for planning
**Feature:** GitHub-integrated development lifecycle with compound knowledge

## What We're Building

A **template repository** containing Claude Code skills that integrate the brainstorm → plan → work → review lifecycle with GitHub issues and PRs. The system:

1. **Creates GitHub issues** when brainstorming begins, with full content sync
2. **Updates issues** with finalized plans from the planning phase
3. **Creates PRs** when work is complete, linked to the tracking issue
4. **Handles review feedback** via event-driven hooks that detect review activity
5. **Iterates on the same issue** when reviews fail (no new issues per attempt)
6. **Compounds knowledge** by capturing learnings in `docs/solutions/`

Projects adopt the skills via GitHub template or by copying the skills directory.

## Scope

### Core Deliverables
- Template repository structure with `.claude/skills/github-workflows/`
- Enhanced `brainstorm` skill that creates/updates GitHub issues
- Enhanced `plan` skill that updates issues with finalized plans
- Enhanced `work` skill that creates PRs linked to issues
- New `review-cycle` skill for handling review feedback
- Event-driven hooks for detecting PR review activity
- Issue and PR templates for consistency

### Distribution Mechanism
- GitHub template repository
- `workflows.json` manifest for project configuration
- Documentation for adoption and customization

### Out of Scope
- MCP plugin modifications
- Changes to compound-engineering
- Automatic webhook infrastructure
- GitHub Actions automation (beyond existing CI)

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Review failure handling | Same issue, iterate | Keeps all context in one place, shows evolution |
| Knowledge capture | docs/solutions/ only | Follows existing pattern, searchable locally |
| Automation model | Event-driven hooks | Reactive without polling infrastructure |
| Issue content | Full content sync | GitHub is self-contained, readable without local docs |
| Distribution | GitHub template repo | Simple adoption, git-based updates, works today |
| Skill location | Separate template repo | Shareable across projects, opt-in adoption |

## Implementation Notes

### Workflow Lifecycle

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Brainstorm │────▶│    Plan     │────▶│    Work     │────▶│   Review    │
│             │     │             │     │             │     │             │
│ Creates     │     │ Updates     │     │ Creates PR  │     │ Monitors    │
│ GitHub      │     │ issue with  │     │ linked to   │     │ via hooks   │
│ Issue       │     │ plan        │     │ issue       │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                                    ┌──────────────┼──────────────┐
                                                    │              │              │
                                                    ▼              ▼              ▼
                                              ┌──────────┐  ┌──────────┐  ┌──────────┐
                                              │ Approved │  │ Changes  │  │ Rejected │
                                              │          │  │ Requested│  │          │
                                              │ Close    │  │          │  │ Re-plan  │
                                              │ issue    │  │ Iterate  │  │ same     │
                                              │ Compound │  │ same     │  │ issue    │
                                              │ learning │  │ issue    │  │          │
                                              └──────────┘  └──────────┘  └──────────┘
```

### Template Repository Structure

```
claude-code-github-workflows/
├── .claude/
│   ├── skills/
│   │   └── github-workflows/
│   │       ├── SKILL.md              # Main skill documentation
│   │       ├── brainstorm.md         # Enhanced brainstorm skill
│   │       ├── plan.md               # Enhanced plan skill
│   │       ├── work.md               # Enhanced work skill
│   │       ├── review-cycle.md       # Review feedback handler
│   │       └── helpers/
│   │           ├── issue-creator.md  # GitHub issue creation logic
│   │           ├── pr-creator.md     # PR creation logic
│   │           └── hooks-config.md   # Hook configuration guide
│   ├── hooks/
│   │   └── post-fetch.sh             # Hook for detecting review activity
│   └── settings.json                 # Permissions for gh commands
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── brainstorm.md             # Template for brainstorm issues
│   │   └── config.yml
│   └── PULL_REQUEST_TEMPLATE.md      # Template for PRs
├── workflows.json                     # Manifest for configuration
└── README.md                          # Adoption guide
```

### workflows.json Manifest

```json
{
  "version": "1.0.0",
  "name": "github-workflows",
  "description": "GitHub-integrated development lifecycle skills",
  "skills": {
    "brainstorm": {
      "creates": "github-issue",
      "labels": ["brainstorm", "feature"],
      "content": "full-sync"
    },
    "plan": {
      "updates": "github-issue",
      "labels": ["planned"],
      "content": "full-sync"
    },
    "work": {
      "creates": "pull-request",
      "links": "github-issue",
      "branch-pattern": "feat/{issue-number}-{slug}"
    },
    "review-cycle": {
      "on-approved": "close-issue",
      "on-changes-requested": "iterate",
      "on-rejected": "re-plan",
      "compound": "docs/solutions/"
    }
  },
  "hooks": {
    "post-fetch": "check-review-status"
  }
}
```

### Event-Driven Hooks

The system uses Claude Code hooks to react to git events:

1. **post-fetch hook**: After `git fetch`, checks if any open PRs have new reviews
2. **Detection logic**: Uses `gh pr view --json reviews` to check review status
3. **User notification**: If reviews detected, prompts user with next action

### Issue Content Sync Format

When creating/updating GitHub issues, the full brainstorm/plan content is synced:

```markdown
## Brainstorm: {Title}

**Date:** {date}
**Local doc:** `docs/brainstorms/{filename}`

### What We're Building
{content}

### Scope
{scope bullets}

### Key Decisions
{decisions table}

---

## Plan (Added after planning phase)

**Local doc:** `docs/plans/{filename}`

### Overview
{plan overview}

### Implementation Phases
{phases}

### Acceptance Criteria
{criteria as task list}
```

### Iteration Tracking

When a review fails and iteration is needed, the issue is updated with:

```markdown
---

## Iteration {n} - {date}

**Review feedback:** {summary of changes requested}
**Action taken:** {re-brainstorm | re-plan | code-fix}

### Changes
- {change 1}
- {change 2}

### Updated Plan
{if re-planned, include new plan section}
```

### Knowledge Compounding

When a PR is approved and merged:

1. Check if any learnings were captured during iterations
2. If issues were encountered, create `docs/solutions/{category}/{issue}.md`
3. Follow existing frontmatter format with tags, symptoms, solution
4. Link back to the GitHub issue/PR for context

## Open Questions

1. **Hook complexity**: How much logic should live in hooks vs. skills? Hooks should be lightweight triggers, skills do the work.

2. **Offline mode**: What happens if GitHub is unreachable? Skills should gracefully degrade to local-only mode.

3. **Multi-issue PRs**: Should one PR ever span multiple issues? For now, 1:1 relationship is simpler.

4. **Template updates**: How do projects pull updates from the template? Document git remote add + merge strategy.

## Next Steps

Run `/workflows:plan docs/brainstorms/2026-02-06-github-workflow-integration-brainstorm.md`
