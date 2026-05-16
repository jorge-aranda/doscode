# AGENTS.md

This repository contains DOSCODE, a retro DOS AI coding agent. For project
usage, architecture, and build details, read `README.md` first.

## Rules for agents

- Write source code and documentation in English.
- Keep the DOS client authentic: `SCREEN 0`, text mode, CP437/ANSI style, low
  memory use, and no modern network dependencies.
- Keep the serial protocol plain text; do not add heavy JSON to the DOS side.
- `RUN` actions must ask for confirmation before executing commands.
- Prefer small, modular files that can be understood on vintage hardware.
- Do not commit IDE state, local memory, Python bytecode, or DOS build outputs.
- Use Conventional Commits for commit messages.
  - Example: `feat(client): add serial prompt streaming`.
  - Example: `fix(proxy): handle empty serial frames`.
  - Example: `docs(readme): explain DOSBox setup`.
  - Example: `chore(gitignore): ignore QuickBasic build outputs`.
