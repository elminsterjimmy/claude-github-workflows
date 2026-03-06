---
name: gw-plan-review
description: Review and refine implementation plans - gather feedback, improve plan quality, and finalize before work begins.
---

# Plan Review Workflow

Review and refine implementation plans before implementation begins. This workflow helps gather feedback on plan quality, identify gaps, and improve the plan based on stakeholder input.

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

validate_path() {
    [[ "$1" =~ ^[a-zA-Z0-9/_.-]+$ ]] || { echo "Invalid path: $1"; exit 1; }
}
```

## Label Helpers

```bash
# Create label if it doesn't exist
ensure_label() {
    local label="$1"
    local color="${2:-ededed}"
    gh label list --search "$label" --json name --jq '.[].name' 2>/dev/null | grep -qx "$label" || \
        gh label create "$label" --color "$color" 2>/dev/null || true
}

# Ensure required labels exist
ensure_label "planned" "0E8A16"
ensure_label "plan-reviewed" "1D76DB"
ensure_label "claude-code" "7C3AED"
```

## Workflow

### Step 1: Detect Plan Issue

Find the issue with the plan to review:

```bash
# Try branch name first
BRANCH=$(git branch --show-current)
validate_branch "$BRANCH"

ISSUE=$(echo "$BRANCH" | grep -oE 'feat/([0-9]+)' | grep -oE '[0-9]+' || echo "")

# If no issue from branch, check for recent planned issues
if [ -z "$ISSUE" ]; then
    ISSUE=$(gh issue list --label planned --limit 1 --json number --jq '.[0].number' 2>/dev/null)
fi

# Still nothing? Ask user
if [ -z "$ISSUE" ]; then
    echo "No planned issue found."
    echo "Provide issue number or run /gw-plan first."
    exit 1
fi

# Validate issue number format
validate_number "$ISSUE"

# Validate issue exists on GitHub
if ! gh issue view "$ISSUE" &>/dev/null; then
    echo "Issue #$ISSUE not found on GitHub"
    exit 1
fi

echo "Reviewing plan for issue #$ISSUE"
```

### Step 2: Read Plan Content

```bash
# Get issue details
ISSUE_TITLE=$(gh issue view "$ISSUE" --json title --jq '.title')
ISSUE_BODY=$(gh issue view "$ISSUE" --json body --jq '.body')

# Extract plan document path from issue body
PLAN_PATH=$(echo "$ISSUE_BODY" | grep -oE 'docs/plans/[a-zA-Z0-9/_.-]+\.md' | head -1)

if [ -z "$PLAN_PATH" ]; then
    echo "Warning: No plan document path found in issue body"
    echo "Looking for pattern: docs/plans/*.md"
fi

# Verify plan file exists locally
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    echo "Local plan: $PLAN_PATH"
    validate_path "$PLAN_PATH"
else
    echo "Plan document not found locally: $PLAN_PATH"
    echo "Using issue body content for review"
    PLAN_PATH=""
fi
```

### Step 3: Review Plan Quality

Analyze the plan for completeness and quality:

#### Check Plan Structure

- [ ] **Overview** - Clear problem statement and objectives
- [ ] **Technical Approach** - Architecture, patterns, key decisions documented
- [ ] **Implementation Phases** - Logical breakdown with deliverables
- [ ] **Acceptance Criteria** - Testable functional and non-functional requirements
- [ ] **Dependencies** - Prerequisites and blockers identified
- [ ] **Risk Analysis** - Risks documented with mitigation strategies

#### Review Content Quality

For each section, check:

1. **Clarity**: Is it understandable by someone unfamiliar with the problem?
2. **Completeness**: Are there obvious gaps or missing details?
3. **Specificity**: Are deliverables concrete and measurable?
4. **Testability**: Can success be objectively verified?

#### Identify Gaps

Look for:
- Missing edge cases
- Unclear acceptance criteria
- Unaddressed technical challenges
- Missing test strategy
- Insufficient risk mitigation
- Vague implementation steps

### Step 4: Generate Review Feedback and Enhanced Plan

**IMPORTANT: You MUST actually perform this review analysis AND create an enhanced plan, not just describe it.**

Analyze the plan content and create TWO documents:

#### A. Review Document

```markdown
# Plan Review: {ISSUE_TITLE}

**Issue:** #{ISSUE} | **Reviewer:** Claude Code | **Date:** {DATE}

## Overall Assessment

**Status:** [Approved | Needs Revision | Rejected]
**Quality Score:** [1-10]

