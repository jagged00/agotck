# AGOT Dragon Compatch – New Instance Continuation Guide

Use this file to continue AGOT dragon compatch work from a fresh Codex/agent session.

## 1) Prompt Template for the Next Agent

```text
Continue converting AGOT dragon content into the vanilla compatch layout under `AGOT Compatch/`.

Rules:
- Source AGOT files only from folders beginning with `ref `.
- Use non-`ref` folders as vanilla formatting references.
- Keep all output under `AGOT Compatch/` with CK3-correct directory structure.
- Work in small batches to avoid file/context limits.
- At the end of each batch: stop, summarize, and ask to continue after merge.
- Do not modify outside `AGOT Compatch/` and this handoff file unless asked.
```

## 2) Progress So Far

### Batch 1 (completed)
- Core dragon systems copied:
  - `common/traits`
  - `common/scripted_triggers`
  - `common/scripted_effects` (core)
  - `common/script_values` (core)
  - `common/scripted_modifiers`
  - `events/agot_events` (core: dragon/egg/taming)
  - `localization/english/agot` (core + taming/event/interactions subset)

### Batch 2 (completed)
- Added gameplay wiring files:
  - `common/character_interactions/*dragon*.txt`
  - `common/decisions/agot_decisions/*dragon*.txt`
  - `common/modifiers/00_agot_dragon_modifiers.txt`
  - `common/on_action/agot_on_actions/*dragon*`
  - `common/on_action/schemes/agot_dragon_bond_on_actions.txt`
- Added events/localization:
  - `events/agot_events/agot_dragon_{bond,combat,death,dreams,maintenance,personality}_events.txt`
  - `localization/english/agot/decisions/agot_decisions_dragons_l_english.yml`
  - `localization/english/agot/modifiers/agot_dragon_modifiers_l_english.yml`
  - matching event localization for bond/combat/debug/dreams/personality

### Batch 3 (completed)
- Added additional dragon event chains:
  - `events/agot_events/agot_choose_dragonpit_events.txt`
  - `events/agot_events/agot_dragon_pits_events.txt`
  - `events/agot_events/agot_dragon_siege_events.txt`
  - `events/agot_events/agot_dragon_slaying_events.txt`
  - `events/agot_events/agot_dragon_warfare_events.txt`
  - `events/agot_events/agot_dragonkeepers_events.txt`
  - `events/agot_events/agot_dragonstone_events.txt`
  - `events/agot_events/agot_dragon_designer_events.txt`
- Added matching event localization files for those chains under:
  - `localization/english/agot/event_localization/`

## 3) Next High-Value Targets (Remaining)

Prioritize missing dragon-related files from `ref ` into matching paths in `AGOT Compatch/`:

### Events still likely missing
- `events/agot_events/agot_dragon_canon_personality_events.txt`
- `events/agot_events/agot_dragon_debug_events.txt`
- `events/agot_filler/00_agot_dragon_filler_events.txt`
- `events/agot_travel_events/agot_dragon_travel_events.txt`
- `events/activities/agot_hatching_activity/agot_dragon_hatching_activity_events.txt`
- `events/activities/agot_hatching_activity/agot_hatching_dragonlore_events.txt`

### Common files still likely missing
- `common/scripted_effects/00_agot_dragon_*_effects.txt` (remaining subsets)
- `common/script_values/00_agot_dragon_*_values.txt` (remaining subsets)
- `common/scripted_guis/00_agot_dragons_scripted_gui.txt`
- `common/scripted_guis/00_agot_dragon_editor_scripted_gui.txt`
- `common/scripted_guis/00_agot_dragon_tree_scripted_gui.txt`
- `common/nicknames/00_agot_dragon_nicknames.txt`
- `common/activities/activity_types/agot_dragon_hatching.txt`
- `common/scripted_character_templates/00_agot_dragon_templates.txt`
- `common/casus_belli_types/00_agot_dragon_wars.txt`
- `common/game_concepts/00_agot_dragon_game_concepts.txt`

### Localization still likely missing (English)
- `localization/english/agot/gui/agot_dragon_tree_l_english.yml`
- `localization/english/agot/modifiers/*dragon*` (check for any additional files)
- `localization/english/agot/event_localization/filler_events/agot_filler_events_dragon_l_english.yml`
- `localization/english/agot/event_localization/activities/agot_dragon_hatching_l_english.yml`
- `localization/english/agot/event_localization/travel_events/agot_travel_events_dragon_l_english.yml`
- `localization/english/agot/names/agot_dragon_names_l_english.yml`
- `localization/english/agot/names/agot_baby_dragon_names_l_english.yml`
- `localization/english/agot/agot_nicknames_dragons_l_english.yml`

## 4) Fast Validation Commands

```bash
git status --short
find 'AGOT Compatch' -type f | wc -l
find 'AGOT Compatch' -type f | sort
```

```bash
# probable missing dragon/drac files
comm -23 \
  <(rg --files | rg '^ref ' | rg -i 'dragon|drac' | sed 's#^ref ##' | sort) \
  <(find 'AGOT Compatch' -type f | sed "s#^AGOT Compatch/##" | sort)
```

## 5) If the Agent Fails Mid-Batch

1. Keep partial files unless clearly broken.
2. Capture `git status --short` in the handoff prompt.
3. Ask next instance to finish only the current folder subset.
4. Split by folder order if needed:
   - `events/` first,
   - then matching `localization/english/agot/event_localization`,
   - then `common/scripted_guis` and GUI localization,
   - then remaining `common/*` data files.

## 6) Batch Size Rule

Keep each PR around **10–25 files** or one coherent system slice. End each batch with:
**“Continue next batch after merge?”**
