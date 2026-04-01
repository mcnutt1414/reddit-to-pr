---
name: reddit-to-pr
description: >-
  Use when asked to find Reddit complaints about a product and ship fixes,
  when asked to "check reddit for issues", "reddit to pr", "find user pain
  points", or on a schedule to improve a product based on real user feedback
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

### Preflight Check

Perform these checks before proceeding:

- Validate GitHub authentication: Ensure `gh` command is available and authenticated.
- Validate repository path: Check if `{repoPath}` is a valid Git repository.
- Check for a clean working tree: Ensure there are no uncommitted changes in `{repoPath}`.
- Confirm branch base is up-to-date: Verify that the local main branch is in sync with its remote counterpart.

If any check fails, stop execution and log the issue for resolution.

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
   - **Fixability:** Can