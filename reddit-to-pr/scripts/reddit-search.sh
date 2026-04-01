#!/usr/bin/env bash
# Reddit API search helper for reddit-to-pr skill
# Usage: reddit-search.sh <subreddit> <query> [time_range]
#
# Requires: REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET env vars
# Optional: jq for formatted output (falls back to raw JSON)

set -euo pipefail

SUBREDDIT="${1:?Usage: reddit-search.sh <subreddit> <query> [time_range]}"
QUERY="${2:?Usage: reddit-search.sh <subreddit> <query> [time_range]}"
TIME_RANGE="${3:-month}"
LIMIT=25
USER_AGENT="reddit-to-pr-skill/1.0"

if [[ -z "${REDDIT_CLIENT_ID:-}" || -z "${REDDIT_CLIENT_SECRET:-}" ]]; then
  echo "Error: REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET must be set" >&2
  exit 1
fi

# OAuth2 client_credentials flow
TOKEN_RESPONSE=$(curl -s -X POST \
  -u "${REDDIT_CLIENT_ID}:${REDDIT_CLIENT_SECRET}" \
  -A "${USER_AGENT}" \
  -d "grant_type=client_credentials" \
  "https://www.reddit.com/api/v1/access_token")

# Extract access token
if command -v jq &>/dev/null; then
  ACCESS_TOKEN=$(echo "${TOKEN_RESPONSE}" | jq -r '.access_token // empty')
else
  ACCESS_TOKEN=$(echo "${TOKEN_RESPONSE}" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
fi

if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "Error: Failed to get access token. Response: ${TOKEN_RESPONSE}" >&2
  exit 1
fi

# Search subreddit
ENCODED_QUERY=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${QUERY}'))")

SEARCH_RESPONSE=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -A "${USER_AGENT}" \
  "https://oauth.reddit.com/r/${SUBREDDIT}/search.json?q=${ENCODED_QUERY}&sort=new&restrict_sr=on&t=${TIME_RANGE}&limit=${LIMIT}")

# Format output
if command -v jq &>/dev/null; then
  echo "${SEARCH_RESPONSE}" | jq '[.data.children[].data | {
    title: .title,
    selftext: (.selftext[:500]),
    score: .score,
    num_comments: .num_comments,
    url: ("https://reddit.com" + .permalink),
    author: .author,
    created_utc: .created_utc,
    subreddit: .subreddit
  }]'
else
  echo "${SEARCH_RESPONSE}"
fi
