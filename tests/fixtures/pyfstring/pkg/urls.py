from pkg.consts import DOC_ROOT


def doc_url(page: str) -> str:
    return f"https://example.test/{DOC_ROOT}/{page}.html"


def legend() -> str:
    return "GHOST_KEY was dropped in 0.3"
