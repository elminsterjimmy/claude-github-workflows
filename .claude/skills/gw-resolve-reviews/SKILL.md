---
name: gw-resolve-reviews
description: Resolve all PR comments on the current branch - fetch all review comments and inline comments, search project knowledge (skills, scripts, docs, solutions), address each comment, push changes, and compound learnings. Use when PR has review feedback to address regardless of approval status.
---

# Resolve PR Reviews Workflow

Resolve all PR comments on the current branch: fetch all review comments and inline comments, search project resources for relevant knowledge, address each comment, push changes, and capture learnings.

## Prerequisites

Check GitHub CLI authentication:

```bash
gh auth status || { echo "Error: Run 'gh auth login' first"; exit 1; }
```

## Input Validation

```bash
# Validate inputs before shell use
validate_branch() {
    [[ "$1" =~ ^[a-zA-Z0-9/_-]+$ ]] || { echo "Invalid branch name: $1"; exit 1; }
}

validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "Invalid number: $1"; exit 1; }
}

validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid username: $1"; exit 1; }
}
```

## Workflow

### Step 1: Detect Current PR and Fetch Latest Changes

```bash
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

# Fetch latest changes from remote to ensure we have up-to-date review comments
echo "Fetching latest changes from remote..."
git fetch origin "$BRANCH" 2>/dev/null || echo "Warning: Could not fetch from remote"

# Get PR info in single API call
PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,body 2>/dev/null) || {
    echo "No PR found for branch: $BRANCH"
    echo "Create a PR first with /gw-work"
    exit 1
}

PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
validate_number "$PR_NUM"

PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')

echo "PR #${PR_NUM}: $PR_TITLE"
echo ""
echo "🔄 Refreshing review data from GitHub..."
```

### Step 2: Fetch All Comments

**IMPORTANT:** Always fetch fresh review data from GitHub API to ensure you have the latest feedback.

Gather all types of review feedback:

#### Get Review Comments (Inline Code Comments)

**Note:** GitHub API caches may be stale. Always fetch with explicit API calls.

```bash
# Get all review comments (inline comments on code) with fresh API call
echo "Fetching inline review comments..."
REVIEW_COMMENTS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/comments --jq '.[] | {id: .id, path: .path, line: .line, body: .body, user: .user.login, created_at: .created_at}' 2>/dev/null)

REVIEW_COMMENT_COUNT=0
if [ -n "$REVIEW_COMMENTS" ]; then
    REVIEW_COMMENT_COUNT=$(echo "$REVIEW_COMMENTS" | jq -s 'length' 2>/dev/null || echo "0")
    echo ""
    echo "=== Inline Review Comments (${REVIEW_COMMENT_COUNT}) ==="
    echo "$REVIEW_COMMENTS"
else
    echo "✓ No inline review comments"
fi
```

#### Get PR Conversation Comments

```bash
# Get PR conversation comments with fresh data
echo ""
echo "Fetching PR conversation comments..."
PR_COMMENTS=$(gh pr view "$PR_NUM" --json comments --jq '.comments[] | {id: .id, body: .body, author: .author.login, createdAt: .createdAt}' 2>/dev/null)

PR_COMMENT_COUNT=0
if [ -n "$PR_COMMENTS" ]; then
    PR_COMMENT_COUNT=$(echo "$PR_COMMENTS" | jq -s 'length' 2>/dev/null || echo "0")
    echo ""
    echo "=== PR Conversation Comments (${PR_COMMENT_COUNT}) ==="
    echo "$PR_COMMENTS"
else
    echo "✓ No PR conversation comments"
fi
```

#### Get Review Submissions

```bash
# Get review submissions with their bodies - ALWAYS FETCH FRESH
echo ""
echo "Fetching review submissions..."
REVIEWS=$(gh pr view "$PR_NUM" --json reviews --jq '.reviews[] | {id: .id, state: .state, body: .body, author: .author.login, submittedAt: .submittedAt}' 2>/dev/null)

REVIEW_COUNT=0
if [ -n "$REVIEWS" ]; then
    REVIEW_COUNT=$(echo "$REVIEWS" | jq -s 'length' 2>/dev/null || echo "0")
    echo ""
    echo "=== Review Submissions (${REVIEW_COUNT}) ==="
    echo "$REVIEWS"

    # Count reviews by state
    CHANGES_REQUESTED=$(echo "$REVIEWS" | jq -s '[.[] | select(.state == "CHANGES_REQUESTED")] | length' 2>/dev/null || echo "0")
    APPROVED=$(echo "$REVIEWS" | jq -s '[.[] | select(.state == "APPROVED")] | length' 2>/dev/null || echo "0")
    COMMENTED=$(echo "$REVIEWS" | jq -s '[.[] | select(.state == "COMMENTED")] | length' 2>/dev/null || echo "0")

    echo ""
    echo "Review Status Summary:"
    echo "  - Changes Requested: ${CHANGES_REQUESTED}"
    echo "  - Approved: ${APPROVED}"
    echo "  - Commented: ${COMMENTED}"
else
    echo "✓ No review submissions"
fi

# Calculate total actionable items
TOTAL_ITEMS=$((REVIEW_COMMENT_COUNT + PR_COMMENT_COUNT + REVIEW_COUNT))
echo ""
echo "📋 Total review items to address: ${TOTAL_ITEMS}"

if [ "$TOTAL_ITEMS" -eq 0 ]; then
    echo ""
    echo "✅ No review comments to address. PR is clean!"
    exit 0
fi
```

