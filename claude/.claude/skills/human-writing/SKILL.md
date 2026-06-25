---
name: human-writing
description: Write content that sounds natural, conversational, and authentically human - avoiding AI-generated patterns, corporate speak, and generic phrasing
---
 
# Human-Style Writing
 
This skill helps you write content that reads like it was written by a real person with opinions, personality, and specific knowledge. Not a corporate blog generator or AI assistant trying to sound helpful.
 
## Core Principle
 
**Write like you're explaining something to a colleague over coffee, not presenting to a board room.**
 
Good writing is specific, opinionated, and conversational. Bad writing is generic, safe, and sounds like every other tech blog.
 
## Hard Rules: The Clearest AI Tells
 
These are the patterns that researchers, editors, and journalists most consistently flag as AI fingerprints. Treat them as banned defaults. If you catch yourself reaching for one, rewrite.
 
### Rule 1: Never use em-dashes (—)
 
The em-dash is the single most-cited AI tell. Don't use one. Ever. Not even "for emphasis."
 
If you want to add a side thought, use one of:
- A period and a new sentence
- A comma
- Parentheses
- A colon
```markdown
❌ "We shipped it in three weeks — faster than anyone expected."
❌ "The migration tool — built on top of AST parsing — handles 47 frameworks."
 
✅ "We shipped it in three weeks. Faster than anyone expected."
✅ "The migration tool, built on top of AST parsing, handles 47 frameworks."
✅ "The migration tool (built on top of AST parsing) handles 47 frameworks."
```
 
Don't substitute en-dashes (–) either. Use a plain hyphen for ranges: "60-80%", not "60–80%".
 
### Rule 2: Kill the "It's not just X, it's Y" pattern
 
This antithesis/negation construction is the most prominent giveaway in AI prose, more than any single word. Variants to avoid:
 
- "It's not just X, it's Y."
- "X isn't just Y. It's Z."
- "X is more than just Y."
- "X goes beyond Y."
- "Not only X, but also Y."
- "This isn't about X. It's about Y."
```markdown
❌ "PRPM isn't just a package manager. It's a way to ship reasoning with code."
 
✅ "PRPM ships the reasoning behind the code, not just the code."
✅ "PRPM is a package manager for AI instructions. That's it."
```
 
### Rule 3: Avoid compulsive rule-of-three structure
 
AI loves triplets. Three parallel clauses. Three adjectives stacked before a noun. Three-item lists for ideas that aren't actually three things.
 
```markdown
❌ "It's fast, reliable, and powerful."
❌ "We built it to be efficient, robust, and scalable."
❌ "Clear, concise, and comprehensive documentation."
 
✅ "It's fast and we haven't seen it crash."
✅ "Two adjectives is usually enough. Often one."
```
 
One or two specifics beat three abstractions. If you genuinely have three concrete items, fine. But don't pad to three for rhythm.
 
### Rule 4: Banned words and phrases
 
These cluster together in AI output. A single one is fine. Two in the same paragraph is a smell. Three is a rewrite.
 
**Verbs to avoid:** delve, leverage, navigate (when used metaphorically), foster, underscore, harness, utilize, facilitate, showcase, garner, bolster, embody, exemplify, encompass, align with, resonate with, streamline, empower, unlock.
 
**Adjectives to avoid:** crucial, pivotal, vital, key (as in "key insight"), robust, seamless, intricate, multifaceted, comprehensive, holistic, paramount, profound, vibrant, meticulous, groundbreaking, transformative, innovative, invaluable, nuanced, cutting-edge, state-of-the-art, best-in-class.
 
**Nouns/metaphors to avoid:** tapestry, landscape (metaphorical), realm, journey (metaphorical), testament, paradigm, interplay, synergy, ecosystem (metaphorical), stakeholders.
 
**Connectors to avoid:** moreover, furthermore, additionally, consequently, nevertheless, notably, ultimately, essentially, indeed.
 
**Cliché openers to avoid:** "In today's ever-evolving...", "In the realm of...", "In the fast-paced world of...", "As we navigate the complexities of...", "When it comes to...", "In an era where...".
 
### Rule 5: Cut the hedging and meta-commentary
 
These phrases are pure filler and a strong AI tell:
 
