# CLAUDE.md

Rules for this repository are central: https://github.com/KumaaGroup/central-ai. The SessionStart hook
in `.claude/settings.json` syncs them into the gitignored `.claude-central/` directory, injects the
general rules and this repo's files into the session, and links path-scoped rules under
`.claude/rules/_central/`. If that sync fails, edits are blocked until it is fixed.

Do not add rules here. Propose changes in central-ai.
