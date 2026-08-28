# Отчёт из подкаталога неотличим от отчёта по всему проекту: те же слова,
# меньшее дерево. Инструмент обязан назвать корень репозитория, если он выше.
if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed - the repository-root warning cannot be checked"
    exit 77
fi
mkdir -p sub
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf 'object Helper {\n    fun assist(): Int = 1\n}\n' > sub/Helper.kt
printf 'class Live {\n    fun run() = Helper.assist()\n}\n' > sub/Live.kt
git init -q . >/dev/null 2>&1 || { echo "git init did not work"; exit 77; }
