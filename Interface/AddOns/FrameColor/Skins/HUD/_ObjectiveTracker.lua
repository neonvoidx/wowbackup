local _, private = ...

-- Specify the options.
local options = {
  name = "_ObjectiveTracker",
  displayedName = "",
  order = 3,
  category = "HUD",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("main"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, 0)
end

function skin:Apply(mainColor, desaturation)
  -- Headers
  for _, objectiveTrackerFrame in pairs({
    AdventureObjectiveTracker,
    MonthlyActivitiesObjectiveTracker,
    ObjectiveTrackerFrame,
    WorldQuestObjectiveTracker,
    BonusObjectiveTracker,
    QuestObjectiveTracker,
    ScenarioObjectiveTracker,
    AchievementObjectiveTracker,
    CampaignQuestObjectiveTracker,
    ProfessionsRecipeTracker,
    InitiativeTasksObjectiveTracker,
  }) do
    objectiveTrackerFrame.Header.Background:SetDesaturation(desaturation)
    objectiveTrackerFrame.Header.Background:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end
end


