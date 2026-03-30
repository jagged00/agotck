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

