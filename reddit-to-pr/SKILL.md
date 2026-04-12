---
name: reddit-to-pr
description: >-
  Use when asked to find Reddit complaints about a product and ship fixes,
  when asked to "check reddit for issues", "reddit to pr", "find user pain
  points", or on a schedule to improve a product based on real user feedback
metrics:
  enabled: true
view:
  enabled: true
  renderer: json-render
  components: [Card, Stack, Grid, Heading, Text, Badge, Table, Progress, Separator, Alert]
---

# Reddit to PR

Scan Reddit for real user pain points → investigate your codebase → ship a fix as a PR.

## Mode Detection

`{baseDir}` = the directory containing this SKILL.md.

- If `{baseDir}/config.json` does NOT exist → **Setup Mode**
- If user says "setup" or "reconfigure" → **Setup Mode**
- Otherwise → **Execution Mode**

---

## Setup Mode

Ask these questions ONE AT A TIME, waiting for each answer:

### 1. Target Subreddits
"What subreddits should I monitor? These should be communities where your users hang out."
Example: `r/webdev, r/reactjs, r/programming`
Store as: `subreddits` (array, without r/ prefix)

### 2. Product Context
"Describe your product in 1-2 sentences. What does it do and who is it for?"
Store as: `productDescription` (string)

### 3. Repository
"What's the path to your code repository?"
Store as: `repoPath` (string)

### 4. Search Keywords
"What keywords should I look for? These help filter for relevant complaints."
Example: `slow, crash, bug, broken, doesn't work, error`
Store as: `keywords` (array)

### 5. Schedule
"How often should I run? Options: `nightly`, `twice-daily`, `weekly`, `manual`"
Store as: `schedule` (string)

### 6. Results Destination
"Where should I post results? `pr` (default), `slack` (needs webhook), or `both`"
Store as: `resultsDestination` (string). If slack: ask for webhook URL → `slackWebhook`.

Save all to `{baseDir}/config.json` with `"setupComplete": true` and `"setupDate": "<today>"`.

If schedule is not `manual`, provide the cron expression and help set up scheduling:
- `nightly`: `0 2 * * *`
- `twice-daily`: `0 8,20 * * *`
- `weekly`: `0 2 * * 1`

---

## Execution Mode

Load `{baseDir}/config.json`.

### Phase 1: Search Reddit

**Detect access method:**
- If `REDDIT_CLIENT_ID` env var is set → use `bash {baseDir}/scripts/reddit-search.sh "{subreddit}" "{query}"`
- Otherwise → use the browse skill on `old.reddit.com`

**Browse path:** For each subreddit, load these URLs and extract post listings with `$B text`:
```
$B goto "https://old.reddit.com/r/{subreddit}/search?q={keywords joined by OR}&sort=new&restrict_sr=on&t=month"
$B text
```
Then run a complaint-phrase search:
```
$B goto "https://old.reddit.com/r/{subreddit}/search?q=%22wish+it+could%22+OR+%22frustrated+with%22+OR+%22why+can%27t%22+OR+%22doesn%27t+work%22&sort=new&restrict_sr=on&t=month"
$B text
```

**API path:** Run the script for each subreddit with both keyword and complaint-phrase queries.

For promising posts (high score, many comments), load the full thread to read comments:
- Browse: `$B goto "https://old.reddit.com{permalink}"` then `$B text`
- API: additional request to comments endpoint

Collect for each finding: **title, body snippet, score, comment count, URL, subreddit, username, age**.

### Phase 2: Analyze & Rank

1. Deduplicate findings (same issue described differently)
2. Filter for relevance to `productDescription`
3. Score each: `frequency × severity × fixability`
   - **Frequency:** How many independent posts/comments mention this?
   - **Severity:** How frustrated are users? (rage posts > mild annoyance)
   - **Fixability:** Can this be addressed with a code change?

**Hard gate — evidence threshold:**
- Require **2+ independent Reddit sources** describing the same issue
- If threshold not met → output a **Research Report** summarizing what was found and stop
- Do NOT attempt a code fix with insufficient evidence

Pick the top issue. Document with **direct quotes** and **URLs**.

### Phase 3: Investigate Target Repo

1. `cd {repoPath}`
2. Use Grep, Glob, and Read to find code related to the complaint
3. Confirm the Reddit complaint maps to actual code behavior
4. Identify specific file(s) that need changing

**Hard gate:** If no code correlation found → output a **Research Report** and stop. Do not hallucinate a fix.

### Phase 4: Implement Fix

1. Create branch: `fix/reddit-{short-slug}-{YYYY-MM-DD}`
2. Implement the **minimal** code change that addresses the complaint
3. Add or update tests for the fix
4. Run existing tests — ensure nothing breaks
5. Commit: `fix: {description} (sourced from r/{subreddit} user feedback)`

### Phase 5: Open PR

Use `gh pr create` with this body format:

