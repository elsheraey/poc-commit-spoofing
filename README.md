# Commit Spoofing POC

**Educational / security-awareness demo. Private repo. Do not share externally.**

## What this demonstrates

Every commit in this repo (except the last one) was authored by me — `elsheraey` —
but appears in the GitHub UI as if authored by a different member of the
`asksyntheia` organization. GitHub shows each teammate's avatar, name, and
links through to their profile.

No account was compromised. No password was stolen. No internal email address
was used. The only thing needed was:

```bash
git -c user.name="Teammate Name" \
    -c user.email="ID+login@users.noreply.github.com" \
    commit --allow-empty -m "looks legit"
```

That's the entire "attack." Git trusts whatever you put in `user.email` locally,
and GitHub uses that email to look up the corresponding account for display.

## Why this matters

Look at `git log` on this repo in the GitHub UI. You will see:

- 11 commits from teammates, each with a green avatar and a link to their profile.
- Zero "Verified" badges on **any** commit — including the ones attributed to me.
- No way, from the UI alone, to tell real commits from spoofed ones.

During the presentation I'll enable SSH commit signing live, push one signed
commit, and show the `Verified` badge appear — the only trustworthy signal.

Now imagine this on a public repo, or inside a compromised fork, or in a PR
opened against a shared repo. A commit reading `"bump internal-sdk to 1.4.2"`
authored-by a senior engineer's avatar is a very effective phishing primitive —
reviewers trust the name, not the signature.

## Real incidents this enables or amplifies

- **xz-utils (CVE-2024-3094)** — multi-year social engineering. Commit
  attribution was a forensic anchor after the fact; signing would have raised
  the bar.
- **PR phishing** — spoofed maintainer commits in opened PRs have been
  demonstrated against Google, Linux kernel contributors, and others.
- **Internal threat** — a disgruntled employee can make it look as if any
  coworker authored a controversial change.

## How to stop it

1. **Branch protection → "Require signed commits"** on `main` and any
   release branches. This is the single highest-leverage control.
2. **SSH commit signing** — much easier than GPG. Reuse your existing auth key:
   ```bash
   git config --global gpg.format ssh
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   git config --global commit.gpgsign true
   ```
   Upload the same public key to GitHub under *Settings → SSH and GPG keys →
   New SSH key → Key type: Signing Key*.
3. **Enforce in CI** — reject unsigned commits in a pre-merge check so the
   guarantee doesn't depend on reviewer diligence.
4. **Don't trust the avatar.** Trust the badge.

## Scope of this demo

- Private repo, my personal account.
- Only GitHub public `noreply` email addresses used (`ID+login@users.noreply.github.com`).
  No internal/work emails were harvested or used.
- All commit content is benign — the point is the attribution, not the payload.
- No commits were pushed to any shared `asksyntheia` repo.
