 
*! Author: Lian Yu-jun (Modify and update)
*! E-mail: arlionn@163.com
*! First modify: 2011.07.24
*! This version: 2012.07.04
*! Hompage: http://www.lingnan.net/intranet/teachinfo/dispuser.asp?name=lianyj


**  pvar_a.ado - package for estimating VAR  (vector auto-regressions)
**
** created by Inessa Love (Chevtchinskaia), March 2000, contact: ilove@worldbank.org
**
** THIS IS SET UP TO DO PANEL DATA VAR (see notes below) 
**
** use of this package requires program sgmm.ado (enclosed with the package)
** or, you can use your own system estimation program , but the estimates 
** must be in the same format as after my sgmm.ado  
** 
** SYNTAX : 
** 
** pvar varlist [if exp], [lag(p) options]
** 
** where: varlist  is the list with variable names in desired order (order is important!)
**        p is optional number of lags in VAR, must be integer >0 (default=1) 
**        if is optional subsample indicator (using standard Stata's syntax)
**
** options are (must be low case):
**
** gmm  -  will estimate coefficients by gmm (this will call a separate program sgmm.ado)
**        required option if new model is estimated (even if only the order changed!), 
**        otherwise the latest estimates are taken from the memory (left after previous run of 
**        the program);  gmm must be the first parameter for a new model; 
**
** impulse - will generate numerical impulse-responses without errors
**   list_imp - will list a table with impulse-responses (use after impulse)
**   gr_imp -  will graph impulses (witout errors ); if using monte for standard errors - no 
**           need to graph impulses separately
**
** monte [#] - will generate errors for impulse responses using monte-carlo simulation;
**         optional parameter after monte is desired number of repetitions, default 200;
**         note that monte will call impulse - so no need to specify it separately;
**         monte will graph impulses with the bands automatically; 
**   list_mon - will list tables with impulses and error bands (use after monte)
**
** decomp - will print out variance-decompositions; one optional parameter is the max number
**          of periods (note that ony every 10th period is printed out), default is 20
**          to use different number of periods have to use double quotes for ex. "decomp 30"
** 
** for example, the common line to call the program would look like :
**
** pvar IK SK , lag(3) gmm impulse monte 500 decomp
**
** here number 500 (repetitions for monte-carlo) could be ommited (or changed)
** if errors on impulses are not needed, change monte for gr_imp (to graph without errors)
**
** Notes : 
**
** 1) this will do panel data VAR! that is it assumes that fixed effects are removed
** using helmert transformation and transformed variables already exist in the dataset with 
** names h_y1, h_y2 ...( where y1 and y2 - are original names of the variables);
** it is advised that original variables are timedemeaned before helmert (for panel only);
** note that names in the startup line are original names, (i.e. if IK is original - variable 
** and h_IK is helmert transformed use IK and not h_IK in the startup line ! ;
** helmert transformation program is included with the package (or use your own) ;
** estimation is by gmm with untransformed variables used as instruments for helmert-
** transformed
** 2) to use different transformation (for ex. first difference) - the easiest way is to fool 
** the program and store transformed variables with names h_y1 h_y2 ...
** 3)  Alternatively, to use this program without fixed effects -  create a copy of original 
** variables  with names h_y1 h_y2... (the program will use original variables as both 
** regressors and instruments i.e. use gmm program to perform system OLS)
** 4) no constant is included at this time! (since var's are demeaned and helmert)
** 5) to run any of enclosed programs outside of var.ado - need to create separate ado 
** files -i.e. copy program impulse into impulse.ado and so on
** 6) formulas are from Hamilton 1994 ch.11
** 7) Maximum number of variables is 6 at this time (to extend it change routine MAKED to add 
**    D7... matrices 
** 8) before you can run these you must do the command tsset to tell Stata what is your panel data structure,
**   for example if your cross-section variable is named id and yur itme variable is named year 
**   do the command: tsset id year
**   also note that if you are using my program helm.ado your i and t variables must be named id and year
**
** The programs work to the best of my knowledge and ability, but please  - Use at your own risk ! 
** Please report all errors or modifications that you make to ilove@worldbank.org 
**
**


capture program drop pvar2
program define pvar2, eclass
version 8.0
*set matsize 200
*set log l 100

*syntax varlist [if] , [ Lag(integer 1) ] [ * ]   // old version Arlion


syntax varlist [if] [, ///
       Lag(int 1)      /*PVAR 滞后阶数
	*/ Reps(int 200)   /*Reps of MC to get 95% CI        
	*/ IRF(int 0)      /*Impulse Response Function steps
	*/ IRFFormat(string) /*IRF 图形的纵轴刻度显示格式
	*/ Decomp(int 0)   /*FEVD 分解阶数 //DSteps(int 10)
	*/ Timeeffect      /*通过组内差分去除时间效应
	*/ RESidual        /*呈现残差的协方差矩阵和相关系数矩阵
	*/ NOgraph         /*设定该选项不输出 IRF 图形,便于比较组间差异
	*/ Saving(string)  /*设定存储 IRF 数据的文件名称
	*/ SOC             /*基于 AIC,BIC,HQIC 筛选滞后阶数
	*/ Granger         /*Granger 因果检验
	*/ SEED(real 0.01)       /*种子值
	*/ ]

qui capture tsset
capture confirm e `r(panelvar)'
if ( _rc != 0 ) {
  dis as error "You must {help tsset} or {help xtset} your data before using {cmd:pvar2},see help {help pvar2}."
  exit
}

*cap mat drop _all    // 删除内存中的所有矩阵，可能会影响用户已经定义的矩阵

if `irf'==0&`reps'!=200{
  dis in r "Note: " in y "reps(#)" in red " works if and only if" in y " irf(#)" in red " is also specified."
  exit
}

if `irf'==0&"`irfformat'"!=""{
    dis in r "Note: " in y "irfformat(string)" in red " works if and only if" in y " irf(#)" in red " is also specified."
    exit
}

if `"`irfformat'"' != "" { 
  capt local tmp : display `format2' 1
  if _rc {
    di as err `"invalid %fmt in format(): `format2'"'
    exit 120
  }
  else{
    global irfformat "`irfformat'"
  }
}
else{
  local irfformat %6.3f
  global irfformat "`irfformat'"
}

if `seed'!=0.01{
  set seed `seed'
}


qui tsset
global TT = r(tmax)-r(tmin)+1
global panelvariable = r(panelvar)
global timevariable = r(timevar)

qui xtdes
global NN = r(N)
global TT = r(min)

global depvarlist "`varlist'"

global saving "`saving'"     //存储 IRF 数据的文件名称

global nograph "`nograph'"   //是否绘图开关

global residual "`residual'" //是否呈现残差的方差-协方差矩阵和相关系数矩阵

global granger "`granger'"   //Granger因果检验


*-mark sample

  marksample touse
  markout `touse' `varlist' 
  
  *qui cap drop xxx_touse
  *qui gen xxx_touse = 1 if `touse'       // Arlion, 2012.07.04
  *qui replace xxx_touse = 0 if ~`touse'  // Arlion, 2012.07.04
  
  
*-====================
  preserve
*-====================


  _rmcoll `varlist' if `touse', nocons     /*to delete the collinearity variable, by Arlion*/ 
  local varlist "`r(varlist)'"
  
  qui keep if `touse'   // add by Arlion
  
*-timeeffects demean
  if "`timeeffect'" != ""{
    foreach v of varlist `varlist'{
      egen ava_`v' = mean(`v')
	  bysort $timevariable: egen av_`v' = mean(`v')
	  replace `v' = `v' - av_`v' + ava_`v'
    }
    global timeeffect "Yes"
  }
  
*-lag orders  
  global P=`lag'

*-前向差分处理(forward-difference)
  pvar_helm `varlist'
  
  
  /*
preserve        
if "`if'"~="" { 
   keep `if'       /* if a subset of the data was specified */
}
global if="`if'"


**  Arlion, 2011.07.24
***** separating options into local macros **************
tokenize `options' , parse(" """)   /* this will take options into separate macro arguments */
  local i=0        
  while "`1'"~="" {  
     * di "current option read is `1'"   // open by Arlion
     local i=`i'+1
     local parm`i' "`1'"   /* assign the entered parameter to local macro parm1, parm2 ... */
     mac shift              
  }
  local parms `i'

if `parms'==0 { 
   di in red "at least one option is required"
   exit 
}
*/   // modified by Arlion