- "It's important to note that..."
- "It's worth mentioning that..."
- "It's worth noting that..."
- "Keep in mind that..."
- "That said,..."
- "With that in mind,..."
- "No discussion would be complete without..."
- "In this article/post/section, we'll..."
Just say the thing. If it's worth noting, note it without telling the reader you're about to.
 
### Rule 6: Cut the wrap-up paragraph
 
The closing summary that restates what you just said is an AI tell. Banned openers for final paragraphs:
 
- "In conclusion,..."
- "In summary,..."
- "Overall,..."
- "Ultimately,..."
- "In essence,..."
- "To sum up,..."
- "As we look to the future,..."
- "Looking ahead,..."
End on the last specific thing you had to say, or on a call to action. Not on a restatement.
 
### Rule 7: Don't use bold lead-in bullets as filler
 
The pattern `**Bold phrase:** explanation that just rewords the bold phrase` is everywhere in AI output and rare in human writing. If the explanation after the colon doesn't add information beyond the bolded label, delete the bullet.
 
```markdown
❌ - **Performance:** The system performs well under load.
❌ - **Reliability:** Our system is reliable.
❌ - **Scalability:** It scales to many users.
 
✅ - We've run this at 12k req/s on a single box with p99 under 80ms.
✅ - Three customers hit our previous bottleneck. None hit this one.
```
 
Bold lead-ins are fine when the label is a real category and the text adds genuine detail. They're a tell when they're decorative.
 
### Rule 8: Avoid relentless positivity and inflated significance
 
AI defaults to upbeat and important-sounding. Strip both.
 
**Banned tonal moves:**
- "Exciting", "fascinating", "remarkable", "powerful" (as a generic compliment)
- "A pivotal moment", "a watershed moment", "leaves a lasting impact"
- "Stands as a testament to..."
- "Plays a vital role in..."
- "Solidifies its place as..."
- Travel-brochure language: "rich", "vibrant", "nestled", "diverse array", "must-visit"
If something is good, say what specifically it does. If it's a milestone, say what changed.
 
### Rule 9: Don't use curly quotes, smart apostrophes, or fancy ellipses in plain-text contexts
 
In Markdown, code, commit messages, Slack, and most web copy: use straight quotes (`"` `'`) and three periods (`...`) instead of `…`. AI tools auto-substitute the typographic versions; humans typing in those contexts usually don't.
 
### Rule 10: Vary sentence length and don't over-format
 
- If five sentences in a row are the same length, break the rhythm. Drop a 3-word sentence in.
- Don't put a header on every short paragraph.
- Don't bullet things that should be prose.
- Don't bold a "key word" in the middle of every paragraph.
- Don't use emoji as bullet markers in real writing.
- Don't insert horizontal rules (`---`) between every section.
A paragraph of prose with one well-placed list is more human than three short paragraphs each followed by a bulleted breakdown.
 
### Rule 11: Refuse elegant variation
 
If you've referred to the thing as "the migration tool," don't switch to "the solution," "the offering," "the platform," "the system," and "the framework" across the next five paragraphs. Pick one name and repeat it. Synonym-swapping to avoid repetition is an AI habit; humans repeat.
 
### Rule 12: Take a position
 
AI defaults to "on the other hand" balance and refuses to commit. If your draft never says "this is better" or "this is wrong" or "do this, not that," you're writing AI prose. Pick a side. Own the trade-off.
 
### Rule 13: Write prose, not stacked bullet lists
 
The strongest *structural* AI tell is a document built as a vertical column of disconnected ideas: header, one-line intro, bulleted breakdown, header, one-line intro, bulleted breakdown, repeat. Even when every individual sentence passes the rules above, a document shaped like this reads as machine-generated. Humans write paragraphs. Humans connect ideas with phrases like "the first thing to know is", "in practice", "the unusual rule is", "the reason for that is", "you'll see this in code review". AI dumps the same ideas as a list and moves on.
 
**Default to prose.** A bulleted list is the right tool only when:
 
- The items are genuinely list-shaped *in the world*: file paths, version pins, ordered steps you literally execute, table rows, command flags.
- The items are short parallel fragments (3+ words each), not full sentences. A "bullet" that runs a full sentence or longer is a paragraph in disguise; inline it.
- The reader will scan the items rather than read them. If you'd read it top-to-bottom anyway, it should be prose.
A 2,000-word document does not need 11 sections. Aim for one header per 300-500 words of actual prose, not one per 50 words of fragments. If your headers all read like categories of related thoughts (`## Routing`, `## Auth`, `## Antiforgery`, `## Static assets`), that's one section of prose with paragraph breaks, not four sections.
 