### Step 3: Search Project Knowledge

Before addressing comments, search project resources for relevant solutions and patterns:

#### Search Documented Solutions

```bash
# Search for relevant solutions in docs/solutions/
find docs/solutions -name "*.md" -exec grep -l "<keyword>" {} \; 2>/dev/null

# Parse YAML frontmatter for matching symptoms, tags, or categories
grep -r "symptoms:" docs/solutions/ | grep -i "<keyword>"
grep -r "tags:" docs/solutions/ | grep -i "<keyword>"
```

**Search locations:**
- `docs/solutions/**/*.md` - Documented problem solutions with YAML frontmatter
- Look for matching `symptoms`, `tags`, `category`, `module` in frontmatter

#### Search Skills and Scripts

```bash
# Search skills for relevant workflows
find .claude/skills -name "SKILL.md" -exec grep -l "<keyword>" {} \; 2>/dev/null

# Search scripts for relevant utilities
find .claude/skills -name "*.py" -o -name "*.sh" -exec grep -l "<keyword>" {} \; 2>/dev/null
```

**Search locations:**
- `.claude/skills/**/SKILL.md` - Skill workflows and instructions
- `.claude/skills/**/scripts/` - Utility scripts
- `.claude/skills/**/references/` - Reference documentation

#### Search Project Documentation

```bash
# Search project docs
find docs -name "*.md" -exec grep -l "<keyword>" {} \; 2>/dev/null

# Search README and guidelines
grep -r "<keyword>" README.md CLAUDE.md GUIDELINES.md 2>/dev/null
```

**Search locations:**
- `docs/**/*.md` - Project documentation
- `CLAUDE.md` - Project conventions
- `GUIDELINES.md` - Code guidelines

### Step 4: Analyze and Categorize Comments

For each comment, determine:
1. **File/location**: Which file and line the comment refers to
2. **Action required**: What change is being requested
3. **Relevant knowledge**: What documented solutions or patterns apply
4. **Priority**: Address blocking issues first

Create a summary:

```
Comment Analysis:
- Total inline comments: {count}
- Total PR comments: {count}
- Reviews with feedback: {count}

Relevant Knowledge Found:
- docs/solutions/{file}.md: {applicable pattern}
- .claude/skills/{skill}/SKILL.md: {relevant workflow}

Action Items:
1. {file:line} - {summary of requested change} [applies: {knowledge reference}]
2. {file:line} - {summary of requested change}
...
```

### Step 5: Address Each Comment

For each comment that requires action:

1. **Review relevant knowledge** from Step 3
2. **Navigate to the location** (file and line)
3. **Understand the context** of the requested change
4. **Make the change** following documented patterns
5. **Track completion** for the commit message

### Step 6: Update Architecture Documentation (If Needed)

After addressing review comments, check whether any changes affect the project's architecture or structure. Review comments sometimes request structural refactors, new abstractions, or pattern changes that make existing docs stale.

**Triggers — update docs when review changes:**
- Added or removed files, modules, or packages
- Changed entry points, request flow, or routing
- Introduced new integrations, protocols, or APIs
- Modified deployment or infrastructure configuration
- Changed core patterns, abstractions, or conventions

**Documents to check and update:**

| Document | Update when |
|----------|------------|
| `CLAUDE.md` | Architecture section, file tree, key patterns, or env vars are stale |
| `README.md` | Project overview, architecture tree, or feature list is outdated |
| Architecture docs (e.g. `docs/architecture/`) | Technical flows or diagrams no longer match the code |

**Rules:**
1. Read the existing doc before editing — understand its structure
2. Make **minimal, surgical edits** — only update affected sections
3. Match the existing tone, formatting, and detail level
4. Stage doc updates alongside code changes in the same commit
5. Skip this step entirely for non-structural changes (style fixes, variable renames, test additions, comment updates)

### Step 7: Verify Pipeline Requirements

Before committing, ensure all pipeline requirements are met:

```bash
# Run tests and coverage verification
echo "Running tests and coverage verification..."
mvn verify -pl core

# Check exit code
if [ $? -ne 0 ]; then
    echo "❌ Pipeline verification failed!"
    echo ""
    echo "Common issues:"
    echo "- Tests failing"
    echo "- Coverage below 80% threshold (instruction or branch)"
    echo "- Build errors"
    echo ""
    echo "Fix issues before committing."
    exit 1
fi

echo "✅ Pipeline requirements met:"
echo "  - All tests passing"
echo "  - Coverage thresholds met (80%+ instruction and branch)"
echo ""
```

