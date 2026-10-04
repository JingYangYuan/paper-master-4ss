*! version 1.0.0 22aug2025 元景阳
*! crse_sim: 验证聚类稳健标准误 (Cluster-Robust Standard Errors)

capture program drop crsesim
program define crsesim , rclass
    version 16.0
    syntax, clusters(integer) obsper(integer) ///
             [ beta0(real 1) beta1(real 0.5) ///
               sigmau(real 0.5) sigmav(real 1) seed(integer 12345) ]

    clear
    set seed `seed'

    * 1. 设置模拟参数
    local num_clusters   = `clusters'
    local obs_per_cluster = `obsper'
    local total_obs       = `num_clusters' * `obs_per_cluster'

    di as result ">>> 模拟设置:"
    di as result "    群组数 (G)     = `num_clusters'"
    di as result "    每组观测 (Tg)  = `obs_per_cluster'"
    di as result "    总观测数 (N)   = `total_obs'"
    di as result "    截距 beta0     = `beta0'"
    di as result "    系数 beta1     = `beta1'"
    di as result "    组间误差 σ_u   = `sigmau'"
    di as result "    组内误差 σ_v   = `sigmav'"
    di as result "    随机种子       = `seed'"
	
    * 2. 生成模拟数据
    qui set obs `total_obs'
	
	qui gen id = _n
	label var id "个体 ID"
	
    qui gen cluster_id = ceil(_n / `obs_per_cluster')
    label var cluster_id "群组 ID"

    qui gen x = rnormal(0, 1)
    label var x "解释变量 X (N(0,1))"

    qui bys cluster_id: gen u_g = rnormal(0, `sigmau') if _n == _N
    qui bys cluster_id: replace u_g = u_g[_N]
    label var u_g "组间误差 u_g (群组效应)"

    qui gen v_ig = rnormal(0, `sigmav')
    label var v_ig "组内误差 v_ig"

    qui gen epsilon = u_g + v_ig
    label var epsilon "总误差项 (u_g + v_ig)"

    qui gen y = `beta0' + `beta1'*x + epsilon
    label var y "因变量 Y"

    * 3. 回归估计
    quietly reg y x
    estimates store naive_ols

    quietly reg y x, robust
    estimates store robust_ols

    quietly reg y x, vce(cluster cluster_id)
    estimates store cluster_robust_ols

    * 4. 输出对比表
    esttab naive_ols robust_ols cluster_robust_ols, ///
        t(3) b(%6.4f) compress nogaps ///
        star(* 0.1 ** 0.05 *** 0.01) ///
        scalar(N r2_a) ///
        mtitles("Naive OLS" "Robust SE" "Cluster-Robust SE") ///
        replace
	capture drop *_ols
end
