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

## 2) What Already Exists

### Batch 1 (completed earlier)
Copied these categories into `AGOT Compatch/`:
- `common/traits`
- `common/scripted_triggers`
- `common/scripted_effects` (core subset)
- `common/script_values` (core subset)
- `common/scripted_modifiers`
- `events/agot_events` (core subset)
- `localization/english/agot` (core subset)

### Batch 2 (completed)
Copied core dragon gameplay systems:
- `common/character_interactions` (dragon, dragon bond, dragonkeeper)
- `common/decisions/agot_decisions` (dragon, dragonkeeper)
- `common/modifiers/00_agot_dragon_modifiers.txt`
- `common/on_action/agot_on_actions/*dragon*` (+ relations subfolder)
- `common/on_action/schemes/agot_dragon_bond_on_actions.txt`
- Added corresponding English localization for decisions/interactions/modifiers.

### Batch 3 (completed)
Copied major remaining dragon event + localization set:
- `events/agot_events/agot_choose_dragonpit_events.txt`
- `events/agot_events/agot_dragon_pits_events.txt`
- `events/agot_events/agot_dragon_siege_events.txt`
- `events/agot_events/agot_dragon_slaying_events.txt`
- `events/agot_events/agot_dragon_warfare_events.txt`
- `events/agot_events/agot_dragonkeepers_events.txt`
- `events/agot_events/agot_dragonstone_events.txt`
- Matching English event localization files for all of the above.

### Batch 4 (completed in this continuation)
Copied additional dragon event systems + localization:
- `events/agot_events/agot_dragon_canon_personality_events.txt`
- `events/agot_events/agot_dragon_debug_events.txt`
- `events/agot_events/agot_dragon_designer_events.txt`
- `events/agot_decisions_events/agot_dragon_tree_events.txt`
- `events/agot_filler/00_agot_dragon_filler_events.txt`
- `events/agot_travel_events/agot_dragon_travel_events.txt`
- `localization/english/agot/event_localization/agot_dragon_designer_events_l_english.yml`
- `localization/english/agot/event_localization/filler_events/agot_filler_events_dragon_l_english.yml`
- `localization/english/agot/event_localization/travel_events/agot_travel_events_dragon_l_english.yml`
- `localization/english/agot/gui/agot_dragon_tree_l_english.yml`

### Batch 5 (completed in this continuation)
Copied dragon common-systems support files:
- `common/script_values/00_agot_dragon_combat_values.txt`
- `common/script_values/00_agot_dragon_dragon_size_values.txt`
- `common/script_values/00_agot_dragon_gene_values.txt`
- `common/script_values/00_agot_dragon_skill_values.txt`
- `common/script_values/00_agot_dragon_tree_values.txt`
- `common/scripted_character_templates/00_agot_dragon_templates.txt`
- `common/scripted_effects/00_agot_artifact_dragon_skulls_effects.txt`
- `common/scripted_effects/00_agot_dragon_animation_effects.txt`
- `common/scripted_effects/00_agot_dragon_appearance_effects.txt`
- `common/scripted_effects/00_agot_dragon_canon_dragons_effects.txt`
- `common/scripted_effects/00_agot_dragon_combat_effects.txt`
- `common/scripted_effects/00_agot_dragon_combat_moves_effects.txt`
- `common/scripted_effects/00_agot_dragon_congenital_traits_effects.txt`
- `common/scripted_effects/00_agot_dragon_slay_effects.txt`
- `common/scripted_effects/00_agot_dragon_tree_effects.txt`
- `common/scripted_effects/00_agot_dragon_warfare_effects.txt`
- `common/scripted_effects/00_agot_dragonpit_effects.txt`

### Batch 6 (completed in this continuation)
Copied dragon supporting content for artifacts/genes/gui/scenarios:
- `common/artifacts/types/00_agot_dragonegg_type.txt`
- `common/artifacts/visuals/00_agot_dragon_egg_visuals.txt`
- `common/casus_belli_types/00_agot_dragon_wars.txt`
- `common/customizable_localization/00_agot_dragon_custom_loc.txt`
- `common/customizable_localization/99_fr_agot_dragons_loc.txt`
- `common/ethnicities/03_agot_dragon.txt`
- `common/genes/dragon_accessory_genes.txt`
- `common/genes/dragon_morph_genes.txt`
- `common/scripted_effects/00_agot_scenario_dance_of_the_dragons_effects.txt`
- `common/scripted_effects/00_agot_scenario_dragons_effects.txt`
- `common/scripted_guis/00_agot_dragon_editor_scripted_gui.txt`
- `common/scripted_guis/00_agot_dragon_tree_scripted_gui.txt`
- `common/scripted_guis/00_agot_dragons_scripted_gui.txt`

## 3) High-Value Next Batch Targets

Prioritize these still-missing dragon files from `ref ` into matching paths under `AGOT Compatch/`:

### Common systems
- `gui/custom_gui/agot_dragon_character_window.gui`
- `gui/custom_gui/agot_dragon_siege.gui`
- `gui/custom_gui/agot_dragon_tree.gui`
- `gui/event_window_widgets/agot_dragon_customizer.gui`
- `gui/event_window_widgets/agot_dragon_egg_selection.gui`
- `gui/event_window_widgets/agot_dragon_tree_selection.gui`
- `gui/event_window_widgets/agot_dragonpit_selection_three_options.gui`
- `gui/event_windows/agot_dragon_character_event.gui`
- `gui/event_windows/agot_dragon_duel_event.gui`
- `gui/shared/agot_dragon_event_window.gui`
- `gui/shared/agot_dragon_portraits.gui`

### Activities + gameplay support
- `common/activities/activity_types/agot_dragon_hatching.txt`
- `events/activities/agot_hatching_activity/agot_dragon_hatching_activity_events.txt`
- `events/activities/agot_hatching_activity/agot_hatching_dragonlore_events.txt`
- `localization/english/agot/event_localization/activities/agot_dragon_hatching_l_english.yml`

### Remaining likely dragon-adjacent content
- `common/game_concepts/00_agot_dragon_game_concepts.txt`
- `common/nicknames/00_agot_dragon_nicknames.txt`
- `localization/english/agot/agot_nicknames_dragons_l_english.yml`

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
