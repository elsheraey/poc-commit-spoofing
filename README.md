# Commit Spoofing POC

**Educational / security-awareness demo.**

## What this demonstrates

Every commit in this repo (except the last one) was authored by me, `elsheraey`,
but appears in the GitHub UI as if authored by a different GitHub user. GitHub
shows each spoofed user's avatar, name, and links through to their profile.

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

- Commits from multiple users, each with an avatar and a link to their profile.
- Zero "Verified" badges on **any** commit, including the ones attributed to me.
- No way, from the UI alone, to tell real commits from spoofed ones.

The last commit in this repo is SSH-signed and carries a `Verified` badge. That
badge is the only trustworthy signal — everything above it is spoofed.

Now imagine this inside a compromised fork, or in a PR opened against a shared
repo. A commit reading `"bump internal-sdk to 1.4.2"` authored-by a senior
engineer's avatar is a very effective phishing primitive. Reviewers trust the
name, not the signature.

## Why developers ignore this

If the risk is this easy to demonstrate, why is signing still a minority
practice? A few honest reasons:

- **The "Unverified" badge is invisible to most reviewers.** It sits in a
  corner of the commits tab and isn't surfaced in PR review, blame, or the
  file diff. If nothing in the workflow forces you to look at it, you don't.
- **Key management has historically been painful.** GPG was the default for
  a decade and it is genuinely awful: keyrings, expirations, subkeys, agent
  forwarding, lost keys on new laptops. SSH signing fixes most of that but
  is recent (Git 2.34, 2021) and still not well known.
- **Signing breaks other workflows.** Rebase-and-merge and squash-merge on
  the GitHub web UI re-author commits (GitHub re-signs web merges, but any
  local rebase drops signatures). Cherry-picks, `git commit --amend` after
  a pull, and bot-driven commits all create Unverified noise that teams
  learn to ignore.
- **Ephemeral environments.** Codespaces, devcontainers, CI runners, and
  new laptops each need a signing key provisioned. Without SSO-backed key
  distribution it's per-developer toil, so most orgs skip it.
- **Bots and automation don't sign by default.** Dependabot, Renovate,
  release-please, and most CI commit bots produce Unverified commits out
  of the box. Once half your history is Unverified, the badge stops meaning
  anything and reviewers tune it out.
- **The threat feels abstract.** "Someone could impersonate you" sounds
  theoretical until it happens. Most developers have never seen a spoofed
  commit in the wild, so the cost of setup feels higher than the benefit.
- **It's opt-in on both ends.** The author has to sign AND the reader has
  to check. Without branch protection enforcing "Require signed commits,"
  signing is a private ritual that no one audits.
- **Culture follows defaults.** GitHub doesn't sign commits by default, git
  doesn't sign by default, and new-hire setup guides rarely mention it.
  What isn't in the paved path doesn't get done.

The fix isn't persuading individuals. It's flipping the default at the
org level, so unsigned commits can't land on protected branches at all.

## Real incidents this enables or amplifies

- **xz-utils (CVE-2024-3094).** Multi-year social engineering. Commit
  attribution was a forensic anchor after the fact; signing would have
  raised the bar.
- **PR phishing.** Spoofed maintainer commits in opened PRs have been
  demonstrated against Google, Linux kernel contributors, and others.
- **Internal threat.** A disgruntled employee can make it look as if any
  coworker authored a controversial change.

## How to stop it

1. **Branch protection, "Require signed commits"** on `main` and any
   release branches. This is the single highest-leverage control.
2. **SSH commit signing**, much easier than GPG. Reuse your existing auth key:
   ```bash
   git config --global gpg.format ssh
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   git config --global commit.gpgsign true
   ```
   Upload the same public key to GitHub under *Settings, SSH and GPG keys,
   New SSH key, Key type: Signing Key*.
3. **Enforce in CI.** Reject unsigned commits in a pre-merge check so the
   guarantee doesn't depend on reviewer diligence.
4. **Don't trust the avatar.** Trust the badge.

## Scope of this demo

- Public repo on my personal account, made public for educational purposes.
- Only GitHub public `noreply` email addresses used (`ID+login@users.noreply.github.com`).
  No internal/work emails were harvested or used.
- All commit content is benign. The point is the attribution, not the payload.
- No commits were pushed to any shared organization repo.
