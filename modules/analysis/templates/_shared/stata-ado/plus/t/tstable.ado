* Integrated commands for time series smoothness test (DF/ADF/PP/DF-GLS)

capture program drop tstable

program define tstable
	version 17.0
	syntax varlist
 
 
foreach var in `varlist' {
 local variable "`var'"
 di _n _n "---`variable'---"
  //DF检验
 di _n
 qui dfuller `var',tr reg
 local p=r(p)
 while `p'>0.05{
  qui dfuller `var',dr reg
  local p=r(p)
  while `p'>0.05{
   qui dfuller `var', nocons reg
   local p=r(p)
   while `p'>0.05{
    di "DF检验结果：`variable'非平稳"
    local p=0.05
   }
   while `p'<0.05{
    di "DF检验结果：`variable'不含截距项和趋势项平稳"
    local p=0.05
   }
   local p=0.05
  }
  while `p'<0.05{
   mat a=r(table)
   local pcons=el(a,4,2)
   while `pcons'>0.05{
    qui dfuller `var', nocons reg
    local p=r(p)
    while `p'>0.05{
     di "DF检验结果：`variable'平稳性未知，不含截距项时非平稳"
     local p=0.05
    }
    while `p'<0.05{
     di "DF检验结果：`variable'不含截距项和时间趋势项平稳"
     local p=0.05
    }
    local pcons=0.05
   }
   while `pcons'<0.05{
    di "DF检验结果：`variable'含截距项平稳"
    local pcons=0.05
   }
   local p=0.05
  }
  local p=0.05
 }
 while `p'<0.05{
  mat a=r(table)
  local ptren=el(a,4,2)
  while `ptren'<0.05{
   di "DF检验结果：`variable'趋势平稳"
   local ptren=0.05
  }
  while `ptren'>0.05{
   qui dfuller `var',dr reg
   local pcons=el(a,4,2)
   while `pcons'>0.05{
    qui dfuller `var', nocons reg
    local p=r(p)
    while `p'>0.05{
     di "DF检验结果：`variable'平稳性未知，不含截距项时非平稳"
     local p=0.05
    }
    while `p'<0.05{
     di "DF检验结果：`variable'不含截距项和时间趋势项平稳"
     local p=0.05
    }
    local pcons=0.05
   }
   while `pcons'<0.05{
    di "DF检验结果：`variable'含截距项平稳"
    local pcons=0.05
   }
   local ptren=0.05
  }
  local p=0.05
 }
 
 //ADF检验
 di _n "ADF检验结果：以(c,p,t)表示"
 qui su `var'
 local i=int(12*(r(N)/100)^(1/4))
 local i=`i'-1
 while `i'>0{
  qui dfuller `var',l(`i') tr reg
  local p=r(p)
  while `p'<0.05{
   local result "无单位根"   
   local p=0.05
   }
  while `p'>0.05{
   local result "有单位根"    
   local p=0.05
   }
  mat a=r(table)
  local pl=el(a,4,`i'+1)
  while `pl'<0.05{
   di "(1,1,`i')，`variable'`result'"
   local i=0
   local pl=0.05
   }
  while `pl'>0.05{
   local i=`i'-1
   local pl=0.05
  }
 }
 local i=int(12*(r(N)/100)^(1/4))
 local i=`i'-1
 while `i'>0{
  qui dfuller `var',l(`i') dr reg
  local p=r(p)
  while `p'<0.05{
   local result "无单位根"    
   local p=0.05
   }
  while `p'>0.05{
   local result "有单位根"    
   local p=0.05
   }
  mat a=r(table)
  local pl=el(a,4,`i'+1)
  while `pl'<0.05{
   di "(1,0,`i')，`variable'`result'"
   local i=0
   local pl=0.05
   }
  while `pl'>0.05{
   local i=`i'-1
   local pl=0.05
  }
 }
 local i=int(12*(r(N)/100)^(1/4))
 local i=`i'-1
 while `i'>0{
  qui dfuller `var',l(`i') nocons reg
  local p=r(p)
  while `p'<0.05{
   local result "无单位根"    
   local p=0.05
   }
  while `p'>0.05{
   local result "有单位根"    
   local p=0.05
   }
  mat a=r(table)
  local pl=el(a,4,`i'+1)
  while `pl'<0.05{
   di "(0,0,`i')，`variable'`result'"
   local i=0
   local pl=0.05
   }
  while `pl'>0.05{
   local i=`i'-1
   local pl=0.05
  }
 }
 
  //PP检验
 di _n "PP检验结果："
 qui pperron `var',tr
 local p=r(pval)
 while `p'<0.05 {
  local result "无单位根"
  local p=0.05
 }
 while `p'>0.05 {
  local result "有单位根"
  local p=0.05
 }
 di "c=1,t=1，`variable'`result'"
 qui pperron `var'
 local p=r(pval)
 while `p'<0.05 {
  local result "无单位根"
  local p=0.05
 }
 while `p'>0.05 {
  local result "有单位根"
  local p=0.05
 }
 di "c=1,t=0，`variable'`result'"
 qui pperron `var',nocons
 local p=r(pval)
 while `p'<0.05 {
  local result "无单位根"
  local p=0.05
 }
 while `p'>0.05 {
  local result "有单位根"
  local p=0.05
 }
 di "c=0,t=0，`variable'`result'"
 
  //DF-GLS检验
 di _n "DF-GLS检验结果："
 qui dfgls `var'
 di "对于最大滞后阶数" r(maxlag) "，SIC最小滞后阶数" r(siclag) "，AIC最小滞后阶数" r(maiclag) "，序贯检验滞后阶数" r(optlag)
 mat a=r(cvalues)
 foreach lags in r(maxlag) r(siclag) r(maiclag) r(optlag) {
  local tau= el(a,r(maxlag)+1-`lags',2)
  local lim= el(a,r(maxlag)+1-`lags',4)
  local lag=`lags'
  while `tau'>`lim'{
   local result "有单位根"
   local tau=1
   local lim=1
  }
  while `tau'<`lim'{
   local result "无单位根"
   local tau=1
   local lim=1
  }
  di "t=1,p=`lag'，`variable'`result'"
 }
 qui dfgls `var',not
 di "对于最大滞后阶数" r(maxlag) "，SIC最小滞后阶数" r(siclag) "，AIC最小滞后阶数" r(maiclag) "，序贯检验滞后阶数" r(optlag)
 mat a=r(cvalues)
 foreach lags in r(maxlag) r(siclag) r(maiclag) r(optlag) {
  local tau= el(a,r(maxlag)+1-`lags',2)
  local lim= el(a,r(maxlag)+1-`lags',4)
  local lag=`lags'
  while `tau'>`lim'{
   local result "有单位根"
   local tau=1
   local lim=1
  }
  while `tau'<`lim'{
   local result "无单位根"
   local tau=1
   local lim=1
  }
  di "t=0,p=`lag'，`variable'`result'"
 }
}

end