local AheadOfTheCurve = LibStub('AceAddon-3.0'):NewAddon('AheadOfTheCurve', 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local container
local checkButton
local raids = {
    {
        ids = {413, 414, 468},
        name = 'Emerald Nightmare',        
        achievements = {11191, 11194, 10820},
        highestCompleted = nil,
    },
    {
        ids = {456, 457},
        name = 'Trial of Valor',        
        achievements = {11580, 11581, 11394},
        highestCompleted = nil,
    }, 
    {
        ids = {415, 416},
        name = 'The Nighthold',        
        achievements = {11192, 11195, 10839},
        highestCompleted = nil,
    }, 
    {
        ids = {458},
        name = 'World Bosses',
        achievements = {},
        highestCompleted = nil,
    }
}
local defaults = {
  global = {
    enable = {
        addon = true,
        override = false,
        whisper = false
    }
  }
}

function AheadOfTheCurve:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('AheadOfTheCurveDB', defaults)

    self.achievementSearchList = {}
    local id = self.db.global.overrideAchievement

    if id ~= nil then
        local _, name = GetAchievementInfo(id)
        self.achievementSearchList[id] = name
    end
end

function AheadOfTheCurve:OnEnable()
    self:HookScript(LFGListFrame.CategorySelection.FindGroupButton, 'OnClick', 'GetLFGCategory')
    self:HookScript(LFGListFrame.SearchPanel.SignUpButton, 'OnClick', 'GetLFGRaid')
    self:HookScript(LFGListApplicationDialog.SignUpButton, 'OnClick', 'SendWhisper')
    self:RegisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:RegisterEvent('ACHIEVEMENT_EARNED')
    self:GetHighestDefaultAchievement()

    if not container then
        container = CreateFrame('Frame', 'AheadOfTheCurveDialog', LFGListApplicationDialog)
        container:SetSize(306, 50)
        container:SetPoint('BOTTOM', 0, -55)
        container:SetBackdrop({
            bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
            edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
    end

    if not checkButton then
        checkButton = CreateFrame('CheckButton', 'AheadOfTheCurveCheckBox', container, 'UICheckButtonTemplate')
        checkButton:SetSize(24, 24)
        checkButton:SetPoint('CENTER', -85, 0)
        checkButton:SetChecked(self.db.global.enable.whisper)
        checkButton.text:SetText('Use Ahead of the Curve Whisper')
        checkButton.text:SetWidth(175)
        checkButton:SetScript('OnEnter', function(self) 
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText('Will only send for the following raids: \n Emerald Nightmare \n Trial of Valor \n The Nighthold', nil, nil, nil, nil, true) 
            GameTooltip:Show() 
        end)
        checkButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
    end

    container:Show()
    checkButton:Show()
end

function AheadOfTheCurve:OnDisable()
    self:UnhookAll()
    self:UnregisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:UnregisterEvent('ACHIEVEMENT_EARNED')
    container:Hide()
    checkButton:Hide()
end

function AheadOfTheCurve:ACHIEVEMENT_SEARCH_UPDATED()
    local numFiltered = GetNumFilteredAchievements();

    if numFiltered < 500 then
        for index in pairs(self.achievementSearchList) do
            self.achievementSearchList[index] = nil
        end

        for index = 1, numFiltered do
            local achievementId = GetFilteredAchievementID(index)
            local _, name, _, completed = GetAchievementInfo(achievementId)

            if completed then
                 self.achievementSearchList[achievementId] = name
            end    
        end 
    end

    AceConfigRegistry:NotifyChange('AheadOfTheCurve')
end

function AheadOfTheCurve:ACHIEVEMENT_EARNED()
    self:GetHighestDefaultAchievement()
    AceConfigRegistry:NotifyChange('AheadOfTheCurve')
end

function AheadOfTheCurve:GetHighestDefaultAchievement()
    for index, raid in pairs(raids) do
        for _, id in pairs(raid.achievements) do
            local _, _, _, completed = GetAchievementInfo(id)

            if completed then
                raids[index].highestCompleted = id
                break
            end
        end
    end
end

function AheadOfTheCurve:DisplayHighestDefaultAchievement(index)
    if raids[index].highestCompleted ~= nil then 
        local _, name = GetAchievementInfo(raids[index].highestCompleted) 
        return name
    else
        return 'None Completed'
    end
end

function AheadOfTheCurve:GetLFGCategory(findAGroupButton)
    local category = findAGroupButton:GetParent().selectedCategory;

    if category ~= 3 then
        container:Hide()
        checkButton:Hide()
    else
        container:Show()
        checkButton:Show()
    end
end

function AheadOfTheCurve:GetLFGRaid(signUpButton)
    local _, raidId = C_LFGList.GetSearchResultInfo(signUpButton:GetParent().selectedResult)
    local highestCompleted = self:GetLFGAchievement(raidId)

    if not highestCompleted and not self.db.global.enable.override or raidId == raids[4].ids[1] then
        container:Hide()
        checkButton:Hide()
    else
        container:Show()
        checkButton:Show()
    end
end

function AheadOfTheCurve:GetLFGAchievement(raidId)
    for _, raid in pairs(raids) do
        for _, id in pairs(raid.ids) do
            if id == raidId then
                return raid.highestCompleted
            end
        end
    end
end

function AheadOfTheCurve:SendWhisper(signUpButton)
    local _, raidId, _, _, _, _, _, _, _, _, _, _, leaderName = C_LFGList.GetSearchResultInfo(signUpButton:GetParent().resultID)

    if checkButton:GetChecked() or raidId == raids[4].ids[1] then
        local achievementId

        if self.db.global.enable.override then
            achievementId = self.db.global.overrideAchievement        
        else
            achievementId = self:GetLFGAchievement(raidId)
        end

        if achievementId then
            local success = pcall(SendChatMessage, GetAchievementLink(achievementId), 'WHISPER', nil, leaderName)

            if not success then
                self:Print('There was an error sending your whisper.')     
            end 
        end
    end
end