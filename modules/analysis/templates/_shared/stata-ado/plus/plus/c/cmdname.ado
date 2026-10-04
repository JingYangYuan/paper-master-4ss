*! version 1.0.5  13aug1999                          [STB-51: os15]
program define cmdname
	version 6
	gettoken word 0 : 0, parse(" ,")
	syntax [, REGister Name(string) Email(string) ]

	local word = lower(trim(`"`word'"'))
	ChkWord `"`word'"'

	if "`register'" != "" {
		ChkOpt `"`name'"' `"`email'"'
		GetName `"`name'"'
		local name `"`s(name)'"'
		GetEmail `"`email'"'
		local email `"`s(email)'"'
		Register `"`word'"' `"`name'"' `"`email'"'
	}
	else {
		Query `"`word'"'
	}
end

program define Query, rclass
	args word
	tempfile res
	SendReq `"`res'"' <- query `"`word"'
	preserve
	ReadRes `"`res'"'
	local rc = real(line[1])
	if `rc' == 0 { 
		di
		di in ye `"`word'"' in gr `" is available for registration"'
		exit
	}
	ret local status "inuse"
	if `rc' == 1 { 
		InUse `"`word'"'
		exit
	}
	if `rc'==2 { 
		InDict `"`word'"'
		exit
	}
	if `rc'==5 { 
		InValid `"`word'"'
		exit
	}
	Unexp `rc' `"`word'"'
end


program define Register, rclass
	args word name email
	tempfile res 
	SendReq `"`res'"' <- register `"`word'"' `"`name'"' `"`email'"'
	preserve
	ReadRes `"`res'"'
	local rc = real(line[1])
	if `rc' == 0 { 
		di 
		di in ye `"`word'"' in gr /* 
		*/ `" now registered to you (`name', `email')"'
		exit
	}
	if `rc' == 1 { 
		InUse `"`word'"'
		di in red `"`word' already registered"'
		exit 110
	}
	if `rc' == 2 { 
		InDict `"`word'"'
		di in red `"`word' not available for registration"'
		exit 110
	}
	if `rc' == 5 { 
		InValid `"`word'"'
		di in red `"`word' not available for registration"'
		exit 110
	}
	Unexp `rc' `"`word'"' `"`name'" `"`email'"'
end

program define InUse 
	args word
	local name  = line[3]
	local email = line[4] 
	di 
	di in ye `"`word'"' in gr /*
	*/ `" already registered to "' in ye /* 
	*/ `"`name'"' in gr ", " in ye `"`email'"'
end

program define InDict
	args word
	di
	di in ye `"`word'"' in gr /*
	*/ " is a word in the dictionary and not available for registration"
end

program define InValid
	args word 
	di 
	di in ye `"`word'"' in gr /* 
	*/ " is not a valid name for a command"
end


