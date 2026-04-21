# Commit Spoofing POC

**Educational / security-awareness demo, originally built for team members at
[Syntheia](https://syntheia.io) and shared publicly in case it's useful to others.**

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

## Why this is possible at all

This isn't a bug. It's a consequence of what Git was designed to be.

Linus Torvalds built Git in 2005 to replace BitKeeper for Linux kernel
development, and the original priorities were:

- **Distributed development.** Every clone is a full, equal repository.
  There is no central authority to ask "is this really you?" because by
  design there is no central authority at all.
- **Performance and scalability.** Fast enough to handle thousands of
  patches flowing through mailing lists every week, on the hardware of
  2005. Cryptographic identity checks on every commit were not on the
  table.
- **Content integrity, not author identity.** Git uses SHA-1 (now also
  SHA-256) to guarantee that the *contents* of a commit haven't been
  tampered with after the fact. The author field is metadata attached to
  that content, not something the hash is meant to authenticate.

In the kernel workflow those tradeoffs were fine: patches arrived by
email, were reviewed by humans who knew each other, and maintainers signed
the *tags* they pulled rather than every individual commit. Trust lived
in the social graph of maintainers, not in the commit object.

GitHub inherited Git's data model and layered a social UI on top, turning
author metadata into avatars, profile links, and contribution graphs.
That UI promotes the author field from "a note from the committer" to "an
identity claim," without adding any mechanism to verify the claim. Signed
commits and the `Verified` badge are the retrofit. They're opt-in because
they were bolted on afterwards, not built in from day one.

So the spoof works because Git is doing exactly what it was designed to
do. The gap is between Git's original threat model (trusted maintainers
exchanging patches) and how we use it today (strangers opening PRs into
shared repos, AI bots auto-merging on identity signals).

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

## The AI and auto-merge angle ([Nada Abdallah](https://github.com/Nada-Abdalla))

The risk is growing, not shrinking, because more of the review pipeline is
now automated and identity-aware:

- **AI code reviewers** (Copilot review, CodeRabbit, Cursor review bots,
  in-house LLM reviewers) often receive author metadata alongside the
  diff, and can weight "this is from a trusted senior engineer" as a
  reason to approve faster or comment less critically. A spoofed identity
  inherits that trust for free. See Manifold Security's write-up of an
  AI reviewer being fooled by a spoofed git identity:
  https://www.manifold.security/blog/spoofed-git-identity-ai-code-reviewer
- **Auto-merge rules** keyed on author (e.g. "auto-merge if author is in
  the `core` team" or "skip review if author is Dependabot") can be
  short-circuited by a spoofed `user.email`. The merge queue never sees
  the attacker, only the impersonated identity.
- **CODEOWNERS bypass patterns.** Some pipelines treat commits authored
  by an owner as implicitly pre-reviewed. A spoof collapses that check.
- **Bot impersonation.** Spoofing `dependabot[bot]` or a release bot
  makes a malicious commit look like routine automation, precisely the
  kind of change humans skim rather than review.

None of these systems should trust `user.email`. The only field worth
trusting is the cryptographic signature.

Slide deck with more background on this angle, authored by Nada Abdalla:
[`commit-spoofing-nada-abdalla.pdf`](./commit-spoofing-nada-abdalla.pdf).

## Real incidents this enables or amplifies

- **xz-utils (CVE-2024-3094).** Multi-year social engineering. Commit
  attribution was a forensic anchor after the fact; signing would have
  raised the bar.
- **PR phishing.** Spoofed maintainer commits in opened PRs have been
  demonstrated against Google, Linux kernel contributors, and others.
- **Internal threat.** A disgruntled employee can make it look as if any
  coworker authored a controversial change, or hide their own authorship
  of a change they do not want traced back to them.
- **Contribution fraud.** Farming green squares or faking a contribution
  history for hiring and reputation purposes.

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
