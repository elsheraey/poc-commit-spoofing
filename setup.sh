#!/usr/bin/env bash
# Builds the spoofed commit history. Idempotent-ish: run from a fresh clone.
set -euo pipefail

cd "$(dirname "$0")"

git init -q -b main
git add README.md
GIT_AUTHOR_NAME="Mourad Elsheraey" \
GIT_AUTHOR_EMAIL="22550173+elsheraey@users.noreply.github.com" \
GIT_COMMITTER_NAME="Mourad Elsheraey" \
GIT_COMMITTER_EMAIL="22550173+elsheraey@users.noreply.github.com" \
  git commit -q -m "docs: add POC README"

commit_as() {
  local name="$1" email="$2" msg="$3" file="$4" content="$5"
  printf '%s\n' "$content" >> "$file"
  git add "$file"
  GIT_AUTHOR_NAME="$name" \
  GIT_AUTHOR_EMAIL="$email" \
  GIT_COMMITTER_NAME="$name" \
  GIT_COMMITTER_EMAIL="$email" \
    git commit -q -m "$msg"
}

touch CHANGELOG.md src.txt deps.txt

commit_as "ahmeditalia"          "34543951+ahmeditalia@users.noreply.github.com"                 "chore: add project skeleton"       src.txt      "init"
commit_as "writetohorace"        "58406744+writetohorace@users.noreply.github.com"               "build: bump internal-sdk to 1.4.2" deps.txt     "internal-sdk==1.4.2"
commit_as "MahmoudHanyFathalla"  "87129311+MahmoudHanyFathalla@users.noreply.github.com"         "feat(auth): tidy token refresh"    src.txt      "auth: refresh"
commit_as "mahmoudS-abdallah"    "32122487+mahmoudS-abdallah@users.noreply.github.com"           "chore: add structured logging"     src.txt      "log: json"
commit_as "Mohamed-Alhadrami"    "169135989+Mohamed-Alhadrami@users.noreply.github.com"          "feat: add feature flag scaffold"   src.txt      "flags: off"
commit_as "Mohamed-Elraey"       "169617966+Mohamed-Elraey@users.noreply.github.com"             "refactor: config loader"           src.txt      "config: v2"
commit_as "msaoudallah"          "6372325+msaoudallah@users.noreply.github.com"                  "chore: bump version to 0.3.0"      CHANGELOG.md "## 0.3.0"
commit_as "Nada-Abdalla"         "151619112+Nada-Abdalla@users.noreply.github.com"               "docs: update onboarding notes"     CHANGELOG.md "- onboarding"
commit_as "peter-naoum"          "164209923+peter-naoum@users.noreply.github.com"                "test: add unit tests for loader"   src.txt      "tests: ok"
commit_as "YahiaElkhasahb"       "46698452+YahiaElkhasahb@users.noreply.github.com"              "fix: typo in error message"        src.txt      "typo fixed"
commit_as "AmrMsCLL"             "141947355+AmrMsCLL@users.noreply.github.com"                   "ci: add GitHub Actions workflow"   src.txt      "ci: added"

# Final commit authored as me — will show Verified if signing is configured globally.
printf '\nSee README for the point.\n' >> CHANGELOG.md
git add CHANGELOG.md
GIT_AUTHOR_NAME="Mourad Elsheraey" \
GIT_AUTHOR_EMAIL="22550173+elsheraey@users.noreply.github.com" \
GIT_COMMITTER_NAME="Mourad Elsheraey" \
GIT_COMMITTER_EMAIL="22550173+elsheraey@users.noreply.github.com" \
  git commit -q -m "demo: compare Verified vs Unverified on the 12 commits above"

git log --pretty=format:'%h %an <%ae> — %s' | cat
