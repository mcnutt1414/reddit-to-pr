# reddit-to-pr

A Claude Code skill that scans Reddit for real user complaints about your product, identifies actionable issues, and ships code fixes as pull requests — with Reddit evidence in the PR body.

## Installation

Symlink the skill directory into your Claude Code skills:

```bash
ln -s /path/to/reddit-to-pr/reddit-to-pr ~/.claude/skills/reddit-to-pr
```

## Usage

In Claude Code, run:

```
/reddit-to-pr
```

**First run:** Interactive setup wizard configures your target subreddits, product description, repo path, and search keywords. Config is saved to `config.json` in the skill directory.

**Subsequent runs:** Executes the full pipeline — scan Reddit, analyze findings, investigate code, implement fix, open PR.

You can also pass a repo path directly:

```
/reddit-to-pr /path/to/your/repo
```

Or reconfigure at any time:

```
/reddit-to-pr setup
```

## Reddit Access

The skill supports two modes for accessing Reddit:

### Browse Skill (default, zero config)

Uses the gstack browse skill to scrape `old.reddit.com`. No API keys needed. Requires the [gstack browse skill](https://github.com/anthropics/skills) to be installed.

### Reddit API (optional, higher rate limits)

Set these environment variables for API-based access:

```bash
export REDDIT_CLIENT_ID="your_client_id"
export REDDIT_CLIENT_SECRET="your_client_secret"
```

Create a Reddit app at [reddit.com/prefs/apps](https://www.reddit.com/prefs/apps) (choose "script" type).

## How It Works

1. **Search** — Queries Reddit for complaints, bug reports, and feature requests matching your product
2. **Analyze** — Ranks findings by frequency, severity, and fixability. Requires 2+ independent sources before acting
3. **Investigate** — Reads your codebase to confirm the complaint maps to actual code
4. **Fix** — Creates a branch, implements a minimal fix, runs tests
5. **PR** — Opens a pull request with Reddit quotes, evidence links, and root cause analysis

## Evidence Guardrails

The skill is deliberately conservative:

- Will not fabricate or paraphrase Reddit quotes
- Requires 2+ independent Reddit posts/comments before attempting a fix
- Outputs a research report (not a code change) when evidence is insufficient
- Always includes Reddit URLs in the PR body for human verification

## Requirements

- Claude Code with skills v2 support
- `gh` CLI (for opening PRs)
- gstack browse skill OR Reddit API credentials
