*! version 0.1.2 18Jan2026 修复了一些特殊地区的匹配 bug      公众号：凯恩斯学计量
*! version 0.1.1 23Nov2025 公众号：凯恩斯学计量
capture program drop cncity
program define cncity
    syntax varlist 
    
    local v "`varlist'"

    * 初始化生成的变量 (如果已存在则删除)
    capture drop city_stname city_type city_prov city_special
    qui{
        gen city_stname = ""
        gen city_type = ""
        gen city_prov = ""
        gen city_special = ""
		gen special_ctlist = ""
    }
    
    dis as res "正在标准化城市名称，请稍候..."
    
    qui{
        * ==============================
        * 1. 直辖市
        * ==============================
        local zhixia "北京 天津 上海 重庆"
        foreach c of local zhixia {
            replace city_stname = "`c'市" if regexm(`v', "`c'")
            replace city_type = "直辖市" if regexm(`v', "`c'")
            replace city_prov = "`c'市" if regexm(`v', "`c'")
        }

        * ==============================
        * 2. 省份/自治区 循环处理
        * ==============================        
        * --- 河北省 ---
        local prov "河北省"
        local diji "石家庄 唐山 秦皇岛 邯郸 邢台 保定 张家口 承德 沧州 廊坊 衡水"
        local xian "辛集 晋州 新乐 遵化 迁安 滦州 武安 南宫 沙河 涿州 定州 安国 高碑店 平泉 泊头 任丘 黄骅 河间 霸州 三河 深州"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 山西省 ---
        local prov "山西省"
        local diji "太原 大同 阳泉 长治 晋城 朔州 晋中 运城 忻州 临汾 吕梁"
        local xian "古交 高平 怀仁 介休 永济 河津 原平 侯马 霍州 孝义 汾阳"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 内蒙古自治区 ---
        local prov "内蒙古自治区"
        local diji "呼和浩特 包头 乌海 赤峰 通辽 鄂尔多斯 呼伦贝尔 巴彦淖尔 乌兰察布"
        local xian "霍林郭勒 满洲里 牙克石 扎兰屯 额尔古纳 根河 丰镇 乌兰浩特 阿尔山 二连浩特 锡林浩特"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 辽宁省 ---
        local prov "辽宁省"
        local diji "沈阳 大连 鞍山 抚顺 本溪 丹东 锦州 营口 阜新 辽阳 盘锦 铁岭 朝阳 葫芦岛"
        local xian "新民 瓦房店 庄河 海城 东港 凤城 凌海 北镇 盖州 大石桥 灯塔 调兵山 开原 北票 凌源 兴城"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 吉林省 ---
        local prov "吉林省"
        local diji "长春 吉林 四平 辽源 通化 白山 松原 白城"
        local xian "榆树 德惠 公主岭 蛟河 桦甸 舒兰 磐石 双辽 梅河口 集安 临江 扶余 洮南 大安 延吉 图们 敦化 珲春 龙井 和龙"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 黑龙江省 ---
        local prov "黑龙江省"
        local diji "哈尔滨 齐齐哈尔 鸡西 鹤岗 双鸭山 大庆 伊春 佳木斯 七台河 牡丹江 黑河 绥化"
        local xian "尚志 五常 讷河 虎林 密山 铁力 同江 富锦 抚远 绥芬河 海林 宁安 穆棱 东宁 北安 五大连池 嫩江 安达 肇东 海伦 漠河"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 江苏省 ---
        local prov "江苏省"
        local diji "南京 无锡 徐州 常州 苏州 南通 连云港 淮安 盐城 扬州 镇江 泰州 宿迁"
        local xian "江阴 宜兴 新沂 邳州 溧阳 常熟 张家港 昆山 太仓 启东 如皋 海安 东台 仪征 高邮 丹阳 扬中 句容 兴化 靖江 泰兴"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 浙江省 ---
        local prov "浙江省"
        local diji "杭州 宁波 温州 嘉兴 湖州 绍兴 金华 衢州 舟山 台州 丽水"
        local xian "建德 余姚 慈溪 瑞安 乐清 龙港 海宁 平湖 桐乡 诸暨 嵊州 兰溪 义乌 东阳 永康 江山 温岭 临海 玉环 龙泉"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 安徽省 ---
        local prov "安徽省"
        local diji "合肥 芜湖 蚌埠 淮南 马鞍山 淮北 铜陵 安庆 黄山 滁州 阜阳 宿州 六安 亳州 池州 宣城"
        local xian "巢湖 无为 桐城 潜山 天长 明光 界首 宁国 广德"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 福建省 ---
        local prov "福建省"
        local diji "福州 厦门 莆田 三明 泉州 漳州 南平 龙岩 宁德"
        local xian "福清 永安 石狮 晋江 南安 邵武 武夷山 建瓯 漳平 福安 福鼎"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 江西省 ---
        local prov "江西省"
        local diji "南昌 景德镇 萍乡 九江 新余 鹰潭 赣州 吉安 宜春 抚州 上饶"
        local xian "乐平 瑞昌 共青城 庐山 贵溪 瑞金 龙南 井冈山 丰城 樟树 高安 德兴"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 山东省 ---
        local prov "山东省"
        local diji "济南 青岛 淄博 枣庄 东营 烟台 潍坊 济宁 泰安 威海 日照 临沂 德州 聊城 滨州 菏泽"
        local xian "胶州 平度 莱西 滕州 龙口 莱阳 莱州 招远 栖霞 海阳 青州 诸城 寿光 安丘 高密 昌邑 曲阜 邹城 新泰 肥城 荣成 乳山 乐陵 禹城 临清 邹平"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 河南省 ---
        local prov "河南省"
        local diji "郑州 开封 洛阳 平顶山 安阳 鹤壁 新乡 焦作 濮阳 许昌 漯河 三门峡 南阳 商丘 信阳 周口 驻马店"
        local xian "巩义 荥阳 新密 新郑 登封 舞钢 汝州 林州 卫辉 辉县 长垣 沁阳 孟州 禹州 长葛 义马 灵宝 邓州 永城 项城 济源"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 湖北省 ---
        local prov "湖北省"
        local diji "武汉 黄石 十堰 宜昌 襄阳 鄂州 荆门 孝感 荆州 黄冈 咸宁 随州"
        local xian "大冶 丹江口 宜都 当阳 枝江 老河口 枣阳 宜城 钟祥 京山 应城 安陆 汉川 石首 洪湖 松滋 监利 麻城 武穴 赤壁 广水 恩施 利川 仙桃 潜江 天门"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 湖南省 ---
        local prov "湖南省"
        local diji "长沙 株洲 湘潭 衡阳 邵阳 岳阳 常德 张家界 益阳 郴州 永州 怀化 娄底"
        local xian "浏阳 宁乡 醴陵 湘乡 韶山 耒阳 常宁 武冈 邵东 汨罗 临湘 津市 沅江 资兴 祁阳 洪江 冷水江 涟源 吉首"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 广东省 ---
        local prov "广东省"
        local diji "广州 韶关 深圳 珠海 汕头 佛山 江门 湛江 茂名 肇庆 惠州 梅州 汕尾 河源 阳江 清远 东莞 中山 潮州 揭阳 云浮"
        local xian "乐昌 南雄 台山 开平 鹤山 恩平 廉江 雷州 吴川 高州 化州 信宜 四会 兴宁 陆丰 阳春 英德 连州 普宁 罗定"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 广西壮族自治区 ---
        local prov "广西壮族自治区"
        local diji "南宁 柳州 桂林 梧州 北海 防城港 钦州 贵港 玉林 百色 贺州 河池 来宾 崇左"
        local xian "横州 荔浦 岑溪 东兴 桂平 北流 靖西 平果 合山 凭祥"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 海南省 ---
        local prov "海南省"
        local diji "海口 三亚 三沙 儋州"
        local xian "五指山 琼海 文昌 万宁 东方"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 四川省 ---
        local prov "四川省"
        local diji "成都 自贡 攀枝花 泸州 德阳 绵阳 广元 遂宁 内江 乐山 南充 眉山 宜宾 广安 达州 雅安 巴中 资阳"
        local xian "都江堰 彭州 邛崃 崇州 简阳 广汉 什邡 绵竹 江油 射洪 隆昌 峨眉山 阆中 华蓥 万源 马尔康 康定 西昌 会理"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 贵州省 ---
        local prov "贵州省"
        local diji "贵阳 六盘水 遵义 安顺 毕节 铜仁"
        local xian "清镇 盘州 赤水 仁怀 黔西 兴义 兴仁 凯里 都匀 福泉"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 云南省 ---
        local prov "云南省"
        local diji "昆明 曲靖 玉溪 保山 昭通 丽江 普洱 临沧"
        local xian "安宁 宣威 澄江 腾冲 水富 楚雄 禄丰 个旧 开远 蒙自 弥勒 文山 景洪 大理 瑞丽 芒 泸水 香格里拉"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 西藏自治区 ---
        local prov "西藏自治区"
        local diji "拉萨 日喀则 昌都 林芝 山南 那曲"
        local xian "米林 错那"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 陕西省 ---
        local prov "陕西省"
        local diji "西安 铜川 宝鸡 咸阳 渭南 延安 汉中 榆林 安康 商洛"
        local xian "兴平 彬州 韩城 华阴 子长 神木 旬阳"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 甘肃省 ---
        local prov "甘肃省"
        local diji "兰州 嘉峪关 金昌 白银 天水 武威 张掖 平凉 酒泉 庆阳 定西 陇南"
        local xian "华亭 玉门 敦煌 临夏 合作"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 青海省 ---
        local prov "青海省"
        local diji "西宁 海东"
        local xian "同仁 玉树 格尔木 德令哈 茫崖"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 宁夏回族自治区 ---
        local prov "宁夏回族自治区"
        local diji "银川 石嘴山 吴忠 固原 中卫"
        local xian "灵武 青铜峡"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }

        * --- 新疆维吾尔自治区 ---
        local prov "新疆维吾尔自治区"
        local diji "乌鲁木齐 克拉玛依 吐鲁番 哈密"
        local xian "昌吉 阜康 博乐 阿拉山口 库尔勒 阿克苏 库车 阿图什 喀什 和田 伊宁 奎屯 霍尔果斯 塔城 乌苏 沙湾 阿勒泰 石河子 阿拉尔 图木舒克 五家渠 北屯 铁门关 双河 可克达拉 昆玉 胡杨河 新星 白杨"
        foreach c of local diji {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "地级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县级市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        
        * --- 港澳台 ---
        replace city_stname = "香港特别行政区" if regexm(`v', "香港") & city_stname == ""
        replace city_type = "特别行政区" if city_stname == "香港特别行政区"
        replace city_prov = "香港特别行政区" if city_stname == "香港特别行政区"
        
        replace city_stname = "澳门特别行政区" if regexm(`v', "澳门") & city_stname == ""
        replace city_type = "特别行政区" if city_stname == "澳门特别行政区"
        replace city_prov = "澳门特别行政区" if city_stname == "澳门特别行政区"
        
        local prov "台湾省"
        local xzzx "台北 新北 桃园 台中 台南 高雄"
        local xian "基隆 新竹 嘉义"
        foreach c of local xzzx {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "行政院直辖市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        foreach c of local xian {
            replace city_stname = "`c'市" if regexm(`v', "`c'") & city_stname == ""
            replace city_type = "县辖市" if city_stname == "`c'市"
            replace city_prov = "`prov'" if city_stname == "`c'市"
        }
        
        * --- 地区、州、盟 ---
        replace city_special = "大兴安岭地区" if regexm(`v', "漠河|大兴安岭")
		replace city_special = "阿里地区" if regexm(`v', "阿里")
        replace city_special = "塔城地区" if regexm(`v', "塔城|乌苏|沙湾")
        replace city_special = "阿勒泰地区" if regexm(`v', "阿勒泰")
        replace city_special = "喀什地区" if regexm(`v', "喀什")
        replace city_special = "和田地区" if regexm(`v', "和田")
        replace city_special = "阿克苏地区" if regexm(`v', "阿克苏|库车")
        
        replace city_special = "延边朝鲜族自治州" if regexm(`v', "延吉|图们|敦化|珲春|龙井|和龙|延边")
        replace city_special = "恩施土家族苗族自治州" if regexm(`v', "恩施|利川")
        replace city_special = "湘西土家族苗族自治州" if regexm(`v', "吉首|湘西")
        replace city_special = "阿坝藏族羌族自治州" if regexm(`v', "马尔康|阿坝")
        replace city_special = "甘孜藏族自治州" if regexm(`v', "康定|甘孜")
        replace city_special = "凉山彝族自治州" if regexm(`v', "西昌|凉山")
        replace city_special = "黔东南苗族侗族自治州" if regexm(`v', "凯里|黔东南")
        replace city_special = "黔南布依族苗族自治州" if regexm(`v', "都匀|福泉|黔南")
        replace city_special = "黔西南布依族苗族自治州" if regexm(`v', "兴义|兴仁|黔西南")
        replace city_special = "楚雄彝族自治州" if regexm(`v', "楚雄|禄丰")
        replace city_special = "大理白族自治州" if regexm(`v', "大理")
        replace city_special = "德宏傣族景颇族自治州" if regexm(`v', "瑞丽|芒|德宏")
        replace city_special = "迪庆藏族自治州" if regexm(`v', "香格里拉|迪庆")
        replace city_special = "红河哈尼族彝族自治州" if regexm(`v', "个旧|开远|蒙自|弥勒|红河")
        replace city_special = "怒江傈僳族自治州" if regexm(`v', "泸水|怒江")
        replace city_special = "文山壮族苗族自治州" if regexm(`v', "文山")
        replace city_special = "西双版纳傣族自治州" if regexm(`v', "景洪|西双版纳")
        replace city_special = "甘南藏族自治州" if regexm(`v', "合作|甘南")
        replace city_special = "临夏回族自治州" if regexm(`v', "临夏")
        replace city_special = "海西蒙古族藏族自治州" if regexm(`v', "德令哈|格尔木|茫崖|海西蒙古")
        replace city_special = "海南藏族自治州" if regexm(`v', "海南藏族")
        replace city_special = "海北藏族自治州" if regexm(`v', "海北藏族")
        replace city_special = "黄南藏族自治州" if regexm(`v', "黄南藏族")
        replace city_special = "果洛藏族自治州" if regexm(`v', "果洛藏族")
        replace city_special = "玉树藏族自治州" if regexm(`v', "玉树")
        replace city_special = "巴音郭楞蒙古自治州" if regexm(`v', "库尔勒|巴音郭楞")
        replace city_special = "博尔塔拉蒙古自治州" if regexm(`v', "博乐|阿拉山口|博尔塔拉")
        replace city_special = "昌吉回族自治州" if regexm(`v', "昌吉|阜康")
        replace city_special = "克孜勒苏柯尔克孜自治州" if regexm(`v', "阿图什|克孜勒苏柯尔克孜")
        replace city_special = "伊犁哈萨克自治州" if regexm(`v', "伊宁|奎屯|霍尔果斯|伊犁")
        
        replace city_special = "兴安盟" if regexm(`v', "乌兰浩特|阿尔山|兴安盟") | `v' == "兴安"
        replace city_special = "锡林郭勒盟" if regexm(`v', "锡林浩特|二连浩特|锡林")
        replace city_special = "阿拉善盟" if regexm(`v', "阿拉善")
		
		// 去除错误将地区、州、盟命名为城市的观测
		replace city_stname  = "" if regexm(`v', "地区|自治州|盟")
		replace city_type    = "" if regexm(`v', "地区|自治州|盟")
		
		// 匹配省份名称
		replace city_prov = "黑龙江省" if city_special == "大兴安岭地区" & mi(city_prov)
		replace city_prov = "西藏自治区" if city_special == "阿里地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "塔城地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "阿勒泰地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "喀什地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "和田地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "阿克苏地区" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "巴音郭楞蒙古自治州" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "博尔塔拉蒙古自治州" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "昌吉回族自治州" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "克孜勒苏柯尔克孜自治州" & mi(city_prov)
		replace city_prov = "新疆维吾尔自治区" if city_special == "伊犁哈萨克自治州" & mi(city_prov)
		replace city_prov = "吉林省" if city_special == "延边朝鲜族自治州" & mi(city_prov)
		replace city_prov = "湖北省" if city_special == "恩施土家族苗族自治州" & mi(city_prov)
		replace city_prov = "湖南省" if city_special == "湘西土家族苗族自治州" & mi(city_prov)
		replace city_prov = "四川省" if city_special == "阿坝藏族羌族自治州" & mi(city_prov)
		replace city_prov = "四川省" if city_special == "甘孜藏族自治州" & mi(city_prov)
		replace city_prov = "四川省" if city_special == "凉山彝族自治州" & mi(city_prov)
		replace city_prov = "贵州省" if city_special == "黔东南苗族侗族自治州" & mi(city_prov)
		replace city_prov = "贵州省" if city_special == "黔南布依族苗族自治州" & mi(city_prov)
		replace city_prov = "贵州省" if city_special == "黔西南布依族苗族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "楚雄彝族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "大理白族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "德宏傣族景颇族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "迪庆藏族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "红河哈尼族彝族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "怒江傈僳族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "文山壮族苗族自治州" & mi(city_prov)
		replace city_prov = "云南省" if city_special == "西双版纳傣族自治州" & mi(city_prov)
		replace city_prov = "甘肃省" if city_special == "甘南藏族自治州" & mi(city_prov)
		replace city_prov = "甘肃省" if city_special == "临夏回族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "海西蒙古族藏族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "海南藏族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "海北藏族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "黄南藏族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "果洛藏族自治州" & mi(city_prov)
		replace city_prov = "青海省" if city_special == "玉树藏族自治州" & mi(city_prov)
		replace city_prov = "内蒙古自治区" if city_special == "兴安盟" & mi(city_prov)
		replace city_prov = "内蒙古自治区" if city_special == "锡林郭勒盟" & mi(city_prov)
		replace city_prov = "内蒙古自治区" if city_special == "阿拉善盟" & mi(city_prov)
		
		// 特殊地区城市名单
		replace special_ctlist = "漠河市" if city_special == "大兴安岭地区"
		replace special_ctlist = "塔城市,乌苏市,沙湾市" if city_special == "塔城地区"
		replace special_ctlist = "阿勒泰市" if city_special == "阿勒泰地区"
		replace special_ctlist = "喀什市" if city_special == "喀什地区"
		replace special_ctlist = "和田市" if city_special == "和田地区"
		replace special_ctlist = "阿克苏市,库车市" if city_special == "阿克苏地区"
		replace special_ctlist = "库尔勒市" if city_special == "巴音郭楞蒙古自治州"
		replace special_ctlist = "博乐市,阿拉山口市" if city_special == "博尔塔拉蒙古自治州"
		replace special_ctlist = "昌吉市,阜康市" if city_special == "昌吉回族自治州"
		replace special_ctlist = "阿图什市" if city_special == "克孜勒苏柯尔克孜自治州"
		replace special_ctlist = "伊宁市,奎屯市,霍尔果斯市" if city_special == "伊犁哈萨克自治州"
		replace special_ctlist = "延吉市,图们市,敦化市,珲春市,龙井市,和龙市" if city_special == "延边朝鲜族自治州"
		replace special_ctlist = "恩施市,利川市" if city_special == "恩施土家族苗族自治州"
		replace special_ctlist = "吉首市" if city_special == "湘西土家族苗族自治州"
		replace special_ctlist = "马尔康市" if city_special == "阿坝藏族羌族自治州"
		replace special_ctlist = "康定市" if city_special == "甘孜藏族自治州"
		replace special_ctlist = "西昌市" if city_special == "凉山彝族自治州"
		replace special_ctlist = "凯里市" if city_special == "黔东南苗族侗族自治州"
		replace special_ctlist = "都匀市,福泉市" if city_special == "黔南布依族苗族自治州"
		replace special_ctlist = "兴义市,兴仁市" if city_special == "黔西南布依族苗族自治州"
		replace special_ctlist = "楚雄市,禄丰市" if city_special == "楚雄彝族自治州"
		replace special_ctlist = "大理市" if city_special == "大理白族自治州"
		replace special_ctlist = "瑞丽市,芒市" if city_special == "德宏傣族景颇族自治州"
		replace special_ctlist = "香格里拉市" if city_special == "迪庆藏族自治州"
		replace special_ctlist = "个旧市,开远市,蒙自市,弥勒市" if city_special == "红河哈尼族彝族自治州"
		replace special_ctlist = "泸水市" if city_special == "怒江傈僳族自治州"
		replace special_ctlist = "文山市" if city_special == "文山壮族苗族自治州"
		replace special_ctlist = "景洪市" if city_special == "西双版纳傣族自治州"
		replace special_ctlist = "合作市" if city_special == "甘南藏族自治州"
		replace special_ctlist = "临夏市" if city_special == "临夏回族自治州"
		replace special_ctlist = "德令哈市,格尔木市,茫崖市" if city_special == "海西蒙古族藏族自治州"
		replace special_ctlist = "玉树市" if city_special == "玉树藏族自治州"
		replace special_ctlist = "乌兰浩特市,阿尔山市" if city_special == "兴安盟"
		replace special_ctlist = "锡林浩特市,二连浩特市" if city_special == "锡林郭勒盟"
    }
    display as res "标准化完成。"
end
