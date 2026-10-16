# OSC 1.0 核心库配置与可执行协议对照

## 1. 唯一目标版本与声明范围

MoonOSC 0.2.0 的规范基线固定为 **Open Sound Control 1.0，2002-03-26**：
https://opensoundcontrol.stanford.edu/spec-1_0.html 。不以“OSC 1.0/1.1”混称目标，
不声明 OSC 1.1、所有可选扩展或完整网络服务器符合性。

严格入口是 `encode_osc10`、`decode_osc10`、`plan_osc10` 和 `Osc10Scheduler`。
本配置覆盖 1.0 必需 wire 类型 i/f/s/b、完整分段模式匹配规则、全匹配方法分发计划、
时间关系校验以及 bundle 直接消息的不可拆批次。配置内有效且未超资源限额的输入不因
“模式子集”而被拒绝。执行层仍须完成下面明确列出的宿主责任；不能只调用解码器就声称
已经实现服务器的分发、计时或原子执行语义。

`encode` / `decode` 是兼容的通用 wire 工具，允许显式可选类型，**不检查**模式语法和
父子时间关系。`flatten` / `Scheduler` 是按消息工作流，**不是本配置的原子调度入口**。

## 2. 必需语义逐项映射

下表测试名均可在仓库中检索。运行 `moon test --deny-warn --target wasm-gc`；
CI 另外实际运行 wasm、js、native。`moon run examples/conformance` 给出综合可执行案例。

