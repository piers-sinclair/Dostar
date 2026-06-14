---
description: Audit documentation for conciseness, clarity, and developer experience — report all findings before making any changes.
argument-hint: [path]
allowed-tools: Bash(git *) Read Glob Grep
---

# doc-audit

Audit documentation for developer experience quality and report all findings before making any changes.

## Usage

```
/doc-audit [path]
```

- No argument → audits docs changed on the current branch (`git diff main...HEAD --name-only` filtered to `.md` files)
- Path given → audits all `.md` files under that path recursively

## Workflow

1. **Determine scope**: resolve the file list (diff or path)
2. **Read every file** in scope
3. **Audit** each file against every category below
4. **Report** all findings grouped by category, with severity, file reference, what was found, and a suggested fix
5. **Ask the user** which findings they want applied — do not touch any file until they confirm

## Severity levels

| Level | Meaning |
|-------|---------|
| `Error` | Clear violation that harms DX — fix unconditionally |
| `Warning` | Probable issue needing context to confirm |
| `Info` | Improvement opportunity — polish or clarity gain |

## Reporting format

For each finding:

```
[<Severity>] <Category> — <file>:<line or range>
  Found: <what was found>
  Fix:   <suggested change>
```

Group by category. End with a summary table:

| Category | Error | Warning | Info |
|----------|-------|---------|------|
| ...      | N     | N       | N    |

Then ask: **"Which findings would you like me to fix? List numbers, 'all', or 'none'."**

---

## Audit categories

### 1. Length & bloat

The best documentation is the shortest documentation that still answers the question. Every line that doesn't earn its place costs the reader attention they won't get back.

Flag:
- Any `.md` file **over 200 lines** — suggest splitting into focused sub-documents linked from an index, or cutting content that restates what the code already shows
- Any `.md` file **over 100 lines** that could be split — `Warning`
- Sections that duplicate information already covered elsewhere in the repo (link instead of repeat)
- Any preamble or closing section that exists only as filler (e.g. "In conclusion, as we have seen...", "This document covers...", "Thank you for reading")
- Identical or near-identical content across multiple files — consolidate and link

### 2. Language simplicity

Plain language respects the reader's time. Every jargon term or passive sentence is a small tax the reader pays.

Flag:
- Passive voice where active is clearer (`"the command is run by the user"` → `"run the command"`)
- Jargon or acronyms introduced without definition on first use
- Sentences over ~25 words — suggest splitting
- Hedging language that adds no information (`"it may be worth considering"`, `"you might want to think about"`, `"generally speaking"`)
- Nominalisation (turning verbs into nouns): `"perform an installation of"` → `"install"`, `"make a decision"` → `"decide"`
- Filler phrases: `"please note that"`, `"it should be noted"`, `"as mentioned above"`, `"in order to"` (→ `"to"`)

### 3. Executional clarity

Good docs eliminate the need to think. Every step must be a concrete action with an exact command or UI interaction — no interpretation required.

