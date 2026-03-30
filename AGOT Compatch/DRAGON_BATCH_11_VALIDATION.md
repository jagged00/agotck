# AGOT Dragon Compatch – Batch 11 Validation (English-only)

Date: 2026-03-30

## Scope
Validation-only batch, continuing the English-only dragon migration rule.

## Commands run

```bash
git status --short
find 'AGOT Compatch' -type f | wc -l
comm -23 \
  <(rg --files | rg '^ref ' | rg -i 'dragon|drac' | sed 's#^ref ##' | sort) \
  <(find 'AGOT Compatch' -type f | sed 's#^AGOT Compatch/##' | sort)
```

## Result summary

- Total files currently in `AGOT Compatch/`: **143**.
- No missing **English** dragon files were found by the `dragon|drac` diff query.
- Remaining unmatched paths are non-English localization only (French and Simplified Chinese), which remain intentionally deferred by the current rule.

## Deferred (non-English only)

Examples from the unmatched output:

- `localization/replace/french/agot/...`
- `localization/replace/simp_chinese/agot/...`
- `localization/simp_chinese/agot/...`


## Final sweep update (2026-03-30)

Additional compatibility validation after trait/language/culture fallback work:

```bash
git status --short
find 'AGOT Compatch' -type f | wc -l
comm -23 \
  <(rg --files | rg '^ref ' | rg -i 'dragon|drac' | sed 's#^ref ##' | sort) \
  <(find 'AGOT Compatch' -type f | sed 's#^AGOT Compatch/##' | sort)
rg -n "knows_language = language_agot_valyrian" 'AGOT Compatch/events'
rg -n "title:c_dragonstone\\s*=|title:c_dragonstone\\.holder\\s*=" 'AGOT Compatch/common/character_interactions/00_agot_dragon_bond_interactions.txt'
rg -n "has_trait = pure_blooded" 'AGOT Compatch/common' 'AGOT Compatch/events'
```

Results:

- `AGOT Compatch` file count is now **149** (increased due compat culture/language/heritage + localization files).
- English dragon migration remains complete for the `dragon|drac` source-vs-compatch query.
- Remaining source-vs-compatch misses are still non-English localization only (French/Simplified Chinese), deferred by scope.
- Direct event usage was migrated off `knows_language = language_agot_valyrian` checks to scripted trigger usage.
- Dragonstone checks in `visit_dragonpit_with_child_interaction` were switched to optional (`?=`) lookups.
- No direct `has_trait = pure_blooded` references remain in `AGOT Compatch/common` or `AGOT Compatch/events`.
