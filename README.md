# redfirst

**Deterministic checkpoints for AI-assisted development.**

MIT · no dependencies · nothing leaves your machine

---

An assistant writes code ten times faster than a human. The practices that used
to check that code did not keep up. The gap between what is written and what is
verified got a name in 2026 — the **Verification Gap** — and numbers: a
vulnerability is found in 45% of AI-generated samples, and 63% of developers
spend more time debugging generated code than they would have spent writing it.

The core of the problem is simple and unpleasant: **the tests are written by the
same author as the code.** If the assistant misunderstood the task, it will
write a test that confirms its misunderstanding, and the test will be green.
Green stopped being proof.

`redfirst` does not try to fix that whole. One check it performs itself, in six
it refuses to take anyone's word, and about three it reminds.

## The principle

> **A check counts only if its result can be judged without reading code.**

"I checked, it's fine" is not a result. A number, three sample lines, or a move
from red to green is a result. Hence the name: show how it fails before calling
it done.

## What it does

Three levels, and they are not equal in strength. We keep them apart precisely
because they are the easiest thing to blur.

**1. Executed by the harness. Nothing to run, nothing to skip:**

| | |
|---|---|
| Overdue restore checks | printed at the start of every session |

That is all. One row, because there is exactly one automatic guarantee here.

**2. Will not take your word. You have to run them, but the answer cannot be
faked:**

| | |
|---|---|
| "Where do I even start" | `changed` takes candidates from the change itself, not from what the assistant said |
| "I showed how it fails" | `red` runs the command itself and refuses to record a red if it passes |
| "Fixed it" | `green` requires a red with the same wording to be in the journal already |
| Dead code | `wired` shows in how many non-test files the name occurs in code; one is red |
| A crooked measurement | `samples` will not let a number be given without samples of what it counted |
| "That is nowhere" | `counter` searches for presence and attaches the output |

**3. Reminders — they live in `CLAUDE.md`, compliance is the assistant's to
keep:** a cheap check comes before the theory that it is unnecessary; ask
whether the measurement created the difference the conclusion rests on; a claim
of absence requires a search for presence.

The difference between the levels matters. The second level does not guarantee
the check is run — it guarantees the result cannot be faked with words. The
third guarantees nothing.

## Install

```sh
git clone https://github.com/ArxSecretorum/redfirst.git
sh redfirst/install.sh /path/to/your/project
```

<!-- redfirst-claim: installer-asks-nothing -->
It asks nothing — there is no prompt anywhere in it. It detects the project
type, creates `.redfirst/irreplaceable` from a template, writes the session-start
hook into `.claude/settings.json`, and puts the rules for the assistant into
`CLAUDE.md`. An existing `settings.json` or `CLAUDE.md` is never edited for you:
it prints what to add and leaves the decision where it belongs.

Filling in the asset list is then yours to do. Nothing else can do it — that
list is the one part of this only you know.

### Proving the hook reaches you

The installer proves the command runs. It cannot prove your harness will show
what the command prints, and it says so rather than implying otherwise. You can
prove that half yourself, in one command: start a session and read the harness's
own account of what it did with the hook.

```sh
claude -p ok --output-format stream-json --verbose | tr ',' '\n' | grep -A6 hook_response
```

With something overdue in the registry you should see `"exit_code":1`, an empty
`"stdout"`, the warning in `"stderr"` and `"outcome":"error"` — the path that
gets surfaced rather than the one that gets swallowed. If instead the output is
in `"stdout"` with `"exit_code":0`, it is being handed to the model as context
and not to you, which is the arrangement this tool exists to replace.

The check costs nothing. The hook runs before the model is called at all, so it
answers even on an account with no credit left to reply with.

## Commands

### `changed` — where to start when nobody gave you a name

Every other command takes a symbol you have to know in advance. And you learn it
from the assistant — from the very side you are about to check. The claim "I
cleaned up the old auth path" cannot be checked: there is no name in it.

<!-- redfirst-output: These are CANDIDATES, not a verdict -->
```
$ redfirst changed
redfirst changed: what appeared and what disappeared
Scanned from: /path/to/project
Comparing against: HEAD
Changed files with code: 2 (0 skipped)

APPEARED - these names were absent from the comparison base. Is it wired in:
  redfirst wired BrandNewThing

These are CANDIDATES, not a verdict. Names are taken from code positions
only - strings and comments are stripped by the same pass wired uses - so
local variables are still among them, but prose is not. Which of them is a
thing worth checking is a question this list opens, not one it closes.
```

