local AheadOfTheCurve = LibStub('AceAddon-3.0'):NewAddon('AheadOfTheCurve', 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local keyStoneLink
local defaults = {
    global = {
        enable = {
            addon = true,
            override = false,
            whispers = {
                achievement = false,
                keystone = false
            }
        },
        minimap = {
            hide = true
        } 
    }
}

function AheadOfTheCurve:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('AheadOfTheCurveDB', defaults)
    
    self.achievementSearchList = {}
    local id = self.db.global.overrideAchievement
    
    if id then
        local _, name = GetAchievementInfo(id)
        self.achievementSearchList[id] = name
    else
        self.achievementSearchList[1] = 'Please search and then select an achievement from the list'
    end

    self.instances = {
        {
            ids = {413, 414, 468},
            name = 'Emerald Nightmare',
            achievements = {11191, 10827, 11194, 10820},
            highestCompleted = nil,
        },
        {
            ids = {456, 457},
            name = 'Trial of Valor',
            achievements = {11580, 11398, 11581, 11394},
            highestCompleted = nil,
        },
        {
            ids = {415, 416},
            name = 'The Nighthold',
            achievements = {11192, 10850, 11195, 10839},
            highestCompleted = nil,
        },
        {
            ids = {458},
            name = 'World Bosses',
            achievements = {},
            highestCompleted = nil,
        },
        {
            ids = {459, 460, 461, 462, 463, 464, 465, 466, 467},
            name = 'Mythic Plus',
            achievements = {11162, 11185, 11184},
            highestCompleted = nil,
        },
        {
            ids = {455},
            name = 'Karazhan',
            achievements = {11430, 11429},
            highestCompleted = nil,
        }
    }
end

function AheadOfTheCurve:OnEnable()
    self:HookScript(LFGListFrame.CategorySelection.FindGroupButton, 'OnClick', 'GetLFGCategory')
    self:HookScript(LFGListFrame.SearchPanel.SignUpButton, 'OnClick', 'GetLFGInstance')
    self:HookScript(LFGListApplicationDialog.SignUpButton, 'OnClick', 'SendWhisper')
    self:RegisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:RegisterEvent('ACHIEVEMENT_EARNED')
    self:GetHighestDefaultAchievement()
    
    if not self.container then
        self.container = CreateFrame('Frame', 'AheadOfTheCurveDialog', LFGListApplicationDialog)
        self.container:SetSize(306, 50)
        self.container:SetPoint('BOTTOM', 0, -55)
        self.container:SetBackdrop({
            bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
            edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
    end
    
    if not self.checkButtonAchievement then
        self.checkButtonAchievement = CreateFrame('CheckButton', 'AheadOfTheCurveCheckBoxAchievement', self.container, 'UICheckButtonTemplate')
        self.checkButtonAchievement:SetSize(24, 24)
        self.checkButtonAchievement:SetPoint('CENTER', -85, 0)
        self.checkButtonAchievement:SetChecked(self.db.global.enable.whispers.achievement)
    end

    if not self.checkButtonKeystone then
        self.checkButtonKeystone = CreateFrame('CheckButton', 'AheadOfTheCurveCheckBoxKeystone', self.container, 'UICheckButtonTemplate')
        self.checkButtonKeystone:SetSize(24, 24)
        self.checkButtonKeystone:SetPoint('CENTER', -85, -11)
        self.checkButtonKeystone:SetChecked(self.db.global.enable.whispers.keystone)
        self.checkButtonKeystone.text:SetText('Send Mythic Plus Keystone')
        self.checkButtonKeystone.text:SetWidth(145)
    end
    
    self.container:Show()
    self.checkButtonAchievement:Show()
    self.checkButtonKeystone:Hide()
end

function AheadOfTheCurve:OnDisable()
    self:UnhookAll()
    self:UnregisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:UnregisterEvent('ACHIEVEMENT_EARNED')
    self.container:Hide()
    self.checkButtonAchievement:Hide()
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
    for index, instance in pairs(self.instances) do
        for _, id in pairs(instance.achievements) do
            local _, _, _, completed = GetAchievementInfo(id)
            
            if completed then
                self.instances[index].highestCompleted = id
                break
            end
        end
    end
end

function AheadOfTheCurve:DisplayHighestDefaultAchievement(index)
    if self.instances[index].highestCompleted then
        local _, name, _, _, _, _, _, _, _, iconPath = GetAchievementInfo(self.instances[index].highestCompleted)
        return name, iconPath
    else
        return nil, nil
    end
end

function AheadOfTheCurve:GetLFGCategory(findAGroupButton)
    local category = findAGroupButton:GetParent().selectedCategory;
    
    if category ~= 2 or category ~= 3 then
        self.container:Hide()
        self.checkButtonAchievement:Hide()
    else
        self.container:Show()
        self.checkButtonAchievement:Show()
    end

    if category == 2 then
        self:ScanBagsForKeystone()
    end
end

function AheadOfTheCurve:GetLFGInstance(signUpButton)
    local _, instanceId = C_LFGList.GetSearchResultInfo(signUpButton:GetParent().selectedResult)
    local highestCompleted = self:GetLFGAchievement(instanceId)
    local isMythicDungeon = self:IsMythicDungeon(instanceId)
    local checkButtonAchievementText, checkButtonAchievementWidth, checkButtonAchievementPoint = self:GetCheckButtonAchievementData(instanceId, isMythicDungeon)

    if not highestCompleted and not self.db.global.enable.override or raidId == self.instances[4].ids[1] then
        self.container:Hide()
        self.checkButtonAchievement:Hide()
    else
        self.container:Show()
        self.checkButtonAchievement:Show()
        self.checkButtonAchievement:SetChecked(self.db.global.enable.whispers.achievement)
        self.checkButtonAchievement.text:SetText(checkButtonAchievementText)
        self.checkButtonAchievement.text:SetWidth(checkButtonAchievementWidth)
        self.checkButtonAchievement:SetPoint('CENTER', checkButtonAchievementPoint, 0)      
    end

    if isMythicDungeon and keyStoneLink then
        self:ShowMythicPlusOption(highestCompleted)
    else
        self.container:SetPoint('BOTTOM', 0, -55)
        self.container:SetSize(306, 50)
        self.checkButtonAchievement:SetPoint('CENTER', checkButtonAchievementPoint, 0)
        self.checkButtonKeystone:Hide()
        self.checkButtonKeystone:SetChecked(false)
    end
end

function AheadOfTheCurve:GetCheckButtonAchievementData(instanceId, isMythicDungeon)
    if self.db.global.enable.override then
        return 'Send Override Achievement', 158, -85
    end

    if isMythicDungeon then
        return 'Send Mythic Plus Achievement', 170, -85
    end

    if instanceId == 455 then
        return 'Send Karazhan Achievement', 155, -75
    end

    return 'Send Ahead of the Curve Achievement', 205, -100
end

function AheadOfTheCurve:GetLFGAchievement(instanceId)
    for _, instance in pairs(self.instances) do
        for _, id in pairs(instance.ids) do
            if id == instanceId then
                return instance.highestCompleted
            end
        end
    end
end

function AheadOfTheCurve:SendWhisper(signUpButton)
    local _, instanceId, _, _, _, _, _, _, _, _, _, _, leaderName = C_LFGList.GetSearchResultInfo(signUpButton:GetParent().resultID)
    
    if self.checkButtonAchievement:GetChecked() or self.checkButtonKeystone:GetChecked() or instanceId == self.instances[4].ids[1] then
        local achievementId
        
        if self.db.global.enable.override and self.db.global.overrideAchievement then
            achievementId = self.db.global.overrideAchievement
        else
            achievementId = self:GetLFGAchievement(instanceId)
        end
        
        if achievementId then
            local success = pcall(SendChatMessage, self:BuildWhisper(achievementId), 'WHISPER', nil, leaderName)
            
            if not success then
                self:Print('There was an error sending your whisper.')
            end
        end
    end
end

function AheadOfTheCurve:BuildWhisper(achievementId)
    if self.checkButtonAchievement:GetChecked() and (self.checkButtonKeystone:GetChecked() and keyStoneLink) then
        return GetAchievementLink(achievementId) .. keyStoneLink
    end

    if self.checkButtonAchievement:GetChecked() then
        return GetAchievementLink(achievementId)
    end

    if self.checkButtonKeystone:GetChecked() and keyStoneLink then
        return keyStoneLink
    end
end

function AheadOfTheCurve:ScanBagsForKeystone()
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local _, _, _, _, _, _, link, _, _, itemId = GetContainerItemInfo(bag, slot)

            if itemId == 138019 then
                keyStoneLink = link
                break
            end
        end
    end
end

function AheadOfTheCurve:IsMythicDungeon(instanceId)
    for _, id in pairs(self.instances[5].ids) do
        if id == instanceId then
            return true
        end
    end
end

function AheadOfTheCurve:ShowMythicPlusOption(highestCompleted)
     if not highestCompleted and not self.db.global.enable.override then
        self.checkButtonAchievement:Hide()
        self.container:SetPoint('BOTTOM', 0, -55)
        self.container:SetSize(306, 50)
        self.checkButtonKeystone:SetPoint('CENTER', -75, 0)
        self.container:Show()
    else
        self.container:SetPoint('BOTTOM', 0, -75)
        self.container:SetSize(306, 70)
        self.checkButtonAchievement:SetPoint('CENTER', -85, 9)
    end

    self.checkButtonKeystone:SetChecked(self.db.global.enable.whispers.keystone)    
    self.checkButtonKeystone:Show()
end