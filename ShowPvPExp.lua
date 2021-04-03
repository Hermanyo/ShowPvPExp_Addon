---@diagnostic disable: undefined-global
local __DEV__ = true; -- to debugging
local bracketsNames = {"2v2", "3v3", "5v5", "RBG"}
local achievements = {370, 595, 596, nil}
local showErrorMessage = false;
local LocalGameTooltip = GameTooltip;

-- local function Ternary ( cond , T , F ) // Ternay comparison
--     if cond then return T else return F end
-- end
local function PrintDebugMessage(message)
    if __DEV__ then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end
local function RatingColor(score)
    if score <= 1499 then
        return '|cff9d9d9d'
    elseif score <= 1799 then
        return '|cff1eff00'
    elseif score <= 2099 then
        return '|cff0070dd'
    elseif score <= 2399 then
        return '|cffa335ee'
    else
        return '|cffff8000'
    end
end

local function ArenaRatingByBracket(bracket)
    local rating, seasonPlayed, seasonWon = GetInspectArenaData(bracket)
    if rating > 0 then
        return RatingColor(rating) .. rating .. "|cffffffff";
    end
    return '|cff9d9d9d' .. 0 .. "|cffffffff";
end

local function PrevArenaRatingByAchievID(AchievId)
    if (AchievId == nil) then
        return '|cff9d9d9d' .. 0 .. "|cffffffff"
    end
    local value = GetComparisonStatistic(AchievId);
    if tonumber(value) ~= nil then
        local prevRating = tonumber(GetComparisonStatistic(AchievId));
        return RatingColor(prevRating) .. prevRating .. "|cffffffff";
    end
    return '|cff9d9d9d' .. 0 .. "|cffffffff";
end

local function WritePvPExp(tooltip, bracketName, arenaBracket, achievId)
    tooltip:AddLine(bracketName .. " CR: " .. ArenaRatingByBracket(arenaBracket) .. " Exp: " ..
                        PrevArenaRatingByAchievID(achievId), 1, 1, 1);
    tooltip:Show();
end

local function PatternSubstrings(index)
    local left = _G["GameTooltipTextLeft" .. index]
    local leftText = left:GetText()
    if (leftText == nil) then
        return false
    end
    if leftText:match("PvPExp") then
        left:SetText(GladiatorString())
        tooltip:Show();
        return true
    elseif leftText:match("2v2") then
        left:SetText("2v2" .. " CR: " .. ArenaRatingByBracket(1) .. " Exp: " .. PrevArenaRatingByAchievID(370));
        tooltip:Show();
        return true;
    elseif leftText:match("3v3") then
        left:SetText("3v3" .. " CR: " .. ArenaRatingByBracket(2) .. " Exp: " .. PrevArenaRatingByAchievID(595));
        tooltip:Show();
        return true;
    elseif leftText:match("5v5") then
        left:SetText("5v5" .. " CR: " .. ArenaRatingByBracket(3) .. " Exp: " .. PrevArenaRatingByAchievID(596));
        tooltip:Show();
        return true;
    elseif leftText:match("RBG") then
        left:SetText("RBG" .. " CR: " .. ArenaRatingByBracket(4));
        tooltip:Show();
        return true
    end
    return false
end
local function GladiatorString()
    local completed, month, _, year = GetAchievementComparisonInfo(2091);

    if (completed) then
        if (month < 10) then
            month = "0" .. month
        end 
        return "PvPExp - Gladiator earned in " .. month .. "/" .. year;
    end
    local completed, month, _, year = GetAchievementComparisonInfo(2092);
    if (completed) then
        if (month < 10) then
            month = "0" .. month
        end 
        return "PvPExp - Duelist earned in " .. month .. "/" .. year;
    end
    return "PvPExp"
end

local function CheckIfPvPExpIsAlreadyShowing(tooltip)
    local counterLine = 0;
    for i = 1, tooltip:NumLines() do
        local printed = PatternSubstrings(i);
        if (printed ~= true) then
            counterLine = counterLine + 1;
        end
    end
    if (counterLine == tooltip:NumLines()) then
        tooltip:AddLine(" ", 1, 1, 1)
        tooltip:AddLine(GladiatorString())
        tooltip:Show();

        for k = 1, 4 do
            WritePvPExp(tooltip, bracketsNames[k], k, achievements[k]);
        end
    end
end

local function ShowPvPExp_OnEvent(self, event, unit,  arg1, arg2) 
    PrintDebugMessage("Tooltip OnEvent Event fired! event " .. event)
    if ((event == "INSPECT_READY"  or event == "INSPECT_HONOR_UPDATE") and self:IsVisible()) then
        CheckIfPvPExpIsAlreadyShowing(self);
        ClearAchievementComparisonUnit();
        ClearInspectPlayer();
    elseif (event == "UPDATE_MOUSEOVER_UNIT" and self:IsVisible()) then
        ClearAchievementComparisonUnit();
        ClearInspectPlayer();
        SetAchievementComparisonUnit(unit);
        NotifyInspect(unit)  
    -- elseif(event == "MODIFIER_STATE_CHANGED" and self:IsVisible() and arg1 == "LCTRL") then  --TODO
    --     ClearAchievementComparisonUnit();
    --     ClearInspectPlayer();
    --     SetAchievementComparisonUnit(unit);
    --     NotifyInspect(unit);  
    end 
end

local function ShowPvPExp_CheckIfCanInteractWithUnit(self, event, arg1, arg2)
    local _, unit = self:GetUnit();
    if (UnitExists(unit) and CanInspect(unit, false)) then
        ShowPvPExp_OnEvent(self, event, unit, arg1, arg2);
    else 
        tooltip:AddLine("PvPExp - ", 1, 1, 1) 
        tooltip:Show();
    end
end

local function ShowPvPExp_OnHide(tooltip) 
    PrintDebugMessage("Tooltip OnHide Event fired!")
    tooltip:ClearLines();
    ClearInspectPlayer();
    ClearAchievementComparisonUnit();
    tooltip:Hide()
end

local function SetOrHookHandler(tooltip, script, func)
    if tooltip:GetScript(script) then
        tooltip:HookScript(script, func)
    else
        tooltip:SetScript(script, func)
    end
end

 

LocalGameTooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
LocalGameTooltip:RegisterEvent("ADDON_LOADED");
LocalGameTooltip:RegisterEvent("INSPECT_HONOR_UPDATE");
LocalGameTooltip:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
LocalGameTooltip:RegisterEvent("INSPECT_READY"); 

SetOrHookHandler(LocalGameTooltip, "OnEvent", ShowPvPExp_CheckIfCanInteractWithUnit);
SetOrHookHandler(LocalGameTooltip, "OnHide", ShowPvPExp_OnHide);  