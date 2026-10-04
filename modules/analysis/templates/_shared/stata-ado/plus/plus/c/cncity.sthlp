{smcl}
{* *! version 0.1.2 18Jan2026}{...}
{vieweralsosee "[R] regexm" "help regexm"}{...}
{vieweralsosee "[R] replace" "help replace"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "cncity##syntax"}{...}
{viewerjumpto "Standardization" "cncity##standardization"}{...}
{viewerjumpto "Example" "cncity##example"}{...}
{viewerjumpto "Variable" "cncity##variable"}{...}
{title:Title}

{p2colset 5 15 22 2}{...}
{p2col :{hi:cncity} {hline 2}}A Stata command for Chinese city name standardization{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}
{p 8 14 4}{cmd:cncity} {it:city_string}

{pstd}
{it:city_string} is a variable with standardized or non-standardized city names.
{p_end}

{marker standarization}{...}
{title:Standarization}

{pstd}
See: {browse "https://mp.weixin.qq.com/s/Ox6z8b4P-mruAy7l_iGZWQ":4个直辖市、293个地级市、397个县级市名单}
{p_end}

{marker example}{...}
{title:Example}

{phang2}{cmd:. cncity city}{p_end}

{marker variable}{...}
{title:Variable}

{pstd}
{bf:city_stname}: Standardized city names, which must end in "市".
{p_end}
{pstd}
{bf:city_type}: City type, e.g. prefecture-level city, county-level city, municipality, etc.
{p_end}
{pstd}
{bf:city_prov}: The province of the city, or itself if it is a municipality.
{p_end}
{pstd}
{bf:city_special}: Some special demand, such as matching with regions, autonomous regions, and leagues.
{p_end}
{pstd}
{bf:special_ctlist}: The city list for city_special.
{p_end}

{marker author}{...}
{title:Author}

{pstd}公众号：凯恩斯学计量{p_end}

{phang}{p_end}
