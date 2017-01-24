aotc = LibStub('AceAddon-3.0'):NewAddon('AheadOfTheCurve', 'AceConsole-3.0', 'AceHook-3.0')

function aotc:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New('AheadOfTheCurveDB') 
end

function aotc:OnEnable()
    aotc:HookScript(LFGListApplicationDialog.SignUpButton, 'OnClick', 'GetLFGInfo')
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
  --SendChatMessage(GetAchievementLink(11194), 'WHISPER', nil, leaderName)
end