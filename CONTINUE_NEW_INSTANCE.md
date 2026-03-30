# AGOT Dragon Compatch – New Instance Continuation Guide

Use this when you need to continue the dragon compatch work from a fresh Codex/agent session.

## 1) Prompt Template for the Next Agent

Copy/paste this as the first message in a new instance:

```text
Continue converting AGOT dragon content into the vanilla compatch layout under `AGOT Compatch/`.

Rules:
- Source of truth for AGOT files: folders starting with `ref `.
- Use non-`ref` folders as formatting references for vanilla style.
- Keep all output inside `AGOT Compatch/` with proper CK3 directory structure.
- Do work in small batches to avoid file limits.
- At the end of each batch: stop, summarize, and ask whether to continue after merge.
- Do not modify files outside `AGOT Compatch/` unless explicitly asked.

Start with the next missing dragon batch (decisions, interactions, modifiers, on_actions, and remaining dragon events/localization) and preserve original script syntax.
```

## 2) What Already Exists (Batch 1)

Current batch already copied these categories into `AGOT Compatch/`:
- `common/traits`
- `common/scripted_triggers`
- `common/scripted_effects` (core subset)
- `common/script_values` (core subset)
- `common/scripted_modifiers`
- `events/agot_events` (core subset)
- `localization/english/agot` (core subset)

## 3) High-Value Next Batch Targets

Prioritize these missing dragon files from `ref ` into matching paths under `AGOT Compatch/`:

### Common gameplay
- `common/character_interactions/00_agot_dragon_interactions.txt`
- `common/character_interactions/00_agot_dragon_bond_interactions.txt`
- `common/character_interactions/00_agot_dragonkeeper_interactions.txt`
- `common/decisions/agot_decisions/00_agot_dragon_decisions.txt`
- `common/decisions/agot_decisions/00_agot_dragonkeeper_decisions.txt`
- `common/modifiers/00_agot_dragon_modifiers.txt`
- `common/on_action/agot_on_actions/agot_dragon_cradling_on_action.txt`
- `common/on_action/agot_on_actions/agot_dragon_travel_on_actions.txt`
- `common/on_action/agot_on_actions/relations/agot_dragon_relation_on_actions.txt`
- `common/on_action/agot_on_actions/relations/agot_story_dragon_relation_on_actions.txt`
- `common/on_action/schemes/agot_dragon_bond_on_actions.txt`

### Remaining event files
- `events/agot_events/agot_dragon_bond_events.txt`
- `events/agot_events/agot_dragon_combat_events.txt`
- `events/agot_events/agot_dragon_death_events.txt`
- `events/agot_events/agot_dragon_dreams_events.txt`
- `events/agot_events/agot_dragon_maintenance_events.txt`
- `events/agot_events/agot_dragon_personality_events.txt`
- `events/agot_events/agot_dragon_pits_events.txt`
- `events/agot_events/agot_dragon_siege_events.txt`
- `events/agot_events/agot_dragon_slaying_events.txt`
- `events/agot_events/agot_dragon_warfare_events.txt`
- `events/agot_events/agot_choose_dragonpit_events.txt`
- `events/agot_events/agot_dragonkeepers_events.txt`
- `events/agot_events/agot_dragonstone_events.txt`

### English localization for those systems
- `localization/english/agot/decisions/agot_decisions_dragons_l_english.yml`
- `localization/english/agot/modifiers/agot_dragon_modifiers_l_english.yml`
- `localization/english/agot/interactions/agot_dragon_interactions_l_english.yml` (already present; only update if stale)
- `localization/english/agot/event_localization/*dragon*.yml` (remaining missing files)

## 4) Fast Validation Commands

Run these before committing:

```bash
git status --short
find 'AGOT Compatch' -type f | wc -l
find 'AGOT Compatch' -type f | sort
```

Optional quick sanity checks:

```bash
# find probable missing dragon files not yet copied
comm -23 \
  <(rg --files | rg '^ref ' | rg -i 'dragon|drac' | sed 's#^ref ##' | sort) \
  <(find 'AGOT Compatch' -type f | sed "s#^AGOT Compatch/##" | sort)
```

## 5) If the Agent Fails Mid-Batch

1. Keep partial files; do **not** delete work unless broken.
2. `git status --short` and copy output to the next prompt.
3. Ask next agent to continue from unstaged state and only finish current target subset.
4. If context/token issues recur, split by one folder at a time in this order:
   - `common/character_interactions`
   - `common/decisions`
   - `common/on_action`
   - `events/agot_events`
   - `localization/english/agot/event_localization`

## 6) Batch Size Rule

To reduce review risk, keep each PR to roughly **10–25 files** or one coherent system slice. End every batch with: “Continue next batch after merge?”
