local AddonName, NS = ...

local LibStub = LibStub
local CopyTable = CopyTable
local next = next

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = NS.BGWC.frame

local Anchor = NS.Anchor
local Interface = NS.Interface
local Prediction = NS.Prediction
local Banner = NS.Banner
local Bases = NS.Bases
local Info = NS.Info
local Orbs = NS.Orbs
local Flags = NS.Flags
local Score = NS.Score
local Stacks = NS.Stacks
local Maps = NS.Maps
local Version = NS.Version
local Changelog = NS.Changelog

local Options = {}
NS.Options = Options

NS.AceConfig = {
  name = AddonName,
  descStyle = "inline",
  type = "group",
  childGroups = "tab",
  args = {
    general = {
      name = "General",
      type = "group",
      args = {
        lock = {
          name = "Lock the position",
          desc = "Turning this feature on hides the anchor bar.",
          type = "toggle",
          width = "double",
          order = 1,
          set = function(_, val)
            NS.db.global.general.lock = val
            if val then
              Anchor:Lock(Anchor.frame)
            else
              Anchor:Unlock(Anchor.frame)
            end
          end,
          get = function(_)
            return NS.db.global.general.lock
          end,
        },
        banner = {
          name = "Show banner only (hides win text)",
          desc = "Turning this feature on hides the win text and only shows the GG Banner.",
          type = "toggle",
          width = "double",
          order = 2,
          set = function(_, val)
            NS.db.global.general.banner = val

            if val then
              NS.db.global.general.info = false

              if NS.IN_GAME == false then
                Interface:Clear()
                Interface:CreateTestBanner()
              else
                Interface:ShowBanner()
                Interface:HideInfo()
              end

              Info:SetAnchor(Anchor.frame, 0, 0)
              Score:SetAnchor(Info.frame, 0, 0)
            else
              if NS.IN_GAME == false then
                Interface:Clear()
                Interface:CreateTestBanner()
                Interface:CreateTestInfo()
              else
                Interface:ShowBanner()
                Interface:ShowInfo()
              end

              Info:SetAnchor(Banner.frame, 0, 0)
              Score:SetAnchor(Info.frame, 0, -5)
            end
          end,
          get = function(_)
            return NS.db.global.general.banner
          end,
        },
        info = {
          name = "Show info only (hides banner bar)",
          desc = "Turning this feature on hides the GG Banner and only shows the win text.",
          type = "toggle",
          width = "double",
          order = 3,
          set = function(_, val)
            NS.db.global.general.info = val

            if val then
              NS.db.global.general.banner = false

              if NS.IN_GAME == false then
                Interface:Clear()
                Interface:CreateTestInfo()
              else
                Interface:HideBanner()
                Interface:ShowInfo()
              end

              Info:SetAnchor(Anchor.frame, 0, 0)
              Score:SetAnchor(Info.frame, 0, 0)
            else
              if NS.IN_GAME == false then
                Interface:Clear()
                Interface:CreateTestBanner()
                Interface:CreateTestInfo()
              else
                Interface:ShowBanner()
                Interface:ShowInfo()
              end

              Info:SetAnchor(Banner.frame, 0, 0)
              Score:SetAnchor(Info.frame, 0, -5)
            end

            if NS.IN_GAME == false and NS.db.global.general.infogroup.infobg then
              NS.UpdateInfoSize(
                NS.Info.frame,
                NS.Banner,
                { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                "NS.AceConfig 1"
              )
            end
          end,
          get = function(_)
            return NS.db.global.general.info
          end,
        },
        test = {
          name = "Show test info outside of games (for placement)",
          desc = "Turning this feature on shows test info while out of a game for placement purposes.",
          type = "toggle",
          width = "double",
          order = 4,
          set = function(_, val)
            NS.db.global.general.test = val
            if val then
              if NS.IN_GAME == false then
                if NS.db.global.general.banner then
                  Interface:CreateTestBanner()
                else
                  Interface:CreateTestBanner()
                  Interface:CreateTestInfo()
                end
              end
            else
              if NS.IN_GAME == false then
                Interface:Clear()
              end
            end
          end,
          get = function(_)
            return NS.db.global.general.test
          end,
        },
        bannergroup = {
          name = "Banner",
          type = "group",
          inline = true,
          order = 6,
          args = {
            bannerfont = {
              name = "Font",
              type = "select",
              width = "normal",
              dialogControl = "LSM30_Font",
              values = AceGUIWidgetLSMlists.font,
              order = 0,
              set = function(_, val)
                NS.db.global.general.bannergroup.bannerfont = val
                Banner:SetFont(Banner.text, val)
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.bannerfont
              end,
            },
            bannerscale = {
              type = "range",
              name = "Scale",
              width = "double",
              min = 0.8,
              max = 2,
              step = 0.01,
              order = 1,
              set = function(_, val)
                NS.db.global.general.bannergroup.bannerscale = val
                Banner:SetScale(Banner.frame)
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.bannerscale
              end,
            },
            spacer1 = { type = "description", order = 2, name = " " },
            tiebgcolor = {
              name = "Tie Background Color",
              type = "color",
              width = "double",
              hasAlpha = true,
              order = 3,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.tiebgcolor.r = val1
                NS.db.global.general.bannergroup.tiebgcolor.g = val2
                NS.db.global.general.bannergroup.tiebgcolor.b = val3
                NS.db.global.general.bannergroup.tiebgcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.tiebgcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.tiebgcolor.r,
                  NS.db.global.general.bannergroup.tiebgcolor.g,
                  NS.db.global.general.bannergroup.tiebgcolor.b,
                  NS.db.global.general.bannergroup.tiebgcolor.a
              end,
            },
            tietextcolor = {
              name = "Tie Text Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 4,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.tietextcolor.r = val1
                NS.db.global.general.bannergroup.tietextcolor.g = val2
                NS.db.global.general.bannergroup.tietextcolor.b = val3
                NS.db.global.general.bannergroup.tietextcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.tietextcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.tietextcolor.r,
                  NS.db.global.general.bannergroup.tietextcolor.g,
                  NS.db.global.general.bannergroup.tietextcolor.b,
                  NS.db.global.general.bannergroup.tietextcolor.a
              end,
            },
            spacer2 = { type = "description", order = 5, name = " " },
            winbgcolor = {
              name = "Win Background Color",
              type = "color",
              width = "double",
              hasAlpha = true,
              order = 6,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.winbgcolor.r = val1
                NS.db.global.general.bannergroup.winbgcolor.g = val2
                NS.db.global.general.bannergroup.winbgcolor.b = val3
                NS.db.global.general.bannergroup.winbgcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.winbgcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.winbgcolor.r,
                  NS.db.global.general.bannergroup.winbgcolor.g,
                  NS.db.global.general.bannergroup.winbgcolor.b,
                  NS.db.global.general.bannergroup.winbgcolor.a
              end,
            },
            wintextcolor = {
              name = "Win Text Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 7,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.wintextcolor.r = val1
                NS.db.global.general.bannergroup.wintextcolor.g = val2
                NS.db.global.general.bannergroup.wintextcolor.b = val3
                NS.db.global.general.bannergroup.wintextcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.wintextcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.wintextcolor.r,
                  NS.db.global.general.bannergroup.wintextcolor.g,
                  NS.db.global.general.bannergroup.wintextcolor.b,
                  NS.db.global.general.bannergroup.wintextcolor.a
              end,
            },
            spacer3 = { type = "description", order = 8, name = " " },
            losebgcolor = {
              name = "Lose Background Color",
              type = "color",
              width = "double",
              hasAlpha = true,
              order = 9,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.losebgcolor.r = val1
                NS.db.global.general.bannergroup.losebgcolor.g = val2
                NS.db.global.general.bannergroup.losebgcolor.b = val3
                NS.db.global.general.bannergroup.losebgcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.losebgcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.losebgcolor.r,
                  NS.db.global.general.bannergroup.losebgcolor.g,
                  NS.db.global.general.bannergroup.losebgcolor.b,
                  NS.db.global.general.bannergroup.losebgcolor.a
              end,
            },
            losetextcolor = {
              name = "Lose Text Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 10,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.losetextcolor.r = val1
                NS.db.global.general.bannergroup.losetextcolor.g = val2
                NS.db.global.general.bannergroup.losetextcolor.b = val3
                NS.db.global.general.bannergroup.losetextcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.losetextcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.losetextcolor.r,
                  NS.db.global.general.bannergroup.losetextcolor.g,
                  NS.db.global.general.bannergroup.losetextcolor.b,
                  NS.db.global.general.bannergroup.losetextcolor.a
              end,
            },
            spacer4 = { type = "description", order = 11, name = " " },
            resetbgcolor = {
              name = "Reset Background Color",
              type = "color",
              width = "double",
              hasAlpha = true,
              order = 12,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.resetbgcolor.r = val1
                NS.db.global.general.bannergroup.resetbgcolor.g = val2
                NS.db.global.general.bannergroup.resetbgcolor.b = val3
                NS.db.global.general.bannergroup.resetbgcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetBackgroundColor(Banner.bg, NS.db.global.general.bannergroup.resetbgcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.resetbgcolor.r,
                  NS.db.global.general.bannergroup.resetbgcolor.g,
                  NS.db.global.general.bannergroup.resetbgcolor.b,
                  NS.db.global.general.bannergroup.resetbgcolor.a
              end,
            },
            resettextcolor = {
              name = "Reset Text Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 13,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.bannergroup.resettextcolor.r = val1
                NS.db.global.general.bannergroup.resettextcolor.g = val2
                NS.db.global.general.bannergroup.resettextcolor.b = val3
                NS.db.global.general.bannergroup.resettextcolor.a = val4

                if NS.IN_GAME == false then
                  Banner:SetTextColor(Banner.text, NS.db.global.general.bannergroup.resettextcolor)
                end
              end,
              get = function(_)
                return NS.db.global.general.bannergroup.resettextcolor.r,
                  NS.db.global.general.bannergroup.resettextcolor.g,
                  NS.db.global.general.bannergroup.resettextcolor.b,
                  NS.db.global.general.bannergroup.resettextcolor.a
              end,
            },
          },
        },
        infogroup = {
          name = "Info",
          type = "group",
          inline = true,
          order = 7,
          args = {
            infofont = {
              name = "Font",
              type = "select",
              width = "normal",
              dialogControl = "LSM30_Font",
              values = AceGUIWidgetLSMlists.font,
              order = 0,
              set = function(_, val)
                NS.db.global.general.infogroup.infofont = val
                Bases:SetFont(Bases.text)
                Orbs:SetFont(Orbs.orbText)
                Orbs:SetFont(Orbs.buffText)
                Flags:SetFont(Flags.text)
                Score:SetFont(Score.text)
                Stacks:SetFont(Stacks.text)
              end,
              get = function(_)
                return NS.db.global.general.infogroup.infofont
              end,
            },
            -- spacer1 = { type = "description", order = 1, name = " " },
            infofontsize = {
              type = "range",
              name = "Font Size",
              width = "double",
              min = 10,
              max = 32,
              step = 1,
              order = 2,
              set = function(_, val)
                NS.db.global.general.infogroup.infofontsize = val
                Score:SetFont(Score.text)
                Bases:SetFont(Bases.text)
                Flags:SetFont(Flags.text)
                Orbs:SetFont(Orbs.orbText)
                Orbs:SetFont(Orbs.buffText)
                Stacks:SetFont(Stacks.text)
              end,
              get = function(_)
                return NS.db.global.general.infogroup.infofontsize
              end,
            },
            infotextcolor = {
              name = "Text Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 3,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.infogroup.infotextcolor.r = val1
                NS.db.global.general.infogroup.infotextcolor.g = val2
                NS.db.global.general.infogroup.infotextcolor.b = val3
                NS.db.global.general.infogroup.infotextcolor.a = val4
                Score:SetTextColor(Score.text, NS.db.global.general.infogroup.infotextcolor)
                Bases:SetTextColor(Bases.text, NS.db.global.general.infogroup.infotextcolor)
                Flags:SetTextColor(Flags.text, NS.db.global.general.infogroup.infotextcolor)
                Orbs:SetTextColor(Orbs.orbText, NS.db.global.general.infogroup.infotextcolor)
                Orbs:SetTextColor(Orbs.buffText, NS.db.global.general.infogroup.infotextcolor)
                Stacks:SetTextColor(Stacks.text, NS.db.global.general.infogroup.infotextcolor)
              end,
              get = function(_)
                return NS.db.global.general.infogroup.infotextcolor.r,
                  NS.db.global.general.infogroup.infotextcolor.g,
                  NS.db.global.general.infogroup.infotextcolor.b,
                  NS.db.global.general.infogroup.infotextcolor.a
              end,
            },
            infobg = {
              name = "Enable Background",
              desc = "Adds a background color to the info text to make it more readable.",
              type = "toggle",
              width = "normal",
              order = 4,
              disabled = false,
              set = function(_, val)
                NS.db.global.general.infogroup.infobg = val

                if val then
                  Info.bg:SetAlpha(1)
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 2"
                  )

                  if NS.IN_GAME and NS.IS_TEMPLE then
                    Orbs:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
                  end
                else
                  Info.bg:SetAlpha(0)
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 3"
                  )

                  if NS.IN_GAME and NS.IS_TEMPLE then
                    Orbs:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
                  end
                end
              end,
              get = function(_)
                return NS.db.global.general.infogroup.infobg
              end,
            },
            infobgcolor = {
              name = "Background Color",
              type = "color",
              width = "normal",
              hasAlpha = true,
              order = 5,
              disabled = function(info)
                return info[3] and not NS.db.global.general.infogroup.infobg
              end,
              set = function(_, val1, val2, val3, val4)
                NS.db.global.general.infogroup.infobgcolor.r = val1
                NS.db.global.general.infogroup.infobgcolor.g = val2
                NS.db.global.general.infogroup.infobgcolor.b = val3
                NS.db.global.general.infogroup.infobgcolor.a = val4
                Info:SetBackgroundColor(Info.bg, NS.db.global.general.infogroup.infobgcolor)
              end,
              get = function(_)
                return NS.db.global.general.infogroup.infobgcolor.r,
                  NS.db.global.general.infogroup.infobgcolor.g,
                  NS.db.global.general.infogroup.infobgcolor.b,
                  NS.db.global.general.infogroup.infobgcolor.a
              end,
            },
          },
        },
        debug = {
          name = "Toggle debug mode",
          desc = "Turning this feature on prints debug messages to the chat window.",
          type = "toggle",
          width = "full",
          order = 99,
          set = function(_, val)
            NS.db.global.debug = val
          end,
          get = function(_)
            return NS.db.global.debug
          end,
        },
        reset = {
          name = "Reset Everything",
          type = "execute",
          width = "normal",
          order = 100,
          func = function()
            BattlegroundWinConditionsDB = CopyTable(NS.DefaultDatabase)
            NS.db = CopyTable(NS.DefaultDatabase)
            Interface:Refresh()
          end,
        },
      },
    },
    maps = {
      name = "Maps",
      type = "group",
      childGroups = "tab",
      args = {
        arathibasin = {
          name = "Arathi Basin",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.arathibasin[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.arathibasin[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Arathi Basin. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.arathibasin.enabled = val
                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
          },
        },
        deepwindgorge = {
          name = "Deepwind Gorge",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.deepwindgorge[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.deepwindgorge[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Deepwind Gorge",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.deepwindgorge.enabled = val
                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
          },
        },
        eyeofthestorm = {
          name = "Eye of the Storm",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.eyeofthestorm[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.eyeofthestorm[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Eye of the Storm. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.eyeofthestorm.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
            showflaginfo = {
              name = "Show Flags Needed",
              desc = "Show how many flag caps your team is ahead or behind by.",
              type = "toggle",
              width = "normal",
              order = 2,
              set = function(_, val)
                NS.db.global.maps.eyeofthestorm.showflaginfo = val

                if val then
                  Flags.frame:SetAlpha(1)
                  if NS.IN_GAME == false then
                    Orbs:SetAnchor(Flags.frame, 0, -10)
                  end

                  if
                    NS.db.global.maps.templeofkotmogu.showorbinfo == false
                    and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
                  then
                    Stacks:SetAnchor(Flags.frame, 0, -10)
                  else
                    Stacks:SetAnchor(Orbs.frame, 0, -10)
                  end
                else
                  Flags.frame:SetAlpha(0)
                  if NS.IN_GAME == false then
                    Orbs:SetAnchor(Bases.frame, 0, -10)
                  end

                  if
                    NS.db.global.maps.templeofkotmogu.showorbinfo == false
                    and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
                  then
                    Stacks:SetAnchor(Bases.frame, 0, -10)
                  else
                    Stacks:SetAnchor(Orbs.frame, 0, -10)
                  end
                end

                if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 4"
                  )
                end
              end,
            },
            showflagvalue = {
              name = "Show Flag Value",
              desc = "Show how many points a flag cap for your team is worth.",
              type = "toggle",
              width = "normal",
              order = 3,
              set = function(_, val)
                NS.db.global.maps.eyeofthestorm.showflagvalue = val

                if val then
                  Flags.frame:SetAlpha(1)
                  if NS.IN_GAME == false then
                    Orbs:SetAnchor(Flags.frame, 0, -10)
                  end

                  if
                    NS.db.global.maps.templeofkotmogu.showorbinfo == false
                    and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
                  then
                    Stacks:SetAnchor(Flags.frame, 0, -10)
                  else
                    Stacks:SetAnchor(Orbs.frame, 0, -10)
                  end
                else
                  Flags.frame:SetAlpha(0)
                  if NS.IN_GAME == false then
                    Orbs:SetAnchor(Bases.frame, 0, -10)
                  end

                  if
                    NS.db.global.maps.templeofkotmogu.showorbinfo == false
                    and NS.db.global.maps.templeofkotmogu.showbuffinfo == false
                  then
                    Stacks:SetAnchor(Bases.frame, 0, -10)
                  else
                    Stacks:SetAnchor(Orbs.frame, 0, -10)
                  end
                end

                if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 5"
                  )
                end
              end,
            },
          },
        },
        silvershardmines = {
          name = "Silvershard Mines",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.silvershardmines[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.silvershardmines[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Silvershard Mines. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = true,
              set = function(_, val)
                NS.db.global.maps.silvershardmines.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
          },
        },
        deephaulravine = {
          name = "Deephaul Ravine",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.deephaulravine[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.deephaulravine[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Deephaul Ravine. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = true,
              set = function(_, val)
                NS.db.global.maps.deephaulravine.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
          },
        },
        templeofkotmogu = {
          name = "Temple of Kotmogu",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.templeofkotmogu[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.templeofkotmogu[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Temple of Kotmogu. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.templeofkotmogu.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
            showorbinfo = {
              name = "Show Available Orbs",
              desc = "Shows what orbs are available and what taken orbs stack percentages are.",
              type = "toggle",
              width = "normal",
              order = 2,
              set = function(_, val)
                NS.db.global.maps.templeofkotmogu.showorbinfo = val

                if val then
                  Stacks:SetAnchor(Orbs.frame, 0, -10)

                  if NS.db.global.maps.templeofkotmogu.showbuffinfo then
                    Orbs.buffTextFrame:SetPoint("TOPLEFT", Orbs.orbTextFrame, "BOTTOMLEFT", 0, -5)
                  end

                  Orbs.orbTextFrame:SetAlpha(1)
                  Orbs.frame:SetAlpha(1)
                else
                  Orbs.orbTextFrame:SetAlpha(0)

                  if NS.db.global.maps.templeofkotmogu.showbuffinfo == false then
                    if
                      NS.db.global.maps.eyeofthestorm.showflaginfo == false
                      and NS.db.global.maps.eyeofthestorm.showflagvalue == false
                    then
                      Stacks:SetAnchor(Bases.frame, 0, -10)
                    else
                      Stacks:SetAnchor(Flags.frame, 0, -10)
                    end

                    Orbs.frame:SetAlpha(0)
                  else
                    Orbs.buffTextFrame:SetPoint("TOPLEFT", Orbs.frame, "TOPLEFT", 0, 0)
                  end
                end

                NS.UpdateContainerSize(Orbs.frame)

                if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 6"
                  )
                end
              end,
            },
            showbuffinfo = {
              name = "Show 4x Orb Buff",
              desc = "Shows when the 4x point increase buff starts when carrying 4 orbs.",
              type = "toggle",
              width = "normal",
              order = 3,
              set = function(_, val)
                NS.db.global.maps.templeofkotmogu.showbuffinfo = val

                if val then
                  Stacks:SetAnchor(Orbs.frame, 0, -10)

                  if NS.db.global.maps.templeofkotmogu.showorbinfo then
                    Orbs.buffTextFrame:SetPoint("TOPLEFT", Orbs.orbTextFrame, "BOTTOMLEFT", 0, -5)
                  else
                    Orbs.buffTextFrame:SetPoint("TOPLEFT", Orbs.frame, "TOPLEFT", 0, 0)
                  end

                  Orbs.buffTextFrame:SetAlpha(1)
                  Orbs.frame:SetAlpha(1)
                else
                  Orbs.buffTextFrame:SetAlpha(0)

                  if NS.db.global.maps.templeofkotmogu.showorbinfo == false then
                    if
                      NS.db.global.maps.eyeofthestorm.showflaginfo == false
                      and NS.db.global.maps.eyeofthestorm.showflagvalue == false
                    then
                      Stacks:SetAnchor(Bases.frame, 0, -10)
                    else
                      Stacks:SetAnchor(Flags.frame, 0, -10)
                    end

                    Orbs.frame:SetAlpha(0)
                  end
                end

                NS.UpdateContainerSize(Orbs.frame)

                if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
                  NS.UpdateInfoSize(
                    NS.Info.frame,
                    NS.Banner,
                    { NS.Score, NS.Bases, NS.Flags, NS.Orbs, NS.Stacks },
                    "NS.AceConfig 7"
                  )
                end
              end,
            },
          },
        },
        thebattleforgilneas = {
          name = "The Battle for Gilneas",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.thebattleforgilneas[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.thebattleforgilneas[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for The Battle for Gilneas. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.thebattleforgilneas.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
          },
        },
        twinpeaks = {
          name = "Twin Peaks",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.twinpeaks[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.twinpeaks[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Twin Peaks. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.twinpeaks.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
            showdebuffinfo = {
              name = "Show Debuff Info",
              desc = "Shows the damage taken increase and healing received decrease % amounts for Flag Carriers.",
              type = "toggle",
              width = "normal",
              order = 2,
            },
          },
        },
        warsonggulch = {
          name = "Warsong Gulch",
          type = "group",
          disabled = function(info)
            return info[3] and not NS.db.global.maps[info[2]].enabled
          end,
          get = function(info)
            local name = info[#info]
            return NS.db.global.maps.warsonggulch[name]
          end,
          set = function(info, val)
            local name = info[#info]
            NS.db.global.maps.warsonggulch[name] = val
          end,
          args = {
            enabled = {
              name = "Enabled",
              desc = "Enable for Warsong Gulch. Toggling this feature on/off while inside a game requires a reload.",
              type = "toggle",
              width = "half",
              order = 1,
              disabled = false,
              set = function(_, val)
                NS.db.global.maps.warsonggulch.enabled = val

                if val then
                  Maps:PrepareZone()
                else
                  if NS.IN_GAME then
                    Prediction:StopInfoTracker()
                    Interface:Clear()
                  end
                end
              end,
            },
            showdebuffinfo = {
              name = "Show Debuff Info",
              desc = "Shows the damage taken increase and healing received decrease % amounts for Flag Carriers.",
              type = "toggle",
              width = "normal",
              order = 2,
            },
          },
        },
      },
    },
  },
}

function Options:SlashCommands(message)
  if message == "toggle lock" then
    if NS.db.global.general.lock == false then
      NS.db.global.general.lock = true
      Anchor:Lock(Anchor.frame)
    else
      NS.db.global.general.lock = false
      Anchor:Unlock(Anchor.frame)
    end
  elseif message == "toggle placeholder" then
    if NS.db.global.general.test == false then
      NS.db.global.general.test = true
    else
      NS.db.global.general.test = false
    end
  elseif message == "toggle banner" then
    if NS.db.global.general.banner == false then
      NS.db.global.general.banner = true
    else
      NS.db.global.general.banner = false
    end
  elseif message == "toggle debug" then
    NS.db.global.debug = not NS.db.global.debug
    NS.write("Debug mode", NS.db.global.debug and "enabled" or "disabled")
  else
    AceConfigDialog:Open(AddonName)
  end
end

function Options:Setup()
  AceConfig:RegisterOptionsTable(AddonName, NS.AceConfig)
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName)

  SLASH_BGWC1 = "/battlegroundwinconditions"
  SLASH_BGWC2 = "/bgwc"
  SLASH_BGWC3 = "/bwc"

  function SlashCmdList.BGWC(message)
    self:SlashCommands(message)
  end
end

function BGWC:ADDON_LOADED(addon)
  if addon == AddonName then
    BGWCFrame:UnregisterEvent("ADDON_LOADED")

    BattlegroundWinConditionsDB = BattlegroundWinConditionsDB
        and next(BattlegroundWinConditionsDB) ~= nil
        and BattlegroundWinConditionsDB
      or {}

    -- Copy any settings from default if they don't exist in current profile
    NS.CopyDefaults(NS.DefaultDatabase, BattlegroundWinConditionsDB)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    NS.db = BattlegroundWinConditionsDB

    -- Remove table values no longer found in default settings
    NS.CleanupDB(BattlegroundWinConditionsDB, NS.DefaultDatabase)

    Options:Setup()
    Version:Setup()
    Changelog:Setup()
  end
end
BGWCFrame:RegisterEvent("ADDON_LOADED")
