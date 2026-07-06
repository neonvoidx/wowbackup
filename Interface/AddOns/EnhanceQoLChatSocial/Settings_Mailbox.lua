local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local mailboxContactsOrder = {}

local mailboxExpandable = addon.functions.SettingsCreateExpandableSection(nil, {
	name = MINIMAP_TRACKING_MAILBOX,
	newTagID = "Mailbox",
	modernCategory = "social",
	modernOnly = true,
	iconKey = "mailbox",
	expanded = false,
	colorizeTitle = false,
})

local data = {
	{
		var = "enableMailboxAddressBook",
		text = L["enableMailboxAddressBook"],
		func = function(v)
			addon.db["enableMailboxAddressBook"] = v
			if addon.Mailbox then
				if addon.Mailbox.SetEnabled then addon.Mailbox:SetEnabled(v) end
				if v and addon.Mailbox.AddSelfToContacts then addon.Mailbox:AddSelfToContacts() end
				if v and addon.Mailbox.RefreshList then addon.Mailbox:RefreshList() end
			end
		end,
		desc = L["enableMailboxAddressBookDesc"],
		children = {
			{
				listFunc = function()
					local contacts = addon.Mailbox and addon.Mailbox.NormalizeContacts and addon.Mailbox.NormalizeContacts() or addon.db["mailboxContacts"]
					if type(contacts) ~= "table" then contacts = {} end
					local entries = {}
					local tList = { [""] = "" }
					wipe(mailboxContactsOrder)
					table.insert(mailboxContactsOrder, "")

					for key, rec in pairs(contacts) do
						local class = rec and rec.class
						local col = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or ""] or { r = 1, g = 1, b = 1 }
						local label = string.format("|cff%02x%02x%02x%s|r", (col.r or 1) * 255, (col.g or 1) * 255, (col.b or 1) * 255, key)
						local rawSort = (rec and rec.name) or key or ""
						entries[#entries + 1] = { key = key, label = label, sortKey = rawSort:lower() }
					end

					table.sort(entries, function(a, b)
						if a.sortKey == b.sortKey then return a.key < b.key end
						return a.sortKey < b.sortKey
					end)

					for _, entry in ipairs(entries) do
						tList[entry.key] = entry.label
						table.insert(mailboxContactsOrder, entry.key)
					end
					return tList
				end,
				order = mailboxContactsOrder,
				text = L["mailboxRemoveHeader"],
				get = function() return "" end,
				set = function(key)
					if not key or key == "" then return end
					local contacts = addon.Mailbox and addon.Mailbox.NormalizeContacts and addon.Mailbox.NormalizeContacts() or (addon.db and addon.db["mailboxContacts"])
					if type(contacts) ~= "table" or not contacts[key] then return end

					local dialogKey = "EQOL_MAILBOX_CONTACT_REMOVE"
					StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey]
						or {
							text = L["mailboxRemoveConfirm"],
							button1 = ACCEPT,
							button2 = CANCEL,
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}

					StaticPopupDialogs[dialogKey].OnAccept = function(_, contactKey)
						local currentContacts = addon.Mailbox and addon.Mailbox.NormalizeContacts and addon.Mailbox.NormalizeContacts() or (addon.db and addon.db["mailboxContacts"])
						if not contactKey or type(currentContacts) ~= "table" then return end
						currentContacts[contactKey] = nil
						if addon.Mailbox and addon.Mailbox.RefreshList then addon.Mailbox:RefreshList() end
					end

					StaticPopup_Show(dialogKey, key, nil, key)
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["enableMailboxAddressBook"]
						and addon.SettingsLayout.elements["enableMailboxAddressBook"].setting
						and addon.SettingsLayout.elements["enableMailboxAddressBook"].setting:GetValue() == true
				end,
				parent = true,
				default = "",
				var = "mailboxContacts",
				type = Settings.VarType.String,
				sType = "scrolldropdown",
			},
		},
	},
	{
		var = "mailboxRememberLastRecipient",
		text = L["mailboxRememberLastRecipient"],
		desc = L["mailboxRememberLastRecipientDesc"],
		func = function(v)
			addon.db["mailboxRememberLastRecipient"] = v
			if addon.Mailbox and addon.Mailbox.SetRememberRecipientEnabled then addon.Mailbox:SetRememberRecipientEnabled(v) end
		end,
	},
}

for _, entry in ipairs(data) do
	entry.parentSection = mailboxExpandable
	if entry.children then
		for _, child in ipairs(entry.children) do
			child.parentSection = mailboxExpandable
		end
	end
end
table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(nil, data)
