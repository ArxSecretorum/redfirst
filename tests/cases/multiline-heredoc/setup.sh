# То же в shell: heredoc. Правда: deploy мёртв — объявление плюс две строки
# текста внутри heredoc.
mkdir -p src
printf 'deploy() { echo 1; }\n' > src/lib.sh
cat > src/doc.sh <<'SHX'
usage() {
cat <<TXT
deploy is no longer available
use the new command instead of deploy
TXT
}
SHX
