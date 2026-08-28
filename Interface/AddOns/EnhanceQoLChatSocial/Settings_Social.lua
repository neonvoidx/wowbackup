local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)

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

friendsData[#friendsData + 1] = {
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
}

applyParentSection(friendsData, friendsExpandable)
addon.functions.SettingsCreateCheckboxes(cSocial, friendsData)

----- REGION END

function addon.functions.initSocial() end

local eventHandlers = {
	["DUEL_REQUESTED"] = function()
		if addon.db["blockDuelRequests"] then
			CancelDuel()
			StaticPopup_Hide("DUEL_REQUESTED")
		end
	end,
	["PET_BATTLE_PVP_DUEL_REQUESTED"] = function()
		if addon.db["blockPetBattleRequests"] then
			C_PetBattles.CancelPVPDuel()
			StaticPopup_Hide("PET_BATTLE_PVP_DUEL_REQUESTED")
		end
	end,
	["PARTY_INVITE_REQUEST"] = function(unitName, arg2, arg3, arg4, arg5, arg6, inviterGUID, arg8)
		if addon.db["autoAcceptGroupInvite"] then
			if addon.db["autoAcceptGroupInviteGuildOnly"] then
				local playerRealm = _G.GetNormalizedRealmName and _G.GetNormalizedRealmName()
				if not playerRealm or playerRealm == "" then playerRealm = select(2, UnitFullName("player")) end

				local function normalizeCharacterName(name)
					if type(name) ~= "string" or name == "" then return nil end
					local characterName, realmName = strsplit("-", name, 2)
					if not characterName or characterName == "" then return nil end
					if not realmName or realmName == "" then realmName = playerRealm end
					if not realmName or realmName == "" then return nil end
					return characterName .. "-" .. realmName
				end

				local normalizedInviterName = normalizeCharacterName(unitName)
				local gMember = GetNumGuildMembers()
				if gMember then
					for i = 1, gMember do
						local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
						local matchesGuildMember
						if inviterGUID and guid then
							matchesGuildMember = inviterGUID == guid
						else
							matchesGuildMember = normalizedInviterName ~= nil and normalizeCharacterName(name) == normalizedInviterName
						end
						if matchesGuildMember then
							AcceptGroup()
							StaticPopup_Hide("PARTY_INVITE")
							return
						end
					end
				end
			end
			if addon.db["autoAcceptGroupInviteFriendOnly"] then
				if C_BattleNet.GetGameAccountInfoByGUID(inviterGUID) then
					AcceptGroup()
					StaticPopup_Hide("PARTY_INVITE")
					return
				end
				for i = 1, C_FriendList.GetNumFriends() do
					local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
					if friendInfo.guid == inviterGUID then
						AcceptGroup()
						StaticPopup_Hide("PARTY_INVITE")
						return
					end
				end
			end
			if not addon.db["autoAcceptGroupInviteGuildOnly"] and not addon.db["autoAcceptGroupInviteFriendOnly"] then
				AcceptGroup()
				StaticPopup_Hide("PARTY_INVITE")
				return
			end
		end
		if addon.db["blockPartyInvites"] then
			DeclineGroup()
			StaticPopup_Hide("PARTY_INVITE")
		end
	end,
}

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
