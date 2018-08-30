local AheadOfTheCurve = LibStub('AceAddon-3.0'):GetAddon('AheadOfTheCurve')
local AheadOfTheCurveOptions = AheadOfTheCurve:NewModule('AheadOfTheCurveOptions', 'AceConsole-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local LDB = LibStub('LibDataBroker-1.1')
local icon = LibStub('LibDBIcon-1.0')
local newSearch = false
local optionsOpened = false

function AheadOfTheCurveOptions:OnInitialize()
    self.db = AheadOfTheCurve.db
    self:RegisterChatCommand('aotc', 'OpenOptions')

    local aotcLDB = LDB:NewDataObject('AheadOfTheCurveMinimap', {
        type = 'data source',
        text = 'AheadOfTheCurveMinimap',
        icon = 'Interface\\AddOns\\AheadOfTheCurve\\Media\\icon',
        OnClick = function(_, button) 
            if button == 'LeftButton' then
                self:OpenOptions() 
            end 
        end,
        OnTooltipShow = function(self)
            self:AddLine('Ahead of the Curve')
            self:AddLine('Left Click to open the options menu.')
        end
    })

    icon:Register('AheadOfTheCurveMinimap', aotcLDB, self.db.global.minimap)
end

function AheadOfTheCurveOptions:OnEnable()
    local options = self:GetOptions()
    local blizOptions = self:GetBlizOptions()

    self:GetInstanceOptions(options)
    
    AceConfig:RegisterOptionsTable('AheadOfTheCurve', options)
    AceConfig:RegisterOptionsTable('AheadOfTheCurveOptions', blizOptions)
    AceConfigDialog:AddToBlizOptions('AheadOfTheCurveOptions', 'Ahead of the Curve')
end

function AheadOfTheCurveOptions:TableLength(t)
    local count = 0

    for _ in pairs(t) do 
        count = count + 1 
    end

    return count
end

function AheadOfTheCurveOptions:LinkAchievement(index)
    local achievementId = AheadOfTheCurve.instances[index].highestCompleted
                        
    if achievementId then
        ChatFrame1EditBox:Show()
        ChatFrame1EditBox:SetFocus()
        ChatFrame1EditBox:Insert(GetAchievementLink(achievementId))
    end
end

function AheadOfTheCurveOptions:OpenOptions()
    if not optionsOpened then
        optionsOpened = true

        local height = 480 

        for index, instance in pairs(AheadOfTheCurve.instances) do
            if instance.highestCompleted ~= nil then
                height = height + 30
            end
        end

        AceConfigDialog:SetDefaultSize('AheadOfTheCurve', 500, height)
        AceConfigDialog:Open('AheadOfTheCurve')
    else
        optionsOpened = false
        AceConfigDialog:Close('AheadOfTheCurve')
    end
end

function AheadOfTheCurveOptions:GetBlizOptions()
    return {
        name = 'Ahead of the Curve',
        handler = AheadOfTheCurve,
        type = 'group',
        args = {
            configure = {
                name = 'Configure',
                descStyle = 'inline',
                type = 'execute',
                func = function()
                    while CloseWindows() do end
                    AheadOfTheCurveOptions:OpenOptions()
                end
            }
        }
    }
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
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return self.db.global.enable.override end,
                set = function(info, value)self.db.global.enable.override = value end
            },
            serach = {
                order = 2.2,
                name = 'Search Achievements',
                desc = 'Search term must be greater than 3 characters.',
                type = 'input',
                width = 'full',
                disabled = function() return not self.db.global.enable.override or not self.db.global.enable.addon end,
                set = function(info, value) 
                    SetAchievementSearchString(value) 
                    newSearch = true 
                end,
                validate = function(info, value) 
                    if string.len(value) < 3 then 
                        return 'Error: Search term must be greater than 3 characters' 
                    else 
                        return true 
                    end 
                end
            },
            results = {
                order = 2.3,
                name = function()
                    if newSearch then 
                        return string.format('Select Override Achievement: %s Results Returned', tostring(self:TableLength(AheadOfTheCurve.achievementSearchList)))
                    else
                        return 'Select Override Achievement'
                    end
                end,
                desc = 'Results are limited to 500 and only completed achievemnts. Please try a more specific search term if you cannot find the achievement listed.',
                type = 'select',
                values = AheadOfTheCurve.achievementSearchList,
                width = 'full',
                disabled = function() 
                    return not self.db.global.enable.override 
                           or not self.db.global.enable.addon 
                           or (not self.db.global.overrideAchievement and not newSearch) 
                end,
                get = function() 
                    if self.db.global.overrideAchievement then
                        return self.db.global.overrideAchievement
                    else
                        return 1
                    end
                end,
                set = function(info, value) self.db.global.overrideAchievement = value end,
                validate = function(info, value) 
                    if value == 1 then 
                        return 'Error: Please select an achievement' 
                    else 
                        return true 
                    end 
                end
            },
            header3 = {
                order = 3,
                name = 'Other Options',
                type = 'header'
            },
            enableWhisperAchievement = {
                order = 3.1,
                name = 'Always Check Achievement Whisper Dialog Checkbox',
                desc = 'This will always check the achievement whisper dialog checkbox when signing up for a group by default.',
                type = 'toggle',
                width = 'double',
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return self.db.global.enable.whispers.achievement end,
                set = function(info, value) 
                    self.db.global.enable.whispers.achievement = value 
                    AheadOfTheCurve.checkButtonAchievement:SetChecked(value) 
                end,
            },
            enableWhisperKeystone = {
                order = 3.2,
                name = 'Always Check Keystone Whisper Dialog Checkbox',
                desc = 'This will always check the keystone whisper dialog checkbox when signing up for a mythic plus group by default.',
                type = 'toggle',
                width = 'double',
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return self.db.global.enable.whispers.keystone end,
                set = function(info, value) 
                    self.db.global.enable.whispers.keystone = value 
                    AheadOfTheCurve.checkButtonKeystone:SetChecked(value)  
                end,
            },
            minimap = {
                order = 3.3,
                name = 'Show Minimap Icon',
                desc = 'Displays the minimap icon.',
                type = 'toggle',
                disabled = function() return not self.db.global.enable.addon end,
                get = function() return not self.db.global.minimap.hide end,
                set = function(info, value) 
                    self.db.global.minimap.hide = not value 

                    if value then 
                        icon:Show('AheadOfTheCurveMinimap') 
                    else 
                        icon:Hide('AheadOfTheCurveMinimap') 
                    end 
                end
            },
            header4 = {
                order = 4,
                name = 'About',
                type = 'header'
            },
            about = {
                order = 4.1,
                name = 'Version: @project-version@\nCreated by Pigletoos of Zul\'jin-US',
                type = 'description'
            }
        }
    }