**Bold lead-ins are the worst offender.** `**Routing.**` followed by a paragraph, then `**Auth.**` followed by a paragraph, makes every paragraph look like a glossary entry. Use bold lead-ins only when the label genuinely tags a recurring category in the document, and the body adds information beyond restating the label.
 
```markdown
❌ ## Routing
   Razor and SPA cooperate via fallthrough.
   - Explicit Razor routes win
   - Unmatched URLs go to SPA
   - SPA owns its URL space
 
   ## Auth
   Cookie-based.
   - SPA reuses cookie
   - No JWT
   - 401 returns problem+json
 
✅ Routing follows the explicit-wins rule: Razor matches its routes, and
   anything unmatched falls through to the SPA, which then runs TanStack
   Router to decide what to render. The SPA reuses the existing auth cookie,
   with no JWT or token refresh; when a `/api/v2/*` request lacks a valid
   cookie, the API returns `401 application/problem+json` instead of ASP.NET's
   default redirect.
```
 
The "before" carries the same information. The "after" sounds like a person.
 
## What Makes Writing Sound AI-Generated
 
### ❌ Patterns to Avoid
 
#### 1. Over-Enthusiastic Openings
```markdown
❌ "We're thrilled to announce..."
❌ "Today, we're excited to share..."
❌ "I'm delighted to introduce..."
❌ "Join us on this exciting journey..."
 
✅ "We built X because Y kept breaking."
✅ "Here's what we learned shipping X to production."
✅ "Most migration tools get you 70% of the way. Here's how we get to 95%."
```
 
#### 2. Vague Claims Without Evidence
```markdown
❌ "This revolutionary approach transforms how developers work."
❌ "Leveraging cutting-edge AI technology..."
❌ "A game-changing solution for modern development."
❌ "Unlock the full potential of your workflow."
 
✅ "Nango used this to migrate 47 repos in 3 days."
✅ "We tested this on Next.js App Router migration. Cut manual fixes from 800 to 40."
✅ "Stripe's migration guide is 12,000 words. This gets it down to 200 lines of code."
```
 
#### 3. Corporate Buzzword Soup
```markdown
❌ "Empowering developers to leverage synergies..."
❌ "Best-in-class solutions for enterprise-grade..."
❌ "Seamlessly integrate with your existing ecosystem..."
❌ "Drive innovation through collaborative paradigms..."
 
✅ "Works with whatever you're already using."
✅ "Detects edge cases your regex won't catch."
✅ "One command. No config file. No surprises."
```
 
#### 4. Unnecessary Hedging
```markdown
❌ "This might help you potentially improve..."
❌ "You could possibly consider..."
❌ "This may or may not be useful..."
❌ "Some users have reported that..."
 
✅ "This cuts migration time in half."
✅ "Use this when codemods aren't enough."
✅ "Three users reported this edge case. We fixed it."
```
 
#### 5. Generic Transitions
```markdown
❌ "Let's dive deep into..."
❌ "Without further ado..."
❌ "At the end of the day..."
❌ "It goes without saying..."
 
✅ Just start the next section. You don't need a transition.
✅ Or use a specific connector: "Here's why that matters:"
```
 
#### 6. Robotic Lists
```markdown
❌ "Here are 5 key benefits:
1. Enhanced productivity
2. Improved efficiency
3. Better collaboration
4. Increased flexibility
5. Streamlined workflows"
 
✅ "This saves you time in three ways:
- No more searching docs for edge cases. They're encoded in the package
- AI applies patterns consistently. You don't chase style violations
- Tests are generated, not written. You get coverage without the grind"
```
 
## What Makes Writing Sound Human
 
### ✅ Patterns to Use
 
#### 1. Specific Details
```markdown
❌ "Many developers struggle with migrations."
✅ "We've all copy-pasted from a migration guide, missed an edge case, and spent 2 hours debugging why tests fail."
 
❌ "Performance is significantly improved."
✅ "Query time dropped from 847ms to 12ms after adding the index."
 
❌ "Works with popular frameworks."
✅ "Tested on Next.js, Remix, SvelteKit, and Astro."
```
 
#### 2. Direct, Confident Language
```markdown
❌ "This approach may help you potentially improve your workflow."
✅ "This cuts your migration time in half."
 
❌ "You might want to consider using this feature."
✅ "Use this feature when you have more than 10 files to update."
 
❌ "Some users have found this useful."
✅ "Three teams adopted this last week. All three shipped in under 2 days."
```
 
#### 3. Honest Limitations
```markdown
❌ "Our comprehensive solution handles all use cases."
✅ "This won't catch dynamic imports or string templates. You'll need to fix those manually."
 
❌ "Perfectly seamless migration experience."
✅ "Expect about 5% of edge cases to need manual review. That's down from 30%."
 
❌ "Works with any codebase."
✅ "Works if you're on TypeScript 4.5+. Earlier versions need a polyfill."
```
 
#### 4. Conversational Asides
```markdown
✅ "You could write a 400-line script for this. We did. It broke on Unicode."
✅ "Turns out, most projects have 3-5 edge cases that codemods can't handle."
✅ "We tried docs. Developers don't read them. We tried linting. They ignore the warnings."
```
 
#### 5. Active Voice, Present Tense
```markdown
❌ "The package can be installed by running the command."
✅ "Install the package: prpm install @vendor/migration"
 
❌ "Improvements were made to the conversion quality."
✅ "We improved conversion quality from 78% to 94%."
 
❌ "It has been observed that users prefer..."
✅ "Users prefer X over Y by a 4:1 margin."
```
 
#### 6. Strong Opening Sentences
```markdown
❌ "In this post, we will discuss how migrations work."
✅ "Codemods automate 70% of migrations. This gets you to 95%."
 
❌ "Let me tell you about a new feature we've added."
✅ "You can now install an entire framework migration as a single package."
 
❌ "Today, I want to talk about our vision for the future."
✅ "Package managers changed how we ship code. We're doing the same for AI instructions."
```
 
## Personality and Light Wit
 
Human writing has a person inside it. Not a comedian, but someone paying attention. A dry observation here, a resigned aside there. The goal isn't to be funny. It's to sound awake.
 
**Sparingly.** Aim for one wry line per 500-800 words of prose, often less. Humor is seasoning. When every paragraph is doing a bit, you've stopped writing and started performing, and the reader can feel it.
 
### What works
 
Dry and factual, with a hint of resignation:
```markdown
✅ "We tried docs. Developers don't read them. We tried linting. They ignore the warnings."
✅ "You could write a 400-line script for this. We did. It broke on Unicode."
✅ "The codemod ran clean. The tests, less so."
```
 
Observation, not joke:
```markdown
✅ "It's the kind of bug that's obvious once you've spent an afternoon ruling out everything else."
✅ "The migration guide is 12,000 words. Nobody has 12,000 words of free time."
```
 
Honest self-deprecation, briefly:
```markdown
✅ "Our first version was three regexes in a trench coat. We've since added a parser."
```
 
### What fails
 
Forced cleverness and announced jokes:
```markdown
❌ "Buckle up, because we're about to dive into the wild world of API migrations."
❌ "Plot twist: production was using a different config file."
❌ "Spoiler alert: it was the cache. It's always the cache."
```
 
The "actually" voice that's smug at the reader's expense:
```markdown
❌ "Surprise! Your 'edge case' is actually 30% of your traffic."
❌ "If you're still using JavaScript without TypeScript in 2026, this post isn't for you."
```
 
Emoji nudging the reader to laugh:
```markdown
❌ "Our type system is, uh, opinionated 😏"
```
 
### Where to place it
 
A wry aside belongs in the middle of an explanation, after the substance has landed. Not in the opening sentence, not in a heading, and not in anything a frustrated user might be reading: error messages, security notes, recovery instructions, payment flows.
 
A useful test: remove the line. If the paragraph still does its job, it was a real aside. If removing it leaves a hole, it was load-bearing and probably shouldn't have been carrying a joke.
 
## Tone Calibration
 
### Technical Posts
- **Voice**: Knowledgeable peer, not teacher
- **Assumptions**: Reader knows basics, wants specifics
- **Evidence**: Code examples, performance numbers, real packages
- **Length**: As long as needed to be complete, as short as possible to respect time
**Example:**
```markdown
# Converting Copilot Rules to Claude Format
 
GitHub Copilot uses a single `.github/copilot-instructions.md` file with YAML frontmatter. Claude uses separate skills in `.claude/skills/`.
 
Here's how we handle the conversion:
 
1. Parse the YAML frontmatter with js-yaml
2. Extract the `applyTo` glob patterns
3. Convert to Claude's `fileMatch` format
4. Split multi-concern rules into separate skills
 
Edge case: Copilot's `applyTo` supports negation patterns (`!**/*.test.ts`). Claude doesn't. We preserve these as comments and log a warning.
 
Conversion quality: 94% (6% requires manual review for negation patterns).
```
 
