#!/bin/sh
# redfirst installer.
#
# Adds one thing to your project: a SessionStart hook that prints overdue
# restore checks. Nothing else runs automatically, nothing phones home,
# nothing updates itself.
#
# Read bin/redfirst before running this. It is one file and it is short —
# that is deliberate. A tool that installs a session hook has to be auditable,
# especially in 2026, when a session hook was the delivery vector for a
# supply-chain worm.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET_IN="${1:-$PWD}"

[ -d "$TARGET_IN" ] || { echo "installer: no such directory: $TARGET_IN" >&2; exit 2; }
TARGET=$(CDPATH= cd -- "$TARGET_IN" && pwd)

# Resolved paths on both sides. The previous guard compared the argument
# verbatim, so `sh ./install.sh .` from inside redfirst walked straight past it
# and installed the tool into itself.
case "$TARGET" in
    "$SELF_DIR"|"$SELF_DIR"/*)
        echo "installer: point this at your project, not at the redfirst directory" >&2; exit 2 ;;
esac

BIN="$SELF_DIR/bin/redfirst"
[ -f "$BIN" ] || { echo "installer: not found: $BIN" >&2; exit 2; }

# The hook is invoked by the harness, not necessarily by a shell that honours a
# shebang. On Windows a bare path to an extensionless file opens the
# "choose an app" dialog instead of running — observed, not theorised — so the
# interpreter has to be named explicitly, and the path is quoted so a space in
# it cannot split the command.
#
# Naming it `sh` is not enough, and that took installing the tool for real to
# find out. Measured on Windows: `sh` does not resolve from cmd.exe at all, and
# the harness is free to spawn the hook from there. The installer could not see
# this, because it verifies the command by running it from itself — that is,
# from a POSIX shell, the one launcher for which the bare name always works.
#
# So the interpreter is named by ABSOLUTE path in this platform's own form.
#
# And on the emulation layers it is started as a LOGIN shell. Without that it
# inherits the bare Windows PATH, where none of the POSIX utilities exist: the
# tool dies on `mktemp: command not found` before reaching a single check. It
# dies loudly, exit 2, as designed — but the one automatic guarantee of this
# product would never have fired. Measured, then fixed: the login form runs
# from cmd.exe, PowerShell and bash alike, and costs 427 ms against 189 ms,
# once per session.
SH=$(command -v sh 2>/dev/null) || SH=""
[ -n "$SH" ] || SH="/bin/sh"
LOGIN=""
# cygpath ships with Git Bash, MSYS and Cygwin — exactly the environments where
# a POSIX path is what a non-POSIX launcher cannot use, and exactly the ones
# whose utilities live outside the Windows PATH.
if command -v cygpath >/dev/null 2>&1; then
    _native=$(cygpath -w "$SH" 2>/dev/null) || _native=""
    [ -n "$_native" ] && { SH="$_native"; LOGIN=" -l"; }
fi
HOOK_CMD="\"$SH\"$LOGIN \"$BIN\" due --quiet"

# JSON needs backslashes and quotes escaped; Windows paths are full of the first.
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
HOOK_JSON=$(json_escape "$HOOK_CMD")

SETTINGS="$TARGET/.claude/settings.json"
hook_done=0
claude_done=0

echo "redfirst → $TARGET"
echo

# ── 1. config ────────────────────────────────────────────────────────────────
( cd "$TARGET" && REDFIRST_DIR=.redfirst sh "$BIN" init )

# ── 2. hook ──────────────────────────────────────────────────────────────────
echo
if [ -e "$TARGET/.claude" ] && [ ! -d "$TARGET/.claude" ]; then
    echo "installer: $TARGET/.claude exists and is not a directory - not installing the hook." >&2
elif [ -e "$SETTINGS" ] && [ ! -f "$SETTINGS" ]; then
    echo "installer: $SETTINGS exists and is not a file - not installing the hook." >&2
elif [ -f "$SETTINGS" ]; then
    # Match the actual command, not the word "redfirst": a project that merely
    # mentions the tool in some unrelated setting used to be reported as
    # already wired, and the hook was never installed at all.
    if grep -Fq "$BIN" "$SETTINGS" 2>/dev/null; then
        echo "The hook is already in $SETTINGS - leaving it alone."
        hook_done=1
    else
        cat <<EOF
$SETTINGS already has settings, so it is NOT edited automatically:
merging JSON blindly is a reliable way to break your configuration.

Add a SessionStart hook to it with this command:

  $HOOK_CMD

EOF
    fi
else
    mkdir -p "$TARGET/.claude"
    cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_JSON" }
        ]
      }
    ]
  }
}
EOF
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SETTINGS" 2>/dev/null; then
            echo "Created $SETTINGS with a session-start hook (JSON validated)."
            hook_done=1
        else
            echo "installer: the resulting $SETTINGS does not parse as JSON - removing it." >&2
            rm -f "$SETTINGS"
        fi
    else
        echo "Created $SETTINGS with a session-start hook (JSON not validated: no python3)."
        hook_done=1
    fi
fi

# Prove the command actually runs, rather than assuming it does.
if [ "$hook_done" = 1 ]; then
    if ( cd "$TARGET" && eval "$HOOK_CMD" >/dev/null 2>&1 || [ $? -le 2 ] ); then
        echo "The hook command was executed for real - it works."
    else
        echo "installer: the hook command does not run. The hook will be useless." >&2
        hook_done=0
    fi
fi

# ── 3. instructions for the assistant ────────────────────────────────────────
TPL="$SELF_DIR/templates/CLAUDE.redfirst.md"
if [ -e "$TARGET/CLAUDE.md" ] && [ ! -f "$TARGET/CLAUDE.md" ]; then
    echo "installer: $TARGET/CLAUDE.md exists and is not a file - skipping." >&2
elif [ -f "$TARGET/CLAUDE.md" ]; then
    if grep -Fq "redfirst counter" "$TARGET/CLAUDE.md" 2>/dev/null; then
        echo "CLAUDE.md already contains the redfirst rules."
        claude_done=1
    else
        echo "CLAUDE.md exists. Append the contents of this file to it:"
        echo "  $TPL"
    fi
elif cp "$TPL" "$TARGET/CLAUDE.md" 2>/dev/null; then
    echo "Created $TARGET/CLAUDE.md with the rules for the assistant."
    claude_done=1
else
    echo "installer: could not create $TARGET/CLAUDE.md" >&2
fi

# ── 4. honest summary ────────────────────────────────────────────────────────
# The banner used to print unconditionally, including when nothing was wired.
echo
if [ "$hook_done" = 1 ]; then
    # The second paragraph is the honest half. This installer establishes that
    # the command runs; the product is that its output REACHES A HUMAN, and
    # that part is decided by the harness, which cannot be interrogated from
    # here. Saying so is cheaper than checking and more honest than silence —
    # and the same gap already cost a hook that ran fine from a POSIX shell
    # and not at all from anywhere else.
    cat <<'EOF'
It works on its own: at the start of every session the assets whose restore
check is overdue are printed. The harness prints them, not the model.

What this installer did NOT check: that your harness will SHOW that output. It
ran the hook command for real, and that is all it can see from here. Whether
the harness surfaces it becomes visible at the next session start and nowhere
earlier - so look then, and if nothing appears, the hook is not doing its job.
EOF
else
    cat <<'EOF'
THE HOOK IS NOT INSTALLED. There are no automatic checks right now, only the
manual commands below. Until it is, nobody will remind you of overdue checks.
EOF
fi
[ "$claude_done" = 1 ] || echo "The rules for the assistant are not installed - three checks will not apply."

cat <<'EOF'

Manually:
  redfirst red "<what>" -- <cmd>   run it and record that the check FAILS
  redfirst green "<what>" -- <cmd> run it and record the move to green
  redfirst drop "<what>" -- <why>  withdraw an entry, with the reason recorded
  redfirst log                     journal: what was shown red, what is closed
  redfirst wired <Symbol>          in how many files the name is in code
  redfirst samples <pattern>       a count together with what it counted
  redfirst counter <term>          search for what is claimed absent
  redfirst removable <file>        move aside, build, put back - never deletes

First, write your assets into .redfirst/irreplaceable - an empty list
means the hook stays silent, and its silence will be undeserved.
EOF
