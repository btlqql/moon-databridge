# Moon DataBridge——面向数据导入、质量控制与可核对转换流水线的 MoonBit 组件

项目账号：btlqql  
主要语言：MoonBit；开源许可：Apache-2.0  
仓库：[https://github.com/btlqql/moon-databridge](https://github.com/btlqql/moon-databridge)  
修订版本：0.2.0；日期：2026-10-16  
公开包：[moon_databridge@0.2.0](https://mooncakes.io/docs/btlqql/moon_databridge@0.2.0)

> 本稿供个人参考。正文按本次实际实现说明功能和边界；公开提交、CI 及包发布状态另附核对记录。修改材料不代表主办方已重新审核通过。

## 一、项目简介

DataBridge 接收 CSV、JSONL 或 JSON 记录，执行字段映射、类型转换、约束校验、筛选、去重、关联与聚合，输出结果、拒绝记录、字段画像和处理计数。当前修订增加逐阶段行数核对及拒绝率质量门槛，使使用者能够解释原始数据为何减少、哪些记录被拒绝，以及本次数据是否满足调用方设定的质量条件。

## 二、使用问题与组件职责

在数据迁移、目录整理和批次导入中，仅得到一份转换后的文件，不能说明坏记录、筛选、去重和关联分别影响了多少输入。DataBridge 把数据结果和处理账目同时交付，让调用方复核数据去向。业务方定义字段与门槛，核心负责转换和报告；是否写库或阻止发布由上层程序决定。

## 三、核心机制与实现

### 输入、转换与错误边界

CSV 处理引号转义、字段内逗号和跨行内容；表头重复、空表头和列宽错误作为批次结构问题拒绝。JSONL 对非空物理行逐行解析，坏行进入拒绝报告。字段转换支持字符串、数字、整数和布尔值，配合必填、默认值、裁剪、小写、枚举、数值范围及缩放处理。数值使用有限 Double，不提供十进制定点精度保证。

本次将列规则配置提前检查：即使输入为空，也拒绝未知类型、重复目标列、非布尔开关和反向范围。数据错误仍按记录隔离。分组键不得与输出保留字段 count、sum、mean 冲突，避免聚合覆盖原分组身份。

### 流水线计数

顺序为输入解析、逐行转换、筛选、去重、唯一右键关联、排序、画像、分组及导出。新增 audit 包含 input、rejected、accepted、filtered、deduplicated、join_discarded、before_group、returned 和 conserved。

核心校验两条关系：`input = accepted + rejected`；`input = rejected + filtered + deduplicated + join_discarded + before_group`。分组会改变行数，所以 returned 单列，不能直接当成输入守恒式的保留记录数。当前关联右键必须唯一，关联不会放大行数；join_discarded 对应内关联未匹配而丢弃的左侧记录。

### 质量门槛

quality_gate 支持 max_rejected 与 max_rejection_fraction，分别设置拒绝条数和拒绝比例上限。等于上限视为通过，空输入的拒绝比例约定为 0。门槛配置错误使请求失败，未满足门槛则在正常报告中返回 passed=false 与 violations；调用方需要检查报告，不能仅依据进程退出码判断质量是否合格。门槛只针对解析和转换拒绝，业务筛选掉的记录不计为坏记录。

## 四、完整案例

### 案例一：多阶段导入核对

输入五条订单行，其中一条数值非法。转换后保留四条，按数值条件筛掉一条，按 ID 去掉一条重复，再用内关联去掉一条未匹配记录，最终剩余一条；全局聚合得到 sum=2。audit 给出 input=5、rejected=1、filtered=1、deduplicated=1、join_discarded=1、before_group=1，守恒检查通过。若门槛为不允许拒绝，报告明确标记未通过。

### 案例二：JSONL 批次质量判断

三条非空 JSONL 输入中两条有效、一条格式错误。报告原始条数 3、拒绝条数 1；max_rejected=1、max_rejection_fraction=0.5 时通过。坏行不会凭空从原始输入计数中消失。

### 案例三：空批次及全坏批次

空输入返回零比例和一致的零计数，但非法字段配置仍被拒绝。单条坏记录的批次返回空结果、拒绝比例 1，并按门槛失败；报告保留可核对的账目，不把空结果解释为导入成功。

## 五、工程结构与可复核验证

领域计算位于 MoonBit 核心，标准 JSON 通过 execute 转换为语义值并调用 run。cmd/main 提供 JS CLI；核心可面向 JS、wasm、wasm-gc、native 测试，宿主脚本单独承担文件读取与参考核对。数据来自合成固定样本和确定性随机数据，没有声明真实生产用户或商业部署。

当前包含 16 项 MoonBit 测试，以及通过真实 Node CLI 执行的 14 组 JSON 夹具。独立 Python 检查用标准库 csv 验证 80 条含引号、中文与跨行记录的往返；新增 20 组随机流水线，对拒绝、筛选、去重、内关联计数及质量门槛逐项核对。 新案例输入见 examples/scenario-4.json；完整断言位于 tests/cases.json 和新增回归测试文件。

复核命令：

```sh
moon update
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon test --target native
moon build --target js
node scripts/check.mjs
python -B scripts/reference.py
moon run cmd/main --target js -- examples/scenario-4.json
```

native 需要 C 编译器；实际执行后端、结果及对应版本以交付核对记录和公开 CI 为准，不能将“提供测试命令”当成“测试已经通过”。

## 六、针对初审反馈的工程修订

所提供通知指出：GitHub 仓库自 2026 年 9 月 1 日后的提交不足 10 次。修订前公开 main 分支核查为 5 次。本次围绕输入或状态错误修复、回归测试、新增领域能力、独立对照用例和版本文档逐步提交，使用真实当日时间，保留原有历史。

开发记录可在 [公开 main 历史](https://github.com/btlqql/moon-databridge/commits/main/) 核对；最终提交数量、日期及哈希见配套提交核对表。本次没有创建空提交、倒填日期或将既有成果重写成虚假历史。提交数达到通知所述数量只解决该项可核对条件，不等同于项目规模、独立价值或最终验收已经获认可。

## 七、来源、复用与当前边界

领域实现和本次新增机制随仓库开源。MoonBit 标准库、Node 内置模块及 Python 标准库分别用于运行、宿主操作或独立核对；来源说明见 THIRD_PARTY.md。共享 JSON/CLI 脚手架按基础设施说明，不将其当成不同项目各自独有的领域创新。

当前处理方式为批次内存计算。严格 CSV 的结构错误会拒绝整个 CSV 批次；JSONL 解析与记录转换错误可隔离。没有流式执行、数据库写入、分布式调度或自动修复坏数据。字段画像对应聚合之前的数据。质量门槛没有替上层应用执行阻断动作。

本稿撤去旧参考方案中尚未完成的高级能力、生产规模和性能目标。当前功能、测试与开发记录可以实际复核；项目仍是持续完善的组件，不能把原先 4,000–8,000 行内部目标写成已经交付的代码量。
