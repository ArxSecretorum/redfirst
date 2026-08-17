# Настоящий репозиторий с историей: база без символа, рабочее дерево с ним.
if ! command -v git >/dev/null 2>&1; then
    echo "git не установлен — сравнивать нечем"
    exit 77
fi
git init -q . >/dev/null 2>&1 || { echo "git init не отработал"; exit 77; }
git config user.email t@example.com; git config user.name t
printf '{}\n' > package.json
printf 'export function Existing(){ return 1 }\n' > a.js
git add -A >/dev/null 2>&1
git -c commit.gpgsign=false commit -qm base >/dev/null 2>&1 || { echo "коммит не прошёл"; exit 77; }
# появилось имя, которого в базе не было, и оно используется дважды
printf 'export function BrandNewThing(){ return 2 }\n' > b.js
printf 'import { BrandNewThing } from "./b.js"\nBrandNewThing()\n' > c.js