{High-level summary of plan quality - analyze the actual plan content}

## Strengths

- ✅ {What the plan does well - identify 3-5 specific strengths}
- ✅ {Strong aspects from the actual plan}

## Areas for Improvement

### Critical Issues

- ❌ {Blocking issue that must be fixed - or state "None" if plan is solid}
- ❌ {Critical gap - be specific}

### Suggestions

- 💡 {Recommended improvement - actionable advice}
- 💡 {Enhancement suggestion - specific to this plan}

## Specific Feedback by Section

### Overview
{Evaluate: Is problem clear? Are objectives stated? Score: X/10}

### Technical Approach
{Evaluate: Is design sound? Are patterns appropriate? Score: X/10}

### Implementation Phases
{Evaluate: Are phases logical? Are deliverables clear? Score: X/10}

### Acceptance Criteria
{Evaluate: Are criteria testable and complete? Score: X/10}

### Risk Analysis
{Evaluate: Are risks identified? Mitigations concrete? Score: X/10}

## Recommended Actions

1. {Action 1 - specific next step}
2. {Action 2 - what needs to be done}

## Sign-off

- [ ] All critical issues addressed
- [ ] Plan ready for implementation
```

**Save this review to a local file:**

```bash
REVIEW_PATH="${PLAN_PATH%.md}-review.md"
# Write the review markdown content to $REVIEW_PATH
```

#### B. Enhanced Plan Document

**CRITICAL: Create an improved version of the plan that addresses all feedback.**

Take the original plan and enhance it by:

1. **Fixing Critical Issues** - Address all blocking problems identified in review
2. **Adding Missing Sections** - Fill gaps in coverage (edge cases, test strategy, etc.)
3. **Improving Clarity** - Rewrite ambiguous sections for better understanding
4. **Adding Detail** - Expand vague deliverables into concrete, measurable items
5. **Enhancing Risk Analysis** - Add overlooked risks with mitigation strategies
6. **Strengthening Acceptance Criteria** - Make all criteria objectively testable

```markdown
---
title: "{ORIGINAL_TITLE} (Enhanced)"
type: {TYPE}
date: {DATE}
issue: {ISSUE}
review_date: {REVIEW_DATE}
original_plan: {ORIGINAL_PLAN_PATH}
---

# {TITLE} (Enhanced)

> **Note:** This is an enhanced version of the original plan, incorporating feedback from the plan review conducted on {REVIEW_DATE}.

## Overview

{ENHANCED_OVERVIEW - incorporate suggestions from review}

## Technical Approach

{ENHANCED_APPROACH - fix any design issues, add missing patterns}

## Implementation Phases

{ENHANCED_PHASES - make deliverables more specific, add missing phases}

### Phase N: {Name}

**Deliverables:**
- [ ] {Specific, measurable deliverable}
- [ ] {With concrete acceptance criteria}

**Acceptance Criteria:**
- {Testable criterion 1}
- {Testable criterion 2}

## Acceptance Criteria

### Functional Requirements

{ENHANCED_FUNCTIONAL - make more specific and testable}

### Non-Functional Requirements

{ENHANCED_NON_FUNCTIONAL - add performance, security, maintainability criteria}

### {Any New Sections Suggested in Review}

{Content for newly identified sections}

## Dependencies

{ENHANCED_DEPENDENCIES - ensure all prerequisites identified}

## Risk Analysis

{ENHANCED_RISKS - add overlooked risks, strengthen mitigation}

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {Risk from original plan} | {L/M/H} | {L/M/H} | {Enhanced mitigation} |
| {New risk identified in review} | {L/M/H} | {L/M/H} | {Mitigation strategy} |

## Testing Strategy

{ENHANCED_TESTING - add if missing, or strengthen if weak}

## Success Metrics

{ENHANCED_METRICS - make more specific and measurable}

## Changes from Original Plan

**Improvements made based on review feedback:**

1. **{Improvement 1}** - {What was changed and why}
2. **{Improvement 2}** - {What was added/fixed}
3. **{Improvement 3}** - {How clarity was improved}

## References

- Original plan: `{ORIGINAL_PLAN_PATH}`
- Plan review: `{REVIEW_PATH}`
- Issue: https://github.com/{owner}/{repo}/issues/{ISSUE}
```

**Save the enhanced plan:**

```bash
ENHANCED_PLAN_PATH="${PLAN_PATH%.md}-enhanced.md"
# Write the enhanced plan markdown content to $ENHANCED_PLAN_PATH
echo "Enhanced plan saved to: $ENHANCED_PLAN_PATH"
```

### Step 5: Post Review and Enhanced Plan to GitHub

**CRITICAL: You MUST post both the review AND enhanced plan to GitHub. This is not optional.**

First, save both documents to local files:

```bash
REVIEW_PATH="${PLAN_PATH%.md}-review.md"
ENHANCED_PLAN_PATH="${PLAN_PATH%.md}-enhanced.md"