Two questions answered by `grep`, and none that would need a parser:
**appeared** — the name is in the changed lines and nowhere in the comparison
base; **disappeared** — the other way round. The first leads to `wired`, the
second to `counter`.

Three classes are filtered out: a name occurring **once** in the whole tree is a
mention, not a thing; a name spread across **three files or more** is wired in
beyond doubt; and a word that lives only in comments and strings is prose. The
last one is decided by the classifier `wired` already uses — declarations are
still not recognised, and that is a different thing from stripping comments.
How many were dropped in each class is printed — silently shortening the list
would read as "there was nothing else".

### `red` and `green` — what the tool is named after

"Show how it fails first" was the last rule the tool did not check: it lived as
text and rested on the good faith of the party being checked. Now the tool runs
the command itself.

<!-- redfirst-output: Recorded RED -->
```
$ redfirst red "the hook reaches the human" -- sh run-the-hook.sh
redfirst red: the hook reaches the human
Running: sh run-the-hook.sh
Exit code: 1. Last lines of output:
  hook printed nothing
Recorded RED. Close it with: redfirst green "the hook reaches the human" -- <the same command>
```

You cannot declare something red that passes — there is nothing to record. You
cannot close something green that never had a red: green on its own proves
nothing, the tests were written by the same author as the code.

`redfirst log` shows the journal: what was declared broken, on what date, at
which commit, by which command, and whether it reached green. Exit code 1 while
any red is still open. It is the one artefact that accumulates, and the one a
person who does not read code can open and read.

The commit is part of the entry because without it the journal reads, a week
later, as a date next to a sentence and matches no change in the repository. If
the working tree differed from `HEAD` at the time, the entry says `+dirty`
rather than claiming a precision it does not have.

Matching a green to its red by exact wording is what stops one check from
closing another — and it means a typo leaves an entry nothing can close. That is
what `drop` is for:

<!-- redfirst-output: Withdrawn. Both entries stay in the journal -->
```
$ redfirst drop "the hok reaches the human" -- typo in the wording, reopened as "hook"
redfirst drop: the hok reaches the human
Reason: typo in the wording, reopened as "hook"
Withdrawn. Both entries stay in the journal - nothing was deleted, and this
is NOT a green: closing it green again requires showing a red again first.
```

A withdrawal needs a reason and is itself recorded. Deleting an entry outright
is not offered: an entry that vanished is worse than a wrong one, because
nothing is left to say it was ever there.

### `wired` — does this thing actually exist

<!-- redfirst-output: A SINGLE MENTION in the whole project -->
```
$ redfirst wired DiagnosticRingLog
redfirst wired "DiagnosticRingLog"
Scanned from: /path/to/project
  files mentioning it   1
  of those, in code     1
  outside code only     0
  mentions in code      1
A SINGLE MENTION in the whole project:
  ./src/main/kotlin/diag/DiagnosticRingLog.kt:10:class DiagnosticRingLog(
If that is the declaration, the thing is dead: nothing names it, itself included.
If that is a call, the declaration lies outside the scanned masks.
```

Exit code 1. The question it answers is "in how many non-test files does this
name occur in code", not "is it called": parsing declarations failed on six
forms out of seven and was thrown away. Strings and comments do not count — a
mention is not a use. It says nothing about whether the code is correct.

A real case: 287 lines, six green tests, zero callers. For six weeks those tests
counted as coverage in status reports. The gate was green — there was nothing
for it to catch.

### `samples` — a number together with what it counted

<!-- redfirst-output: Samples from the start, the middle and the end -->
```
$ redfirst samples "Thread("
redfirst samples "Thread(": 27 matches
Samples from the start, the middle and the end - check this is what you meant to count:
  .../MainActivity.kt:1314:        Thread({
  .../MediaArtworkRepository.kt:191:  if (Thread.currentThread().isInterrupted) return
  .../BoundedSerialWorker.kt:36:      Thread(runnable, "$threadName-...").apply {
```

The middle line is `Thread.currentThread()`, not a thread being created. That is
how a confident finding about "26 ownerless threads" appears when there are ten.
Samples are taken from the start, the middle and the end deliberately: the first
three lines would not have shown that mistake.

### `counter` — searching for what is claimed absent

<!-- redfirst-output: The claim of absence, as worded, is false -->
```
$ redfirst counter sanitize redact
redfirst counter: searching for what is claimed absent (tests and vendor included).
Scanned from: /path/to/project
  sanitize                     5
  redact                      10
Found. The claim of absence, as worded, is false.
```

"I did not find it" and "it is not there" are different claims. The second one
requires a search that would have found the opposite, and its output next to the
claim.

