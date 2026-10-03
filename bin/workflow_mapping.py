JIRA_TO_PHASE = {
    "Formal Verification": "formal_verification",
}

def phase_from_jira(status: str) -> str:
    try:
        return JIRA_TO_PHASE[status]
    except KeyError:
        raise ValueError(f"Unmapped Jira status: {status!r}") from None