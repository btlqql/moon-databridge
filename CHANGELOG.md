# Changelog

## 0.3.0 — 2026-10-18

Registry version: 0.3.0.

新增 all、any、not 组合条件，严格检查组合结构和深度；空数据批次同样校验过滤配置。结果仍纳入现有行数守恒账目和拒绝率门槛，筛除数量可以核对。空 all 为真、空 any 为假，not 作用于单个条件。

## 0.2.0 — 2026-10-16

Row reconciliation audits and rejection quality gates. Column schemas are validated before processing even empty inputs; grouping keys cannot overwrite aggregate fields.

Added regression fixtures and independent randomized checks for the revised behavior.

## 0.1.0 — 2026-10-05

Initial library, JSON CLI, fixtures and independent reference checks.
