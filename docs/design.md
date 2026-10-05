# Implemented architecture

## Core

CSV with escaped quotes and multiline fields; JSONL error isolation; typed column mapping with required/default/trim/lower/enum/range/scale constraints; row filters; composite-key deduplication; unique-key joins; deterministic sorting; grouped count/sum/mean; field profiling; CSV export.

## Boundaries

Batch in memory. JSONL diagnostics preserve physical line numbers; transformation diagnostics use parsed row indices. Missing/null join keys and duplicate right keys are rejected. Arithmetic uses finite Double; decimal accounting and streaming are outside this release. Column order for CSV export must be explicit. The CSV reader is strict about quotes and column widths; malformed CSV rejects the batch.

## Integration

The core accepts semantic values and returns deterministic JSON-shaped reports. Host adapters handle files, network or processes; they invoke the compiled MoonBit engine. The CLI package declares `supported_targets = "js"`; other backends test the portable core.

## Validation evidence

Fixture cases are hand-checked assertions. Independent reference checks and integration scripts are runnable from a clean checkout. CI executes four core backends and host checks. Historical proposal targets are not release results.
