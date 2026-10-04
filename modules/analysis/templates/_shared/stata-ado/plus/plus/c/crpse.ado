*! version 1.1.0 22aug2025
*! CRSESIM-like Experiment with adjustable parameters
program define crpse
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

    di as text ">>> 开始类似实验（参数可调）..."
    di as text "    beta0=`beta0', beta1=`beta1', sigmau=`sigmau', sigmav=`sigmav'"
    di as text "    集群: `clusters'"
    di as text "    意见:   `observations'"

    *-------------------------------------------------------------------------------
    * 初始化结果文件
    *-------------------------------------------------------------------------------
    tempfile results_file
    postfile results num_clusters obs_per_cluster se_iid se_hetero se_cluster using `results_file', replace

    *-------------------------------------------------------------------------------
    * 主循环
    *-------------------------------------------------------------------------------
    foreach N_clusters in `clusters' {
        foreach N_obsper in `observations' {

            di as text "----------------------------------------------------"
            di as text "  Running: clusters = " as result "`N_clusters'" as text ", obsper = " as result "`N_obsper'"
            di as text "----------------------------------------------------"

            clear
            qui set obs `N_clusters'
            qui gen id = _n
            qui gen u = rnormal(0, `sigmau')

            expand `N_obsper'
            sort id

            qui gen x = rnormal()
            qui gen v = rnormal(0, `sigmav')
            qui gen y = `beta0' + `beta1'*x + u + v

            qui regress y x
            local se_iid = _se[x]

            qui regress y x, robust
            local se_hetero = _se[x]

            qui regress y x, vce(cluster id)
            local se_cluster = _se[x]

            qui post results (`N_clusters') (`N_obsper') (`se_iid') (`se_hetero') (`se_cluster')
        }
    }

    postclose results
    use `results_file', clear

    *-------------------------------------------------------------------------------
    * 添加标签
    *-------------------------------------------------------------------------------
    label variable num_clusters "集群数量"
    label variable obs_per_cluster "每个群组的观测数据"
    label variable se_iid "标准 OLS SE"
    label variable se_hetero "异方差-稳健 SE"
    label variable se_cluster "集群-稳健 SE"

    di as text ">>> 实验结束！结果:"
    list, clean noobs sep(0)
end
