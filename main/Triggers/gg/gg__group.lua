local timeToReturn = tonumber(matches[3] or 4.5)
if matches[1] == "You take a drink of an elixir" then
    matches[2] = "Elixir"
end

local badgeLookup = {
    Balance={name="balBadge", label="BAL"},
    Equilibrium={name="eqBadge", label="EQ"},
    Elixir={name="sipBadge", label="SIP"},
}

if table.contains(badgeLookup, matches[2]) then
    local badgeInfo = badgeLookup[matches[2]]
    local uiWidget = gg.ui[badgeInfo.name]
    if not uiWidget then error("ui widget for ".. matches[2] .."(".. badgeInfo.name ..") not found") end
    uiWidget:cecho("<center><".. gg.ui.offColor ..">".. badgeInfo.label .."</center>")
    if timeToReturn then
        tempTimer(timeToReturn - 3.05, function()
            uiWidget:cecho("<center><".. gg.ui.threeSecWarnColor ..">".. badgeInfo.label .."</center>")
        end)
        tempTimer(timeToReturn - 2.05, function()
            uiWidget:cecho("<center><".. gg.ui.twoSecWarnColor ..">".. badgeInfo.label .."</center>")
        end)
        tempTimer(timeToReturn - 1.05, function()
            uiWidget:cecho("<center><".. gg.ui.oneSecWarnColor ..">".. badgeInfo.label .."</center>")
        end)
        tempTimer(timeToReturn - 0.05, function()
            uiWidget:cecho("<center><".. gg.ui.availColor ..">".. badgeInfo.label .."</center>")
        end)
    end
end
