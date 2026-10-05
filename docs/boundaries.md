# Version 0.1.0 boundaries

Batch in memory. JSONL diagnostics preserve physical line numbers; transformation diagnostics use parsed row indices. Missing/null join keys and duplicate right keys are rejected. Arithmetic uses finite Double; decimal accounting and streaming are outside this release. Column order for CSV export must be explicit. The CSV reader is strict about quotes and column widths; malformed CSV rejects the batch.