***** creating global lists Y, X, Z to call GMM **********************
tokenize `varlist'

local g=0        /* g is a counter of equations for GMM/variables in VAR */
global names=""
while "`1'"~="" {          /* read one input variable at a time */
   local g=`g'+1
   *drop if `1'==.             /* drop MISSING - OPTIONAL - uncomment  */ 
   global y`g'="h_`1'"        /* these will be Y1...YG to use in GMM */
   global name`g'="`1'"       /* this is a list of original names one by one */
   global names="$names `1'"  /* this is global list of all names */
   local p=1                  /* p is counter for lags */
   while `p'<=$P {            /* will generate x's and z'a for each lag */
     local x_`p' "`x_`p'' l`p'.h_`1'" 
     local z_`p' "`z_`p'' l`p'.`1'"
     local p=`p'+1 
   }
   mac shift
} 

global G=`g'                /* total number of variables/equations */


** make x's and z's lists from separate lags:
local p=1   
while `p'<=$P {             /* join together separate lags */
   local x "`x' `x_`p''" 
   local z "`z' `z_`p''"
   local p=`p'+1 
}
** now make all Xg and Zg to be the same as x and z - i.e. use same insstruments for each eq.

global IVs ""
local g=1
while `g'<=$G {
global x`g' "`x'"
global z`g' "`z'"
global IVs "$IVs `z'"
*helm ${name`g'}   /** optional is to call HELMERT HERE - after missing have been deleted **/
  local g=`g'+1 
}



*-----------------Given by Arlion-------begin--------------
  
  *-Estimating Panel VAR model with sgmm2
  
    if "`soc'" == ""{
       sgmm2   // 默认情况下，必须先执行 GMM 估计, 
	           // 若设定 soc, 则自动执行 pvar2_soc 程序 
    }
  
  *-MC 
    if `irf' != 0{
	   global impulse_steps = `irf'   // IRF steps
       di _n(1) in y  "======================================="
       di       in g  " Monte-Carlo Simulation for IRF bounds " 
       di       in y  "======================================="
	   monte `reps'
    }
  

  *-Decomp variance
    if `decomp' != 0{
       di _n(1) in y  "==============================================="
       di       in g  " Forecast-error Variance Decompositions (FEVD) " 
       di       in y  "==============================================="	
       decomp `decomp'  /* Variance Decompositon #`decomp' steps */
    }

  *-Granger causality tests
    if "`granger'" != ""{
       di _n(1) in y  "============================="
       di       in g  "   Granger Causality tests   " 
       di       in y  "============================="	
       pvar2_granger 	   
	}
	
  *-
    if "`soc'" != ""{
       di _n(1) in y  "==========================================="
       di       in g  "  Selection Order Criteria for Panel VAR  " 
       di       in y  "==========================================="	
       pvar2_soc `lag' 	   
	}	

end
*-----------------Given by Arlion--------over--------------

/*
** calling the routines that were requested  - OPTIONS after comma
local g=1  
if "`parms'"~="" {     
  while `g'<=`parms' { 

    if "`parm`g''"=="monte" {     /* this will allow for a number of iterations to be entered*/ 
      local temp=`g'+1 
      capture confirm integer number `parm`temp''   /* check if next parameter is integer */
      if _rc==0 {                            /* yes, it is integer */
         local g=`g'+1                     /* skip to the next parameter */
         monte `parm`temp''                /* call monte with parameter */
      }
      else { 
	     monte            /* otherwise call monte without parameter */
	  }
      local g=`g'+1
    } 
	
    else {
      if "`parm`g''"=="gmm" { 
         sgmm   /* renamed gmm into system gmm */
      }  
      else {
         `parm`g'' 
      }
      local g=`g'+1
    }
  }
}
*/





*************************************************
** Monte-Carlo for errors on impulse-responses **
*************************************************
capture program drop monte
program define monte
** will perform Monte-Carlo simulation for errors, parameter 1 has the number of
** repetitions, default 200
*qui set matsize 800

  impulse $impulse_steps       /* call  impulse - for the first pass */
                   
