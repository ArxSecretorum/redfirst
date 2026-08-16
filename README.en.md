# redfirst

**Deterministic checkpoints for AI-assisted development.**

[Русский](README.md) · MIT · no dependencies · nothing leaves your machine

---

Assistants write code ten times faster than people. The practices that used to
verify that code did not scale with it. The gap between what ships and what is
checked got a name in 2026 — the **Verification Gap** — and numbers: a security
flaw in roughly 45% of AI-generated samples, and 63% of developers reporting
they spend more time debugging AI code than writing it themselves would have
taken.

The core of it is simple and uncomfortable: **the tests are written by the same
author as the code.** When the assistant misunderstands the requirement, it
writes a test that confirms the misunderstanding, and the test is green. Green
stopped being evidence.

`redfirst` does not try to close that gap entirely. It closes three specific
holes mechanically and reminds you about three more.

## The principle

> **A check only counts if its result can be judged without reading the code.**

"I checked, it's fine" is not a result. A count, three sample lines, or a
red-then-green transition is a result. Hence the name: show it fail before you
call it done.

## What it does

**Guaranteed — executed by the harness, the model is not involved:**

| | |
|---|---|
| Overdue restore checks | printed at the start of every session |
| Dead code | `wired` prints non-test references; zero exits red |
| A bad measurement | `samples` will not let a number be reported without what it counted |

**Advisory — lives in `CLAUDE.md`, compliance is the assistant's to keep:**
a cheap check runs before any theory about it being unnecessary; ask whether the
measurement itself created the difference the conclusion rests on; a claim of
absence requires a search for presence.

The difference between those two lists is the point, and we do not blur it.
Only the first one guarantees anything.

## Install

```sh
git clone https://github.com/ArxSecretorum/redfirst.git
sh redfirst/install.sh /path/to/your/project
```

The installer detects the project type, proposes candidates for your
irreplaceable assets, writes the config and wires the session hook. You write no
paths — you confirm what it found and answer two questions.

## Commands

### `wired` — does this thing actually exist

```
$ redfirst wired DiagnosticRingLog
redfirst wired "DiagnosticRingLog": 0 references outside tests and declaration
Declared here:
  ./app/src/main/java/.../DiagnosticRingLog.kt:54:class DiagnosticRingLog(
Zero. This does not exist in the running system, however many tests cover it.
```

A real case: 287 lines, six green tests, zero callers. For six weeks those tests
counted as coverage in status reports. The gate was green — there was nothing
for it to catch.

### `samples` — a number, together with what it counted

```
$ redfirst samples "Thread("
redfirst samples "Thread(": 27 matches
Samples from the start, middle and end — confirm this is what you meant to count:
  .../MainActivity.kt:1314:        Thread({
  .../MediaArtworkRepository.kt:191:  if (Thread.currentThread().isInterrupted) return
  .../BoundedSerialWorker.kt:36:      Thread(runnable, "$threadName-...").apply {
```

The middle line is `Thread.currentThread()`, not a thread being created. That is
how you get a confident finding about "26 ownerless threads" when there are ten.
Samples are taken from the start, middle and end deliberately: the first three
lines would not have shown it.

### `counter` — search for the thing you are about to say doesn't exist

```
$ redfirst counter sanitize redact
redfirst counter: looking for what supposedly isn't there.
  sanitize                     5
  redact                      10
Found. The claim of absence is wrong as stated.
```

"I didn't find it" and "it isn't there" are different claims. The second one
requires a search that looked for the opposite, with its output attached.

### `due` — what is overdue

```
$ redfirst due
  ! Application signing key — restore has NEVER been tested
  ! Licence signing key — verified 227 days ago, limit 90
redfirst: 2 of 3 irreplaceable assets overdue.
A copy you have never restored from is not a copy.
```

Runs from the session-start hook. The automation is the whole point: a risk
written into four documents over five days and executed in none of them is not a
memory problem, it is a prioritisation problem. The asset list holds **no paths**
— a file describing where your secrets live is itself a map.

## What it does not do

It does not make code better. It does not catch logic errors in code that is
wired up and covered by passing tests. It replaces neither review nor the QA
services that exercise application behaviour — it answers a different question:
**is what was written connected, and is what was claimed confirmed.**

And plainly: three of the six checks are reminders in a text file. The assistant
can skip them. A tool promising more than that is misleading you.

## On security

`redfirst` installs a session-start hook. In February 2026 an RCE was disclosed
through Claude Code hooks; in April a PyPI worm planted a malicious
`SessionStart` hook, so merely opening a project executed the payload. We are
asking for exactly the access you were recently attacked through, and we treat it
that way:

- everything executable is **one file**, `bin/redfirst`, readable in one sitting;
- no network, no dependencies, no self-update;
- the installer does not edit an existing `settings.json` — it prints what to add
  and leaves the decision to you.

Read `bin/redfirst` before installing. That is not a formality: short and
auditable is the only honest basis of trust for a tool like this.

## Provenance

These checks were not invented at a desk. Each grew out of a recorded failure in
a live commercial project: a dead module that passed for coverage for six weeks;
a miscount that a conclusion was built on; a claim of absence published without a
counter-search; a signing key whose irreplaceability was documented in four
places and acted on in none.

By [Arx Secretorum](https://github.com/ArxSecretorum). MIT licence.
