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
- For MS-DOS client files (`client/*.bas`, `client/*.bat`, and `client/*.mak`):
  - Keep content as plain ASCII only; do not add UTF-8 BOM or extended Unicode.
  - Use DOS `CRLF` line endings, not Unix `LF` line endings.
  - End each file with the DOS EOF marker `Ctrl+Z` (`0x1A`).
  - Avoid `CONST` and `COMMON SHARED`; prefer module-local `DIM SHARED` values
    and small accessor/subroutine bridges when sharing state is needed.
  - Avoid `ON ERROR GOTO` labels in BASIC modules because some QuickBasic IDE
    setups fail to resolve them reliably.
  - Keep code compatible with QuickBasic 4.5-era parsing and memory limits.
- Do not commit IDE state, local memory, Python bytecode, or DOS build outputs.
- Use Conventional Commits for commit messages.
  - Example: `feat(client): add serial prompt streaming`.
  - Example: `fix(proxy): handle empty serial frames`.
  - Example: `docs(readme): explain DOSBox setup`.
  - Example: `chore(gitignore): ignore QuickBasic build outputs`.
