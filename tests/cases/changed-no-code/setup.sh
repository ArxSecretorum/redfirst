# Изменения есть, но только в документации.
if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed - nothing to compare against"
    exit 77
fi
git init -q . >/dev/null 2>&1 || { echo "git init did not work"; exit 77; }
git config user.email t@example.com; git config user.name t
printf '{}\n' > package.json
printf 'export function Existing(){ return 1 }\n' > a.js
printf '# заметки\n' > NOTES.md
git add -A >/dev/null 2>&1
git -c commit.gpgsign=false commit -qm base >/dev/null 2>&1 || { echo "the commit did not go through"; exit 77; }
printf '# заметки\nещё строка\n' > NOTES.md