if "`1'"==""{ 
   global maxi 200  /* number of iterations for MOnte-Carlo, default 200 */
} 
else{
   global maxi `1'  
}

*** 1 generate E - sigma, var-cov matrix of errors uu
** Dn and Dnp used to transfrom vec into vech and back
maked $G               /* get appropriate matrix Dn corresponding to number of equations G */
mat Dnp=(inv(Dn'*Dn))*Dn'
vec uu vecu
mat vechu=Dnp* vecu
mat E=(1/$T)*2*Dnp*(uu # uu)*Dnp'  /* var-cov of elements of uu */
                         /* ask Charlie about T - degrees of freedom */

drop _all
use impulse
drop varname
qui save errors, replace   /* start with empty dataset */

di _n in g "Starting Monte-Carlo loop: "   in y "$S_TIME"
di    in g "Total repetitions requested: " in y "$maxi" 

capture mat drop Di   /* this is big matrix containing impulses */

** loop around here :
global i = 1   /* number of iterations to use in impulse program */
while $i<=$maxi { 
***  generate random vectors for coefficients and uu
  random bgmm var     /* random vector with coefficients, mean: bgmm var: var */
  mat bgmmi=random
  random vechu E      /* random vector vech with errors, mean: vecu, var: E*/
  mat vecui=Dn*random    /* random vector vec with errors */
  unvec vecui uui        /* uui is the random matrix with errors */
  mat rownames uui= $names
  mat colnames uui= $names

*comp i           /* generate companion matrix for simulation i -will be called from impulse*/
  *impulse 10 i
  impulse $impulse_steps i   // now, OK! 可以实现任意阶数的 IRF
  global i=$i+1 
}

di _n in g "Finished Monte-Carlo loop: " in y "$S_TIME"


** create percentiles and merge with impulse data
local g = 1
while `g'<=$G { /* creating names of new variables for collapse */
  local list1 "`list1' ${name`g'}_5=${name`g'}"
  local list2 "`list2' ${name`g'}_95=${name`g'}"
  local g=`g'+1 
}
*di "list1 `list1' list2 `list2'"


collapse (p5) `list1' (p95) `list2', by(order s)
sort order s
merge order s using impulse

*-保存冲击反应函数数据(IRF)
*set trace on
if "$saving" == ""{   //默认保存为 irf_data.dta)
   qui save "irf_data", replace
}
else{
   qui save "$saving", replace  // 此时采用用户指定的文件名称
}
*set trace off

if "$nograph" == ""{  //若设定nograph()选项,则关闭绘图程序
  dis _n in y "Graphing the IRFs ......"
  gr_imp i
}
end


**
** this will graph impulses with monte-errors - it is done autumatically in monte ! ***
**
capture program drop gr_mon
program define gr_mon
 drop _all
 use imp_$maxi
 gr_imp i
end



*********************************
** graph of impulse-responses ***
*********************************

capture program drop gr_imp
program define gr_imp

* can graph with errors and without errors

if "`1'"=="i"{
   local i "i"   /* in case of Monte-Carlo `i'="i" */
}
else {
   local i ""            /* normal case `i' is a blank     */
}

set textsize 170

local g=1
while `g'<=$G {         /* row variable - the one that is recepient of respone */
  local j=1
  while `j'<=$G {      /* column variable - the one causing response */
     if "`i'"=="i" {   /* with errors */
       format ${name`j'}_5 ${name`j'} ${name`j'}_95 $irfformat  //%6.3f Arlion
       twoway line ${name`j'}_5 ${name`j'} ${name`j'}_95 s   ///
	      if varname=="${name`g'}",  ///
		  saving(gr`g'_`j',replace) yline(0, lp(dash)) /// 
		  ylabel(, angle(0) )  /// // #2
		  legend(off)  ///
          subtitle("IRF of ${name`g'} to ${name`j'}", box bexpand) 
     } 
     else {             /* without errors */
        format ${name`j'}_5 ${name`j'} ${name`j'}_95 $irfformat
        twoway line ${name`j'} s if varname=="${name`g'}",     ///
		   saving(gr`g'_`j',replace) yline(0) ///                               
           subtitle("response of ${name`g'} to ${name`j'}") 
     }
     local grlist "`grlist' gr`g'_`j'.gph"   /* list of all graphs to put together */
     local j=`j'+1 
   }
local g=`g'+1 
}

*qui set textsize 100  // by Arlion
*if length("   Impulse-responses for $P lag VAR of $names ")>80 { set textsize 90}

if "`i'"=="i"{ 
   local b2="note(Errors are 5% on each side generated by Monte-Carlo with $maxi reps)"
}

/*   // by Arlion
if "$if"~="" { 
   local t2="subtitle(Sample : $if)"
}
*/

if length("   Impulse-responses for $P lag VAR of $names ")<80 {
   graph combine `grlist', subtitle("Impulse-responses for $P lag VAR of $names")  ///
   `t2' `b2' xcommon imargin(tiny)
}
else{
   graph combine `grlist', title("$P lag VAR of $names") `t2' `b2' ///
         xcommon imargin(tiny)
}
end



*********************************
** Impulse-response functions  **
*********************************
**
** these are responses to 1 std shock, formulas are:
** dXi/Dvj = A^s*P[.,j]   response of variable Xi to shock in variable j at time s
** take jth column of matrix P - cholesky decomposition of u'u
** unit matrix J=[I(GxG),0,0...,0] is used to extract the right portion 
** (first GxG block) of matrix A^s
**
** the data currently in memory will be save in a file temp_data
** impulse-responses will be save in a file impulse.dta 
**
** takes 2 parameters (optional)
** 1 is - maximum number of periods for response, default=6
** 2 = i if it is a Monte-Carlo simulation, note that in this case
**  first parameter must also be nonmissing
**

capture program drop impulse
program define impulse
*set trace on
        

if "`1'"==""{ 
   local bigs 6
}  /* number of periods for impulse response */
else{ 
   local bigs `1'  /* if parameter is not given, default=6 */   
}

if "`2'"=="i"{
   local i "i"     /* in case of Monte-Carlo `i'="i" */
}  
else{
   local i ""            /* normal case `i'is a blank     */
}
comp `i'

capture mat drop D        /* drop only in  a normal case, keep for MOnte-carlo */
matrix P=cholesky(uu`i')
global R=$P*$G               /* R is the dimension of the companion matrix #lags * #vars */
if $P>1{
   mat J=I($G), J($G, $R-$G,0)  /* J matrix used to extract nesessary portion of A */
}
else{
   mat J=I($G)           /* if P=1 - one lag VAR, J==I - no need to extract anything */
}

order_           /* will return vector with order */
mat colnames order="order"
drop _all

if "`i'"=="i" {
        mat repeat=J(rowsof(order),1,$i)    /* the repetition number ofr MOnte-Carlo */
        mat colnames repeat="repeat"
        local rep "repeat,"   /* this will add the number of the repetition for Monte only */
}
else{   
  local rep ""
}


mat AS=I($R)                 /* start with identity matrix - before the first product */



**** Creating impulses for each time s *******************

local s=0                 /* start with time zero AS=I */
while `s'<=`bigs' {       /* time s shock */
  tempname time DS
  mat `time'=J($G,1,`s')   /* will store time for graphing time==s */
  mat rownames `time'= $names
  mat colnames `time'= s

  mat `DS' =J * AS * J'* P  /* one step creating impulses for all variables */

  mat `DS'= `rep' `time',order, `DS'  /* add column of S - what time the shock is for */
  mat D`i'=nullmat(D`i') \ `DS'  /* D is for all times all shocks */
  mat AS=AS*A`i'           /* raise A to the power S for next round */
  *mat list `DS'           /* i is for MOnte-Carlo, otherwise i=""   */
local s=`s'+1 
}

*mat list D

*drop order


if "`i'"=="i" {              /* for Monte-Carlo save in the errors dataset */
  local gs=(`bigs'+1)*$G     /* this is total number of new variables that will be created */
  local times=int(800/`gs')  /* number of times before saving errors to the disk */
  *if $i/`times'==int($i/`times') | $i==$maxi {  /*这样就不会跳跃呈现 RIF 了*/
     /* only save every `times' times or at the end, otherwise -accumulate, to save time */
     di in w "." _c   // 在屏幕上打点
     qui svmat Di, name(col)   /* create variables for graphing/presentation */
     mat drop Di 
     append using errors
     qui save errors, replace
   *}
}
else { 
  qui svmat D , name(col)   /* create variables for graphing/presentation */
  qui gen str6 varname=""  /* generate variable with names - for original impulses */
  local i = 1
  while `i'<=$G {
    qui replace varname="${name`i'}" if order==`i' 
     format ${name`i'} %7.4f
    local i=`i'+1 
  }
  order varname    /* put varname first variable -for printing*/
  sort order s
  qui save impulse, replace 
}

** variables show effect of column variable name on a row variable name
** i.e. column named Q contains effect of Q shock on variable names in varname
** for ex :
** s  varname  x1      
** 1  x1       1
** 1  x2       2     i.e. effect of x1 on x2 in period s=1 is equal to 2 
** 1  x3       3
** this is the best way to organize impulse-responses for graphing
** to graph :
**  gr ik s, by(varname) R c(l) sort ti(reponse to the shock in ik)
**  gr ik s if varname==Q, c(l) sort ti(reponse of Q to the shock in ik)

end


***********
** list  **
***********
** this program will list numbers for impulse-responses without bands  **
capture program drop list_imp
program define list_imp
  drop _all
  use impulse
  di "Impulse-responses of variable in varname to the shock in column variable"
  list,nod noobs
end

** this program will list impulsee with errors - one by one **
capture program drop list_mon
program define list_mon
  drop _all
  use imp_$maxi
  local j=1
  while `j'<=$G {      /* column variable - the one causing response */
     di "Impulse-responses of variable in varname to the shock in ${name`j'} "
     format ${name`j'}_5 ${name`j'} ${name`j'}_95 %7.4f
     list varname s ${name`j'}_5 ${name`j'} ${name`j'}_95 , nod
     local j=`j'+1 
  }
end


*************************************
** this will create companion form **
*************************************
** my notation ( Charlie's notation)
** G (nk) - number of variables == number of equations in VAR
** P (np) - number of lags in VAR
** r (nr) = G*P  is number of regressors in equation (now all equations have the same
**       number of regressors)  (number of variables* times number of lags)
** Input matrices (must exist) bgmm, output: A (companion form)
**
** takes one parameter (optional) in case it is used for monte-carlo
** first parameter must be i if it has to be used for monte-carlo

capture program drop comp
program define comp

*set trace on
*di "program COMP running"

if "`1'"=="i"{
   local i "i"
}
else{
   local i ""
}

local r=$P*$G  /* number of regressors in each equation */

** will generate new matrix beta which consists of blocks -reshape bgmm ***
capture mat drop beta
tempname b
local g = 1
while `g'<=$G {    /* extract column vector of coefficients for equation g into b */
  mat `b'=bgmm`i'[1+(`g'-1)*`r'..`g'*`r',.]   
  mat colnames `b' = ${y`g'}     /* give name to the column */  
  mat beta=nullmat(beta),`b'
  local g=`g'+1
}
*mat list beta

** generate A - companion matrix ****
capture mat drop A`i'
if $P>1 {
  tempname temp
  mat `temp'=I(`r'-$G), J(`r'-$G, $G,0)    
  mat A`i'=beta' \ `temp'   /* stack vertically */
}
else{
  mat A`i'=beta'
}
mat drop beta

end




*************************************************************************
** Program RANDOM
**
** generates random vector distributed with mean `1' and variance `2'
** first parameter is name of the vector with the mean of the resulting vector
** second parameter is the var-cov of the resulting vector
** length of the vector will be the same as length of vector with means
** resulting vector will be called random
*************************************************************************
capture program drop random
program define random
** first will generate independent random vector N(0,1)
local r=rowsof(`1')
if rowsof(`2')~=colsof(`2') | rowsof(`2')~=rowsof(`1') { 
   di in red "Program Random: Matrix `2' must be square with same # of rows as `1' "
   exit
}
local i = 1
tempname P temp
while `i'<=`r' { /* create element by element and stack into the vector */
  mat `temp'=nullmat(`temp') \ J(1,1,invnorm(uniform()) )
  local i=`i'+1 
}

** transform to have mean `1' and variance `2'
mat `P'=cholesky(`2')
mat random=`1'+`P' * `temp'  /* resulting vector wiht mean `1' and variance `2' */

end


