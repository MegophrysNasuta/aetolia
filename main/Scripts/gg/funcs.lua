function gg.event(event, message, eventColor)
    raiseEvent(event, message)
    local log_message = "\n<white>["
    if eventColor then log_message = log_message .."<".. eventColor ..">" end
    log_message = log_message .. event .. "<white>] ".. (message or "BLANK") .."\n"
    cecho(log_message)
end


function gg.processAffs()
    local Afflictions = gmcp.Char.Afflictions
    local affs = table.deepcopy(Afflictions.List)

    local needToAdd = true
    if Afflictions.Add then
        for index, aff in ipairs(affs) do
            if Afflictions.Add.name == aff.name then
                needToAdd = false
                break
            end
        end
    end
    if needToAdd then affs[#affs + 1] = Afflictions.Add end

    if Afflictions.Remove then
        for index, aff in ipairs(affs) do
            if Afflictions.Remove[1] == aff.name then
                table.remove(affs, index)
                break
            end
        end
    end

    self.debuffs = affs
end


function gg.processDefs()
    local Defences = gmcp.Char.Defences
    local defs = table.deepcopy(Defences.List)

    local needToAdd = true
    if Defences.Add then
        for index, def in ipairs(defs) do
            if Defences.Add.name == def.name then
                needToAdd = false
                break
            end
        end
    end
    if needToAdd then defs[#defs + 1] = Defences.Add end

    if Defences.Remove then
        for index, def in ipairs(defs) do
            if Defences.Remove[1] == def.name then
                table.remove(defs, index)
                break
            end
        end
    end

    self.buffs = defs
end


function gg.processItems(type_filter)
    type_filter = tostring(type_filter or "")
    if gmcp.Char.Items.List.location ~= type_filter then return end

    local Items = gmcp.Char.Items
    local contents = {}
    local needToAdd = true

    for _, item in ipairs(Items.List.items) do
        local this_type_attribs = itemAttribMap[item.attrib or "u"]
        contents[this_type_attribs] = contents[this_type_attribs] or {}
        contents[this_type_attribs][#contents[this_type_attribs] + 1] = item
        if Items.Add and item.id == Items.Add.Item.id then needToAdd = false end
    end

    if Items.Add and Items.Add.location == type_filter and needToAdd then
        local item = Items.Add.item
        local this_type_attribs = itemAttribMap[item.attrib or "u"]
        contents[this_type_attribs] = contents[this_type_attribs] or {}
        contents[this_type_attribs][#contents[this_type_attribs] + 1] = item
    end

    if Items.Remove and Items.Remove.location == type_filter then
        local remove_item = Items.Remove.item
        for attrib_type, subtable in pairs(contents) do
            for index, item in ipairs(subtable) do
                if remove_item.id == item.id then
                    table.remove(subtable, index)
                    break
                end
            end
        end
    end

    if Items.Update and Items.Update.location == type_filter then
        local update_item = Items.Update.item
        local subtable = contents[itemAttribMap[update_item.attrib or "u"]]
        for index, item in ipairs(subtable) do
            if update_item.id == item.id then
                subtable[index] = item
                break
            end
        end
    end

    table.sort(contents)
    return contents
end


function gg.processNearbyAdventurers()
    local Room = gmcp.Room
    local players = {}

    for _, player in ipairs(Room.Players) do
        players[#players + 1] = player.name
    end

    if Room.AddPlayer and not table.contains(players, Room.AddPlayer.name) then
        players[#players + 1] = Room.AddPlayer.name
    end

    if Room.RemovePlayer then
        for index, name in ipairs(players) do
            if Room.RemovePlayer == name then
                table.remove(players, index)
                break
            end
        end
    end

    table.sort(players)
    room.players = players
end


function gg.processTime()
    if not gmcp.IRE.Time.Update then return end
    local time = table.deepcopy(gmcp.IRE.Time.List)
    if not time then return end

    for key, _ in pairs(time) do
        local updated_value = gmcp.IRE.Time.Update[key]
        if updated_value then time[key] = updated_value end
    end

    local ordinals = {
        [1] = "1st", [2] = "2nd", [3] = "3rd",
        [21] = "21st", [22] = "22nd", [23] = "23rd",
        [31] = "31st"
    }

    local ordinal = ordinals[time.day] or (time.day .. "th")

    local months = {"Variach", "Severin", "Ios", "Arios", "Chakros", "Khepary",
                    "Midsummer", "Lleian", "Lanosian", "Niuran", "Slyphian", "Haernos"}
    local month = tonumber(time.month)
    time.month = months[month]

    local seasons = {
        "mid-winter", "late winter", "early spring",
        "mid-spring", "late spring", "early summer",
        "mid-summer", "late summer", "early autumn",
        "mid-autumn", "late autumn", "early winter",
    }
    time.season = seasons[month]

    time.date = (ordinal .." ".. time.month ..", ".. time.year ..
                   " (".. time.season ..", ".. time.moonphase ..")")
    gg.time = time
end


function gg.processWho(event, url, body)
    if event ~= "sysGetHttpDone" or url ~= "https://api.aetolia.com/characters.json" then
        return
    end

    local who = {}
    for _, character in ipairs(yajl.to_value(body).characters) do
        who[#who + 1] = character.name
    end
    table.sort(who)
    gg.who = who
end


function gg.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


local Status = gmcp.Char.Status
local Vitals = gmcp.Char.Vitals
local RoomInfo = gmcp.Room.Info
function gg.drawUI()
    local color
    local width, height = getMainWindowSize()
    setBorderBottom(100)
    setBorderRight(width / 3)

    gg.ui.bottomPanel = Geyser.Container:new({
        name="gg.ui.bottomPanel", x=0, y="-100", width="67%", height="10%"})

    gg.ui.rightPanel = Geyser.Container:new({
        name="gg.ui.rightPanel", x="-33%", y=0, width="33%", height="100%"})

    -- bottom panel
    -- row 1
    if self.can_eat() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.eatBadge = Geyser.Label:new({
        name="gg.ui.eatBadge", x=0, y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.eatBadge:echo("<center>EAT</center>")
    gg.ui.eatBadge:setClickCallback(function() send("") end)

    if self.can_focus() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.focusBadge = Geyser.Label:new({
        name="gg.ui.focusBadge", x="7.5%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.focusBadge:echo("<center>FOCUS</center>")
    gg.ui.focusBadge:setClickCallback(function() send("focus") end)

    if self.can_moss() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.mossBadge = Geyser.Label:new({
        name="gg.ui.mossBadge", x="15%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.mossBadge:echo("<center>MOSS</center>")
    gg.ui.mossBadge:setClickCallback(function() send("touch moss") end)

    if self.can_renew() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.renewBadge = Geyser.Label:new({
        name="gg.ui.renewBadge", x="22.5%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.renewBadge:echo("<center>RENEW</center>")
    gg.ui.renewBadge:setClickCallback(function() send("renew") end)

    if self.can_salve() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.salveBadge = Geyser.Label:new({
        name="gg.ui.salveBadge", x="30%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.salveBadge:echo("<center>SALVE</center>")
    gg.ui.salveBadge:setClickCallback(function() send("") end)

    if self.can_sip() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.sipBadge = Geyser.Label:new({
        name="gg.ui.sipBadge", x="37.5%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.sipBadge:echo("<center>SIP</center>")
    gg.ui.sipBadge:setClickCallback(function() send("") end)

    if self.can_smoke() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.smokeBadge = Geyser.Label:new({
        name="gg.ui.smokeBadge", x="45%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.smokeBadge:echo("<center>SMOKE</center>")
    gg.ui.smokeBadge:setClickCallback(function() send("") end)

    if self.can_tree() then color = gg.ui.availColor else color = gg.ui.offColor end
    gg.ui.treeBadge = Geyser.Label:new({
        name="gg.ui.treeBadge", x="52.5%", y=0, width="7.5%", height=33, fontSize=10,
        fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
    gg.ui.treeBadge:echo("<center>TREE</center>")
    gg.ui.treeBadge:setClickCallback(function() send("touch tree") end)

    -- row 2
    gg.ui.hpBar = Geyser.Gauge:new({
        name="gg.ui.hpBar", x=0, y=33, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.hpBar:setValue(tonumber(Vitals.hp), tonumber(Vitals.maxhp),
                         "<center>HP: ".. gg.round(self.stats.hp(), 2) .."%</center>")
    gg.ui.hpBar.front:setStyleSheet("background-color: green;")
    gg.ui.hpBar.back:setStyleSheet("background-color: black;")

    gg.ui.mpBar = Geyser.Gauge:new({
        name="gg.ui.mpBar", x="33%", y=33, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.mpBar:setValue(tonumber(Vitals.mp), tonumber(Vitals.maxmp),
                         "<center>MP: ".. gg.round(self.stats.mp(), 2) .."%</center>")
    gg.ui.mpBar.front:setStyleSheet("background-color: navy;")
    gg.ui.mpBar.back:setStyleSheet("background-color: black;")

    gg.ui.bloodBar = Geyser.Gauge:new({
        name="gg.ui.bloodBar", x="66%", y=33, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.bloodBar:setValue(tonumber(Vitals.blood), 100,
                            "<center>Blood: ".. Vitals.blood .."%</center>")
    gg.ui.bloodBar.front:setStyleSheet("background-color: maroon;")
    gg.ui.bloodBar.back:setStyleSheet("background-color: black;")

    -- row 3
    gg.ui.epBar = Geyser.Gauge:new({
        name="gg.ui.epBar", x=0, y=66, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.epBar:setValue(tonumber(Vitals.ep), tonumber(Vitals.maxep),
                         "<center>EP: ".. gg.round(self.stats.ep(), 2) .."%</center>")
    gg.ui.epBar.front:setStyleSheet("background-color: goldenrod;")
    gg.ui.epBar.back:setStyleSheet("background-color: black;")

    gg.ui.wpBar = Geyser.Gauge:new({
        name="gg.ui.wpBar", x="33%", y=66, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.wpBar:setValue(tonumber(Vitals.wp), tonumber(Vitals.maxwp),
                         "<center>WP: ".. gg.round(self.stats.wp(), 2) .."%</center>")
    gg.ui.wpBar.front:setStyleSheet("background-color: purple;")
    gg.ui.wpBar.back:setStyleSheet("background-color: black;")

    gg.ui.soulBar = Geyser.Gauge:new({
        name="gg.ui.soulBar", x="66%", y=66, width="32%", height=33,
        fontSize=10}, gg.ui.bottomPanel)
    gg.ui.soulBar:setValue(tonumber(Vitals.soul), 100,
                            "<center>Soul: ".. Vitals.soul .."%</center>")
    gg.ui.soulBar.front:setStyleSheet("background-color: dodgerblue;")
    gg.ui.soulBar.back:setStyleSheet("background-color: black;")

    -- right panel
    -- row 1
    gg.ui.nameBadge = Geyser.Label:new({
        name="gg.ui.nameBadge", x=0, y=0, width="60%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.nameBadge:echo("<center>".. Status.fullname .."</center>")
    gg.ui.nameBadge:setClickCallback(function() send("honours ".. Status.name ) end)

    gg.ui.cityBadge = Geyser.Label:new({
        name="gg.ui.cityBadge", x="60%", y=0, width="40%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.cityBadge:echo("<center>".. Status.city .."</center>")
    gg.ui.cityBadge:setClickCallback(function() send("help ".. Status.city ) end)

    -- row 2
    gg.ui.specBadge = Geyser.Label:new({
        name="gg.ui.specBadge", x=0, y=18, width="50%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.specBadge:echo(("<center>".. Status.gender:title() .." ".. Status.spec ..
                          " ".. Status.race .." ".. Status.class .."</center>"))
    gg.ui.specBadge:setClickCallback(function() send("honours ".. Status.name) end)

    gg.ui.houseBadge = Geyser.Label:new({
        name="gg.ui.houseBadge", x="50%", y=18, width="50%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.houseBadge:echo(("<center> Guild: ".. Status.guild .." Order: "..
                           Status.order .."</center>"))
    gg.ui.houseBadge:setClickCallback(function() send("honours ".. Status.name) end)

    -- row 3
    gg.ui.newsBadge = Geyser.Label:new({
        name="gg.ui.newsBadge", x=0, y=36, width="25%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.newsBadge:echo("<center>Unread news: ".. Status.unread_news .."</center>")
    gg.ui.newsBadge:setClickCallback(function() send("nstat") end)

    gg.ui.msgsBadge = Geyser.Label:new({
        name="gg.ui.msgsBadge", x="25%", y=36, width="25%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.msgsBadge:echo("<center>Unread msgs: ".. Status.unread_msgs .."</center>")
    gg.ui.msgsBadge:setClickCallback(function() send("rmsg") end)

    gg.ui.goldBadge = Geyser.Label:new({
        name="gg.ui.goldBadge", x="50%", y=36, width="50%", height=18, fontSize=10,
        fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
    gg.ui.goldBadge:echo("<center>Gold: " .. Status.gold .." - Banked: ".. Status.bank .."</center>")
    gg.ui.goldBadge:setClickCallback(function() send("currency report") end)

    -- row 4
    local exits = {}
    for dir, roomNum in pairs(RoomInfo.exits) do exits[#exits + 1] = dir end
    gg.ui.roomBadge = Geyser.Label:new({
        name="gg.ui.roomBadge", x=0, y=54, width="100%", height=18, fontSize=10,
        fgColor=gg.ui.roomColor}, gg.ui.rightPanel)
    gg.ui.roomBadge:cecho(("<center><".. gg.ui.roomColor ..">".. RoomInfo.name .." ("..
                           RoomInfo.environment ..", ".. RoomInfo.area .."; exits: <"..
                           gg.ui.infoColor ..">"..tostring(#exits) .."<".. gg.ui.roomColor ..
                           ">)</center>"))
    gg.ui.roomBadge:setClickCallback(function() send("look") end)

    -- map
    openMapWidget(width * .7, 214, width * .34, height * .25)
end


function gg.refreshUI()
    gg.drawUI()
    if gg.ui.updateTimer then killTimer(gg.ui.updateTimer) end
    gg.ui.updateTimer = tempTimer(gg.ui.refreshInterval or .1, gg.refreshUI)
end


function gg.setupGMCPEventHandlers()
    local localPlayerEvents = {"gmcp.Room.Players", "gmcp.Room.AddPlayer", "gmcp.Room.RemovePlayer"}
    local itemEvents = {"gmcp.Char.Items.List", "gmcp.Char.Items.Add",
                        "gmcp.Char.Items.Remove", "gmcp.Char.Items.Update"}
    local selfBuffEvents = {"gmcp.Char.Defences.List", "gmcp.Char.Defences.Add",
                            "gmcp.Char.Defences.Remove"}
    local selfDebuffEvents = {"gmcp.Char.Afflictions.List", "gmcp.Char.Afflictions.Add",
                              "gmcp.Char.Afflictions.Remove"}
    local timeEvents = {"gmcp.IRE.Time.Update", "gmcp.IRE.Time.List"}

    for _, event in ipairs(itemEvents) do
        deleteNamedEventHandler("gg", event)
        registerNamedEventHandler("gg", event, event, function()
            room.contents = gg.processItems("room")
        end)
    end

    for _, event in ipairs(localPlayerEvents) do
        deleteNamedEventHandler("gg", event)
        registerNamedEventHandler("gg", event, event, gg.processNearbyAdventurers)
    end

    for _, event in ipairs(selfBuffEvents) do
        deleteNamedEventHandler("gg", event)
        registerNamedEventHandler("gg", event, event, gg.processDefs)
    end

    for _, event in ipairs(selfDebuffEvents) do
        deleteNamedEventHandler("gg", event)
        registerNamedEventHandler("gg", event, event, gg.processAffs)
    end

    sendGMCP([[Core.Supports.Add ["IRE.Time 1"] ]])
    for _, event in ipairs(timeEvents) do
        deleteNamedEventHandler("gg", event)
        registerNamedEventHandler("gg", event, event, gg.processTime)
    end

    deleteNamedEventHandler("gg", "characters.json")
    registerNamedEventHandler("gg", "characters.json", "sysGetHttpDone", gg.processWho)

    deleteNamedEventHandler("gg.event", "gmcp.Room.AddPlayer")
    registerNamedEventHandler("gg.event", "gmcp.Room.AddPlayer", "gmcp.Room.AddPlayer",
        function() gg.event("Player entered", gmcp.Room.AddPlayer.name, "gold") end)

    deleteNamedEventHandler("gg.event", "gmcp.Room.RemovePlayer")
    registerNamedEventHandler("gg.event", "gmcp.Room.RemovePlayer", "gmcp.Room.RemovePlayer",
        function() gg.event("Player left", gmcp.Room.RemovePlayer, "gold") end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Defences.Add")
    registerNamedEventHandler("gg.event", "gmcp.Char.Defences.Add", "gmcp.Char.Defences.Add",
        function() gg.event("Def+", gmcp.Char.Defences.Add.name, "SpringGreen") end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Defences.Remove")
    registerNamedEventHandler("gg.event", "gmcp.Char.Defences.Remove", "gmcp.Char.Defences.Remove",
        function() gg.event("Def-", gmcp.Char.Defences.Remove[1], "OrangeRed") end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Add")
    registerNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Add", "gmcp.Char.Afflictions.Add",
        function() gg.event("Aff+", gmcp.Char.Afflictions.Add.name, "OrangeRed") end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Remove")
    registerNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Remove", "gmcp.Char.Afflictions.Remove",
        function() gg.event("Aff-", gmcp.Char.Afflictions.Remove[1], "SpringGreen") end)

    gg.refreshUI()
end