```markdown
## User Pain Point

> "{direct quote from Reddit}"
> — u/{username} in r/{subreddit} ({score} upvotes, {comments} comments)

[Additional quotes if available]

## Root Cause
{What's causing this issue in the code}

## Fix
{What this PR changes and why}

## Evidence
- Sources: {number} Reddit posts/comments across r/{subreddits}
- Severity: {High/Medium/Low}
- Reddit URLs: {links to source posts}

## Test Plan
- [ ] {specific test steps}

---
*Generated by reddit-to-pr*
```

If `resultsDestination` includes `slack`, POST a summary to the webhook.

---

## Evidence Rules

These are non-negotiable:

1. **Never fabricate quotes.** Every quote in the PR must be copy-pasted from Reddit.
2. **Never fix without 2+ sources.** One person's complaint is not enough.
3. **Always include URLs.** The PR reviewer must be able to verify every claim.
4. **When unsure, report instead of fix.** A research report is valuable. A bad PR is not.

## Research Report Format

When evidence is insufficient for a fix, output this instead:

```markdown
## Reddit Research Report — {date}

### Findings
{Bullet list of what was found, with direct quotes and URLs}

### Assessment
- Actionable issues found: {count}
- Evidence strength: {Insufficient / Weak / Moderate}
- Reason no fix was attempted: {explanation}

### Recommendations
{What to monitor, what might become actionable with more evidence}
```

## View

This skill tracks operational metrics and can present them using the Forge UI
component catalog. When the client includes a `=== RENDER CONTEXT ===` block,
read its declared capabilities and choose the best supported format. If
`json-render` is supported, emit a spec and still include a markdown fallback
after it.

### Tracked Metrics

- posts_screened (counter): Total Reddit posts evaluated across all runs
- prs_created (counter): Total PRs opened from validated issues
- prs_merged (counter): PRs that have been merged into main
- prs_open (list): Currently open PRs — title, url, status, created date
- issues_watching (counter): Issues flagged but not yet actionable
- last_run (timestamp): When the skill last executed

### Component Catalog

The following components are available for rich UI output. Emit a json-render
spec using these types only — no HTML tags, no lowercase types, no `div`/`p`/`h1`.

| Component | Purpose | Common Composition |
|-----------|---------|--------------------|
| Card      | Container with title/description | Card > Heading for KPIs |
| Stack     | Vertical or horizontal layout | Lists, status rows |
| Grid      | Multi-column layout | KPI rows, dashboards |
| Heading   | Large title or display text | KPI numbers (use `text` prop) |
| Text      | Body copy and labels | Descriptions (use `text` prop) |
| Badge     | Status indicator | Success/warning/failure (use `text` prop) |
| Table     | Tabular data | Lists with columns |
| Progress  | Completion and fill metrics | Progress bars |
| Separator | Dividers | Section breaks |
| Alert     | Important notices | Warnings, errors |

### Spec Format

When `json-render` is supported, output a json-render spec as a JSON code block
in your response. The spec uses the standard json-render element tree format
with a `root` key and an `elements` map. Children are arrays of element keys
(strings), not nested objects.

```json
{
  "root": "dashboard",
  "elements": {
    "dashboard": {
      "type": "Grid",
      "props": { "columns": 3 },
      "children": ["posts", "prs", "status"]
    },
    "posts": {
      "type": "Card",
      "props": { "title": "Posts Screened" },
      "children": ["posts-value"]
    },
    "posts-value": {
      "type": "Heading",
      "props": { "text": "47" }
    },
    "prs": {
      "type": "Card",
      "props": { "title": "PRs Created" },
      "children": ["prs-value"]
    },
    "prs-value": {
      "type": "Heading",
      "props": { "text": "12" }
    },
    "status": {
      "type": "Card",
      "props": { "title": "Status" },
      "children": ["status-badge"]
    },
    "status-badge": {
      "type": "Badge",
      "props": { "text": "Healthy" }
    }
  }
}
```

Use composition patterns:
- **KPI block**: `Card` with a nested `Heading` child for the value
- **Status row**: `Stack` (horizontal) containing a `Text` label and a `Badge`
- **Dashboard layout**: `Grid` with `columns: 2-4` containing Card children

### Plain Text Fallback

When `json-render` is not in the Render Context capabilities, or when responding
conversationally, present metrics as plain text or markdown:

```
Posts Screened: 47
PRs Created: 12
PRs Merged: 8
PRs Open: 3
Status: Healthy
```

Always include this markdown fallback after a json-render spec so text-only
clients still see something readable.

### Capability Negotiation

Read the system prompt for a block that looks like:

```
=== RENDER CONTEXT ===
surface: web
capabilities:
  - json-render
  - shadcn
  - markdown
=== END RENDER CONTEXT ===
```

- If `json-render` is present → emit a spec followed by a markdown fallback
- If only `markdown` is present → respond in markdown
- If neither is present → use plain text