# Write review content to file
cat > "$REVIEW_PATH" << 'EOF'
{FULL_REVIEW_CONTENT}
EOF

# Write enhanced plan to file
cat > "$ENHANCED_PLAN_PATH" << 'EOF'
{FULL_ENHANCED_PLAN_CONTENT}
EOF

echo "Review saved to: $REVIEW_PATH"
echo "Enhanced plan saved to: $ENHANCED_PLAN_PATH"
```

Then, update the GitHub issue body with the enhanced plan:

```bash
# Get current issue body
CURRENT_BODY=$(gh issue view "$ISSUE" --json body --jq '.body')

# Extract original problem/brainstorm section (before "---" separator)
ORIGINAL_CONTENT=$(echo "$CURRENT_BODY" | sed '/^---$/,$d')

# Combine: original + separator + enhanced plan
UPDATED_BODY=$(cat <<EOF
$ORIGINAL_CONTENT

---

## Enhanced Implementation Plan

**Enhanced plan document:** \`${ENHANCED_PLAN_PATH}\`
**Original plan:** \`${PLAN_PATH}\`
**Review:** \`${REVIEW_PATH}\`

$(cat "$ENHANCED_PLAN_PATH")
EOF
)

# Update issue with enhanced plan
gh issue edit "$ISSUE" --body "$UPDATED_BODY" || {
    echo "ERROR: Failed to update issue body with enhanced plan"
    exit 1
}

echo "Issue updated with enhanced plan"
```

Finally, post review summary as a comment:

```bash
# Post the review comment using gh issue comment
gh issue comment "$ISSUE" --body "$(cat <<'REVIEW_EOF'
✅ **Plan Review Complete**

Plan approved with enhancements.

**Quality Score:** {SCORE}/10

## Strengths

{List 3-5 key strengths from your actual review}

## Enhancements Made

The plan has been improved and updated in the issue body:

1. **{Enhancement 1}** - {What was improved}
2. **{Enhancement 2}** - {What was added}
3. **{Enhancement 3}** - {How clarity was improved}

## Minor Suggestions (Optional)

{List any additional minor suggestions if any, or state "None - plan is comprehensive"}

## Quality Assessment

{Brief section-by-section scores}

**Files:**
- **Enhanced plan:** \`{ENHANCED_PLAN_PATH}\` (now in issue body)
- **Review:** \`{REVIEW_PATH}\`
- **Original:** \`{PLAN_PATH}\`

## Next Step

Run \`/gw-work {ISSUE}\` to begin implementation using the enhanced plan:
1. {First phase description}
2. {Follow the N-phase plan}

**Estimated effort:** {Your estimate based on plan complexity}
REVIEW_EOF
)" || {
    echo "ERROR: Failed to post review comment to GitHub"
    echo "Review content saved locally at: $REVIEW_PATH"
    exit 1
}

echo "Review posted to issue #$ISSUE"
```

### Step 6: Update Issue Labels

#### If Plan Approved

```bash
# Create label if needed
ensure_label "plan-reviewed" "1D76DB"

# Add plan-reviewed label
gh issue edit "$ISSUE" --add-label "plan-reviewed" || {
    echo "Warning: Could not add plan-reviewed label"
}

echo ""
echo "Plan approved! Ready to implement."
echo "Next: Run /gw-work to begin"
```

#### If Plan Needs Revision

```bash
# Create label if needed
ensure_label "needs-revision" "D93F0B"

# Keep planned label, add needs-revision
gh issue edit "$ISSUE" --add-label "needs-revision" || {
    echo "Warning: Could not add needs-revision label"
}

# Post revision requests as issue comment with full review
gh issue comment "$ISSUE" --body "$(cat <<'REVIEW_EOF'
📝 **Plan Review - Revisions Needed**

**Quality Score:** {SCORE}/10

## Critical Issues

{List all blocking issues that must be fixed}

## Suggestions

{List recommended improvements}

## Specific Feedback by Section

{Include section-by-section feedback}

**Full review:** \`{REVIEW_PATH}\`

**Next Step:** Address the feedback above and run \`/gw-plan-review\` again
REVIEW_EOF
)" || {
    echo "ERROR: Failed to post review comment to GitHub"
    exit 1
}

echo ""
echo "Plan needs revision. See issue comments for details."
```

#### If Plan Rejected

```bash
# Create label if needed
ensure_label "rejected" "B60205"

# Remove planned label, add rejected
gh issue edit "$ISSUE" --remove-label "planned" --add-label "rejected" || {
    echo "Warning: Could not update labels"
}

# Post rejection reasoning as issue comment
gh issue comment "$ISSUE" --body "$(cat <<'REVIEW_EOF'
❌ **Plan Rejected**

**Reason:** {Explain why plan is fundamentally flawed}

{DETAILED_REJECTION_REASONING}

**Recommendation:** {Suggest alternative approach}

**Full review:** \`{REVIEW_PATH}\`

Close this issue or revise the approach significantly before re-planning.
REVIEW_EOF
)" || {
    echo "ERROR: Failed to post rejection comment to GitHub"
    exit 1
}

echo ""
echo "Plan rejected. See issue for reasoning."
```

### Step 7: Output Results

**Display clear summary of review outcome:**

For approved plan:
```
Plan Review Complete ✅

Issue: #${ISSUE}
Original Plan: ${PLAN_PATH}
Enhanced Plan: ${ENHANCED_PLAN_PATH}
Review: ${REVIEW_PATH}
Quality Score: {SCORE}/10
Status: Approved with Enhancements

GitHub Issue (updated): https://github.com/{owner}/{repo}/issues/${ISSUE}

Enhancements Made:
- {Enhancement 1}
- {Enhancement 2}
- {Enhancement 3}

Next step: Run /gw-work ${ISSUE} to implement the ENHANCED plan
```

For plan needing revision:
```
Plan Review - Revisions Needed 📝

Issue: #${ISSUE}
Critical Issues: {COUNT}
Suggestions: {COUNT}
Quality Score: {SCORE}/10

Enhanced plan created with improvements: ${ENHANCED_PLAN_PATH}
Review posted to: https://github.com/{owner}/{repo}/issues/${ISSUE}
Local review: ${REVIEW_FILE}

Next step: Review the enhanced plan, make any additional changes, and run /gw-plan-review again
```

For rejected plan:
```
Plan Rejected ❌

Issue: #${ISSUE}
Reason: {BRIEF_REASON}

Review posted to: https://github.com/{owner}/{repo}/issues/${ISSUE}

Recommendation: Close issue or significantly revise approach before re-planning
```

## Success Criteria

- [ ] Plan issue detected from branch or user input
- [ ] Plan content loaded from local file or issue body
- [ ] Comprehensive review conducted covering all plan sections
- [ ] Quality assessment generated (score, strengths, gaps, section-by-section feedback)
- [ ] **Enhanced plan created** addressing all review feedback (CRITICAL)
- [ ] **Review saved to local file** (e.g., `*-plan-review.md`)
- [ ] **Enhanced plan saved to local file** (e.g., `*-plan-enhanced.md`)
- [ ] **GitHub issue body updated** with enhanced plan (CRITICAL - must be done)
- [ ] **Review feedback posted to GitHub issue as comment** (CRITICAL - must be done)
- [ ] Appropriate labels applied (plan-reviewed, needs-revision, or rejected)
- [ ] User knows next action (implement with enhanced plan, revise, or re-plan)

## Error Handling

| Error | Action |
|-------|--------|
| No planned issue found | "No planned issue. Run /gw-plan first" |
| Issue not on GitHub | "Issue #N not found on GitHub" |
| Plan document missing | "Plan doc not found. Using issue body." |
| Cannot post comment | Warning only, show feedback locally |
| Cannot update labels | Warning only, continue |

## Review Quality Checklist

Use this to ensure thorough reviews:

### Structure
- [ ] All required sections present
- [ ] Logical flow from overview to risks
- [ ] Clear section headers and formatting

### Content
- [ ] Problem clearly defined
- [ ] Solution approach justified
- [ ] Phases have measurable deliverables
- [ ] Acceptance criteria are testable
- [ ] Dependencies explicitly listed
- [ ] Risks identified with mitigation

### Feasibility
- [ ] Scope is reasonable
- [ ] Timeline estimates realistic
- [ ] Technical approach sound
- [ ] Resources available

### Clarity
- [ ] Technical terms defined
- [ ] No ambiguous deliverables
- [ ] Examples provided where helpful
- [ ] Diagrams/visuals used appropriately
