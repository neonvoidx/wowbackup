local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local function applyParentSection(entries, section)
	for _, entry in ipairs(entries or {}) do
		entry.parentSection = section
		if entry.children then applyParentSection(entry.children, section) end
	end
end

local cSocial = nil
addon.SettingsLayout.socialCategory = cSocial

local privacyExpandable = addon.functions.SettingsCreateExpandableSection(cSocial, {
	name = L["PrivacyBlockingIgnore"] or "Privacy, Blocking & Ignore",
	newTagID = "SocialGeneral",
	configPageKey = "PrivacyBlockingIgnore",
	modernCategory = "social",
	modernOnly = true,
	iconKey = "privacy",
	expanded = false,
	colorizeTitle = false,
})

local privacyData = {
	{
		var = "blockDuelRequests",
		text = L["blockDuelRequests"],
		desc = L["blockDuelRequestsDesc"],
		type = "CheckBox",
		func = function(value) addon.db["blockDuelRequests"] = value end,
	},
	{
		var = "blockPetBattleRequests",
		text = L["blockPetBattleRequests"],
		desc = L["blockPetBattleRequestsDesc"],
		type = "CheckBox",
		func = function(value) addon.db["blockPetBattleRequests"] = value end,
	},
	{
		var = "blockPartyInvites",
		text = L["blockPartyInvites"],
		desc = L["blockPartyInvitesDesc"],
		type = "CheckBox",
		func = function(value) addon.db["blockPartyInvites"] = value end,
	},
	{
		var = "enableIgnore",
		text = L["Enable advanced ignore list"],
		desc = L["enableIgnoreDesc"],
		type = "CheckBox",
		func = function(value)
			addon.db["enableIgnore"] = value
			if addon.Ignore and addon.Ignore.SetEnabled then addon.Ignore:SetEnabled(value) end
		end,
		richNote = {
			text = L["IgnoreDesc2"],
		},
		children = {
			{

				var = "ignoreAttachFriendsFrame",
				text = L["Open with Friends list"],
				desc = L["IgnoreAttachFriendsDesc"],
				func = function(v) addon.db["ignoreAttachFriendsFrame"] = v end,
				parentCheck = function()
					return addon.SettingsLayout.elements["enableIgnore"]
						and addon.SettingsLayout.elements["enableIgnore"].setting
						and addon.SettingsLayout.elements["enableIgnore"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{

				var = "ignoreAnchorFriendsFrame",
				text = L["Anchor to Friends list"],
				desc = L["IgnoreAnchorFriendsDesc"],
				func = function(v)
					addon.db["ignoreAnchorFriendsFrame"] = v
					if addon.Ignore and addon.Ignore.UpdateAnchor then addon.Ignore:UpdateAnchor() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["enableIgnore"]
						and addon.SettingsLayout.elements["enableIgnore"].setting
						and addon.SettingsLayout.elements["enableIgnore"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{

				var = "ignoreTooltipNote",
				text = L["Show ignore note in tooltip"],
				desc = L["ignoreTooltipNoteDesc"],
				func = function(v) addon.db["ignoreTooltipNote"] = v end,
				parentCheck = function()
					return addon.SettingsLayout.elements["enableIgnore"]
						and addon.SettingsLayout.elements["enableIgnore"].setting
						and addon.SettingsLayout.elements["enableIgnore"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{
				var = "ignoreTooltipMaxChars",
				text = L["IgnoreTooltipMaxChars"],
				desc = L["IgnoreTooltipMaxCharsDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["enableIgnore"]
						and addon.SettingsLayout.elements["enableIgnore"].setting
						and addon.SettingsLayout.elements["enableIgnore"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.ignoreTooltipMaxChars or 100 end,
				set = function(value) addon.db["ignoreTooltipMaxChars"] = value end,
				min = 20,
				max = 200,
				step = 1,
				parent = true,
				default = 100,
				sType = "slider",
			},
			{
				var = "IgnoreTooltipWordsPerLine",
				text = L["IgnoreTooltipWordsPerLine"],
				desc = L["IgnoreTooltipWordsPerLineDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["enableIgnore"]
						and addon.SettingsLayout.elements["enableIgnore"].setting
						and addon.SettingsLayout.elements["enableIgnore"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.ignoreTooltipWordsPerLine or 10 end,
				set = function(value) addon.db["ignoreTooltipWordsPerLine"] = value end,
				min = 1,
				max = 20,
				step = 1,
				parent = true,
				default = 10,
				sType = "slider",
			},
		},
	},
	{
		var = "autoAcceptGroupInvite",
		text = L["autoAcceptGroupInvite"],
		desc = L["autoAcceptGroupInviteDesc"],
		type = "CheckBox",
		func = function(value) addon.db["autoAcceptGroupInvite"] = value end,
		children = {
			{

				var = "autoAcceptGroupInviteGuildOnly",
				text = L["autoAcceptGroupInviteGuildOnly"],
				desc = L["autoAcceptGroupInviteGuildOnlyDesc"],
				func = function(v) addon.db["autoAcceptGroupInviteGuildOnly"] = v end,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoAcceptGroupInvite"]
						and addon.SettingsLayout.elements["autoAcceptGroupInvite"].setting
						and addon.SettingsLayout.elements["autoAcceptGroupInvite"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{

				var = "autoAcceptGroupInviteFriendOnly",
				text = L["Friends"],
				desc = L["autoAcceptGroupInviteFriendOnlyDesc"],
				func = function(v) addon.db["autoAcceptGroupInviteFriendOnly"] = v end,
				parentCheck = function()
					return addon.SettingsLayout.elements["autoAcceptGroupInvite"]
						and addon.SettingsLayout.elements["autoAcceptGroupInvite"].setting
						and addon.SettingsLayout.elements["autoAcceptGroupInvite"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
		},
	},
	{
		var = "autoAcceptSummon",
		text = L["autoAcceptSummon"],
		desc = L["autoAcceptSummonDesc"],
		type = "CheckBox",
		func = function(value) addon.db["autoAcceptSummon"] = value end,
	},
}

applyParentSection(privacyData, privacyExpandable)
addon.functions.SettingsCreateCheckboxes(cSocial, privacyData)

local friendsExpandable = addon.functions.SettingsCreateExpandableSection(cSocial, {
	name = L["FriendsAndCommunities"] or "Friends & Communities",
	configPageKey = "FriendsCommunities",
	modernCategory = "social",
	modernOnly = true,
	iconKey = "community",
	expanded = false,
	colorizeTitle = false,
})

local friendsData = {
	{
		var = "friendsListDecorEnabled",
		text = L["friendsListDecorEnabledLabel"],
		desc = L["friendsListDecorEnabledDesc"],
		type = "CheckBox",
		func = function(value)
			addon.db["friendsListDecorEnabled"] = value
			if addon.FriendsListDecor and addon.FriendsListDecor.SetEnabled then addon.FriendsListDecor:SetEnabled(addon.db["friendsListDecorEnabled"]) end
		end,
		richNote = {
			text = L["friendsListDecorEnabledDesc"],
		},
		children = {
			{
				var = "friendsListDecorShowLocation",
				text = L["friendsListDecorShowLocation"],
				desc = L["friendsListDecorShowLocationDesc"],
				func = function(v)
					addon.db["friendsListDecorShowLocation"] = v
					if addon.FriendsListDecor and addon.FriendsListDecor.Refresh then addon.FriendsListDecor:Refresh() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["friendsListDecorEnabled"]
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{
				var = "friendsListDecorHideOwnRealm",
				text = L["friendsListDecorHideOwnRealm"],
				desc = L["friendsListDecorHideOwnRealmDesc"],
				func = function(v)
					addon.db["friendsListDecorHideOwnRealm"] = v
					if addon.FriendsListDecor and addon.FriendsListDecor.Refresh then addon.FriendsListDecor:Refresh() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["friendsListDecorEnabled"]
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
			},
			{
				var = "friendsListDecorNameFontSize",
				text = L["friendsListDecorNameFontSize"],
				desc = L["friendsListDecorNameFontSizeDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["friendsListDecorEnabled"]
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting
						and addon.SettingsLayout.elements["friendsListDecorEnabled"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.friendsListDecorNameFontSize or 0 end,
				set = function(value)
					addon.db["friendsListDecorNameFontSize"] = value
					if addon.FriendsListDecor and addon.FriendsListDecor.Refresh then addon.FriendsListDecor:Refresh() end
				end,
				min = 0,
				max = 24,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
			},
		},
	},
	{
		var = "communityChatPrivacyEnabled",
		text = L["communityChatPrivacy"],
		desc = L["communityChatPrivacyDesc"],
		type = "CheckBox",
		func = function(value)
			addon.db["communityChatPrivacyEnabled"] = value
			if addon.CommunityChatPrivacy then
				if addon.CommunityChatPrivacy.SetMode then addon.CommunityChatPrivacy:SetMode(addon.db["communityChatPrivacyMode"]) end
				if addon.CommunityChatPrivacy.SetEnabled then addon.CommunityChatPrivacy:SetEnabled(value) end
			end
		end,
		children = {
			{
				var = "communityChatPrivacyMode",
				text = L["Behavior"],
				desc = L["communityChatPrivacyModeDesc"],
				list = {
					[1] = {
						label = L["Always"],
						tooltip = L["communityChatPrivacyModeAlwaysDesc"],
					},
					[2] = {
						label = L["communityChatPrivacyModeSession"],
						tooltip = L["communityChatPrivacyModeSessionDesc"],
					},
				},
				get = function() return addon.db and addon.db.communityChatPrivacyMode or 1 end,
				set = function(value)
					addon.db["communityChatPrivacyMode"] = value
					if addon.CommunityChatPrivacy and addon.CommunityChatPrivacy.SetMode then addon.CommunityChatPrivacy:SetMode(value) end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["communityChatPrivacyEnabled"]
						and addon.SettingsLayout.elements["communityChatPrivacyEnabled"].setting
						and addon.SettingsLayout.elements["communityChatPrivacyEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = 1,
				type = Settings.VarType.Number,
				sType = "dropdown",
			},
		},
	},
}

applyParentSection(friendsData, friendsExpandable)
addon.functions.SettingsCreateCheckboxes(cSocial, friendsData)

----- REGION END

function addon.functions.initSocial() end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