| 必需语义 | 实现与确定行为 | 可复现证据 |
| --- | --- | --- |
| int32 大端补码、float32 IEEE 位模式 | Reader/Writer；I32/F32 保留原始位，不隐式转型 | `OSC10 core golden wire and exact required tags`；arguments_test.mbt |
| 非 NUL ASCII 字符串、终止符、4 字节对齐零填充 | string 读写；Text 允许规范中的非 NUL ASCII，包括控制字符；地址/方法另有命名限制 | reader_wbtest.mbt、writer_wbtest.mbt；`OSC10 rejects malformed wire rather than guessing legacy tags` |
| blob 大端 int32 长度、任意字节与零填充 | Blob；拒绝负数、越界、非零 padding | decode_test.mbt；同上 malformed wire 测试 |
| 逗号开头类型串、参数次序与空参数 | 类型串必须明确存在；空参数为逗号加 padding，不做历史无类型猜测 | core golden wire；malformed wire 测试 |
| message 地址以 / 起始；bundle #bundle、64 位 timetag、长度界定子包、递归嵌套 | 严格入口先做 wire/总量/深度校验，再做 profile 校验；空 bundle 合法 | packet_test.mbt；strict nested time、malformed wire 测试 |
| 相同段数、整段匹配、? 单字符、* 零或多字符；均不跨 / | compile_pattern + bounded DP matcher | `OSC10 every normative wildcard form and literal brace alternatives`；matcher_test.mbt |
| [] 字符集合、ASCII 范围、首位 ! 取反、非首位 ! 字面值、末尾 - 字面值、集合内 [ 字面值 | parse_class；不是正则表达式 | 同上 wildcard 测试 |
| {foo,bar} 字面字符串备选项，可与其他模式组合 | parse_choices；包含空备选项；备选项内部不递归解释模式 | 同上 wildcard 测试；pattern_test.mbt |
| 每个匹配方法收到相同参数；无匹配不调用；匹配方法内部次序未规定 | Router::resolve / Dispatcher::plan 返回所有匹配 id；调用方给每个 id 传原 message.arguments | `OSC10 required dispatch reaches every matching method with same arguments`；examples/conformance |
| 单消息立即；raw timetag=1 立即；过去/当前到期；未来保留 | plan_osc10 把单消息/根立即 bundle 解析到传入 now；poll 只返回 due<=now，晚到不自动丢弃 | strict nested time、batch polling 测试 |
| 内层 bundle raw timetag >= 外层 | 严格比较 64 位 wire 值；未来父 bundle 中的立即子 bundle 也拒绝，不偷偷改时间 | `OSC10 strict nested time and pattern validation is not deferred to callbacks` |
| 同 bundle 直接消息按 wire 顺序连续执行，嵌套 bundle 不属于该原子组 | plan_osc10 收集直接消息为一个 batch；Osc10Scheduler::poll 的上限按 batch，不会拆消息 | `OSC10 bundles preserve direct-message atomic groups across nested bundles`；examples/media |
| 整包无效不可部分入队；顺序确定、取消整批 | enqueue 先完整验证和快照，再检查容量/票号，失败不改队列 | batch admission rollback、whole tree limits、independent sorted ticket model 测试 |

## 3. 三个完整案例与精确结果

### A. 必需 wire 类型与拒绝行为

`Message("/x", [I32(-1), F32(0x3f000000), Text("ok"), Blob(01 02)])`
严格编码结果为：

```text
2f7800002c69667362000000ffffffff3f0000006f6b00000000000201020000
```

严格解码恢复相同参数顺序和 float32 位模式。`/x` 后没有逗号类型串、负 blob 长度、
非零 padding、截断子包、未知 z 类型均报错。已知可选 `Rgba` 在通用入口往返，
但严格入口明确报错，不转为 int32。对应 golden wire、optional tags、malformed wire 三组测试。

### B. 不是“模式子集”的分段 fanout

注册 `/synth/lead1/gain`、`/synth/bass2/gain`、`/synth/bass4/gain`，发送
`/synth/{lead,bass}[1-3]/gain` 与 F32(0.5)，结果仅前两个 method 被选中，二者使用同一参数。
另外可执行断言覆盖 `?`、`*`、集合/范围、首位取反、非首位 !、末尾 -、空字符串备选项、
组合模式；`/a/*` 不匹配 `/a/x/y`。每种模式都由测试验证，不以列举少数样例代替实现。

### C. 未来时间、嵌套与不可拆批次

设 `later=now+1秒`，父 bundle 在 later 含 `[first, nested(later,[inside]), last]`。
入队得到两张票：第一批 `[first,last]`，第二批 `[inside]`。poll(now) 为空；
poll(later,max_batches=1) **同时**取出 first 和 last；下一次取出 inside。
同一时间不同组按票号稳定处理，是库的确定性选择，不是标准强制的跨组顺序。
若 nested 时间改为 now 或 raw=1，严格入口在入队前报错，队列和票号不变。

## 4. 可选扩展与兼容工具（不混入必需承诺）

OSC 1.0 自身的可选类型表包含 `h t d S c r m T F N I [ ]`。
通用 codec 支持这些类型，保留整数和 IEEE 位，并提供数组；它们不是本核心配置的
必需类型，也不能据此宣称实现 OSC 1.1。严格入口拒绝全部这些可选类型。
JSON、hex、summary、size-prefix/SLIP 是独立便利工具，不改变规范基线。
`Dispatcher` 的可选 Signature/类型契约是应用层过滤；要执行基础协议 fanout，应不设
契约或设与消息一致的契约，不能以契约错误丢弃必需的匹配方法。

旧 `flatten` 把 nested immediate 解释为继承父时间，旧 `Scheduler` 按单消息出队。
这是保留兼容的通用工具行为；strict APIs 不采用这种时间修补，也不复用其拆分策略。

## 5. 永久排除边界与宿主责任

本核心配置永久不包含：OSC 1.1 recursive-descendant `//`、Unicode OSC 字段、任意正则
表达式、花括号内部的递归/嵌套模式扩展、缺类型串的历史猜测、隐式数值强制转换、
NTP era 推断/时钟同步、套接字/服务发现/认证、DSP 或硬实时保证。strict packet 入口
显式拒绝 `//`；通用 matcher 也不会把它当作递归匹配。备选字符串中的 * ? [] 为字面值，
不是递归 glob；它们不能匹配本身禁止这些字符的 concrete method 名称。
这些不是未来版本的实现承诺；若另做扩展，应另设明确 opt-in API 和配置名称。

宿主责任不等于排除协议义务：宿主提供绝对时钟和 NTP era 选择、传输/包长边界，
在到期时及时 poll，对每个 batch 中的每条消息先获得所有匹配方法，再按消息顺序连续
执行整个 batch，期间不得穿插别的批次、回调或 await。匹配方法内部顺序由宿主选择。
库本身不运行回调，返回 batch 不保证宿主的执行延迟；未遵守上述循环不能宣称原子执行。

```text
for batch in queue.poll(absolute_now):
    plans = [dispatcher.plan(message) for message in batch.messages]
    // 不设置不匹配的应用契约；先处理计划错误，再进入连续执行区。
    for (message, plan) in zip(batch.messages, plans):
        for route in plan.accepted:
            invoke(route.id, message.arguments) // 不跨批次/不 await
```

## 6. 错误与资源限制

未知或格式错误的包 fail-closed，不猜测/部分执行。默认 1 MiB/包、64 KiB/字符串、
512 KiB/blob、4096 参数、4096 包节点、深度32；上限和可配置范围见 security.md。
模式/方法最长4096，默认共享工作预算1000000。超过限额是受控错误，不是假装支持无限包长。
队列默认4096 **批次**，不是4096消息；单次 enqueue 仍受包节点/参数限额约束。
入队持有独立快照；poll 转移所有权。实例单所有者，不保证并发访问安全。
本文件是可执行承诺与职责对照，不是第三方认证或穷举符合性证明。