capture program drop order_
program define order_
** will generate a "sequence" vector with numbers 1,2,3,... $G,
** result is saved in vector order (use for impulse)
capture mat drop order
local i = 1
while `i'<=$G { /* create element by element and stack into the vector */
  mat order=nullmat(order) \ J(1,1,`i')
  local i=`i'+1 
}
end


*******************
** VEC and UNVEC **
*******************
**
** VEC - will create vector from the matrix, only symmetric for now
** parameter `1' - name of the input matrix, `2' - name of output vector
** `1' is square matrix, `2' is vector matrix
**

capture program drop vec
program define vec

if rowsof(`1')~=colsof(`1') { 
   di in red "Matrix `1' is not square - will not create vec"
   exit
}
local r=rowsof(`1')     
capture mat drop `2' 
tempname b
local g = 1
while `g'<=`r' {    
  mat `b'=`1'[1...,`g']             /* extract column g */
  mat `2'=nullmat(`2') \ `b'      /* stack the columns vetrically */
 local g=`g'+1
}
end

capture program drop unvec
program define unvec
**
** will create square matrix from the vector
** `1' is name of input vector, `2' name of output matrix
** for now only does square matrix, i.e. vector should be a vec of a square matrix
**
local r=sqrt(rowsof(`1'))       /* number of rows in resulting matrix */
tempname b
capture mat drop `2' 
local g = 1
while `g'<=`r' {                
  mat `b'=`1'[1+(`g'-1)*`r'..`g'*`r',.]  /* extract column g from the vector  */
  mat `2'=nullmat(`2'),`b'           /* stack columns horisontally */
  local g=`g'+1
  }

end

********************
** Make Dn matrix **
********************
** takes one parameter - the number of the matrix
** this will make Dn matrices to use for generating distribution of uu
** they all will be called Dn, whenre n =$G
** for now only works for up to 6

capture program drop maked
program define maked

capture drop Dn
if `1'==1 {
mat Dn = (1)
exit
}
if `1'==2 {
mat Dn = (1, 0 ,0 \ 0, 1, 0 \ 0, 1, 0 \ 0, 0, 1)
exit
}
if `1'==3 {
mat Dn = (1,0,0,0,0,0\0,1,0,0,0,0\0,0,1,0,0,0\0,1,0,0,0,0\0,0,0,1,0,0\0,0,0,0,1,0\0,0,1,0,0,0\0,0,0,0,1,0\0,0,0,0,0,1)
exit
}
if `1'==4 {
*set trace on
tempname temp1 temp2 temp3 temp4
mat `temp1' =I(4),J(4,6,0)
mat `temp2' =(0,1,0,0,0,0,0,0,0,0)
mat `temp3' =J(3,4,0), I(3), J(3,3,0)
mat `temp4' =(0,0,1,0,0,0,0,0,0,0\0,0,0,0,0,1,0,0,0,0\0,0,0,0,0,0,0,1,0,0\0,0,0,0,0,0,0,0,1,0\0,0,0,1,0,0,0,0,0,0\0,0,0,0,0,0,1,0,0,0\0,0,0,0,0,0,0,0,1,0\0,0,0,0,0,0,0,0,0,1)
mat Dn=`temp1' \ `temp2' \ `temp3' \ `temp4'
exit
}

if `1'==5 {
local e2_5="(0,1,0,0,0)"
local e3_5="(0,0,1,0,0)"
local e4_5="(0,0,0,1,0)"
local e5_5="(0,0,0,0,1)"
local e2_4="(0,1,0,0)"
local e3_4="(0,0,1,0)"
local e4_4="(0,0,0,1)"
local e2_3="(0,1,0)"
local e3_3="(0,0,1)"
tempname temp1 temp2 temp3 temp4 temp5
mat `temp1' =I(5),J(5,10,0)
mat `temp2'=`e2_5',J(1,10,0) \ J(4,5,0),I(4),J(4,6,0)
mat `temp3'=`e3_5',J(1,10,0) \ J(1,5,0), `e2_4', J(1,6,0) \ J(3,9,0), I(3), J(3,3,0)
mat `temp4'=`e4_5',J(1,10,0) \ J(1,5,0), `e3_4', J(1,6,0) \ J(1,9,0), `e2_3', J(1,3,0) \ J(2,12,0), I(2), J(2,1,0)
mat `temp5'=`e5_5',J(1,10,0) \ J(1,5,0), `e4_4', J(1,6,0) \ J(1,9,0), `e3_3', J(1,3,0) \ J(2,13,0), I(2)
mat Dn=`temp1' \ `temp2' \ `temp3' \ `temp4' \ `temp5'
exit
}
if `1'==6 {
local e2_6="(0,1,0,0,0,0)"
local e3_6="(0,0,1,0,0,0)"
local e4_6="(0,0,0,1,0,0)"
local e5_6="(0,0,0,0,1,0)"
local e6_6="(0,0,0,0,0,1)"
local e2_5="(0,1,0,0,0)"
local e3_5="(0,0,1,0,0)"
local e4_5="(0,0,0,1,0)"
local e5_5="(0,0,0,0,1)"
local e2_4="(0,1,0,0)"
local e3_4="(0,0,1,0)"
local e4_4="(0,0,0,1)"
local e2_3="(0,1,0)"
local e3_3="(0,0,1)"
tempname temp1 temp2 temp3 temp4 temp5 temp6
mat `temp1' =I(6),J(6,15,0)
mat `temp2'=`e2_6',J(1,15,0) \ J(5,6,0),I(5),J(5,10,0)
mat `temp3'=`e3_6',J(1,15,0) \ J(1,6,0), `e2_5', J(1,10,0) \ J(4,11,0), I(4), J(4,6,0)
mat `temp4'=`e4_6',J(1,15,0) \ J(1,6,0), `e3_5', J(1,10,0) \ J(1,11,0), `e2_4', J(1,6,0) \ J(3,15,0), I(3), J(3,3,0)
mat `temp5'=`e5_6',J(1,15,0) \ J(1,6,0), `e4_5', J(1,10,0) \ J(1,11,0), `e3_4', J(1,6,0) \ J(1,15,0), `e2_3', J(1,3,0) \ J(2,18,0), I(2), J(2,1,0)
mat `temp6'=`e6_6',J(1,15,0) \ J(1,6,0), `e5_5', J(1,10,0) \ J(1,11,0), `e4_4', J(1,6,0) \ J(1,15,0), `e3_3', J(1,3,0) \ J(2,19,0), I(2)
mat Dn=`temp1' \ `temp2' \ `temp3' \ `temp4' \ `temp5' \ `temp6'
exit
}
end



*********************************
** Variance decomposition      **
*********************************
**
** This will generate matrix D with variance decompositions
** algorithm:
** for each time s, for each variable j : first j loop generates MSEj as sum over t=0...s-1 
** of  At*pj*pj'*At (generated in the inside loop t) 
** then MSEs is sum over MSEj for time s (MSEs is formula (11.5.7) in Hamilton p.324)
** second j loop generates decompositions (ratios):
** Dj is a column of decompositions w.r.t variable j (each row in a column is decomposition 
** for each of the row variables), Ds is all Dj stacked horisontally and finally D is 
** the output matrix (staked vertically all Ds for all times s.)
**
** takes one parameter - number of period to generate decompositions for, default=20
**
capture program drop decomp
program define decomp

capture mat drop D  
matrix P=cholesky(uu)
global R=$P*$G   /* R is the dimension of the companion matrix */

if $P>1 {
  mat J=I($G), J($G, $R-$G,0) /* J matrix used to extract nesessary portion of A */
} 
else{
  mat J=I($G)           /* if P=1 - one lag VAR, J==I - no need to extract anything */
}
local bigs `1'                  /* total number of periods - given by the parameter */
 
*if "`1'"==""{
*   local bigs=20
*}     /* default=20    */


local gs=`bigs'*$G              /* size of the big D matrix */
if `gs'>200 {
  set matsize `gs'
}

tempname A0
mat AS=I($R)              /* Big RxR matrix -at each stage S it is A^s  */ 
mat `A0'=I($G)            /* this is GxG identity - before the first product */

***** loop over s *******

local s=1                 /* start with time one -need A0=I */
di "Variance decomposition: s = " _c
while `s'<=`bigs' {       /* time s shock */

*** this will only be calculated for round s (up to bigs)  s=10, 20, 30 etc ***

