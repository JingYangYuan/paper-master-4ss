*! version 1.6.2  2/20/00 - jf: bug fix   (STB-58: sg155)
*! version 1.6.1  2/6/00 - jf: bug fix
*! version 1.6.0c 1/20/00 - jsl: zip and zinb
*! version 1.6.0b 10/11/99 - jsl: minor changes
*! version 1.6.0a 2/15/1999 - jsl: V6
* 10/24/99 turned over to jf

/*
    return local rhsnms  "`rhsnm'"
    return local nrhs    "`nvar'"
    return local rhsnms2  "`rhsnm2'"
    return local nrhs2    "`nvar2'"
*/

capture program drop _perhs
program define _perhs, rclass
    version 6.0
    * if name is passed as option it will parse these names
    local beta "`1'"
    if "`beta'" == "" {
        tempname beta
        matrix `beta' = e(b)
    }
    local varnms : colnames(`beta')
    tokenize "`varnms'", parse(" ")

    * strip off _cons, _cut & _se
    local rhsnm ""
    local hascon "no"
    local i 1
    while "``i''" != "" {
        if "``i''" == "_cons" & "`hascon'"=="no" {
            local hascon "yes"
            local start2 = `i' + 1
        }
        if "``i''" != "_cons" /*
            */ & "``i''" != "_se" /*
            */ & substr("``i''",1,4) != "_cut" /*
            */ & "`hascon'"=="no" {
            local rhsnm "`rhsnm' ``i''"
        }
        local i = `i' + 1
    }
    local nvar : word count `rhsnm'

    if "`e(cmd)'"=="zip" | "`e(cmd)'"=="zinb" {
        local rhsnm2 ""
        local nvar2 0
        local i `start2'
        while "``i''" != "" {
            if "``i''" == "_cons" {
                local start2 = `i' + 1
            }
            if "``i''" != "_cons" /*
            */ & "``i''" != "_se" /*
            */ & substr("``i''",1,4) != "_cut" {
                local rhsnm2 "`rhsnm2' ``i''"
            }
            local i = `i' + 1
        }
        local nvar2 : word count `rhsnm2'
    } /* zip & zinb */

    if "`e(cmd)'"=="mlogit" {
        parse "`rhsnm'", parse(" ")
        local rhsnm2 ""
        local i 1
        while `i' <= `nvar' {
            local rhsnm2 "`rhsnm2' ``i''"
            local i = `i' + 1
        }
        local rhsnm "`rhsnm2'"
        local rhsnm2 ""
    }

    return local rhsnms  "`rhsnm'"
    return local nrhs    "`nvar'"
    return local rhsnms2  "`rhsnm2'"
    return local nrhs2    "`nvar2'"
/*
    di "rhsnms: `rhsnm'"
    di "nrhs:   `nvar'"
    di "rhsnms2:`rhsnm2'"
    di "nrhs2:  `nvar2'"
*/

end


