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

[ -d "$TARGET_IN" ] || { echo "installer: нет такого каталога: $TARGET_IN" >&2; exit 2; }
TARGET=$(CDPATH= cd -- "$TARGET_IN" && pwd)

# Resolved paths on both sides. The previous guard compared the argument
# verbatim, so `sh ./install.sh .` from inside redfirst walked straight past it
# and installed the tool into itself.
case "$TARGET" in
    "$SELF_DIR"|"$SELF_DIR"/*)
        echo "installer: укажите ваш проект, а не каталог redfirst" >&2; exit 2 ;;
esac

BIN="$SELF_DIR/bin/redfirst"
[ -f "$BIN" ] || { echo "installer: не найден $BIN" >&2; exit 2; }

# The hook is invoked by the harness, not necessarily by a shell that honours a
# shebang. On Windows a bare path to an extensionless file opens the
# "choose an app" dialog instead of running — observed, not theorised. `sh` in
# front makes the command work regardless of who launches it, and the path is
# quoted so a space in it cannot split the command.
HOOK_CMD="sh \"$BIN\" due --quiet"

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
    echo "installer: $TARGET/.claude существует и не является каталогом — хук не ставлю." >&2
elif [ -e "$SETTINGS" ] && [ ! -f "$SETTINGS" ]; then
    echo "installer: $SETTINGS существует и не является файлом — хук не ставлю." >&2
elif [ -f "$SETTINGS" ]; then
    # Match the actual command, not the word "redfirst": a project that merely
    # mentions the tool in some unrelated setting used to be reported as
    # already wired, and the hook was never installed at all.
    if grep -Fq "$BIN" "$SETTINGS" 2>/dev/null; then
        echo "Хук уже прописан в $SETTINGS — не трогаю."
        hook_done=1
    else
        cat <<EOF
В $SETTINGS уже есть настройки, поэтому НЕ правлю его автоматически:
слить JSON вслепую — верный способ сломать вашу конфигурацию.

Добавьте в него хук SessionStart с такой командой:

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
            echo "Создан $SETTINGS с хуком старта сессии (JSON проверен)."
            hook_done=1
        else
            echo "installer: получившийся $SETTINGS не разбирается как JSON — удаляю." >&2
            rm -f "$SETTINGS"
        fi
    else
        echo "Создан $SETTINGS с хуком старта сессии (JSON не проверен: нет python3)."
        hook_done=1
    fi
fi

# Prove the command actually runs, rather than assuming it does.
if [ "$hook_done" = 1 ]; then
    if ( cd "$TARGET" && eval "$HOOK_CMD" >/dev/null 2>&1 || [ $? -le 2 ] ); then
        echo "Команда хука выполнена вживую — работает."
    else
        echo "installer: команда хука не запускается. Хук останется бесполезным." >&2
        hook_done=0
    fi
fi

# ── 3. instructions for the assistant ────────────────────────────────────────
TPL="$SELF_DIR/templates/CLAUDE.redfirst.md"
if [ -e "$TARGET/CLAUDE.md" ] && [ ! -f "$TARGET/CLAUDE.md" ]; then
    echo "installer: $TARGET/CLAUDE.md существует и не является файлом — пропускаю." >&2
elif [ -f "$TARGET/CLAUDE.md" ]; then
    if grep -Fq "redfirst counter" "$TARGET/CLAUDE.md" 2>/dev/null; then
        echo "CLAUDE.md уже содержит правила redfirst."
        claude_done=1
    else
        echo "CLAUDE.md существует. Допишите в него содержимое файла:"
        echo "  $TPL"
    fi
elif cp "$TPL" "$TARGET/CLAUDE.md" 2>/dev/null; then
    echo "Создан $TARGET/CLAUDE.md с правилами для ассистента."
    claude_done=1
else
    echo "installer: не удалось создать $TARGET/CLAUDE.md" >&2
fi

# ── 4. honest summary ────────────────────────────────────────────────────────
# The banner used to print unconditionally, including when nothing was wired.
echo
if [ "$hook_done" = 1 ]; then
    cat <<'EOF'
Работает само: при старте каждой сессии печатается список активов, чьё
восстановление просрочено. Печатает харнесс, а не модель, — пропустить нельзя.
EOF
else
    cat <<'EOF'
ХУК НЕ УСТАНОВЛЕН. Автоматических проверок сейчас нет — только ручные команды
ниже. Пока хука нет, о просроченных проверках вам никто не напомнит.
EOF
fi
[ "$claude_done" = 1 ] || echo "Правила для ассистента не установлены — три проверки из шести действовать не будут."

cat <<'EOF'

Вручную:
  redfirst red "<что>" -- <кмд>    запустить и записать: проверка ПАДАЕТ
  redfirst green "<что>" -- <кмд>  запустить и записать переход в зелёное
  redfirst log                     журнал: что показано красным и что закрыто
  redfirst wired <Symbol>     в скольких файлах имя есть в коде; один — мёртвый
  redfirst samples <pattern>  число вместе с образцами, которые оно посчитало
  redfirst counter <term>     поиск того, чего якобы нет

Первым делом впишите свои активы в .redfirst/irreplaceable — пустой список
означает, что хук будет молчать, и молчать он будет зря.
EOF
