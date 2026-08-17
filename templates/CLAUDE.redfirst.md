# Verification rules (redfirst)

The three rules below cannot be enforced by a hook: there is no machine event to
trigger them. That is why they live here, and why they hold without reminders.

The principle behind all of them: **a check counts only if its result can be
judged by someone who does not read code.** "I checked, it's fine" is not a
result. A number, three sample lines, or a move from red to green is a result.

## 1. A cheap check comes before the theory that it is unnecessary

If a check costing under five minutes is available, run it before the analysis
proving it is not needed. Reasoning about why a measurement is redundant almost
always costs more than the measurement, and is sometimes wrong.

## 2. Did I create the difference I am reasoning from

Before concluding anything from a difference between A and B, check whether you
touched B while measuring. A diagnostic action is part of the experiment, not a
neutral observation of it.

## 3. A claim of absence requires a search for presence

Before saying "X is missing / not handled / not covered", run a search that
would find X, and attach its output:

    redfirst counter <term> [term...]

"I did not find it" and "it is not there" are different claims. Only the first
one may be published when the search was not exhaustive.

## Acceptance

Before the word "done", show how it **fails** on a deliberately broken input
named by the owner. Red first, then green. Green on its own proves nothing: the
tests were written by the same author as the code.

This rule is no longer on anyone's conscience - it is checked:

    redfirst red   "<what you are checking>" -- <command>
    redfirst green "<the same wording>"      -- <the same command>

`red` runs the command itself and refuses to record anything if it passes.
`green` refuses if no red with the same wording is in the journal. The owner
reads the result with `redfirst log`: what was declared broken, on what date,
and whether it ever reached green.

Before treating a new module as existing:

    redfirst wired <Symbol>

It counts files outside tests where the name occurs in code. One file means that
beyond it the thing is not in the running system, however many tests cover it.
Strings and comments do not count: a mention is not a use.

If you do not know which name to check, start from the change itself:

    redfirst changed

## Numbers

Any figure that affects a decision is reported together with three lines of what
it counted:

    redfirst samples <pattern>

The measuring instrument errs as easily as the thing being measured.
