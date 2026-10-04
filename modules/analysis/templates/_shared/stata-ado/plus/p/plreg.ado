*! version 2.20  21Aug2006 M. Lokshin
#delim ;

capture program drop plreg;
program define plreg, eclass;
	version 8;

	syntax varlist [if] [in],
		   nlf(varlist numeric max=1)
                   [GENerate(name max=1) Order(numlist int max=1 <=10 >0) wh Level(cilevel) COLLinear *];

	if (!missing("`generate'")) confirm new variable `generate';

	marksample touse;

	tokenize `varlist'; local y `1'; macro shift; local x `*';
	unab x: `x';

	quietly {;

	tempvar id id_org;
	generate `id_org' = _n;              // id to restore the order at the end, no if conditions
	generate `id'     = _n if (`touse'); // id for future merging

	preserve;

	markout `touse' `varlist' `nlf';

	keep if (`touse');

	foreach var of varlist `varlist' {; drop if (missing(`var')); }; // drop observations with missings
                                            drop if (missing(`nlf'));    // drop observations with missings

	/************ remove collinear variables ***************************/
        _rmcoll `x' if `touse', `collinear';
	local result "`r(varlist)'";
        local colls: list x - result;
	if !missing("`colls'") {;
		noisily display as text "note: `colls' dropped due to collinearity";
		local x `result';
	}; //if
	/*******************************************************************/

	tempname WH1 WH2 WH3 WH4 WH5 WH6 WH7 WH8 WH9 WH10;
	matrix `WH1'  = (0.7071, -0.7071);
	matrix `WH2'  = (0.8090, -0.5000, -0.3090);
	matrix `WH3'  = (0.1942,  0.2809,  0.3832, -0.8582);
	matrix `WH4'  = (0.2708, -0.0142,  0.6909, -0.4858, -0.4617);
	matrix `WH5'  = (0.9064, -0.2600, -0.2167, -0.1774, -0.1420, -0.1103);
	matrix `WH6'  = (0.2400,  0.0300, -0.0342,  0.7738, -0.3587, -0.3038, -0.3472);
	matrix `WH7'  = (0.9302, -0.1965, -0.1728, -0.1506, -0.1299, -0.1107, -0.0930, -0.0768);
	matrix `WH8'  = (0.2171,  0.0467, -0.0046, -0.0348,  0.8207, -0.2860, -0.2453, -0.2260, -0.2879);
	matrix `WH9'  = (0.9443, -0.1578, -0.1429, -0.1287, -0.1152, -0.1025, -0.0905, -0.0792, -0.0687, -0.0588);
	matrix `WH10' = (0.1995,  0.0539,  0.0104, -0.0140, -0.0325,  0.8510, -0.2384, -0.2079, -0.1882, -0.1830, -0.2507);

	tempname WY1 WY2 WY3 WY4 WY5 WY6 WY7 WY8 WY9 WY10;
	matrix `WY1'  = `WH1';
	matrix `WY2'  = `WH2';
	matrix `WY3'  = (0.8582, -0.3832, -0.2809, -0.1942);
	matrix `WY4'  = (0.8873, -0.3099, -0.2464, -0.1901, -0.1409);
	matrix `WY5'  = `WH5';
	matrix `WY6'  = (0.9200, -0.2238, -0.1925, -0.1635, -0.1369, -0.1126, -0.0906);
	matrix `WY7'  = `WH7';
	matrix `WY8'  = (0.9380, -0.1751, -0.1565, -0.1389, -0.1224, -0.1069, -0.0925, -0.0791, -0.0666);
	matrix `WY9'  = `WH9';
	matrix `WY10' = (0.9494, -0.1437, -0.1314, -0.1197, -0.1085, -0.0978, -0.0877, -0.0782, -0.0691, -0.0606, -0.0527);

	tempname W; // assign weight matrix depending on selected weights

	if (missing("`order'")) local order = 1;

	if (!missing("`wh'")) {;
		matrix `W' =`WH`order'';
		noi display in green _newline "Partial Linear regression model with Hall's weighting matrix";
					};  // endif
	else			{;
		matrix `W' =`WY`order'';
		noi display in green _newline "Partial Linear regression model with Yatchew's weighting matrix";
		}; // end else

	/*******************************************************************/
	sort `nlf' `x', stable;	// sort by the variable that enters non-linear, stable to preserve order

	/*********** check for duplicate observations **********************/
	duplicates report `nlf';
	if (r(unique_value) != r(N)) {;
			noi display as result _newline "There are observations with identical `nlf' values.";
			noi display as result "The sort order of the data could affect your results.";
			};
	tempvar ly;
	generate double `ly' = `y'*`W'[1,1];   	  	  					// dependent variable + first lag times weight
	foreach var of varlist `x' {;
			generate double l__`var' = `var'*`W'[1,1]; 				// independent variables + first lag times weight
			local x_string `x_string' l__`var';  					// form string of independent variables for regression
			}; // end foreach

	forvalues i = 1/`order' {;
		replace  `ly' = `ly'+`y'[_n-`i']*`W'[1,`i'+1];      		// lagged dependent variable times weight
		foreach var of varlist `x' {;
			replace l__`var' = l__`var'+`var'[_n-`i']*`W'[1,`i'+1]; // lagged independent variables time weight
			}; // end foreach
	}; /* end forvalues */

	// linear model for the specification test

        regress `y' `x', noheader;
			local tss=e(mss)+e(rss);
			local s2lin=e(rss)/e(N);
			local t=e(N);
	/*******************************************************************/
	// Coefficients of this regression are correct, standard error are incorrect
        regress `ly' `x_string' if (_n>`order'), noconstant noheader;
	// VCM for differencing estimators, proposition 4.5.1 in Yatchew (2003)
	local ssq_diff=e(rss)/e(N); // mean square residual from differencing equation
	tempname DXtDX S_x_z_inv S_beta_diff CovBetaDiff;
	matrix accum `DXtDX' = `x_string', noconstant;
	matrix `S_x_z_inv'   = invsym(`DXtDX');  // Sigma x|x inverse 4.5.5

	matrix `S_beta_diff' = (1+1/(2*`order'))*`ssq_diff'*`S_x_z_inv'; // 4.5.6
	matrix colname `S_beta_diff' = `x'; matrix rowname `S_beta_diff' = `x';
	matrix `CovBetaDiff' = vecdiag(`S_beta_diff'); matrix colname `CovBetaDiff' = `x';

	/*******************************************************************/
	// Significance test
	local vtest = sqrt(`order'*`t')*(`s2lin'-`ssq_diff')/`ssq_diff';

	if (!missing("`generate'")) {;
	    tempvar y_hat y_yhat;
	    tempname BETTAS;
	    matrix `BETTAS' = e(b); matrix colname `BETTAS' = `x';
	    matrix score `y_hat' = `BETTAS'; summarize `y_hat', meanonly; local mean_y_hat=r(mean);
		generate double `y_yhat' = `y'-(`y_hat'-`mean_y_hat');
		lowess `y_yhat' `nlf' if (_n>`order'), gen(`generate') `options';
		tempfile tfile;
		keep `id' `generate';
		sort `id';	save `tfile', replace;
		restore;
		sort `id'; merge `id' using `tfile'; drop _merge; sort `id_org';
	}; // end if
	else restore;

	}; // end quietly

	/********** Saved Results ******************************************/
	tempname COEFF;	matrix `COEFF' = e(b); matrix colname `COEFF' = `x';
	local nobs = e(N);    local dof  = e(df_r); local F   = e(F);   local r2   = e(r2);
	local rmse = e(rmse); local mss  = e(mss);  local rss = e(rss); local r2_a = e(r2_a);
	local ll   = e(ll);   local model= e(model); local estat_cmd = e(estat_cmd);
	local cmd  = e(cmd);  local predict = e(predict);
	matrix b = `COEFF'; matrix V = `S_beta_diff';
	ereturn post b V, depname(`y') obs(`nobs') dof(`dof') esample(`touse');
	ereturn scalar df_m   = `nobs'-`dof';
	ereturn scalar F      = `F';
	ereturn scalar r2     = `r2';
	ereturn scalar rmse   = `rmse';
	ereturn scalar mss    = `mss';
	ereturn scalar rss    = `rss';
	ereturn scalar r2_a   = `r2_a';
	ereturn scalar ll     = `ll';

	ereturn scalar s2diff = `ssq_diff';
	ereturn scalar s2lin  = `s2lin';
	ereturn scalar order  = `order';
	ereturn scalar stest  = `vtest';

	ereturn local title     "Partial linear regression";
	ereturn local depvar    `y';
	ereturn local model     `model';
        ereturn local estat_cmd `estat_cmd';
	ereturn local cmd       `cmd';
        ereturn local predict   `predict';

	/************  OUTPUT TABLE ****************************************/
	display;
	display in green "      Source {c |}       SS       df       MS {col 55} Number of obs ="
			in yellow %8.0f e(N);
	display in green "{hline 13}{c +}{hline 30} {col 55} F(" e(df_m) ", " e(df_r) ")" _col(70) "="
			_col(72) in yellow %7.0g e(F);
	display in green "       Model {c |}"
			in yellow _col(15) %12.0g e(mss) %6.0f e(df_m) _col(34) %11.0g e(mss)/e(df_m)
			in green "{col 55} Prob > f      ="
			in yellow %8.4f Ftail(e(df_m),e(df_r),e(F));
	display in green "    Residual {c |}"
			in yellow _col(15) %12.0g e(rss) %6.0f e(df_r) _col(34) %11.0g e(rss)/e(df_r)
			in green "{col 55} R-squared     =" in yellow %8.4f e(r2);
	display in green "{hline 13}{c +}{hline 30} {col 55} Adj R-squared ="
			in yellow %8.4f e(r2_a);
	display in green "       Total {c |}"
			in yellow %12.3f e(mss)+e(rss) %6.0f e(df_r)+e(df_m) _col(34) %11.0g (e(mss)+e(rss))/(e(df_r)+e(df_m))
			in green " {col 55} Root MSE      ="
			in yellow %8.4f e(rmse) _newline;

	ereturn display; // output table of coefficients

	display as text  "Significance test on `nlf': V ="
			as result %6.3f `vtest' as text " P>|V| = " as result %4.3f 1- normal(`vtest');
	display in green "{hline 78}";

end; // program plreg