**Important Notes:**
- Use `mvn verify` not just `mvn test` - verify includes coverage checks
- JaCoCo enforces 80% instruction and 80% branch coverage on core module
- If coverage fails, add tests for new/modified code
- Check coverage report: `core/target/site/jacoco/index.html`

### Step 8: Commit Changes

After addressing all comments:

```bash
# Stage all changed files
git add <changed-files>

# Commit with descriptive message listing addressed comments
git commit -m "fix: address PR review comments

Addressed feedback:
- {Change 1 from comment}
- {Change 2 from comment}
- {Change 3 from comment}

PR #${PR_NUM}"

git push
```

### Step 9: Reply to Comments (Optional)

For significant changes, reply to the comment threads:

```bash
# Reply to PR conversation
gh pr comment "$PR_NUM" --body "Addressed all review feedback:
- {Change 1}
- {Change 2}
- {Change 3}"
```

### Step 10: Compound Knowledge

After resolving all comments, capture any learnings discovered during the resolution process.

#### Identify Learnings

Check if any of these occurred:
- Discovered a non-obvious gotcha or edge case
- Found a pattern that should be documented
- Encountered a problem that took investigation to solve
- Learned something that would help future reviews

#### Create Solution Document

If learnings are worth documenting, create a solution file:

```bash
# Generate solution doc path
SLUG=$(echo "{topic}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40)
CATEGORY="{category}"  # logic-errors, runtime-errors, configuration, patterns, etc.
SOLUTION_PATH="docs/solutions/${CATEGORY}/${SLUG}.md"
```

**Solution document template:**

```markdown
---
title: {Descriptive Title}
date: {YYYY-MM-DD}
category: {category}
tags:
  - {tag1}
  - {tag2}
module: {affected-module}
component: {affected-component}
severity: {low|medium|high}
status: resolved
symptoms:
  - "{Error message or observable behavior}"
  - "{Another symptom}"
---

# {Title}

## Problem Summary

{1-2 sentences describing the problem}

## Symptoms

**Error Message:**
```
{actual error message}
```

**Observable Behavior:**
- {what was happening}
- {what was expected}

## Root Cause

{Technical explanation of why this happened}

## Solution

**File:** `{path/to/fixed/file.java}`

**Before (buggy):**
```java
// problematic code
```

**After (fixed):**
```java
// fixed code
```

## Prevention

{How to prevent this in the future}

## Related Issues

- PR: #{PR_NUM}

## Keywords

{searchable terms for finding this solution later}
```

#### Commit Learnings

```bash
git add "$SOLUTION_PATH"
git commit -m "docs: add solution for {topic}

Captured learnings from PR #${PR_NUM} review feedback."

git push
```

### Step 11: Output Results

```
=== Review Resolution Summary ===

PR #${PR_NUM}: ${PR_TITLE}

Comments Addressed: {count}
- Inline code comments: {count}
- PR conversation comments: {count}
- Review feedback: {count}

Knowledge Applied:
- {reference1}: {how it helped}
- {reference2}: {how it helped}

Changes Made:
- {file1}: {change description}
- {file2}: {change description}

Learnings Captured: {solution_path or "none needed"}

Commit: {commit_hash}

Next steps:
- Wait for re-review
- Run /gw-review to check status and merge when approved
```

## Success Criteria

- [ ] PR detected from current branch
- [ ] All inline review comments fetched
- [ ] All PR conversation comments fetched
- [ ] All review submission feedback fetched
- [ ] Project knowledge searched for relevant solutions
- [ ] Each actionable comment addressed
- [ ] Architecture docs (`CLAUDE.md`, `README.md`, arch docs) updated if structural changes were made
- [ ] **Pipeline requirements verified (tests + coverage)**
- [ ] Changes committed with descriptive message
- [ ] Changes pushed to remote
- [ ] Learnings compounded if applicable

## Error Handling

| Error | Action |
|-------|--------|
| No PR found | "No PR for branch. Run /gw-work first" |
| No comments found | "No review comments to address. PR is clean!" |
| Git push fails | "Push failed. Check remote access and branch protection." |
| API rate limit | "GitHub API rate limited. Wait and retry." |

## Comment Types Reference

| Type | Source | How to Fetch |
|------|--------|--------------|
| Inline review comments | Code-specific feedback on diff | `gh api .../pulls/{N}/comments` |
| PR conversation | General PR discussion | `gh pr view --json comments` |
| Review submissions | Overall review feedback | `gh pr view --json reviews` |

## Knowledge Sources Reference

| Source | Location | Contains |
|--------|----------|----------|
| Solutions | `docs/solutions/**/*.md` | Documented problem resolutions with searchable YAML frontmatter |
| Skills | `.claude/skills/**/SKILL.md` | Workflows and procedures |
| Scripts | `.claude/skills/**/scripts/` | Utility scripts for common tasks |
| References | `.claude/skills/**/references/` | Reference documentation |
| Project docs | `docs/**/*.md` | Project-specific documentation |
| Guidelines | `GUIDELINES.md`, `CLAUDE.md` | Code conventions and rules |
