aotc = LibStub('AceAddon-3.0'):NewAddon('AheadOfTheCurve', 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local container
local button

local highestDefault = {
    {
        raid = 'Emerald Nightmare',
        ids = {413, 414, 468},
        achievements = {11191, 11194, 10820},
        highestCompleted = nil,
    },
    {
        raid = 'Trial of Valor',
        ids = {456, 457},
        achievements = {11580, 11581, 11394},
        highestCompleted = nil,
    }, 
    {
        raid = 'The Nighthold',
        ids = {415, 416},
        achievements = {11192, 11195, 10839},
        highestCompleted = nil,
    }
}

local dbDefaults = {
  global = {
    enable = {
        addon = true,
        override = false,
        whisper = true
    }
  }
}

function aotc:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('AheadOfTheCurveDB', dbDefaults)

    aotc.achievementList = {}
    local id = self.db.global.overrideAchievement

    if id ~= nil then
        local _, name = GetAchievementInfo(id)
        aotc.achievementList[id] = name
    end

    local options = self:GetOptions()
    
    AceConfig:RegisterOptionsTable('AheadOfTheCurve', options)
    AceConfigDialog:AddToBlizOptions('AheadOfTheCurve', 'AheadOfTheCurve')

    self:RegisterChatCommand('aotc', 'OpenOptions')

    container = CreateFrame('Frame', 'AoTCDialog', LFGListApplicationDialog)
    container:SetSize(306, 50)
    container:SetPoint('BOTTOM', 0, -55)
    container:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
        edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    button = CreateFrame('CheckButton', 'AoTCCheckBox', container, 'UICheckButtonTemplate')
    button:SetSize(24, 24)
    button:SetPoint('CENTER', -45, 0)
    button:SetChecked(self.db.global.enable.whisper)
    button.text:SetText('Use AoTC Whisper')
    button.text:SetWidth(100)
    button:SetScript('OnEnter', function(self) 
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Will only send for the following raids: \n Emerald Nightmare \n Trial of Valor \n The Nighthold', nil, nil, nil, nil, true) 
        GameTooltip:Show() 
    end)
    button:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

function aotc:OnEnable()
    self:HookScript(LFGListFrame.CategorySelection.FindGroupButton, 'OnClick', 'GetLFGCategory')
    self:HookScript(LFGListApplicationDialog.SignUpButton, 'OnClick', 'GetLFGInfo')
    self:RegisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:GetHighestDefault()
end

function aotc:GetLFGCategory(self)
    local category = self:GetParent().selectedCategory;

    if category ~= 3 then
        container:Hide()
    else
        container:Show()
    end
end

function aotc:OpenOptions()
    AceConfigDialog:SetDefaultSize('AheadOfTheCurve', 500, 465)
    AceConfigDialog:Open('AheadOfTheCurve')
end

function aotc:GetLFGInfo(self)
    local id, 
        raidId, 
        name,
        comment, 
        voiceChat, 
        iLvl, 
        honorLevel, 
        age, 
        numBNetFriends,
        numCharFriends,
        numGuildMates,
        isDelisted,
        leaderName = C_LFGList.GetSearchResultInfo(self:GetParent().resultID)
    
    -- aotc.raid = string.gsub(C_LFGList.GetActivityInfo(raidId) ,'%s%b()', '')

    if button:GetChecked() then
        local achievementId

        if aotc.db.global.enable.override then
            achievementId = aotc.db.global.overrideAchievement        
        else
            achievementId = aotc:GetAchievement(raidId)
        end

        if achievementId then
            local success = pcall(SendChatMessage, pcall(GetAchievementLink(achievementId)), 'WHISPER', nil, leaderName)

            if not success then
                aotc:Print('There was an error sending your whisper.')     
            end 
        else
            aotc:Print('Whisper not sent. No achievement found.')
        end
    end
end

function aotc:GetAchievement(raidId)
    for index, raid in pairs(highestDefault) do
        for _, id in pairs(raid.ids) do
            if id == raidId then
                return raid.highestCompleted
            end
        end
    end
end

function aotc:ACHIEVEMENT_SEARCH_UPDATED()
    local numFiltered = GetNumFilteredAchievements();

    -- Limit searchs to only 500 results for now
    if numFiltered < 500 then
        for index in pairs(aotc.achievementList) do
            aotc.achievementList[index] = nil
        end

        for index = 1, numFiltered do
            local achievementId = GetFilteredAchievementID(index)
            local _, name, _, completed = GetAchievementInfo(achievementId)

            if completed then
                 aotc.achievementList[achievementId] = name
            end    
        end 
    end

    AceConfigRegistry:NotifyChange('AheadOfTheCurve')
end

function aotc:GetHighestDefault()
    for index, raid in pairs(highestDefault) do
        for _, id in pairs(raid.achievements) do
            local _, _, _, completed = GetAchievementInfo(id)

            if completed then
                highestDefault[index].highestCompleted = id
                break
            end
        end
    end
end

function aotc:GetOptions()
    return {
        name = 'Ahead Of The Curve',
        handler = aotc,
        type = 'group',
        args = {
            header1 = {
                order = 0,
                name = 'Default Highest Achievements Found',
                type = 'header'
            },
            emeraldNightmare = {
                order = 0.2,
                name = 'Emerald Nightmare',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function()
                    if highestDefault[1].highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault[1].highestCompleted) 
                        return name
                    else
                        return 'None Completed'
                    end 
                end
            },
            trialOfValor = {
                order = 0.3,
                name = 'Trial of Valor',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function()
                    if highestDefault[2].highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault[2].highestCompleted) 
                        return name
                    else
                        return 'None Completed'
                    end 
                end
            },
            nighthold = {
                order = 0.4,
                name = 'The Nighthold',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function()
                    if highestDefault[3].highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault[3].highestCompleted) 
                        return name
                    else
                        return 'None Completed'
                    end 
                end
            },
            header2 = {
                order = 1,
                name = 'Override Defaults',
                type = 'header'
            },
            enableOverride = {
                order = 1.1,
                name = 'Enable Override',
                desc = 'Overrides the default achievements found and will always send the selected achievement from the dropdown.',
                type = 'toggle',
                width = 'full',
                get = function() return self.db.global.enable.override end,
                set = function(info, value) self.db.global.enable.override = value end      
            },
            serach = {
                order = 1.2,
                name = 'Search Achievements',
                desc = 'Search term must be greater than 3 characters.',
                type = 'input',
                width = 'full',
                disabled = function() return not self.db.global.enable.override end,
                set = function(info, value) SetAchievementSearchString(value) end,
                validate = function(info, value) if string.len(value) < 3 then return 'Error: Search term must be greater than 3 characters' else return true end end
            },
            results = {
                order = 1.3,
                name = 'Select Override Achievement',
                desc = 'Results are limited to 500 and only completed achievemnts. Please try a more specific search term if you cannot find the achievement listed.',
                type = 'select',
                values = aotc.achievementList,
                width = 'full',
                disabled = function() return not self.db.global.enable.override end,
                get = function() return self.db.global.overrideAchievement end,
                set = function(info, value) self.db.global.overrideAchievement = value end
            },
            header3 = {
                order = 2,
                name = 'Other Options',
                type = 'header'
            },
            enableWhisper = {
                order = 2.1,
                name = 'Always Check Whisper Dialog Checkbox',
                desc = 'This will always check the whisper dialog checkbox when signing up for a group by default.',
                type = 'toggle',
                width = 'full',
                get = function() return self.db.global.enable.whisper end,
                set = function(info, value) self.db.global.enable.whisper = value end ,
                confirm = function() return 'Changes to this setting will not take effect until the ui is reloaded.' end
            },
            header4 = {
                order = 3,
                name = 'About',
                type = 'header'
            },
            about = {
                order = 3.1,
                name = 'Version: @project-version@ Created by Pigletoos of Skywall',
                type = 'description'
            }
        }
    }
end