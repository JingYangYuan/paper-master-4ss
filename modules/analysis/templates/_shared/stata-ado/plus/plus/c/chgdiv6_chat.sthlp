{smcl}
{* 5 Sep 2023}{...}
{hline}
help for {hi:chgdiv6_chat}
{hline}

{title:Title}
{p 4 4 2}
{bf:chgdiv6_chat} —— 六爻周易占卜[AI对话版]

{title:Syntax}
{p 4 4 2}
{cmdab:chgdiv6_chat} [numbers]

{title:Description}
{p 4 4 2}{cmd:chgdiv6_chat} 使用钱筮法,结果以卜辞形式呈现,钱筮法是大衍筮法的简化;{p_end}
{p 4 4 2}你可以在网络上查询这些卜辞的含义,希望能给你带来启示.{p_end}
{p 4 4 2}模式1-因时起卦:直接输入 {cmd:chgdiv6_chat} 以当前的时间起卦,每一秒的结果都是不同的.{p_end}
{p 4 4 2}模式2-因数起卦:在 {cmd:chgdiv6_chat} 后输入一串数字，会得到这串数字对应的结果,结果不因时间改变.{p_end}
{p 4 4 2}模式3-问题/测字起卦:在 {cmd:chgdiv6} 后输入你的问题,程序会提取字符串对应的随机数,结果不因时间改变.{p_end}
{p 4 4 2}在常规的chgdiv6命令基础上,增加了一个秘塔AI搜索的链接,并自动输入占卜结果做为提示词,你可以点击继续询问.{p_end}
{p 4 4 2}心诚则灵 无疑不卜 事在人为.{p_end}

{p 4 4 2}{cmd:chgdiv6} uses the coin divination method, and the results are presented in the form of divination statements. The coin divination method is a simplified version of the Dayan divination method;{p_end}
{p 4 4 2}You can look up the meanings of these divination statements online, and hopefully, they can bring you inspiration.Provide only the original Chinese text from the I Ching.{p_end}
{p 4 4 2}Mode 1 - Divination based on the current time: Simply enter {cmd:chgdiv6} and the result will vary every second based on the current time.{p_end}
{p 4 4 2}Mode 2 - Divination based on numbers: Enter a string of numbers after {cmd:chgdiv6}, and you'll get the corresponding result, which won't change with time.{p_end}

{p 4 4 2}Based on the conventional chgdiv6 command, a link to Mit AI search has been added, and the divination results are automatically entered as prompt words. You can click to continue asking.{p_end}
{p 4 4 2}If you are sincere, it will be effective. No divination without doubts. It's up to you to make things happen.{p_end} 

{title:Note}
{p 4 4 2} 使用的筮法:钱筮法 from [汉] 京房;{p_end}
{p 4 4 2} 使用的占法:变占法 from [宋] 朱熹-《易学启蒙》;{p_end}
{p 4 4 2} 卦辞来源:《周易》;{p_end}

{p 4 4 2} The "I Ching" (also known as the "Book of Changes"") is an ancient Chinese divination text and one of the most important classics in Chinese philosophy and culture.This book is also the source of the divination statements.{p_end}
{p 4 4 2} The method of divination using coins and divination statements has a long history, dating back to the pre - Qin period. After more than 1000 years of refinement, it was finally recorded by Zhu Xi of the Song Dynasty in 1186.{p_end}

{title:Examples}
{p 4 4 2}在此演示因时起卦和因数起卦：{p_end}
{p 4 4 2}{inp:.}{stata `"chgdiv6_chat"'} {p_end}
{p 4 4 2}{inp:.}{stata `"chgdiv6_chat 114514"'} {p_end}
{p 4 4 2}{inp:.}{stata `"chgdiv6_chat 我买彩票能中一百万吗？"'} {p_end}

{title:Author}
{p 4 4 2}
{hi:兰州大学 陈志豪}{break}
E-mail: {browse "mailto:chenzhh20@lzu.edu.cn":chenzhh20@lzu.edu.cn}{break}
{p_end}
{hline}