*if `s'/10==int(`s'/10) {  // by Arlion
  di "`s'," _c
  mat MSEs=J($G,$G,0)            /* starting value for total MSE for period s */
  local j=1
  while `j'<=$G {              /* response to j's variable */
    mat pj=P[1... ,`j']          /* extract jth colimn of matrix P */
    mat MSE`j'=J($G,$G,0)        /* matrix of zeros - starting value for MSEj */
 
        local t=0                  
        while `t'<=`s'-1 {         /* loop over t=1.. s-1 */
                                   /* max t is always one period less then s, A0=I, A1=A^1 */
        mat temp=`A`t'' * pj * pj ' * `A`t'''  
        mat MSE`j'=MSE`j'+temp     /* sum variance over t periods */ 
        *di " t=`t' this is temp = A`t'* p`j'*p`j' '*A`t' "
        *mat list temp
        local t=`t'+1 
        }

    mat MSEs=MSEs+MSE`j'         /* accumulating MSEs as sum of MSEj; MSEs is GxG */
    mat MSE`j'=vecdiag(MSE`j')  /* keep only diagonal elements after pass j is finished */
    local j=`j'+1 
   }

  mat MSEs=vecdiag(MSEs)                 /* make a row vector of total MSEs */

*** generate decompositions for each j for current s, then stack together to get Ds ***

  mat time=J($G,1,`s')                   /* will store time for graphing time==s */
  mat rownames time= $names              /* name rows  of time with original variable names */ 
  mat Ds=time      /* Ds is staked decompositions for time s start with vector of time only*/


  local j=1
  while `j'<=$G {                     /* response to j's variable */
     element Dj = MSE`j' / MSEs       /* variance ratio wrt j th variable  */
     mat drop MSE`j'
     mat Dj=Dj'                       /* make it a column vector - to stack */
     mat Ds=Ds, Dj                   /* Ds is accumulating columns of Dj */
     local j=`j'+1 
   }
  mat D=nullmat(D) \ Ds                  /* stack vertically for all times */ 
*} /* end  of IF */  // by Arlion

tempname A`s'                            /* generate next As */
mat AS=AS*A                              /* this is big RxR - companion in power s (rolling)*/  
mat `A`s''=J * AS * J'                   /* this is GxG - extracted the right matrix -keep*/
local s=`s'+1 
}

*di ""
di _n "Variance-decompositions: percent of variation in the row variable explained by column variable"
mat drop MSEs pj time Ds Dj temp AS J P
mat colnames D= s $names
mat list D, format(%6.3f)  // Add by Arlion , format(%6.3f)

end

**********************
** program element  **
**********************

capture program drop element
program define element
 * this program will perform element by element operation on matricies
 * possible functions will be +, -, *, /
 * the format is
 * element  output = input1 * input2     - for multiplication
 * element  output = input1 / input2     - for division
 * where * is in place of the operation that is needed to perform
 /* parameters 1 - output matrix
                2 - equal sign, for better readability
                3 - input matrix 1
                4 - operation to perform 
                5 - input matrix 2  */
  * both input patricies must be same size - for now

local input1="`3'"    /* unload input vector into name input */
local input2="`5'"
local o="`4'"           /* operation */
local output="`1'"
local rows=rowsof(`input1')
local cols=colsof(`input1')
mat `output'=`input1'   /* create "dummy" matrix which then will be replaced */
forvalues i=1/`rows'{
  forvalues j=1/`cols'{
     if "`o'"=="/" & `input2'[`i',`j']==0 { 
	    di in r "division by zero in `i' row `j' col" 
     }  
	 else{
	    mat `output'[`i',`j']=`input1'[`i',`j']`o'`input2'[`i',`j']
	 }
  }
}
end


*-----------------------
*-如下程序由 Arlion 添加
*-----------------------

capture program drop pavr_helm
program define pvar_helm
*
* This program will do Helmert transformation for a list of variables
* NOTE:  must have variables named id, year   
* to use enter >> helm var1 var2...
* new variables will be names with h_ in front h_var1  and so on
*
qui while "`1'"~="" {
*gsort id -year                /*sort years descending */
gsort $panelvariable -$timevariable
tempvar one sum n m w 
* capture drop h_`1'         /* IF the variable exist - it will remain and not generated again */
gen `one'=1 if `1'~=.             /*generate one if x is nonmissing */
qui by $panelvariable: gen `sum'=sum(`1')-`1' /*running sum without current element */
qui by $panelvariable: gen `n'=sum(`one')-1     /*number of obs included in the sum */
replace `n'=. if `n'<=0             /* n=0 for last observation and =-1 if
                                   last observation is missing*/
gen `m'=`sum'/`n'                 /* m is forward mean of variable x*/
gen `w'=sqrt(`n'/(`n'+1))         /* weight on mean difference */
capture gen h_`1'=`w'*(`1'-`m')             /* transformed variable */ 
sort $panelvariable $timevariable
mac shift
}
end


*==========================*
*  GMM PROGRAM             *
*==========================*
* this will do system GMM for any number of equations (including 1 equation)
* 
* TO USE : must define global lists with all variables in equations 
*          dep.variables must be in lists y1 y2...
*          regressors must be in x1 x2 ... and instruments in z1 z2 ...
*          must define global macro G which has number of equations
* for example :
* global y1="ik"                             /* EQ 1: dep.var */
* global x1="const l.ik sk"                  /* EQ 1: rhs variables */
* global z1="const l.ik l.sk l2.ik l2.sk"    /* EQ 1: instruments (include exog vars here)  */  
* global G=1
*
* after exit this program will leave behind matrices: b2sls bgmm var std
* results will be posted to Stata so tests can be done using Stata's command
* for ex: test [eq1_]sk=[eq2_]h_sk   
*

*-Modified by Lian Yu-jun, 2011.08.03
* eclass

capture program drop sgmm2
program define sgmm2, eclass
version 8.0          // Arlion, original: version 6.0
*set trace on

di _n in green "System-GMM started: " in yellow "$S_TIME"

/* getting number of variables in each equation */
local l = 0       /* total number of instruments for the system */
local k = 0       /*                 regressors                 */
local g=1
while `g'<=$G {
  local l`g' : word count ${z`g'} 
  local k`g' : word count ${x`g'} 
  local l=`l'+`l`g''
  local k=`k'+`k`g''
  local g=`g'+1 
}
*di "locals l1=`l1' l2=`l2' k1=`k1' k2=`k2' total l= `l' k=`k'" 

/* accumultaing matrices */

tempname zy temp
*di in b "accumulating matrices equation " _c  // Arlion
local g=1
while `g'<=$G {
  *di "`g'," _c
  tempname zz`g' zx`g' zy`g'
  qui mat accum `temp'= ${z`g'} ${x`g'}, nocon       /* equation g */
  mat `zz`g''=`temp'[1..`l`g'', 1..`l`g'']
  mat `zx`g''=`temp'[1..`l`g'', `l`g''+1...]
  qui mat accum `temp'= ${y`g'} ${z`g'}, nocon
  mat `zy`g''=`temp'[2...,1]
  local listzx="`listzx' `zx`g''"   /* accumulate lists of all zx and zz matrices */
  local listzz="`listzz' `zz`g''"
  mat `zy'= nullmat(`zy') \ `zy`g''    /* accumulating ZY - it is not diagonal */
  local g=`g'+1 
}

*di in b "calculating b2sls"

/* System 2SLS - should be equal to equation by equation */

tempname zx zz invz
diag `zx' = `listzx'
diag `zz' = `listzz'
mat `invz'=inv(`zz')
mat b2sls=inv(`zx'' * `invz' * `zx' ) * `zx'' * `invz' * `zy'