Flag:
- Steps without an exact command, path, or click target (e.g. `"configure your environment"` — what exactly?)
- Numbered lists that skip prerequisite steps or assume unstated context
- Instructions that say "you can" or "you may" when a specific action is required — use imperative mood (`"run"`, `"open"`, `"set"`)
- Steps that combine multiple distinct actions into one list item — each action should be its own step
- Missing expected output or success indicator after a command (the reader can't verify they did it right)
- Prerequisites buried mid-document — they must appear before the first step that needs them

### 4. Visual communication

A diagram replaces hundreds of words and makes relationships immediately obvious. Prefer [Mermaid](https://mermaid.js.org/) — GitHub renders it natively with no tooling required.

Flag:
- Any wall of text (5+ lines) describing a flow, sequence, hierarchy, or architecture — suggest a Mermaid diagram
- Any table that describes relationships between more than ~5 entities — suggest a diagram
- Prose that says `"X calls Y, which calls Z, which returns to X"` — this is a sequence diagram
- Component/module/layer relationships described in bullets — this is a graph or architecture diagram
- Decision trees described in text — this is a flowchart

When suggesting a diagram, provide a ready-to-use Mermaid block as the fix.

### 5. Progressive disclosure

Lead with what matters most. Readers scan before they read — structure should match how people actually use the doc, not the order the author thought of things.

Flag:
- The most important information (quick-start command, core concept) is not in the first screen of content
- Detailed reference or advanced configuration appears before the basic getting-started path
- A long explanation of *why* precedes *what to do* — lead with the action, follow with the why if needed
- Background or context sections that exceed 3–4 lines before the reader has seen anything actionable
- Deep detail that would only interest edge-case users placed in the main flow — move to a linked sub-section or collapsible

### 6. README hygiene

The README is a **gateway**, not an encyclopedia. Its job is: what is this, how do I start, where do I go next.

Flag:
- README over 150 lines — it has grown beyond gateway scope; extract sections into linked docs
- Installation, quick-start, and "next steps" links are not all present within the first 50 lines
- Full API reference, exhaustive configuration options, or changelog living in the README — these belong in separate files
- Multiple H2 sections covering unrelated topics (auth, deployment, testing, contributing, etc.) — each topic should link out to its own file
- "Badge soup" (5+ status badges in a row) with no contextual explanation

### 7. Freshness & accuracy

Stale docs are worse than no docs — they actively mislead.

Flag:
- Version numbers, package names, or URLs that appear pinned and may be outdated (flag as `Warning` — requires human verification)
- References to files, commands, or features that no longer exist in the repo (cross-check with `find` or `grep`)
- Phrases like `"coming soon"`, `"TODO"`, `"WIP"`, or `"not yet implemented"` that have existed without resolution
- Dates in the past presented as future (`"this will be released in Q1 2024"`)
- Step-by-step instructions that reference UI or CLI output that no longer matches (flag if verifiable)

### 8. Document type fit (Diátaxis)

Every doc should serve exactly one purpose. Mixing types forces the reader to switch mental modes and degrades comprehension.

The four types ([Diátaxis framework](https://diataxis.fr/)):

| Type | Purpose | Reader state | Wrong when... |
|------|---------|--------------|---------------|
| **Tutorial** | Learning by doing | New, guided | It assumes prior knowledge or lists options instead of prescribing one path |
| **How-to guide** | Accomplish a specific task | Goal-oriented | It explains concepts instead of just showing the steps |
| **Reference** | Look up exact values | Searching | It includes narrative or opinions |
| **Explanation** | Build understanding | Curious | It contains step-by-step instructions |

Flag:
- A single document mixing two or more types (e.g. a README that is simultaneously a tutorial, reference, and explanation)
- A how-to guide that pauses to explain concepts — link to an explanation doc instead
- A reference doc written in narrative prose — reference must be scannable (tables, lists, definitions)
- A tutorial that offers choices (`"you can use X or Y"`) — tutorials prescribe one path

### 9. Cross-linking & discoverability

Docs that don't link to each other create dead ends. Every doc should tell the reader where to go next.

Flag:
- A doc that references a concept or tool without linking to where it's defined or documented
- A doc with no "next steps", "see also", or "related" section when logical follow-up paths exist
- Orphaned docs — not linked from any other file in the repo (check with `grep -r`)
- Duplicate navigation (the same links repeated in 3+ places) — consolidate into one navigation source

### 10. Cognitive overhead

Every doc you add is debt the reader must pay. Documentation that doesn't earn its place actively harms developer experience by increasing the amount of material a new developer must process before they can do anything useful.

Flag:
- **Docs that shouldn't exist at all** — if a file has no clear audience and no clear action the reader can take after reading it, suggest deleting it
- **Sections that document the obvious** — content that restates what well-named code, comments, or the framework already makes clear (e.g. explaining what a standard CRUD endpoint does when the code is self-evident)
- **"Just-in-case" context dumps** — background, history, or rationale sections that no reader in a realistic workflow would need (move to a PR description or ADR if it must be preserved)
- **Docs written for a past state of the project** — whole documents that describe a design, workflow, or decision that no longer applies and are kept only because nobody deleted them
- **Defensive over-documentation** — explaining every edge case, caveat, and exception up front before the reader has done anything; most caveats only matter after the reader hits them
- **Parallel docs that should be one** — two docs covering the same audience and goal at different levels of detail; consolidate into one with progressive disclosure rather than maintaining two

When suggesting deletion, state clearly what the reader loses and whether that information exists elsewhere. Deletion is only appropriate when the doc provides zero unique value.

---

## Conventions

- Never apply any fix before the user confirms which findings to address.
- When applying fixes, change only what resolves the finding — no opportunistic rewriting.
- When suggesting a Mermaid diagram, always provide the full ready-to-paste block.
- Rewritten sentences must preserve 100% of the original meaning — shorten, don't alter intent.
- If a finding requires judgement (e.g. whether a section is truly off-topic), present both sides briefly and let the user decide.
