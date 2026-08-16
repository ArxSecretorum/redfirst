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
TARGET="${1:-$PWD}"

[ -d "$TARGET" ] || { echo "installer: no such directory: $TARGET" >&2; exit 2; }
[ "$TARGET" = "$SELF_DIR" ] && { echo "installer: point me at your project, not at redfirst itself" >&2; exit 2; }

SETTINGS="$TARGET/.claude/settings.json"
HOOK="$SELF_DIR/bin/redfirst due --quiet"

echo "redfirst → $TARGET"
echo

# 1. Config
( cd "$TARGET" && REDFIRST_DIR=.redfirst "$SELF_DIR/bin/redfirst" init )

# 2. Hook
echo
if [ -f "$SETTINGS" ]; then
    if grep -q "redfirst" "$SETTINGS" 2>/dev/null; then
        echo "Хук уже прописан в $SETTINGS — не трогаю."
    else
        cat <<EOF

В $SETTINGS уже есть настройки, поэтому НЕ правлю его автоматически:
слить JSON вслепую — верный способ сломать вашу конфигурацию.

Добавьте туда хук старта сессии вручную, команда такая:

  $HOOK

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
          { "type": "command", "command": "$HOOK" }
        ]
      }
    ]
  }
}
EOF
    echo "Создан $SETTINGS с хуком старта сессии."
fi

# 3. Instructions for the assistant
if [ -f "$TARGET/CLAUDE.md" ]; then
    if grep -q "redfirst" "$TARGET/CLAUDE.md" 2>/dev/null; then
        echo "CLAUDE.md уже содержит правила redfirst."
    else
        echo
        echo "CLAUDE.md существует. Допишите в него содержимое:"
        echo "  $SELF_DIR/templates/CLAUDE.redfirst.md"
    fi
else
    cp "$SELF_DIR/templates/CLAUDE.redfirst.md" "$TARGET/CLAUDE.md"
    echo "Создан $TARGET/CLAUDE.md с правилами для ассистента."
fi

cat <<'EOF'

Готово. Что теперь происходит само:

  При старте каждой сессии печатается список активов, чьё восстановление
  просрочено. Пропустить это нельзя — печатает харнесс, а не модель.

Что можно вызывать руками:

  redfirst wired <Symbol>     ноль ссылок = мёртвый код
  redfirst samples <pattern>  число вместе с образцами, которые оно посчитало
  redfirst counter <term>     поиск того, чего якобы нет

Первым делом — впишите свои активы в .redfirst/irreplaceable.
Пустой список означает, что хук будет молчать, и молчать он будет зря.
EOF