*mat list b2sls
mat `temp'=b2sls

/* generating uhats for each equation g */

local g = 1
while `g'<=$G {
  tempname b`g'           /* extract coefficients for equation g into b`g' */
  tempvar t`g' u`g'
  mat `b`g''=`temp'[1..`k`g'',.]'           /* note bg's are row vectors! */
  capture mat `temp'=`temp'[`k`g''+1...,.]  /* leave coeficients for remaining 
                                             equations in temp */
  mat score `t`g''=`b`g''
  qui gen `u`g''=${y`g'}-`t`g''
  local listu "`listu' `u`g''" /* this is the list of all residuals */
  local g=`g'+1
}

/* calculating big ZuuZ matrix */

* di in b "calculating big ZuuZ matrix"   // Arlion modify

local g=1                         /* equation indicator */
while `g' <=$G {
   tokenize ${z`g'}              /* get names of instruments in separate macros */
   local i=1                     /* instrument indicator */                 
   while "``i''" != "" {         /* go over list of instruments for  equation g */ 
     *di "g=`g' i=`i' zi=``i''"   /* ``i'' will put name of instrument variable */
      tempvar z`g'_`i'
      qui gen `z`g'_`i''=``i''*`u`g''      /* generating tempvar= Zi*u */
      local list "`list' `z`g'_`i''"  /* list of all instruments from all equations */
      *global IVs "`list'"   // by Arlion
	  *dis "Instruments used: " "`list'"
      local i = `i' + 1   
   }
   drop `u`g''                       /* do not need ug after all Zi *ug is calculated */
   local g=`g'+1
}

* di in b "finished accumulating ZuuZ"    // Arlion modify

*di "`list'"     // Arlion 0803
local nlist : word count `list'
*di "Number of instruments used: " in y "`nlist'"   // Arlion 0803

tempname ZuuZ W tstat out output
qui mat accum `ZuuZ'=`list' , nocons    /* this is bigZ consists of all equation zuuz's */

drop `list'             /* do not need these variables anymore */
*drop `listu'            /* no, these errors are already dropped above */


local nused=_result(1)      /* number of obs used for this matrix is the 
                               number of obs for the system -when all 
                               variables in each equation are nonmissing*/
global T=`nused'
mat `W'=inv((1/`nused')*`ZuuZ')
mat W=`W'
*mat list `ZuuZ'


mat bgmm=inv(`zx'' * `W' * `zx')*`zx'' * `W' * `zy'
mat var=`nused'*inv(`zx'' * `W' * `zx')            /* variance-covariance matrix */


*-----------------------add by Arlion------------------
tempname var0 V0 V  b
mat `var0' = var
local g=1
while `g'<=$G {
  mat `V0'_`g'=`var0'[1..`k`g'',....] // pick coefficients for equation g, Arlion _`g'
  *dis "`${y`g'} : ${x`g'}'"
  mat rownames `V0'_`g'=${x`g'}       // add row names, Arlion
  mat roweq    `V0'_`g'=${y`g'}       // add equation names, Arlion
  mat `V' = nullmat(`V') \ `V0'_`g'   // Arlion add
  capture mat `var0'=`var0'[`k`g''+1...,.]   /* matrix var0 is what is left for 
                                      the rest of equations if nothing is
                                      left returns error which I capture*/
  *mat list `V0'_`g', noh
  *di in gr _dup(78) "-"
  local g=`g'+1
}

local rownames:  rowfullnames `V'  // record the full colnames, transfer to mat b and V, Arlion
mat `b' = bgmm' 
mat colnames `b' = `rownames'
mat colnames `V' = `rownames'
eret post `b' `V', obs(`nused') depname("$depvarlist") //esample(xxx_touse) by Arlion
eret local  cmd pvar2     // by Arlion
*eret matrix b = `b'  //by Arlion 2012.07.04
*eret matrix V = `V'  //by Arlion 2012.07.04
*di _n in g "System GMM Results"
*di in g "number of observations used : " in y  "`nused'" _n
*eret display
*--------------------------------------------------------


*-|V| the determinant of variance-covariance matrix of residuals

mat `temp'=bgmm

local listu=""
local g = 1

while `g'<=$G {
  tempname b`g'           /* extract coefficients for equation g into b`g' */
  tempvar t`g' u`g'
  mat `b`g''=`temp'[1..`k`g'',.]'           /* note bg's are row vectors! */
  capture mat `temp'=`temp'[`k`g''+1...,.] 
  mat score `t`g''=`b`g''
  qui gen `u`g''=${y`g'}-`t`g''    
  capture drop u`g'
  qui gen u`g'=${y`g'}-`t`g''    /* NOTE - added permenent variable with residual */

  local listu "`listu' `u`g''" /* this is the list of all residuals - use to calculate u'u */
  local listup "`listup' u`g'"  /* list of permanent variables with residuals */
  local nameu "`nameu' eq`g'"  /*  list of equation numbers - to name rows and columns of uu */
  local g=`g'+1
}
if $G>1 {  
  qui mat accum uu=`listup' , nocons    /* this is u'u for all equations */
  mat uu=(1/`nused')*uu
}
         
  local detSigma = det(uu)  // |V|
 
  
*=========To calculate AIC SBIC and HQIC =====================
   tempname M N T aic sbic hqic m2pi k p NN lnNN detsig
   scalar `p' = $P          // 滞后阶数 lag orders
   scalar `M' = $G          // number of equations
   scalar `m2pi'= `M'*ln(2*_pi) 
   scalar `N' = $NN
   scalar `T' = $TT
   scalar `NN'  = $T        // number of observations used in estimation
   *scalar `NN' = `N'*(`T'-`p')
   *scalar `lnNN'= ln(`NN')
   *scalar `k'   = `M'^2*`p'  // number of parmameters
   scalar `k'   = `M'^2*`p' //+ `M'*`N'
   

   if "`timeeffect'" == ""{
     *scalar `k' = (`M'*`p'+`N'-`p'-1)*`M'  // number of parmameters
	 scalar `k'   = `M'^2*`p' + `M'*`N'
   }
   else{
     *scalar `k' = (`M'*`p'+`N'+`T'-`p'-1)*`M' 
	 scalar `k'   = `M'^2*`p' + `M'*(`N'+`T')
   }
  
   scalar `detsig' = det(uu) // det(uu) = |V| 
  
   *local ln_det_V = ln(`detsig') // ln|V|

   *-AIC
     scalar `aic'  = `m2pi' + `M' + ln(`detsig') + 2*`k'/`NN'
   *-BIC
     scalar `sbic' = `m2pi' + `M' + ln(`detsig') + ln(`NN')*`k'/`NN'
   *-HQIC
     scalar `hqic' = `m2pi' + `M' + ln(`detsig') + 2*ln(ln(`NN'))*`k'/`NN'

 
 /*
   *-----------------------Lutkepohl (2005) -------------------------------------
   *-see: Lutkepohl, H. 2005. 
   *      New Introduction to Multiple Time Series Analysis. New York: Springer.
   *-[TS] pp.436 (varsoc)
     *-AIC
       scalar `aic'  = ln(`detsig') + 2*`p'*`M'^2/`NN'
     *-BIC
       scalar `sbic' = ln(`detsig') + ln(`NN')*`p'*`M'^2/`NN'
     *-HQIC
       scalar `hqic' = ln(`detsig') + 2*ln(ln(`NN'))*`p'*`M'^2/`NN'   
   *-----------------------------------------------------------------------------
 */
 
 
*=============================================================


    #delimit ;
	 di _n in y  "==================================================";   
     di    in gr " Panel Vector Auto-Regression: System-GMM Results" ;
	 di    in y  "==================================================";
     di in gr "Group variable: " in ye abbrev("$panelvariable",12) in gr
             _col(49) "Number of groups" _col(68) "="
             _col(70) in ye %9.0g $NN
             _n in g "Number of obs" _col(14) " =" _col(16) in ye %6.0f `nused' 
			 _col(49) in g "Number of equations" _col(68) "="
			 _col(70) in y %9.0g $G
			 _n in g "Number of instruments used: " in y "`nlist'" 
			 _n       in g "AIC = "  in y %6.5f `aic' 
			 _col(18) in g "BIC = "  in y %6.5f `sbic'
			 _col(35) in g "HQIC = " in y %6.5f `hqic'			 
			 ;
	dis ;
	#delimit cr	

    eret display
	
  *-工具变量列表	
	dis in g "Instruments used: " in y "$z1"
	dis in g "Note: all equations use the same set of Instruments listed above"
  *-时间效应提示
	if "$timeeffect"=="Yes"{
	  dis in g "Time effects have be demeaned: x[it]* = x[it] - mean_x[t] + mean_x"
	}

  *-ereturn values
    ereturn scalar AIC = `aic'
    ereturn scalar BIC = `sbic'
    ereturn scalar HQIC= `hqic'	
	
	
/*  Love's codes
mat `temp'=vecdiag(var)'  
mat list `temp'   
matroot `temp' std     /* calculate square root of vector var, place in std */
element `tstat' = bgmm / std    /* caclutating t-statistics */

mat tstat=`tstat'   /* temporary */

/* printing output */

