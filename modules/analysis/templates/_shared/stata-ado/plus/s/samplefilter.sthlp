{smcl}
{* *! version 1.1 2022-04-30 by Yeyang Li *}
{title:标题}

{phang}
{cmd:samplefilter} {hline 2} 搜索满足指定显著性和系数方向约束的可行子样本

{title:语法}

{p 8 16 2}
{cmd:samplefilter} {it:eq} {ifin} {weight}, 
    {cmdab:cmd(}{it:string}{cmd:)} 
    {cmdab:sig:nificant(}{it:varlist}{cmd:)}
    [{cmdab:sub:samplename(}{it:newvar}{cmd:)} 
     {cmdab:pos:itive(}{it:varlist}{cmd:)}
     {cmdab:neg:ative(}{it:varlist}{cmd:)}
     {cmdab:p:_:value(}{it:#}{cmd:)}
     {cmdab:lr(}{it:#}{cmd:)}
     {cmdab:rr(}{it:#}{cmd:)}
     {cmdab:k(}{it:#}{cmd:)}
     {cmdab:iteration(}{it:#}{cmd:)}
     {cmdab:z:value}
     {cmd:dots1}
     {cmd:dots2}
     {it:* any regression options allowed by cmd()}]

{pstd}
允许使用 {cmd:by}；参见 {help by:help by}

{title:描述}

{pstd}
{cmd:samplefilter} 尝试寻找数据的可行子样本，使得指定回归模型满足以下条件：

{p 4 8 2}
- 列在 {cmd:significant()} 中的所有变量在指定 p 值或以下显著；
{p_end}
{p 4 8 2}
- 列在 {cmd:positive()} 中的变量（可选）具有正系数；
{p_end}
{p 4 8 2}
- 列在 {cmd:negative()} 中的变量（可选）具有负系数。
{p_end}

{pstd}
该命令用于模型诊断、稳健性检验和探索数据子集中的条件显著性。

{title:必需参数}

{phang}
{it:eq} 指定回归方程，遵循指定回归命令的语法（例如：{cmd:reg y x1 x2}）。

{phang}
{cmd:cmd(}{it:string}{cmd:)} 指定要执行的回归命令（例如：{cmd:regress}, {cmd:logit}）。

{phang}
{cmd:significant(}{it:varlist}{cmd:)} 列出必须显著的变量。简写形式：{cmd:sig()}。

{title:可选选项}

{phang}
{cmd:subsamplename(}{it:newvar}{cmd:)} 指定生成的二元变量名称前缀，标记所选子样本。默认为 {cmd:samplefilter}，生成变量名为 {cmd:samplefilter_#}，其中 {cmd:#} 若无 {cmd:by} 分组则为 1，否则为组索引。

{phang}
{cmd:positive(}{it:varlist}{cmd:)} 指定应具有正系数的变量。简写形式：{cmd:pos()}。

{phang}
{cmd:negative(}{it:varlist}{cmd:)} 指定应具有负系数的变量。简写形式：{cmd:neg()}。

{phang}
{cmd:p_value(}{it:#}{cmd:)} 设置显著性水平阈值。默认为 {cmd:0.05}。简写形式：{cmd:p()}。

{phang}
{cmd:lr(}{it:#}{cmd:)} 设置初始随机样本占总样本比例的下限。默认为 {cmd:0.5}。

{phang}
{cmd:rr(}{it:#}{cmd:)} 设置初始随机样本占总样本比例的上限。默认为 {cmd:0.7}。

{phang}
{cmd:k(}{it:#}{cmd:)} 设置完整搜索过程的重复次数（批次）。默认为 {cmd:5}。

{phang}
{cmd:iteration(}{it:#}{cmd:)} 设置每批次搜索可行子样本的最大迭代次数。默认为 {cmd:1000}。

{phang}
{cmd:zvalue} 请求使用 {it:z} 统计量而非 {it:t} 统计量进行显著性检验（用于无法获得自由度时）。简写形式：{cmd:z}。

{phang}
{cmd:dots1} 在初始搜索可行子样本期间显示进度点。当 {cmd:iteration()} 较大或回归较慢时推荐使用。

{phang}
{cmd:dots2} 在扩展子样本以包含更多观测值时显示进度点。推荐用于大数据集或复杂模型。

{phang}
{cmd:*} 将额外选项传递给 {cmd:cmd()} 中指定的回归命令。

{title:输出}

{pstd}
如果成功，{cmd:samplefilter} 会创建一个二元变量（如 {cmd:samplefilter_1}），标记找到的最佳可行子样本（值为 1）。同时会显示全样本和选中子样本上的回归结果。

{title:使用示例}

{p 4 4 2} *- 使用 auto.dta 数据集，在所有解释变量中选择能使变量 {bf:headroom} 和 {bf:weight} 在 {cmd:reg} 模型中 5% 显著的子样本；并设定其预期符号。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"sysuse auto, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global y price"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global x mpg rep78 headroom trunk weight length turn displacement gear_ratio foreign"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global sig headroom weight"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global pos weight"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global neg headroom"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"samplefilter $y $x, sig($sig) pos($pos) neg($neg) cmd(reg) p(0.05)"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"label define samplefilter 1 "可行子样本" 0 "表现不好样本""'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"label values samplefilter_1 samplefilter"'}
{p_end}

{p 4 4 2} *- 按可行子样本对变量汇总，并在前 40 行中分组。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"bys samplefilter_1 : sum $y $x"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"gen group = _n < 40"'}
{p_end}

{p 4 4 2} *- 在分组样本中选择使 {bf:trunk} 显著的子样本，使用 {cmd:reghdfe}，并设置筛选门槛。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"global sig trunk"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"bys group: samplefilter $y $x, sig($sig) cmd(reghdfe) p(0.1) sub(subsample) lr(0.6) rr(0.8) noabsorb"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"cap drop subsample*"'}
{p_end}

{p 4 4 2} *- 使用 {cmd:reghdfe} 检验多个变量联合显著性，设置迭代次数与变量个数控制复杂度。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"global sig mpg trunk gear_ratio"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"samplefilter $y $x, sig($sig) cmd(reghdfe) p(0.1) sub(subsample) noabsorb i(100) k(2)"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"cap drop subsample*"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"samplefilter $y $x, sig($sig) cmd(reghdfe) p(0.1) sub(subsample) noabsorb i(1000) k(5) dots1"'}
{p_end}

{p 4 4 2} *- 使用 {cmd:logit} 在 {bf:low birth weight} 数据中筛选显著变量。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"webuse lbw, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global x age lwt i.race smoke ptl ht ui"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global sig lwt ui ht ptl"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global pos ui ht ptl"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global neg lwt"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"samplefilter low $x, sig($sig) pos($pos) neg($neg) cmd(logit) p(0.1) sub(subsample) i(5000) z dots1"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"cap drop subsample*"'}
{p_end}

{p 4 4 2} *- 使用 {cmd:probit} 检验逻辑回归中变量显著性。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"samplefilter low $x, sig($sig) pos($pos) neg($neg) cmd(probit) p(0.1) sub(subsample) i(5000) z dots1"'}
{p_end}

{p 4 4 2} *- 使用 {cmd:ivreg2} 的因果分析示例，educ 为内生变量。 {p_end}

{p 4 4 2}{inp:-} 
{stata `"use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz.dta, clear"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"ivreg2 lwage exper expersq (educ=age kidslt6 kidsge6), robust savefirst"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global equation lwage exper expersq (educ=age kidslt6 kidsge6)"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"global sig expersq"'}
{p_end}
{p 4 4 2}{inp:-} 
{stata `"samplefilter $equation, sig($sig) cmd(ivreg2) p(0.05) sub(subsample) i(500) robust savefirst z dots1 dots2"'}
{p_end}
