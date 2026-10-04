*! version 5.3
* 2024/2/11
*! version 5.1
* 2023/3/25
*! version 5.0
* 2021/9/5
* gitee changes raw code 
*! version 4.1, 2021/6/17
*! version 4.0, 2021/5/17
*! version 3.0
* 27 Feb 2020
* addeing curl version
* Stata 16 is blocked by Gitee.com
* curl is used when the stata version is higher than 15.

*!version 2.0
* 25 Feb 2020
* Kerry Du, kerrydu@xmu.edu.cn
cap program drop gitee
program define gitee
	version 14 
	mata: vfile = cat("https://gitee.com/kerrydu/gitee/raw/master/gitee.ado") 
	mata: st_local("versiongit",subinstr(vfile[1]," ","",.))
	local versiongit = subinstr("`versiongit'","*!version","",.)
	qui findfile gitee.ado
	mata: vfile = cat("`r(fn)'")
	mata: st_local("versionuse",subinstr(vfile[1]," ","",.))
	local versionuse = subinstr("`versionuse'","*!version","",.)	
	if(`versionuse'<`versiongit'){
		qui net install gitee, from("https://gitee.com/kerrydu/gitee/raw/master") force
		discard
		di "gitee command has been updated."
		di "Please re-prompt the command again."
		exit
	}
	
	
	syntax [anything], [replace force from(string) all BRanch(string)]
 
	if `"`branch'"' == ""  local branch master
	tokenize `"`0'"', p(",")
	local rnew `3'
	local rnew=subinstr(`"`rnew'"',`"branch(`branch')"',"",.)
	
	gettoken subc 0:0, p(" ,")
	tokenize `"`0'"', p(",")

if !(`"`subc'"'=="install" |`"`subc'"'=="get" ){
		  di as red "gitee should be followed by install or get."
	     error 198
}



if (`"`from'"'==""){
 
 	if (`"`1'"'==""|`"`1'"'==","){

		di as error "username/repository[/subfolder] should be specified when from() is not specified."
		exit 198
	}
	local reps `1'
	local reps=subinstr(`"`reps'"',"\","/",.) 

	tokenize `"`reps'"', p("/")
	local usr `1'`2'`3'
	local pth=subinstr(`"`reps'"',`"`usr'"',"",1)
 
	if `"`pth'"'!=""{
		  local pth /tree/`branch'`pth'/
	 }
	 
	 
	  tempname N
      mata: files=cat(`"https://gitee.com/`usr'`pth'"')
	  mata: flag=select(1::length(files),strmatch(files,`"<i class="iconfont icon-file"></i>"'))
	  mata: st_numscalar("`N'",length(flag))
		
		if `=`N''==0{
			di as red "No Stata files found in the repository."
			exit
		}			
		
		mata: files=files[flag:+1,.]
		mata: files=select(files,!strpos(files,`"<span class='simplified-path'>"'))
		mata: files=select(files,strpos(files,`".pkg</a>"'))
		mata: st_numscalar("`N'",length(files))
		
		if `=`N''==0{
			di as red "No Stata *.pkg files found in the repository."
			exit
		}			

		mata: files = substr(files,strpos(files,`"href=""'):+6,.)
		mata: files = substr(files,1,strpos(files,`"">"'):-1)
		mata: files ="https://gitee.com":+ subinstr(files, "/blob/`branch'","/raw/`branch'",1)
		
		mata: pkgs = ""
		mata: urls = ""
		mata: pathsplit2(files,urls,pkgs) //
		//mata: files
		//mata: urls
		//mata: pkgs
		mata: st_local("urls",urls[1])
		mata: st_local("pkgs",strconcat(pkgs))
		if(`"`pkgs'"'!=""){
		   di _n
		   if "`subc'" == "install" di "trying to install package(s): `pkgs'"
		   else di "trying to copy ancillary files in package(s): `pkgs'"
		   di  _n
			foreach pkgi of local pkgs{
				net `subc' `pkgi', from(`urls') `rnew'	
			}			   

        }		
		
}
	
	
	
else{

	if(`"`1'"'!=""&`"`1'"'!=","){
		local pkgs `1'
		} 

	local rnew=subinstr(`"`rnew'"',`"from(`from')"',"",.)	

       tempname N
      mata: files=cat(`"`from'"')
	  mata: flag=select(1::length(files),strmatch(files,`"<i class="iconfont icon-file"></i>"'))
	  mata: st_numscalar("`N'",length(flag))
		
		if `=`N''==0{
			di as red "No Stata files found in the repository."
			exit
		}			
		
		mata: files=files[flag:+1,.]
		mata: files=select(files,!strpos(files,`"<span class='simplified-path'>"'))
		mata: files=select(files,strpos(files,`".pkg</a>"'))
		mata: st_numscalar("`N'",length(files))
		
		if `=`N''==0{
			di as red "No Stata *.pkg files found in the repository."
			exit
		}			
		//mata: files
		mata: files = substr(files,strpos(files,`"href=""'):+6,.)
		mata: files = substr(files,1,strpos(files,`"">"'):-1)
		mata: files ="https://gitee.com":+ subinstr(files, "/blob/`branch'","/raw/`branch'",1)
		
		mata: pkgsfound = ""
		mata: urls = ""
		mata: pathsplit2(files,urls,pkgsfound)
		mata: st_local("urls",urls[1])
		mata: st_local("pkgsfound",strconcat(pkgsfound))		
	
	foreach pkgi of local pkgs{

		mata: flag=strmatch(pkgsfound,"`pkgi'.pkg")
		mata: st_numscalar("`N'",sum(flag))		
		if `=`N''==0{
			di as red "`pkgi'.pkg is not found."
			di as red "Check the name of the installed package in the repository."
			mata: notation(pkgsfound)
			exit
		}
		net `subc' `pkgi', from(`urls') `rnew'			
	}

	if `"`pkgs'"'==""{

		if(`"`pkgsfound'"'==""){
			di as red "*.pkg files not found."
			di as red "There are not installable packages in the repository."
		}
		else{
		   di _n
		   if "`subc'" == "install" di "trying to install package(s): `pkgs'"
		   else di "trying to copy ancillary files in package(s): `pkgs'"
		   di  _n
			foreach pkgi of local pkgsfound{
				net `subc' `pkgi', from(`urls') `rnew'	
			}		   
		   
		}

	}
	
}	

end


cap mata mata drop notation()
cap mata mata drop strconcat()	
mata:

void function notation(string colvector filenames)

{
			//flag=strpos(filenames,".pkg")
			   flag=regexm(filenames,"^.*(\.pkg)$")
			   //flag
				if(sum(flag)>0){
				  printf("note: the specified repository includes %s \n",strconcat(select(filenames,flag)))
				}
			


}

string function strconcat(string vector s)
{
   ss=""
   for(i=1;i<=length(s);i++){
   
	ss=ss+" " + s[i]
   
   }
   return(ss)


}
end


cap mata mata drop pathsplit2() 
mata:
void function pathsplit2(string vector files, string vector urls,string vector pkgs)
{
	n =length(files)
	urls = J(n,1,"")
	pkgs=urls

	for(j=1;j<=n;j++){
		pathsplit(files[j],url="",pkg="")
		urls[j] =url
		pkgs[j] =pkg
	}

} 

end

	