end

function AheadOfTheCurveOptions:GetInstanceOptions(options)
    local highestCompletedCount = 0

    for index, instance in pairs(AheadOfTheCurve.instances) do
        if next(instance.achievements) ~= nil and instance.highestCompleted ~= nil then
            options.args[string.format('instance%sIcon', index)] = {
                order = 1 + (index / 10),
                image = function() local _, iconPath = AheadOfTheCurve:DisplayHighestDefaultAchievement(index) return iconPath end,
                type = 'execute',
                width = 'half',
                name = '',
                func = function() self:LinkAchievement(index) end
            }

            options.args[string.format('instance%sButton', index)] = {
                order = 1 + ((index / 10) + 0.01),
                name = function() local name = AheadOfTheCurve:DisplayHighestDefaultAchievement(index) return string.format('%s: %s', instance.name, name) end,
                desc = 'Link Achievement',
                type = 'execute',
                width = 'double',
                func = function() self:LinkAchievement(index) end
            }

            highestCompletedCount = highestCompletedCount + 1
        end
    end

    if highestCompletedCount == 0 then
        local instances = {}

        for index, instance in pairs(AheadOfTheCurve.instances) do
            if next(instance.achievements) ~= nil then
                table.insert(instances, string.format('\n - %s', instance.name))
            end
        end

        options.args.noneFound = {
            order = 1.1,
            name = string.format('No achievements have been earned for: %s', table.concat(instances)),
            width = 'full',
            type = 'description'
        }
    end
end
