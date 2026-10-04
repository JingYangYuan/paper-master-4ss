*! version 1.1.0 22aug2025
*! CRSESIM-like Experiment with adjustable parameters
program define crse
    version 16.0
    syntax , ///
        [ SEED(integer 12345) ///
          B0(real 1) B1(real 0.5) ///
          SIGMAU(real 0.5) SIGMAV(real 1) ///
          CLUSTERS(string) OBSERVATIONS(string) ]

    *-------------------------------------------------------------------------------
    * 设置默认参数
    *-------------------------------------------------------------------------------
    local beta0 = `b0'
    local beta1 = `b1'
    local sigmau = `sigmau'
    local sigmav = `sigmav'

    if "`clusters'" == "" {
        local clusters "10 20 50 100 200 500 1000"
    }
    else {
        local clusters "`clusters'"
    }

    if "`observations'" == "" {
        local observations "5 10 20 50 100"
    }
    else {
        local observations "`observations'"
    }

    set seed `seed'

    *-------------------------------------------------------------------------------
    * 环境与日志
    *-------------------------------------------------------------------------------
    clear all

    di as result ">>> 开始类似实验（参数可调）..."
    di as result "    beta0=`beta0', beta1=`beta1', sigmau=`sigmau', sigmav=`sigmav'"
    di as result "    集群:     `clusters'"
    di as result "    观测值:   `observations'"

    *-------------------------------------------------------------------------------
    * 初始化结果文件
    *-------------------------------------------------------------------------------
    qui tempfile result_file
    qui postfile result num_clusters obs_per_cluster t_iid t_hetero t_cluster using `result_file', replace

    *-------------------------------------------------------------------------------
    * 主循环
    *-------------------------------------------------------------------------------
    foreach N_clusters in `clusters' {
        foreach N_obsper in `observations' {
            clear
            qui set obs `N_clusters'
            qui gen id = _n
            qui gen u = rnormal(0, `sigmau')

            qui expand `N_obsper'
            qui sort id

            qui gen x = rnormal()
            qui gen v = rnormal(0, `sigmav')
            qui gen y = `beta0' + `beta1'*x + u + v

            qui regress y x
			local se_iid = _se[x]
            local b_iid = _b[x]
			local t_iid = `b_iid'/`se_iid'

            qui regress y x, robust
			local se_hetero = _se[x]
            local b_hetero = _b[x]
			local t_hetero = `b_hetero'/`se_hetero'

            qui regress y x, vce(cluster id)
			local se_cluster = _se[x]
            local b_cluster = _b[x]
			local t_cluster = `b_cluster'/`se_cluster'

            qui post result (`N_clusters') (`N_obsper') (`t_iid') (`t_hetero') (`t_cluster')
        }
    }

    capture qui postclose result
    capture qui use `result_file', clear

    *-------------------------------------------------------------------------------
    * 添加标签
    *-------------------------------------------------------------------------------
    label variable num_clusters "集群数量"
    label variable obs_per_cluster "每个群组的观测数据"
    label variable t_iid "标准 OLS T"
    label variable t_hetero "异方差-稳健 T"
    label variable t_cluster "集群-稳健 T"

	qui gen trend = "标准OLS大"
	label variable trend "趋势"
	qui replace trend = "异方差稳健OLS大" if ((t_hetero > t_iid) & (t_hetero > t_cluster))
	qui replace trend = "集群稳健OLS大" if ((t_cluster > t_hetero) & (t_cluster > t_hetero))
	di as result ""
    di as result ">>> 实验结束，结果:"
    list, clean noobs sep(0)
end
