# Version0.4.0 boundaries

批次内存计算，纯MoonBit核心＋JS JSON CLI，不提供流式执行、数据库写入或分布式调度。CLI单请求16MiB；Double算术不等于精确十进制财务计算。CSV结构错误拒绝整批，JSONL解析与单行转换错误可隔离；拒绝原因和行数守恒账目均输出。

0.4.0严格校验未知请求／列／叶条件／join／group配置，空输入同样拒绝错误选项；这是兼容性变化。deduplicate、export字段列表必须非空、无空名称和重复项；空group键列表允许全局聚合。join的inner必须为boolean。字符串比较采用Unicode标量字典序；混合类型仍按规范文本确定顺序，不提供SQL式隐式数值转换。

min/max/enum在scale之前检查；scale之后若integer列出现非整数，隔离该记录。右连接键缺失／null或重复会报错，左键缺失／null视为未匹配：left join保留、inner join丢弃。画像在聚合前计算。质量门槛仅返回结果，上层应用自行决定阻断。当前仍有旧公共接口的编译器弃用提醒。

真实公开提交、测试和发布分别核验；这些不代表比赛审核已经通过，也不证明不存在其他表格处理生态重叠。详见review-20261022.md。