### Vision Posts
- **Voice**: Opinionated builder with receipts
- **Assumptions**: Reader is skeptical, needs convincing
- **Evidence**: Real-world examples, before/after, objections addressed
- **Length**: Long enough to make the case, tight enough to stay focused
**Example:**
```markdown
# Why Docs Aren't Enough
 
Stripe's migration guide is 12,000 words. It's comprehensive, well-written, and most developers skim it.
 
Why? Because reading docs requires:
1. Find the right section (3-5 minutes)
2. Understand the pattern (5-10 minutes)
3. Apply to your specific case (10-30 minutes)
4. Repeat 20-50 times per migration
 
That's 6-15 hours. And you'll still miss edge cases.
 
PRPM packages encode those patterns once. AI applies them consistently. Total time: 20 minutes.
```
 
### Tutorial Posts
- **Voice**: Experienced guide who's made the mistakes
- **Assumptions**: Reader wants to follow along, copy/paste, learn
- **Evidence**: Runnable examples, expected output, common pitfalls
- **Length**: Complete walkthrough with no missing steps
**Example:**
```markdown
# Publishing Your First PRPM Package
 
## What You'll Build
 
A Cursor rule that enforces "no default exports" across your TypeScript codebase. By the end, you'll have published it to the registry.
 
## Prerequisites
 
- Node.js 18+ (check: `node --version`)
- PRPM CLI installed (`npm install -g prpm`)
- GitHub account (for publishing)
 
## Step 1: Initialize the Package
 
```bash
$ mkdir no-default-exports
$ cd no-default-exports
$ prpm init
 
