local AheadOfTheCurve = LibStub('AceAddon-3.0'):GetAddon('AheadOfTheCurve')
local AheadOfTheCurveOptions = AheadOfTheCurve:NewModule('AheadOfTheCurveOptions', 'AceConsole-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')

function AheadOfTheCurveOptions:OnInitialize()
    self.db = AheadOfTheCurve.db

    local options = self:GetOptions()
    
    AceConfig:RegisterOptionsTable('AheadOfTheCurve', options)
    AceConfigDialog:AddToBlizOptions('AheadOfTheCurve', 'AheadOfTheCurve')

    self:RegisterChatCommand('aotc', 'OpenOptions')
end

function AheadOfTheCurveOptions:OpenOptions()
    AceConfigDialog:SetDefaultSize('AheadOfTheCurve', 500, 500)
    AceConfigDialog:Open('AheadOfTheCurve')
end

function AheadOfTheCurveOptions:GetOptions()
    return {
        name = 'Ahead of the Curve',
        handler = AheadOfTheCurve,
        type = 'group',
        args = {
            enable = {
                order = 0,
                name = 'Enable Addon',
                desc = 'Enables / disables the addon',
                type = 'toggle',
                width = 'full',                
                get = function() return self.db.global.enable.addon end,
                set = function(info, value)
                    self.db.global.enable.addon = value
                    
                    if self.db.global.enable.addon then
                        AheadOfTheCurve:OnEnable()
                    else
                        AheadOfTheCurve:OnDisable()
                    end
                end
            },
            header1 = {
                order = 1,
                name = 'Default Highest Achievements Found',
                type = 'header'
            },
            emeraldNightmare = {
                order = 1.2,
                name = 'Emerald Nightmare',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function() return AheadOfTheCurve:DisplayHighestDefaultAchievement(1) end
            },
            trialOfValor = {
                order = 1.3,
                name = 'Trial of Valor',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function() return AheadOfTheCurve:DisplayHighestDefaultAchievement(2) end
            },
            nighthold = {
                order = 1.4,
                name = 'The Nighthold',
                type = 'input',
                width = 'full',
                disabled = true,
                get = function() return AheadOfTheCurve:DisplayHighestDefaultAchievement(3) end
            },
            header2 = {
                order = 2,
                name = 'Override Defaults',
                type = 'header'
            },
            enableOverride = {
                order = 2.1,
                name = 'Enable Override',
                desc = 'Overrides the default achievements found and will always send the selected achievement from the dropdown.',
                type = 'toggle',
                width = 'full',
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return self.db.global.enable.override end,
                set = function(info, value) self.db.global.enable.override = value end      
            },
            serach = {
                order = 2.2,
                name = 'Search Achievements',
                desc = 'Search term must be greater than 3 characters.',
                type = 'input',
                width = 'full',
                disabled = function() return not self.db.global.enable.override or not self.db.global.enable.addon end,
                set = function(info, value) SetAchievementSearchString(value) end,
                validate = function(info, value) if string.len(value) < 3 then return 'Error: Search term must be greater than 3 characters' else return true end end
            },
            results = {
                order = 2.3,
                name = 'Select Override Achievement',
                desc = 'Results are limited to 500 and only completed achievemnts. Please try a more specific search term if you cannot find the achievement listed.',
                type = 'select',
                values = AheadOfTheCurve.achievementSearchList,
                width = 'full',
                disabled = function() return not self.db.global.enable.override or not self.db.global.enable.addon end,
                get = function() return self.db.global.overrideAchievement end,
                set = function(info, value) self.db.global.overrideAchievement = value end
            },
            header3 = {
                order = 3,
                name = 'Other Options',
                type = 'header'
            },
            enableWhisper = {
                order = 3.1,
                name = 'Always Check Whisper Dialog Checkbox',
                desc = 'This will always check the whisper dialog checkbox when signing up for a group by default.',
                type = 'toggle',
                width = 'full',
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return self.db.global.enable.whisper end,
                set = function(info, value) self.db.global.enable.whisper = value end ,
                confirm = function() return 'Changes to this setting will not take effect until the ui is reloaded.' end
            },
            header4 = {
                order = 4,
                name = 'About',
                type = 'header'
            },
            about = {
                order = 4.1,
                name = 'Version: @project-version@ Created by Pigletoos of Skywall',
                type = 'description'
            }
        }
    }
end