### `due` — what is overdue

<!-- redfirst-output: restoring it has NEVER been checked -->
```
$ redfirst due
  ! App signing key - restoring it has NEVER been checked
  ! Licence signing key - checked 259 days ago, the limit is 90
redfirst: 2 of 3 irreplaceable assets need attention.
A copy you have never restored from is not a copy.
Mark it after checking: redfirst verified "<name>"
```

Run by the session-start hook. The point is the automatism: a risk written down
in four documents over five days and acted on never is not a memory problem, it
is a prioritisation problem. The asset list is stored **without paths**: a file
titled "where my secrets live" is a map in its own right.

## What it does not do

It does not make code better. It does not catch logic errors in code that is
wired in and covered by passing tests. It replaces neither review nor the QA
services that test application behaviour — it answers a different question:
**is what was written wired in, and is what was claimed confirmed.**

And plainly: **one** check out of ten is executed automatically. Six refuse to
accept a wrong answer, but you have to run them. Three are reminders in a text
file, and the assistant may not follow them. A tool that promises more is
misleading you.

## About security

`redfirst` installs a session-start hook. In February 2026 an RCE was disclosed
through Claude Code hooks, and in April a worm on PyPI planted a malicious
`SessionStart` — merely opening a project executed the payload. We are asking
for exactly the access you were recently attacked through, and we treat that
accordingly:

<!-- redfirst-claim: one-file-runs-itself -->
<!-- redfirst-claim: no-network -->
<!-- redfirst-claim: installer-keeps-your-settings -->
<!-- redfirst-claim: registry-holds-no-paths -->

- the only file that ever runs **by itself** is `bin/redfirst`, one file,
  readable in one sitting. `install.sh` and `tests/run` are the other two
  scripts in here and you start both of them yourself;
- no network, no dependencies, no self-update;
- the installer does not edit an existing `settings.json` automatically — it
  prints what to add and leaves the decision to you;
- the asset registry holds names and dates, never paths.

Each of those four is checked by `tests/unit/claims.sh` rather than promised.
The first one used to read "everything executable is one file", which was not
true — three files carry the executable bit — and nothing could say so.

Read `bin/redfirst` before installing. That is not a formality: short and
auditable is the only honest basis of trust for a tool like this.

## The regression suite

<!-- redfirst-count: cases=157 checks=328 -->
```sh
sh tests/run              # 157 cases across dash and bash — 328 checks
sh tests/run --self-check # breaks the tool on purpose, demands the suite notices
```

Built around the fact that not all failures are equal. Every case declares a
direction: `red` means the tool **must** raise the alarm, `green` means it must
stay quiet. A failing `red` case means the tool missed a defect and counts as a
**blocker**; a failing `green` case means it complained for nothing and counts
as noise. They are reported separately, because "3 failed" tells you nothing and
"1 blocker, 2 noise" tells you everything.

A case may be marked `red?` or `green?` — "the direction is right, the tool does
not meet it yet". That is how a known open defect is written down: without the
mark a suite carrying such cases is red forever and stops telling the known from
a new regression. The mark is loud — the exit code is never 0 while one is open,
and a marked case that **passes** exits 2 and demands the mark be removed.

<!-- redfirst-count: checks=328 -->
A case whose precondition cannot be created on this machine does not count as
passed: it lands in a **NOT CHECKED** bucket, is named in the report, and the
word "clean" becomes unavailable. Out of 328 checks, six are skipped on Windows
— `chmod 000` silently does nothing there, and neither an unreadable file nor a
symlink can be made — and two are skipped on Linux, which has no Windows shell
emulation for a hook to survive. Neither machine alone runs them all, and each
run names the ones it did not.

Everything runs in two shells, and a divergence between them is its own failure
class: the bashism `$((10#08))` was invisible under bash and killed `due` on
every August date, and `/bin/sh` on Debian and Raspberry Pi OS is dash.

<!-- redfirst-count: breaks=6 -->
`--self-check` deliberately breaks the tool at six points and requires the suite
to go red. A suite that cannot be shown failing proves nothing — the same "green
proves nothing" this tool exists to fight, one level up.

On Raspberry Pi OS a full run takes about six seconds. The same checks take
minutes under Git Bash on Windows; the difference is entirely the price of
spawning processes, so `ONLY=<glob>` is the tool of choice while editing.

Every case carries the date and the defect it holds down, so the files in
`tests/cases/` double as an incident log. Details in `tests/SPEC.md`, which is
kept in Russian as a working document, as is `docs/DEBTS.md`.