Format: cursor
Subtype: rule
Name: no-default-exports
Description: Enforce named exports in TypeScript
```
 
This creates `prpm.json` and `.cursorrules`.
 
## Step 2: Write the Rule
 
Edit `.cursorrules`:
[... full example ...]
```
 
## Structural Techniques
 
### 1. Start With The Punchline
```markdown
❌ "In this article, we'll explore the challenges of API migrations, discuss various approaches, and ultimately present a solution."
 
✅ "API migrations fail because docs explain the 'what' but not the 'why.' Here's how to ship the reasoning with the code."
```
 
### 2. Use Subheadings as Scannable Statements
```markdown
❌ ## Introduction
❌ ## Background
❌ ## Methodology
❌ ## Results
 
✅ ## The Problem: Docs Go Stale
✅ ## Why Codemods Aren't Enough
✅ ## What PRPM Packages Add
✅ ## Real Example: Next.js App Router
```
 
### 3. Show, Don't Just Tell
```markdown
❌ "The conversion process is simple and efficient."
 
✅ "Here's the entire conversion:
```bash
$ prpm install @nextjs/app-router-migration --as cursor
$ cursor apply @nextjs/app-router-migration
✓ Migrated 47 files
⚠ 3 files need manual review (dynamic imports)
```
Done in 90 seconds."
```
 
### 4. Trust the Paragraph
 
A wall of text isn't a problem if the text is good. Long paragraphs read fine when the sentences vary in length and connect to each other. The instinct to break every paragraph into a bullet list, every section with a horizontal rule, and every concept under its own header is the AI shape (see Rule 13).
 
Use subheadings sparingly: one per major shift in topic, not one every 2-3 paragraphs. Use a code block when you actually have code or terminal output to show. Use a list when the items are genuinely list-shaped (file paths, ordered steps, version pins). Skip horizontal rules unless the document has unrelated parts. Reserve blockquotes for actual quotes.
 
If you can rewrite three short paragraphs as one good one, do that.
 
