# То же в Kotlin: """ … """ на несколько строк. Правда: Ghosty мёртв.
mkdir -p src/main/kotlin
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf 'object Ghosty {\n    fun go() = 1\n}\n' > src/main/kotlin/Ghosty.kt
cat > src/main/kotlin/Notes.kt <<'KT'
object Notes {
    val text = """
        Ghosty was removed in v3.
        Do not call Ghosty any more.
    """
}
KT
