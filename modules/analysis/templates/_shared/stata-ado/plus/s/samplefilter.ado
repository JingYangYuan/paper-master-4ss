* -------------------------------------------------------------------
* samplefilter: 子样本筛选工具
* Origion (Python): https://github.com/DangYi4113/SampleFilter
* Author (Stata): Yeyang Li
* Optimized and Quiet-Mode Enhanced by: ChatGPT
* Date: 2022/4/30, Updated: 2025/7/24
* -------------------------------------------------------------------

cap program drop samplefilter				
program samplefilter, byable(recall) rclass sortpreserve	
	version 12.0

	* -------------------------------
	* 解析参数
	* -------------------------------
	syntax anything [if] [in] [fw pw iw], ///
		cmd(string)              /// 回归命令
		SIGnificant(varlist)     /// 预期显著变量
		[POSitive(varlist)       /// 预期正向变量
		NEGative(varlist)        /// 预期负向变量
		P_value(real 0.05)       /// 显著性检验临界值
		lr(real 0.5)             /// 初始样本占比下限
		rr(real 0.7)             /// 初始样本占比上限
		Iteration(int 1000)      /// 每批次最大迭代次数
		k(int 5)                 /// 重复批次数
		Zvalue                   /// 使用z检验代替t检验
		dots1                    /// 打印可行样本搜索进度条
		dots2                    /// 打印样本扩展进度条
		SUBsamplename(string)    /// 可行子样本变量前缀
		* ]                      /// 其他回归命令参数

	if "`subsamplename'" == "" {
        local subsamplename "samplefilter"
    }
    
    local byindex = _byindex()
    
    capture drop `subsamplename'_`byindex'
	
	* -------------------------------
	* 初始化变量和数据处理
	* -------------------------------
	marksample touse, strok
	markout `touse' `_byvars', strok
	local byindex = _byindex()

	tempvar id
	quietly gen `id' = _n

	cap matrix drop success_sub_`byindex'
	global issuccess_all = 0 
	global subsample_obs_`byindex' = 0
	
	if "`subsamplename'" == "" {
		local subsamplename "samplefilter"
	}
	capture confirm new variable `subsamplename'_`byindex'
	if _rc != 0 {
		di in red "`subsamplename'_`byindex' 已经存在"
		exit _rc
	}
	quietly gen `subsamplename'_`byindex' = .

	* -------------------------------
	* 全样本检验
	* -------------------------------
	di as result "全样本结果："
	`cmd' `anything' if `touse', `options'

	if "`zvalue'" == "" & missing(e(df_r)) {
		di as error "该命令没有提供e(df_r)，请尝试增加zvalue选项"
		exit
	}

	if `lr' > `rr' {
		di in red "警告：lr > rr，自动调换"
		local tmp = `lr'
		local lr = `rr'
		local rr = `tmp'
	}

	tempvar allsample 
	quietly gen `allsample' = 1 if e(sample) == 1

	local a = `e(N)' * `lr'
	local b = `e(N)' * `rr'

	sig_t `anything', sig(`significant') pos(`positive') neg(`negative') p(`p_value') `zvalue'
	if "`s(success)'" == "True" {
		global issuccess_all = 1
		global subsample_obs_`byindex' = `e(N)'
		quietly replace `subsamplename'_`byindex' = e(sample)  
		di as result "`_byvars'第`byindex'组全样本符合设定要求"
		exit
	}

	* -------------------------------
	* 可行子样本迭代搜索
	* -------------------------------
	tempvar random random2
	quietly gen `random' = .
	quietly gen `random2' = .

	forvalues i = 1/`k' {
		if ("`dots1'" == "dots1") nois _dots 0, ///
			title("第`i'批寻找可行子样本，共`k'批")

		local found = 0
		forvalues j = 1/`iteration' {
			if ("`dots1'" == "dots1") nois _dots `j' 0, dots(10)

			quietly replace `random' = runiform() if `touse'
			sort `random'
			local obs_n = int(`a' + (`b' - `a') * runiform())
			quietly replace `random' = . if _n > `obs_n'

			capture quietly `cmd' `anything' if !missing(`random'), `options'
			sig_t `anything', sig(`significant') pos(`positive') neg(`negative') p(`p_value') `zvalue'

			if "`s(success)'" == "True" {
				global issuccess_all = 1
				if ${subsample_obs_`byindex'} == 0 {
					global subsample_obs_`byindex' = `e(N)'
					quietly replace `subsamplename'_`byindex' = e(sample)
					cap _estimates hold "`subsamplename'_`byindex'", copy
				}
				local found = 1
				if ("`dots1'" == "dots1") di _newline
				if ("`dots2'" == "dots2") nois _dots 0, ///
					title("第`i'批找到可行子样本，尝试扩展样本")
				continue, break
			}
		}

		* -------------------------------
		* 子样本扩展阶段
		* -------------------------------
		if `found' {
			local moreobs = 0
			quietly count if `touse'
			local total = `r(N)'

			quietly replace `random2' = runiform() if `touse' & missing(`random')
			quietly count if !missing(`random2')
			local maxn = `r(N)'
			sort `random2'

			forvalues n = 1/`maxn' {
				if ("`dots2'" == "dots2") nois _dots `n' 0, dots(10)
				quietly replace `random' = 1 if _n == `n'
				capture quietly `cmd' `anything' if !missing(`random'), `options'
				sig_t `anything', sig(`significant') pos(`positive') neg(`negative') p(`p_value') `zvalue'

				if "`s(success)'" == "True" {
					if `e(N)' > ${subsample_obs_`byindex'} {
						global subsample_obs_`byindex' = `e(N)'
						quietly replace `subsamplename'_`byindex' = e(sample) if `allsample' == 1
						cap _estimates hold "`subsamplename'_`byindex'", copy
						local moreobs = 1
					}
				}
			}
			if ("`dots2'" == "dots2") di _newline

			if `moreobs' {
				di as result "第`i'批找到更大样本量的可行子样本，共${subsample_obs_`byindex'}个观测值"
			}
			else {
				di as result "第`i'批未找到更大的可行子样本"
			}
		}
		else {
			di as result "第`i'批未找到任何可行子样本"
		}
	}

	* -------------------------------
	* 输出最终结果
	* -------------------------------
	if $issuccess_all {
		di as result "可行子样本结果："

		* 构造显示命令（避免多余的逗号）
		if "`options'" != "" {
			local fullcmd = "`cmd' `anything' if `subsamplename'_`byindex' == 1, `options'"
		}
		else {
			local fullcmd = "`cmd' `anything' if `subsamplename'_`byindex' == 1"
		}

		* 显示构造后的命令
		di as result "结果命令：" _newline "`fullcmd'"

		* 执行回归命令
		`cmd' `anything' if `subsamplename'_`byindex' == 1, `options'
	}
	else {
		di in red "`k'批尝试均不成功，请增加迭代次数或调整模型"
	}
end




cap program drop sig_t			
program sig_t, sclass 
	version 12.0
	syntax anything, ///
		SIGnificant(varlist)     /// 要检验显著性的变量
		[POSitive(varlist)       /// 预期正向变量
		NEGative(varlist)        /// 预期负向变量
		P_value(real 0.05)       /// 显著性水平
		Zvalue                   /// 使用z值代替t值
		]

	local stepsuccess = 1

	* 显著性检验
	foreach var in `significant' {
		local stat = _b[`var'] / _se[`var']
		if "`zvalue'" == "" & !missing(e(df_r)) {
			local pv = 2 * ttail(e(df_r), abs(`stat'))
		}
		else {
			local pv = 2 * (1 - normal(abs(`stat')))
		}
		if `pv' >= `p_value' {
			sreturn local success = "False"
			local stepsuccess = 0
			break
		}
	}

	if !`stepsuccess' exit

	* 正向检验
	foreach var in `positive' {
		if _b[`var'] <= 0 {
			sreturn local success = "False"
			exit
		}
	}

	* 负向检验
	foreach var in `negative' {
		if _b[`var'] >= 0 {
			sreturn local success = "False"
			exit
		}
	}

	sreturn local success = "True"
end
