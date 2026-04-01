# reddit-to-pr

Claude Code skill that scans Reddit for user complaints and ships code fixes as PRs.

## Installation

```bash
ln -s /path/to/reddit-to-pr/reddit-to-pr ~/.claude/skills/reddit-to-pr
```

## Dependencies

- **Browse skill** (gstack): Used by default to scrape old.reddit.com — no config needed
- **Reddit API** (optional): Set `REDDIT_CLIENT_ID` and `REDDIT_CLIENT_SECRET` env vars for higher rate limits
- **gh CLI**: Required for opening PRs

## Usage

Invoke with `/reddit-to-pr` in Claude Code. First run triggers a setup wizard. Subsequent runs execute the full scan → analyze → fix → PR pipeline.

## Repo Structure

- `reddit-to-pr/SKILL.md` — The skill definition (skills v2 format)
- `reddit-to-pr/scripts/reddit-search.sh` — Reddit API helper script
