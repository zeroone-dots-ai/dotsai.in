# docs/ — Project Documentation

Every significant change to this project gets documented here.

## Structure

```
docs/
├── architecture/      ← How each system is built
│   ├── GALAXY.md      ← Hero galaxy: stars, physics, D.O.T.S planet
│   ├── CURSOR.md      ← Quantum dot cursor system
│   └── SPLASH.md      ← 6-variant splash animation
│
├── design/            ← Visual language and brand rules
│   └── VISUAL-LANGUAGE.md
│
├── content/           ← All copy and text content
│   └── COPY.md
│
├── deploy/            ← How deployment works
│   └── PIPELINE.md
│
└── sessions/          ← What happened in each work session
    └── 2026-03-26-LAUNCH.md
```

## Doc Update Rules (Agent + Human)

> **After EVERY session where something changes, a doc MUST be updated or created.**

| Change type | What to update |
|-------------|----------------|
| New feature / component | Create `docs/architecture/COMPONENT-NAME.md` |
| Visual/design change | Update `docs/design/VISUAL-LANGUAGE.md` |
| Copy change | Update `docs/content/COPY.md` |
| Deploy/infra change | Update `docs/deploy/PIPELINE.md` |
| Major session | Create `docs/sessions/YYYY-MM-DD-TOPIC.md` |
| Bug fix | Add to relevant architecture doc |

### Session doc format
File: `docs/sessions/YYYY-MM-DD-DESCRIPTION.md`
```markdown
# Session: Title — YYYY-MM-DD

## What Was Done
- Bullet list of changes

## Key Decisions
- Why we chose X over Y

## Files Changed
- list of files modified

## Known Issues / Follow-ups
- anything left to do
```
