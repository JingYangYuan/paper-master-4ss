*! version 1.0.0  12jul2022
program spinst_mus2

  di as smcl "{txt}Installing ..."

  cap noi spinst_mus2_wrk estout http://fmwww.bc.edu/RePEc/bocode/e
  cap noi spinst_mus2_wrk oaxaca http://fmwww.bc.edu/RePEc/bocode/o
  cap noi spinst_mus2_wrk rego http://www.marco-sunder.de/stata/
  cap noi spinst_mus2_wrk ivreg2 http://fmwww.bc.edu/RePEc/bocode/i
  cap noi spinst_mus2_wrk vcemway http://fmwww.bc.edu/RePEc/bocode/v
  cap noi spinst_mus2_wrk st0033_2 http://www.stata-journal.com/software/sj6-3
  cap noi spinst_mus2_wrk ivreg2 http://fmwww.bc.edu/RePEc/bocode/i
  cap noi spinst_mus2_wrk st0108 http://www.stata-journal.com/software/sj6-3
  cap noi spinst_mus2_wrk st0171_1 http://www.stata-journal.com/software/sj11-2
  cap noi spinst_mus2_wrk weakiv http://fmwww.bc.edu/RePEc/bocode/w
  cap noi spinst_mus2_wrk avar http://fmwww.bc.edu/RePEc/bocode/a
  cap noi spinst_mus2_wrk weakivtest http://fmwww.bc.edu/RePEc/bocode/w
  cap noi spinst_mus2_wrk xtscc http://fmwww.bc.edu/RePEc/bocode/x
  cap noi spinst_mus2_wrk xtabond2 http://fmwww.bc.edu/RePEc/bocode/x
  cap noi spinst_mus2_wrk st0035_1 http://www.stata-journal.com/software/sj10-4
  cap noi spinst_mus2_wrk boottest http://fmwww.bc.edu/RePEc/bocode/b
  cap noi spinst_mus2_wrk st0531 http://www.stata-journal.com/software/sj18-2
  cap noi spinst_mus2_wrk gam http://fmwww.bc.edu/RePEc/bocode/g
  cap noi spinst_mus2_wrk gr42_8 http://www.stata-journal.com/software/sj19-3
  cap noi spinst_mus2_wrk grqreg http://fmwww.bc.edu/RePEc/bocode/g
  cap noi spinst_mus2_wrk qreg2 http://fmwww.bc.edu/RePEc/bocode/q
  cap noi spinst_mus2_wrk st0094 http://www.stata-journal.com/software/sj5-4
  cap noi spinst_mus2_wrk spost9_ado https://jslsoc.sitehost.iu.edu/stata
  cap noi spinst_mus2_wrk st0203 http://www.stata-journal.com/software/sj10-3
  cap noi spinst_mus2_wrk moremata http://fmwww.bc.edu/RePEc/bocode/m
  cap noi spinst_mus2_wrk kdens http://fmwww.bc.edu/RePEc/bocode/k
  cap noi spinst_mus2_wrk st0308 http://www.stata-journal.com/software/sj13-3
  cap noi spinst_mus2_wrk xtbalance http://fmwww.bc.edu/RePEc/bocode/x
  cap noi spinst_mus2_wrk spost13_ado https://jslsoc.sitehost.iu.edu/stata
  cap noi spinst_mus2_wrk spost9_legacy https://jslsoc.sitehost.iu.edu/stata
  cap noi spinst_mus2_wrk st0360 http://www.stata-journal.com/software/sj14-4
  cap noi spinst_mus2_wrk hnblogit http://fmwww.bc.edu/RePEc/bocode/h
  cap noi spinst_mus2_wrk qcount http://fmwww.bc.edu/RePEc/bocode/q
  cap noi spinst_mus2_wrk xtbalance http://fmwww.bc.edu/RePEc/bocode/x
  cap noi spinst_mus2_wrk logitfe http://fmwww.bc.edu/RePEc/bocode/l
  cap noi spinst_mus2_wrk qreg2 http://fmwww.bc.edu/RePEc/bocode/q
  cap noi spinst_mus2_wrk poparms http://fmwww.bc.edu/RePEc/bocode/p
  cap noi spinst_mus2_wrk synth http://fmwww.bc.edu/RePEc/bocode/s
  cap noi spinst_mus2_wrk st0500 http://www.stata-journal.com/software/sj17-4
  cap noi spinst_mus2_wrk rdrobust http://fmwww.bc.edu/RePEc/bocode/r
  cap noi spinst_mus2_wrk semipar http://fmwww.bc.edu/RePEc/bocode/s
  cap noi spinst_mus2_wrk sls http://fmwww.bc.edu/RePEc/bocode/s
  cap noi spinst_mus2_wrk vselect http://fmwww.bc.edu/RePEc/bocode/v
  cap noi spinst_mus2_wrk crossfold http://fmwww.bc.edu/RePEc/bocode/c
  cap noi spinst_mus2_wrk loocv http://fmwww.bc.edu/RePEc/bocode/l
  cap noi spinst_mus2_wrk rforest http://fmwww.bc.edu/RePEc/bocode/r
  cap noi spinst_mus2_wrk boost http://fmwww.bc.edu/RePEc/bocode/b
  cap noi spinst_mus2_wrk xtoverid http://fmwww.bc.edu/RePEc/bocode/x


  if "`haserr'" != "" {
    di
    di in smcl "{p}{err}At least one of the packages was not able to be " ///
               "installed.  Try typing {cmd:spinst_mus2} again.  If that " ///
               "fails, look at the output of the error message above to " ///
               "diagnose the problem.  Perhaps you have an out-of-date " ///
               "version of the package already installed.  In that case, " ///
               "type {cmd:adoupdate} to update it."
  }
  else {
   di as smcl "{txt}Installation complete."
  }
end

program spinst_mus2_wrk
  version 10.1
  args package from

  di as smcl "{txt}   package {res:`package'} from {res:`from'}"
  capture net install `package', from(`from') replace
  if _rc {
    di
    di as smcl "{cmd}. net install `package', from(`from')
    capture noisily net install `package', from(`from') replace
    di
    if _rc {
      c_local haserr "yes"
    }
  }
end

