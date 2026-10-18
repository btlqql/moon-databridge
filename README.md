# Moon DataBridge

Tabular data pipelines, implemented in MoonBit with a JSON CLI and reusable library API.

- Repository: [https://github.com/btlqql/moon-databridge](https://github.com/btlqql/moon-databridge)
- Package: `btlqql/moon_databridge@0.3.0`
- License: Apache-2.0
- Release scope: **0.2.0 revised component release**. The broader competition proposal in `docs/proposal.md` is a reference design, not a claim that every planned capability is implemented.

## Implemented

CSV with escaped quotes and multiline fields; JSONL error isolation; typed column mapping with required/default/trim/lower/enum/range/scale constraints; row filters; composite-key deduplication; unique-key joins; deterministic sorting; grouped count/sum/mean; field profiling; CSV export.

## Build and run

Use MoonBit and Node.js 24. The core library supports JS, wasm, wasm-gc and native; the filesystem/HTTP/process CLI is JS only.

```sh
moon update
moon build --target js
moon run cmd/main --target js -- examples/scenario-1.json
node _build/js/debug/build/cmd/main/main.js examples/scenario-1.json
```

Pass `-` to read a UTF-8 JSON request from stdin. A single request must be at most 16 MiB. Successful requests print one JSON result; invalid requests exit nonzero. The host runner is a separate process and does not edit the input request file.

## Library use

```sh
moon add btlqql/moon_databridge@0.3.0
```

In the consumer's `moon.pkg`:

```moonbit
import {
  "btlqql/moon_databridge" @engine,
  "moonbitlang/core/json",
}
```

```moonbit
fn example(request : Json) -> Json raise {
  @engine.execute(request)
}
```

`execute(Json) -> Json raise` is the standard JSON boundary. `from_json`, `Value::to_json`, and `run(Value) -> Value raise` provide a typed semantic value interface. Object ordering is not significant; numeric values use finite Double. Public domain functions are listed in `pkg.generated.mbti`.

## Tests

```sh
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon test --target native  # requires a C compiler
moon build --target js
node scripts/check.mjs
python -B scripts/reference.py
```

There are 18 checked fixture cases in `tests/cases.json`, executed both in MoonBit white-box tests and through the actual Node CLI. Independent reference checks use Python's standard library or separately written algorithms. Fixtures are synthetic and are not presented as production adoption evidence. See [input and output examples](docs/usage.md) and [current boundaries](docs/boundaries.md).

## Current boundaries

Batch in memory. JSONL diagnostics preserve physical line numbers; transformation diagnostics use parsed row indices. Missing/null join keys and duplicate right keys are rejected. Arithmetic uses finite Double; decimal accounting and streaming are outside this release. Column order for CSV export must be explicit. The CSV reader is strict about quotes and column widths; malformed CSV rejects the batch.

See [source and dependency attribution](THIRD_PARTY.md). This release does not establish competition eligibility or organizer acceptance.


## Version 0.2.0 revision

Row reconciliation audits and rejection quality gates. Column schemas are validated before processing even empty inputs; grouping keys cannot overwrite aggregate fields.

当前处理方式为批次内存计算。严格 CSV 的结构错误会拒绝整个 CSV 批次；JSONL 解析与记录转换错误可隔离。没有流式执行、数据库写入、分布式调度或自动修复坏数据。字段画像对应聚合之前的数据。质量门槛没有替上层应用执行阻断动作。

Run the additional complete scenario:

```sh
moon run cmd/main --target js -- examples/scenario-4.json
```


## 2026-10-18 follow-up

新增 all、any、not 组合条件，严格检查组合结构和深度；空数据批次同样校验过滤配置。结果仍纳入现有行数守恒账目和拒绝率门槛，筛除数量可以核对。空 all 为真、空 any 为假，not 作用于单个条件。

组合筛选只组合已有叶条件，不支持任意脚本。排序及既有叶比较沿用当前值比较语义；它不是数据库查询优化器。

Repository release: 0.3.0; installable MoonCakes module: `btlqql/moon_databridge@0.3.0`. Earlier repository 1.0.0 labels are retained as history; the module uses the registry-compatible zero-major sequence.

Current source contains 20 MoonBit test declarations and 18 CLI fixtures (generated fixture tests are included in the declaration count). Run `python -B scripts/followup_reference.py` for independent follow-up oracles and `examples/followup-20261018.json` for the new scenario.