program define Unexp 
	args rc word name email

	if `rc' == 3 {
		di in red `""`name'" is in invalid person or organization name"'
		di in red "registration request ignored"
		exit 198
	}

	if `rc' == 4 { 
		di in red `""`email'" is in invalid email address"'
		di in red "registration request ignored"
		exit 198
	}

	di
	di in gr /*
	*/ "http://www.stata.com returned an unexpected result, code = " /*
	*/ in ye "`rc'"
	if _N > 1 { 
		di in gr "Detail:"
		local i 2 
		while `i' <= _N { 
			di in gr `"""' in ye line[`i'] in gr `"""'
			local i = `i' + 1
		}
	}
	di 
	di in gr "Verify that your ado files are up-to-date"
	di in red "Unexpected result returned by server"
	exit 9999
end




program define SendReq
	args file arrow subcmd word name email

	Sendable `"`word'"'
	local sword `"`s(text)'"'

	Sendable `"`name'"'
	local sname `"`s(text)'"'

	Sendable `"`email'"'
	local semail `"`s(text)'"'

	di in gr "(contacting http://www.stata.com)"
	set checksum off
	capture {
		*di `"SendReq `subcmd' |`sword'| |`sname'| |`semail'|"'
		copy `"http://www.stata.com/commands/register.cgi?version=1&subcmd=`subcmd'&word=`sword'&name=`sname'&email=`semail'"' `"`file'"', text
	}
	local rc = _rc
	set checksum on
	exit `rc'
end

program define Sendable, sclass
	args text
	sret clear 
	sret local text : subinstr local text " " "+", all
end



program define ReadRes 
	args file
	quietly { 
		drop _all
		infix str line 1-80 using `"`file'"'
		compress line 
	}
	capture local rc = line[1]
	if _rc==0 { 
		capture confirm integer number `rc'
		if `rc' == 97 { 
			di in red "command registry is temporarily unavailable"
			exit 696
		}
		if `rc'==96 { 
			di in red "A new version of -cmdname- is available."
			local i 2
			while line[`i'] != "" { 
				local where = line[`i']
				di in red `"`where'"'
				local i = `i' + 1
			}
			exit 696
		}
		if `rc'<90 { 
			exit 
		}
	}
	else	local rc = 100
	di in red "server responded unexpectedly, code = `rc'"
	exit 9999
end



program define ChkWord
	args word
	if `"`word'"' == "" { 
		error 198 
	}
	local n : word count `word'
	if `n' != 1 { 
		di in red `"-`word'- is not a valid name for a command"'
		error 198 
	}
	if length(`"`word'"')<4 {
		di in red "you may not register command names " /*
		*/ "shorter than 4 characters"
		exit 198
	}
	capture confirm var `word'
	if _rc==0 { exit }
	if _rc==111 { 
		capture confirm new var `word'
		if _rc==0 { exit } 
	}
	else if substr(`"`word'"',1,2)=="1x" & length(`"`word'"')<=8 {
		exit
	}
	di in red `"-`word'- is not a valid name for a command"'
	exit 198

end

program define ChkOpt
	args name email
	if `"`name'"'=="" {
		local name `"$S_NAME"'
	}
	if `"`email'"'=="" {
		local email `"$S_EMAIL"'
	}
	if `"`name'"'=="" & `"`email'"'=="" {
		di in red /*
	*/ "must specify options -name()- and -email()- or you must set the"
		di in red /* 
	*/ "global macros S_NAME and S_EMAIL to contain your name and email"
		di in red "address."
		exit 198
	}
end
		

program define GetName, sclass
	args name

	sret clear
	sret local name = trim(`"`name'"')
	if `"`s(name)'"' == "" {
		sret local name = trim(`"$S_NAME"')
		if `"`s(name)'"' == "" {
			di in red "must specify option -name()- " /*
			*/ "or set global macro S_NAME"
			di in red "to contain your name"
			exit 198
		}
	}
end

program define GetEmail, sclass
	args email

	sret clear
	sret local email = trim(`"`email'"')
	if `"`s(email)'"' == "" {
		sret local email = trim(`"$S_EMAIL"')
		if `"`s(email)'"' == "" {
			di in red "must specify option -email()- " /*
			*/ "or set global macro S_EMAIL"
			di in red "to contain your email address"
			exit 198
		}
	}
end

exit

/*
	CGI script returns
		line[1]		result code 
		line[2]		detail 
		...		...

	query, result codes
		0		available for registration
		1		already registered; [2]=text result, 
				[3]=who, [4]=email
		2		in dictionary
		5		word is "", too long, or otherwise invalid

	register, result codes
		0		registered
		1		no; already registered; [2]=text result, 
				[3]=who, [4]=email
		2		no; in dictionary
		3		no; user name is invalid
		4		no; email address is invalid
		5		no; word is "", too long, or otherwise invalid

	other, result codes 
		96		no; incorrect version
		97		no; temporarily unavailable
		98		no; don't understand
		99		no; invalid subcommand
*/
