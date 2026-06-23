# Taxonomy Revamp Migration Report

Generated on 2026-06-18.

## Summary

- Normalized source markdown files: 
- Copied complete/draft/review documents into docs/: 
- Planned stub mappings retained for later migration: 
- Target sections created: 20
- Relative links checked: 682
- Broken links tracked in _meta/link_validation_report.md: 324

## Migration Policy

Only high-value documents (complete, review, or draft) were copied into the new taxonomy during the initial revamp. The legacy `Enterprise Transformation/` tree was fully consolidated into `docs/` on 2026-06-18.

## Next Validation

Run:

    powershell -ExecutionPolicy Bypass -File tools/docs/scripts/revamp_taxonomy.ps1

Then run Python validation when Python/MkDocs is available:

    python tools/docs/scripts/validate_front_matter.py
    python tools/docs/scripts/validate_links.py
    mkdocs build --strict -f tools/docs/mkdocs.yml