local L = LibStub("AceLocale-3.0"):NewLocale("EnhanceQoL_DrinkMacro", "zhCN")
if not L then return end

-- Drink
L["Add SpellID"] = "添加法术ID"
L["allowRecuperate"] = "允许使用复原治疗"
L["allowRecuperateDesc"] = "使拥有“复原”法术的职业可以治疗，但该法术不会恢复法力。"
L["CategoryCombatPotions"] = "战斗药水"
L["CategoryCustomSpells"] = "自定义法术"
L["CategoryHealthstones"] = "治疗石"
L["CategoryPotions"] = "药水"
L["Custom Spells"] = "自定义法术"
L["Drink Macro"] = "饮料宏"
L["Drinks & Food"] = "饮料与食物"
L["Enable Drink Macro"] = "启用饮用宏"
L["Enable Health Macro"] = "启用治疗宏"
L["Health Macro"] = "治疗宏"
L["healthCustomSpellsHint"] = [=[在下拉菜单中选择法术会将其移除（该字段按设计保持空白）。
宏会使用你已学会的所有自定义法术。]=]
L["healthMacroLimitReached"] = "治疗宏：已达到宏数量上限。请释放一个槽位。"
L["healthMacroPlaceOnBar"] = "%s - 放到你的动作条上（战斗外更新）"
L["healthMacroTipReset"] = "提示：要在战斗中可能再次使用恶魔治疗石，请使用 `reset=60`。"
L["healthMacroWillUse"] = "将按顺序使用：%s"
L["mageFoodLeaveText"] = "离开追随者地下城\\n\\n点击离开队伍"
L["mageFoodReminder"] = "显示提醒以从追随者地城获取法师食物"
L["mageFoodReminderDefaultSound"] = "默认声音"
L["mageFoodReminderDesc2"] = [=[点击该提醒可自动排队进入追随者地下城。
按住 Alt 可移动图标。]=]
L["mageFoodReminderEditModeHint"] = "在编辑模式中配置食物提醒的详细信息。"
L["MageFoodReminderHeadline"] = "治疗者法师食物提醒"
L["mageFoodReminderJoinSound"] = "加入声音"
L["mageFoodReminderLeaveSound"] = "离开声音"
L["mageFoodReminderReset"] = "重置位置"
L["mageFoodReminderSize"] = "提醒大小"
L["mageFoodReminderSound"] = "提醒出现时播放声音"
L["mageFoodReminderText"] = [=[从追随者地下城获取法师食物

点击加入队列]=]
L["mageFoodReminderUseCustomSound"] = "使用自定义提醒声音"
L["Minimum mana restore for food"] = "食物的最低法力恢复"
L["None"] = "无"
L["Prefer Healthstone first"] = "优先使用治疗石"
L["Prefer mage food"] = "优先使用法师食物"
L["PriorityOrder"] = "优先级顺序"
L["PrioritySlot"] = "优先级 %d"
L["Reset condition"] = "重置条件"
L["Reset: 10s"] = "10秒后"
L["Reset: 30s"] = "30秒后"
L["Reset: 60s"] = "60秒后"
L["Reset: Combat"] = "战斗结束时"
L["Reset: Target"] = "更换目标时"
L["Use Combat potions for health macro"] = "在生命宏中使用战斗药水"
L["Use custom spells"] = "使用自定义法术"
L["Use Recuperate out of combat"] = "在非战斗时使用“复原”"
L["useManaPotionInCombat"] = "在战斗中使用法力药水"
L["useManaPotionInCombatDesc"] = "添加一行 [combat] 来使用阿加法力药水（最高可用品质）。仅适用于有法力的职业；其他职业将继续使用复原/食物（按配置）。"