*mat `out'=b2sls,bgmm,std,`tstat'
*mat colnames `out'=b_2SLS b_GMM se_GMM t_GMM

*mat drop b2sls
mat `out'=bgmm,std,`tstat'
mat colnames `out'= b_GMM se_GMM t_GMM

di in g "_______ Results of the Estimation by system GMM_________"
di in g "number of observations used : " in y  "`nused'" 

local g=1
while `g'<=$G {
  di in gr _dup(78) "-"
  di in g "EQ`g': dep.var     : " in y  "${y`g'}" 
  *di in g "     regressors  : " in y "${x`g'}"        // Arlion, drop *
  *di in g "     instruments : " in y "${z`g'}"        // Arlion, drop *
  mat `output'_`g'=`out'[1..`k`g'',.]          // pick coefficients for equation g, Arlion _`g'
  *dis "`${y`g'} : ${x`g'}'"
  *mat rownames `output'_`g'=${x`g'}    // add row names, Arlion
  *mat roweq    `output'_`g'=${y`g'}    // add equation names, Arlion
  *mat `outnew' = nullmat(`outnew') \ `output'_`g'     // Arlion add
  capture mat `out'=`out'[`k`g''+1...,.]   /* matrix out is what is left for 
                                      the rest of equations if nothing is
                                      left returns error which I capture*/
  mat list `output'_`g', noh
  di in gr _dup(78) "-"
  local g=`g'+1
}
*/

  
/*
tempname temp2
mat `temp'=bgmm'      /* to post results to STATA for later use, if needed */
mat `temp2'=var
mat post `temp' `temp2'
*mat mlout       /* this can display results easily - but I already have that done */
*/


*============
* hansen test
*============

  di _n(2) in y  "======================================"
  di       in g  " Hansen Test for over-identification" 
  di       in y  "======================================" _n


/* need to calculate new residuals from the gmm estiamtor - replace old ones */
/*
mat `temp'=bgmm

local listu=""
local g = 1

while `g'<=$G {
  tempname b`g'           /* extract coefficients for equation g into b`g' */
  tempvar t`g' u`g'
  mat `b`g''=`temp'[1..`k`g'',.]'           /* note bg's are row vectors! */
  capture mat `temp'=`temp'[`k`g''+1...,.] 
  mat score `t`g''=`b`g''
  qui gen `u`g''=${y`g'}-`t`g''    
  capture drop u`g'
  qui gen u`g'=${y`g'}-`t`g''    /* NOTE - added permenent variable with residual */

*di " score for equation `g': and residual"
*sum `t`g'' `u`g'' ${y`g'}

  local listu "`listu' `u`g''" /* this is the list of all residuals - use to calculate u'u */
  *local listup "`listup' u`g'"  /* list of permanent variables with residuals */
  local nameu "`nameu' eq`g'"  /*  list of equation numbers - to name rows and columns of uu */
  local g=`g'+1
}
*/
*set trace off

if `k'<`l' {
  tempname uZ H h prob
  local g=1
  while `g'<=$G {
    mat vecaccum `temp' = `u`g'' ${z`g'} , nocons
    mat `uZ'=nullmat(`uZ'),`temp'        /* uZ is long row of all uZi */
    local g=`g'+1 
  }
  mat `H'=(1/`nused')* `uZ' * `W' * `uZ''
  scalar `h'=`H'[1,1]
  local df=`l'-`k'
  scalar `prob'=chiprob(`df',`h')
  di in g "Hansen H = " in y `h' in g " with df of " in y "`df'" in g " and prob = " in y `prob'  
}

else{
   di in g "just identified - Hansen statistic is not calculated "
}

if $G>1 {  /* correlation matrix is only calculated if more then 1 equation is specified */
**** generating U'U matrix of variance-covariance of resuduals *****
*di "these are summary  of residuals:"
*sum `listu' $names

  *qui mat accum uu=`listup' , nocons    /* this is u'u for all equations */
  *mat uu=(1/`nused')*uu
  if "$names"~="" {       
     local nameu "$names"        
  } 
  * for VAR only - $names is the list of all Y variable names 
  * for others - make the list later using Y variables, for now will use eq1 eq2 ...
   mat colnames uu = `nameu'     
   mat rownames uu = `nameu'
  
if "$residual" != ""{
  
  di _n(2) in y  "=================================="
  di       in g  " Variance-covariance of residuals " 
  di       in y  "=================================="   
   
   mat list uu

  di _n(2) in y  "==============================="
  di       in g  " Residuals correlation matrix" 
  di       in y  "==============================="
   pwcorr `listup' , sig star(0.05)
   dis in g "Note: " in g "The second line is p-value; * significant at 5% level" _n
}

}
* drop `listup'   /* dropping permanent variables ug */

/*
di " "
di in g "Variance-covariance matrix of residuals (u'u):"
mat list uu
di " "

mat `temp'=vecdiag(uu)   /* vector of mean squared errors of regression */
mat `temp'=`temp'
matroot `temp' rmse
di in g "Mean squared errors of regression (sqrt of diagonal elements of u'u)"
mat list rmse
*/

di " "
di in g "System-GMM finished: " in y "$S_TIME" _n

end



*******************************************
*** Auxilary programs needed to run GMM ***
*******************************************


capture program drop diag
program define diag
** this will construct block diagonal matrix from the matrices supplied as list of parameters
** TO USE:  diag outname = zx1 zx2 zx3 
** outname will be the name of big block diagonal matrix 
local out `1'  /* get name of the output matrix into `out' local */
mac shift      /* skip next parameter - it is equal sign */ 
mac shift
tempname a temp1 temp2
mat `a'=`1'
mac shift
  local i 1      /* i is counter of equations - to use in naming columns and rows*/
*   matrix roweq `a' = eq1_
*   matrix coleq `a' = eq1_
while "`1'"~="" {
mat `temp1'=`a', J(rowsof(`a'),colsof(`1'),0)
mat `temp2'=J(rowsof(`1'),colsof(`a'),0), `1'
  local i=`i'+1                /* all idented lines  are just for*/
*   matrix roweq `1' = eq`i'_    /* corret labeling of variables and equations */
*   matrix coleq `1' = eq`i'_
   local cola : colnames(`a')
   local rowa : rownames(`a')
   local col1 : colnames(`1')
   local row1 : rownames(`1')
   local reqa : roweq(`a')
   local req1 : roweq(`1') 
   local ceqa : coleq(`a')
   local ceq1 : coleq(`1')   
   mat `a'= `temp1' \ `temp2'
   mat colnames `a' = `cola' `col1' 
   mat rownames `a' = `rowa' `row1'
   mat roweq `a'=`reqa' `req1'
   mat coleq `a'=`ceqa' `ceq1'
mac shift
}
mat `out'=`a'
end



capture program drop matroot
program define matroot
 * this program calculates matrix with square roots of each element in the
 * incoming matrix
 * to use :  matroot input output
local input="`1'"    /* unload input vector into name input */
local output="`2'"
local rows=rowsof(`1')
local cols=colsof(`1')
mat `output'=`input'   /* create "dummy" matrix which then will be replaced */
forvalues i=1/`rows'{
  forvalues j=1/`cols'{
     if sqrt(`input'[`i',`j'])==. { 
	    di in r "negative values in input matrix - cannot take sqrt" 
     }  
	 else{
	    mat `output'[`i',`j']=sqrt(`input'[`i',`j'])
	 }
  }
}
end



capture program drop correl
program define correl
 * this program will generate correlation matrix from the covariance matrix

