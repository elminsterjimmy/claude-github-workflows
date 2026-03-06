# gw-pr-codereview

Comprehensive PR code review skill that analyzes changes and adds review comments.

## Overview

This skill performs automated code review on the current PR by:
- Fetching all changed files and diffs
- Running automated quality checks
- Analyzing code against project conventions (CLAUDE.md, GUIDELINES.md)
- Detecting common anti-patterns and issues
- Running tests to verify changes
- Adding inline review comments to the PR
- Posting a review summary

## Usage

```bash
/gw-pr-codereview
```

The skill will:
1. Detect the current PR from your branch
2. Analyze all changed files
3. Run automated checks for:
   - Anti-patterns (debug statements, generic exceptions)
   - Code complexity (deep nesting, long methods)
   - Naming conventions
   - Security issues (SQL injection, hardcoded credentials)
   - Test coverage
4. Add review comments for issues found
5. Post a review summary with approval or change requests

## Features

### Automated Checks

**Anti-patterns:**
- Debug print statements (System.out.println)
- Generic exception catching
- Suppressed warnings
- Poor use of types (implementation vs interface)
- Excessive null checks

**Code Quality:**
- Deep nesting (>3 levels)
- Long methods (>50 lines)
- Complex class names
- Single-letter variables

**Security:**
- SQL injection risks
- Hardcoded credentials
- Use of eval()

**Conventions:**
- Naming conventions (UPPER_SNAKE_CASE for constants)
- GUIDELINES.md compliance
- Test coverage requirements

### Review Actions

The skill can:
- **Approve** - If no issues found (optional auto-approve)
- **Request Changes** - If critical issues detected
- **Comment** - For suggestions and minor issues

## Configuration

Optional config file: `.claude/skills/gw-pr-codereview/config.json`

```json
{
  "autoApprove": false,
  "strictMode": true,
  "maxFilesReview": 50,
  "reviewRules": {
    "requireTests": true,
    "requireDocs": true,
    "maxMethodLength": 50,
    "maxNestingDepth": 3
  }
}
```

## Scripts

### analyze-pr.sh

Automated analysis script that checks for:
- Anti-patterns
- Code complexity
- Naming conventions
- Security issues
- Test coverage

Usage:
```bash
.claude/skills/gw-pr-codereview/scripts/analyze-pr.sh /tmp/pr-diff.patch "changed-files.txt"
```

## Integration

Works with:
- GitHub CLI (gh)
- Maven (for running tests)
- JaCoCo (for coverage)
- Project conventions (CLAUDE.md, GUIDELINES.md)

## Example Output

```
=== PR Code Review Complete ===

PR #30: feat: MiniLang reference DSL implementation

Files reviewed: 15
Changes: +450 -120

Issues found:
- ParseTreeConverter.java:42 - Consider using Optional instead of null check
- MiniLangTest.java:15 - Debug statement should be removed

Comments added: 2
Review status: CHANGES_REQUESTED

Next steps:
- Review inline comments on GitHub
- Address issues found
- Re-run /gw-pr-codereview after fixes
```

## Best Practices

1. Run this skill before requesting human review
2. Address all automated issues first
3. Re-run after making fixes
4. Use with /gw-resolve-reviews to address feedback
5. Combine with CI/CD pipeline checks

## Related Skills

- `/gw-resolve-reviews` - Resolve review comments
- `/gw-review` - Handle review feedback and merge
- `/gw-work` - Create feature branch and PR