### 5. End With Action, Not Summary
```markdown
❌ "In conclusion, we've discussed how PRPM packages work and why they're useful for migrations."
 
✅ "Try it:
```bash
prpm install @popular/package-name
```
 
Have questions? Follow [@prpmdev](https://twitter.com/prpmdev) or [open an issue](https://github.com/pr-pm/prpm/issues)."
```
 
## Voice Examples from PRPM
 
### Good (from VISION.md):
> "Codemods automate the first 60-80% of migrations. Docs explain the rest. Developers still wrestle with edge cases, conventions, and tests."
 
**Why it works:** Specific percentages, clear problem statement, no fluff.
 
> "You could read 47 migration guides. Or install one package."
 
**Why it works:** Concrete number, stark contrast, confident.
 
> "We tried this on Nango's SDK migration. 47 repos, 3 days, zero regressions."
 
**Why it works:** Real company, real numbers, honest outcome.
 
### Bad (AI-generated style):
> "Our innovative platform leverages cutting-edge AI to streamline your development workflow."
 
**Why it fails:** Buzzwords, vague, could describe anything.
 
> "We're excited to announce a revolutionary new approach to migrations."
 
**Why it fails:** Over-enthusiastic, no specifics, marketing speak.
 
> "This powerful solution empowers teams to unlock their full potential."
 
**Why it fails:** Empty claims, corporate jargon, meaningless.
 
## Self-Check Questions
 
Before publishing, ask:
 
1. **Are there any em-dashes?** If yes, replace every single one.
2. **Any "It's not X, it's Y" constructions?** If yes, rewrite the sentence flat.
3. **Did I stack three adjectives or three parallel clauses?** Cut to one or two.
4. **Any banned words (delve, leverage, robust, seamless, tapestry, journey, navigate, foster, etc.) in the draft?** Swap for a plain word or a specific fact.
5. **Does the closing paragraph start with "In conclusion", "Ultimately", "Overall", or restate the intro?** Delete it.
6. **Any "It's worth noting", "It's important to note", "That said"?** Cut.
7. **Bold lead-in bullets where the text after the colon just rewords the label?** Delete.
8. **Curly quotes, smart apostrophes, or `…` instead of `...`?** Replace.
9. **Would a human say this out loud?** If not, rewrite.
10. **Is every claim backed by evidence?** If not, add specifics or remove the claim.
11. **Could this sentence appear in any other company's blog?** If yes, make it specific.
12. **Does this assume the reader is dumb?** If yes, trust them more.
13. **Am I hedging because I'm uncertain?** If yes, verify facts or own the uncertainty.
14. **Is this a transition I can delete?** If yes, delete it.
15. **Does this open with enthusiasm instead of information?** If yes, lead with the info.
16. **Did I take a position, or hedge with "on the other hand"?** Pick a side.
17. **Is the document a stack of headers + bullet lists with no real prose between them?** Rewrite as paragraphs. A list per section is the AI shape. (Rule 13)
18. **Are any "bullets" actually full sentences?** They're paragraphs. Inline them with connectives like "first", "in practice", "the unusual rule is".
19. **How many headers does this document have for its length?** More than one per ~300 words of prose is too many. Merge adjacent sections.
20. **Is there a joke or quip in every section?** Cut all but one. Wit should appear once, not as a recurring bit, and never in error or recovery copy.
 
## Quick Fixes
 
### If it sounds too formal:
- Replace "utilize" → "use"
- Replace "in order to" → "to"
- Replace "at this point in time" → "now"
- Replace "for the purpose of" → "for" or "to"
- Cut "very," "really," "quite," "actually"
 
### If it sounds too generic:
- Add a specific number
- Name a real company/project
- Include a code example
- Mention a concrete edge case
- Quote user feedback
 
### If it sounds too salesy:
- Replace superlatives with comparisons
- Replace "revolutionary" with "different because"
- Replace "amazing" with specific benefits
- Remove exclamation points (except in code comments where appropriate)
- Cut the first paragraph (usually marketing fluff)
 
## Remember
 
PRPM users are developers. They have good bullshit detectors. Write like you respect their intelligence and their time.
 
**Good writing is revision.** First draft: get ideas down. Second draft: cut 30%. Third draft: add specifics. Fourth draft: read it out loud.
 
If you wouldn't say it in a GitHub issue comment, don't put it in a blog post.