local input1="`3'"    /* unload input vector into name input */
local input2="`5'"
local o="`4'"           /* operation */
local output="`1'"
local rows=rowsof(`input1')
local cols=colsof(`input1')
mat `output'=`input1'   /* create "dummy" matrix which then will be replaced */
forvalues i=1/`rows'{
  forvalues j=1/`cols'{
     if "`o'"=="/" & `input2'[`i',`j']==0 { 
	    di in r "division by zero in `i' row `j' col" 
     }  
	 else{
	    mat `output'[`i',`j']=`input1'[`i',`j']`o'`input2'[`i',`j']
	 }
  }
}
end



*==============================
*   Granger causality tests
*==============================

** version 1.0  05July2012
** Based on vargranger.ado
** Author: Lian Yu-jun
** E-mail: arlionn@163.com
** Homepage: http://www.lingnan.net/intranet/teachinfo/dispuser.asp?name=lianyj

program define pvar2_granger, rclass 
    version 8.0

    *syntax, SEParator(numlist integer >=0 max=1)]

	/*
 if $P<2{
	dis as error "to perform Granger causality tests, # should no less than 2 in option lag(#)."
	exit 
 }
	*/

* -------------to transfer lags from "4" to "1 2 3 4", string format------
local lags "$P"
foreach i of numlist 1(1)`lags'{
    local ti "`i'"
    local lags "`lags' `ti'"
}
local L = length(`"`lags'"')
local lags=  substr( `"`lags'"' , 2, `L')
*-------------------------------------------------------------------------
 
    local vlist "$depvarlist"
	global deplist ""
	foreach v of local vlist{
	   global deplist "$deplist h_`v'"
	}
	 
    local varlist "$deplist"
    local eqlist  "$deplist"     

    local j  1
    local j2 1
    di 
    foreach eqn_ts of local varlist {
        foreach var of local varlist {
            if "`eqn_ts'" != "`var'" {
                local eqn : word `j2' of `eqlist'   
                local eqnames "`eqnames' `eqn' "

                foreach i of local lags {
                  local gc_`j' "`gc_`j'' [`eqn']L`i'.`var'"
                  local gc2_`j2' "`gc2_`j2'' [`eqn']L`i'.`var'" 
                }

                local eqstripe "`eqstripe' `eqn' "
                local varstripe "`varstripe' `var' "
                local j = `j'+1 
            }   
        }
        local j2 = `j2' + 1
    }


    local neqs : word count `varlist'
    local neqsm1 = `neqs' -1
    
    local eqnst2 "`eqstripe'"
    local varst2 "`varstripe'"
    local i3 0
    local i4 0
    forvalues i = 1/`neqs' {
        forvalues i2 = 1/`neqsm1' {
            local ++i3
            local ++i4

            local gc3_`i3' " `gc_`i4'' "
            
            gettoken eqnt eqnst2: eqnst2
            gettoken vart varst2: varst2

            local eqstripe2 `eqstripe2' `eqnt'
            local varstripe2 `varstripe2' `vart'
        }
        local ++i3
        local gc3_`i3' " `gc2_`i'' "

        local eqstripe2 `eqstripe2' `eqnt'
        local varstripe2 `varstripe2' ALL
    }

    local eqnst2 "`eqstripe2'"
    local varst2 "`varstripe2'"
        
	tempname results row
	
    forvalues i=1/`i3' {
       qui test `gc3_`i''
       mat `row' =( r(chi2),  r(df), r(p))
       mat `results' = ( nullmat(`results') \ `row')
    }   

    matrix colnames `results' = chi2 df p
    matrix rownames `results' = `varstripe2'
    matrix roweq `results' = `eqstripe2'

    DISP , mname(`results') //separator(`separator')
	
   * _estimates unhold `pest'
    ret matrix gstats  `results'
end


program define DISP
    syntax , mname(name) //separator(numlist integer max=1 >=0)
    CKmat `mname'
    local eqnst : roweq    `mname'
    local varst : rownames `mname'
    di as text "{col 4}Granger causality Wald tests for Panel VAR"
    tempname table
    .`table' = ._tab.new, col(5) separator($G)
    .`table'.width      |19     19|     9   6   12| 
    .`table'.strcolor   green   green   .   .   .
    .`table'.numfmt     .   .   %7.6g   %5.0f   %6.3f
    .`table'.pad        .   .   1   .   2
    .`table'.sep , top
    .`table'.titles "Equation"      /// 1
            "Excluded"      /// 2 
            "chi2 "         /// 3
            "df"            /// 4
            "Prob > chi2"       //  5
    .`table'.sep , mid

    local i = 1
    foreach eqa of local eqnst {
        local vna : word `i' of `varst'
        local eqa = abbrev("`eqa'",17)
        local vna = abbrev("`vna'",17)

        .`table'.row    "`eqa'"         /// 1
                "`vna'"         /// 2
                `mname'[`i',1]      /// 3
                `mname'[`i',2]      /// 4
                `mname'[`i',3]      //  5
                    
        local ++i           

    }

    .`table'.sep , bot

end


program define CKmat
    syntax name(name=mname)
    capture confirm matrix `mname'
    if _rc > 0 {
        di as err "results matrix not found"
        exit 498
    }
end




*=================================
*- SOC: selection of lag orders
*=================================

** version 1.0 10sep2005
** based on varsoc.ado

program define pvar2_soc, eclass sort
    version 8.0
    args lag
        
local separator 0 
   
local varlist "$depvarlist"   

qui tsset
local T = r(tmax)-r(tmin)+1
local panelvar = r(panelvar)
local timevar = r(timevar)

*local N_min = r(imin)
*local N_max = r(imax)
local T_min = r(tmin)
local T_max = r(tmax)
local M : word count depvarlist


qui xtdes
local N = r(N)                          /*update version, by Arlion*/
       
local maxlag = `lag'
    if `maxlag' > `T'-1 {
        di as err "maxlag(`maxlag') not feasible with " `T' " periods "
        exit 198
    }   
    else if `maxlag'<2{
        di as err "maxlag() must be at least 2"
        exit 198
    }


    tempname  stats 
    mat `stats' = J(`maxlag',4,0)
    
    qui tsset `panelvar' `timevar'
    forvalues i=1(1)`maxlag' {
        qui pvar2 `varlist' , lag(`i')   //if `touse'      
        mat `stats'[`i',1] = (`i', e(AIC), e(BIC), e(HQIC) )

    }

    matrix colnames `stats' = lag AIC BIC HQIC

	* mat list `stats' 

    DISP2, stats(`stats') separator(`separator') 
                                  /*Dis the main matrix, by arlion*/

    ereturn matrix soc `stats' 

end 


program define DISP2 
    
    syntax , stats(name) separator(numlist max=1 integer >=0) /*
        */ [level(integer $S_level) ]

    local rows = rowsof(`stats')

    local length 79 

    tempname table

    .`table' = ._tab.new, col(8) scolor(yellow) lcolor(green)  ///
                          separator(`separator')

    .`table'.width |4|  /// 1
            9   /// 4
            1   /// 5
            9   /// 6
            1   /// 7
            9       /// 8
            1   /// 9
            1|      //  10

    .`table'.numfmt %3.0f   /// 1
            %8.7g   /// 4
            .   /// 5
            %8.7g   /// 6
            .   /// 7
            %8.7g   /// 8
            .   /// 9
            .   //  10

    .`table'.pad    .   /// 1
            1   /// 4
            .   /// 5
            1   /// 6
            .   /// 7
            1   /// 8
            .   /// 9
            .   //  10

    .`table'.numcolor green . . . . . . . 
    .`table'.sep, top
    .`table'.titles "lag"   /// 1
            "AIC "  /// 2
            ""  /// 3
            "BIC " /// 4
            ""  /// 5
            "HQIC " /// 6
            ""  /// 7
            ""  //  8

    .`table'.sep, mid

    tempname aics hqics sbics aicv hqicv sbicv
    
    local rows1 = `rows' -1

    local  aics   `rows'
    local  hqics  `rows'
    local  sbics  `rows'
    
    forvalues i = `rows1'(-1)1 {
        local aics  = cond(`stats'[`i',2] < `stats'[`aics',2],  `i', `aics')
        local sbics = cond(`stats'[`i',3] < `stats'[`sbics',3], `i', `sbics')
        local hqics = cond(`stats'[`i',4] < `stats'[`hqics',4], `i', `hqics')
    }

    forvalues i = 1/`rows' {
        local aics`i'  = cond(`i'==`aics',  "*", " ")
        local sbics`i' = cond(`i'==`sbics', "*", " ")
		local hqics`i' = cond(`i'==`hqics', "*", " ")
    }   
    
    local cnt 0
    forvalues i = 1/`rows' {
        local ++cnt
        local aic_el  : display %8.7g `stats'[`i',2] "`aics`i''"
        local sbic_el : display %8.7g `stats'[`i',3] "`sbics`i''"
        local hqic_el : display %8.7g `stats'[`i',4] "`hqics`i''"
        .`table'.row    `stats'[`i',1]      /// 1
                `stats'[`i',2] "`aics`i''"  /// 5
                `stats'[`i',3] "`sbics`i''" /// 7
                `stats'[`i',4] "`hqics`i''" /// 9
                ""          //  10
    }
    
    .`table'.sep, bot
    
end
