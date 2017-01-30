aotc = LibStub('AceAddon-3.0'):NewAddon('AheadOfTheCurve', 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0')

local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local button

local highestDefault = {
    emeraldNightmare = {
        achievements = {11191, 11194, 10820},
        highestCompleted = nil,
    },
    trialOfValor = {
        achievements = {11580, 11581, 11394},
        highestCompleted = nil,
    }, 
    nighthold= {
        achievements = {11192, 11195, 10839},
        highestCompleted = nil,
    }
}

local dbDefaults = {
  global = {
    enable = {
        addon = true,
        override = false,
        whipser = true
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

    local container = CreateFrame('Frame', 'AoTCDialog', LFGListApplicationDialog, 'ThinBorderTemplate')
    container:SetSize(305, 40)
    container:SetPoint('BOTTOM', 0, -45)

    button = CreateFrame('CheckButton', 'AoTCCheckBox', container, 'UICheckButtonTemplate')
    button:SetSize(24, 24)
    button:SetPoint('CENTER', -45, 0)
    button:SetChecked(self.db.global.enable.whipser)
    button.text:SetText('Use AoTC Whipser')
    button.text:SetWidth(100)
end

function aotc:OnEnable()
    self:HookScript(LFGListApplicationDialog.SignUpButton, 'OnClick', 'GetLFGInfo')
    self:RegisterEvent('ACHIEVEMENT_SEARCH_UPDATED')
    self:GetHighestDefault('emeraldNightmare')
    self:GetHighestDefault('trialOfValor')
    self:GetHighestDefault('nighthold')
end

function aotc:OpenOptions()
    AceConfigDialog:SetDefaultSize('AheadOfTheCurve', 475, 475)
    AceConfigDialog:Open('AheadOfTheCurve')
end

function aotc:GetLFGInfo(self)
    local id, 
        activityID, 
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
    
    aotc.test = C_LFGList.GetActivityInfo(activityID)

    if button:GetChecked() then
        --SendChatMessage(GetAchievementLink(11194), 'WHISPER', nil, leaderName)
        aotc:Print(string.format('Whisper sent to %s', leaderName))
    end
end

local numFiltered

function aotc:ACHIEVEMENT_SEARCH_UPDATED()
    numFiltered = GetNumFilteredAchievements();

    self:Print(numFiltered)

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

function aotc:GetHighestDefault(raid)
    for index, value in pairs(highestDefault[raid].achievements) do
        local _, _, _, completed = GetAchievementInfo(value)

        if completed then
            highestDefault[raid].highestCompleted = value
            return
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
                    if highestDefault.emeraldNightmare.highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault.emeraldNightmare.highestCompleted) 
                        return name
                    else
                        return 'None Completed'
                    end 
                end
            },
            trialOfValor = {
                order = 0.3,
                name = 'Trial Of Valor',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function()
                    if highestDefault.trialOfValor.highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault.trialOfValor.highestCompleted) 
                        return name
                    else
                        return 'None Completed'
                    end 
                end
            },
            nighthold = {
                order = 0.4,
                name = 'Nighthold',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function()
                    if highestDefault.nighthold.highestCompleted ~= nil then 
                        local _, name = GetAchievementInfo(highestDefault.nighthold.highestCompleted) 
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
                name = 'Always Check Whipser Dialog Checkbox',
                desc = 'This will always check the whisper dialog checkbox when signing up for a group by default.',
                type = 'toggle',
                width = 'full',
                get = function() return self.db.global.enable.whipser end,
                set = function(info, value) self.db.global.enable.whipser = value end ,
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