gg = gg or {}

gg.self = gg.self or {}
gg.target = gg.target or {}
gg.time = gg.time or {}
gg.who = gg.who or {}

gg.self.buffs = gg.self.buffs or {}
gg.self.debuffs = gg.self.debuffs or {}
gg.self.inv = gg.self.inv or {}
gg.self.room = gg.self.room or {}
gg.self.room.contents = gg.self.room.contents or {}
gg.self.room.players = gg.self.room.players or {}
gg.self.skills = gg.self.skills or {}
gg.self.vitals = gg.self.vitals or {}

gg.target.buffs = gg.target.buffs or {}
gg.target.debuffs = gg.target.debuffs or {}

local self = gg.self
local target = gg.target

local room = self.room

local itemAttribMap = {
    w = "worn items", W = "wearable items", l = "wielded",
    g = "groupable", c = "containers", t = "takeables",
    m = "mobs", d = "corpses", x = "friendlies", u = "unknown items"
}


function gg.processAffs()
    local Afflictions = gmcp.Char.Afflictions
    local affs = table.deepcopy(Afflictions.List)

    if not table.contains(affs, Afflictions.Add) then
        affs[#affs + 1] = Afflictions.Add
    end

    for index, aff in ipairs(affs) do
        if Afflictions.Remove.name == aff.name then
            table.remove(affs, index)
            break
        end
    end

    self.debuffs = affs
end


function gg.processDefs()
    local Defences = gmcp.Char.Defences
    local defs = table.deepcopy(Defences.List)

    if not table.contains(defs, Defences.Add) then
        defs[#defs + 1] = Defences.Add
    end

    for index, def in ipairs(defs) do
        if Defences.Remove.name == def.name then
            table.remove(defs, index)
            break
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
        if item.location == type_filter then
            local this_type_attribs = itemAttribMap[item.attrib or "u"]
            contents[this_type_attribs][#contents[this_type_attribs] + 1] = item
            if item.id == Items.add.item.id then needToAdd = false end
        end
    end

    if Items.Add.location == type_filter and needToAdd then
        local item = Items.Add.item
        local this_type_attribs = itemAttribMap[item.attrib or "u"]
        contents[this_type_attribs][#contents[this_type_attribs] + 1] = item
    end

    if Items.Remove.location == type_filter then
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

    if Items.Update.location == type_filter then
        local update_item = Items.Update.item
        local subtable = contents[itemAttribMap[update_item.attrib or "u"]]
        for index, item in ipairs(subtable) do
            if update_item.id == item.id then
                subtable[index] = item
                break
            end
        end
    end

    return contents
end


function gg.processNearbyAdventurers()
    local Room = gmcp.Room
    local players = {}

    for _, player in ipairs(Room.Players) do
        players[#players + 1] = player.name
    end

    if not table.contains(players, Room.AddPlayer.name) then
        players[#players + 1] = Room.AddPlayer.name
    end

    for index, name in ipairs(players) do
        if Room.RemovePlayer.name == name then
            table.remove(players, index)
            break
        end
    end

    room.players = table.sort(players)
end


function gg.processTime()
    local time = table.deepcopy(gmcp.IRE.Time.List)
    if not time then return end

    for key, _ in pairs(time) do
        local updated_value = gmcp.IRE.Time.Update[key]
        if updated_value then time[key] = updated_value end
    end

    local ordinals = {
        "1" = "1st", "2" = "2nd", "3" = "3rd",
        "21" = "21st", "22" = "22nd", "23" = "23rd",
        "31" = "31st"
    }
    local ordinal = ordinals[time.day] or (time.day .. "th")

    local seasons = {
        "mid-winter", "late winter", "early spring",
        "mid-spring", "late spring", "early summer",
        "mid-summer", "late summer", "early autumn",
        "mid-autumn", "late autumn", "early winter",
    }

    time.string = (ordinal .." ".. time.month ..", ".. time.year ..
                   " (".. seasons[tonumber(time.mon)] ..", ".. time.moonphase ..
                   ")<br>" .. time.time)
    gg.time = time
end


function gg.processWho(event, url, body)
    if event ~= "SysGetHttpDone" or url ~= "https://api.aetolia.com/characters.json" then
        return
    end

    gg.who = yajl.to_value(body).characters
end


function gg.setupGMCPEventHandlers()
    local localPlayerEvents = {"gmcp.Room.Players", "gmcp.Room.AddPlayer", "gmcp.Room.RemovePlayer"}
    local itemEvents = {"gmcp.Char.Items.List", "gmcp.Char.Items.Add",
                        "gmcp.Char.Items.Remove", "gmcp.Char.Items.Update"}
    local selfBuffEvents = {"gmcp.Char.Defences.List", "gmcp.Char.Defences.Add",
                            "gmcp.Char.Defences.Remove"}
    local selfDebuffEvents = {"gmcp.Char.Afflictions.List", "gmcp.Char.Afflictions.Add",
                              "gmcp.Char.Afflictions.Remove"}

    for _, event in ipairs(itemsEvents) do
        registerAnonymousEventHandler(event, function() gg.processItems("room") end)
    end

    for _, event in ipairs(localPlayerEvents) do
        registerAnonymousEventHandler(event, gg.processNearbyAdventurers)
    end

    for _, event in ipairs(selfBuffEvents) do
        registerAnonymousEventHandler(event, gg.processDefs)
    end

    for _, event in ipairs(selfDebuffEvents) do
        registerAnonymousEventHandler(event, gg.processAffs)
    end

    sendGMCP([[Core.Supports.Add ["IRE.Time 1"] ]])
    registerAnonymousEventHandler("gmcp.IRE.Time.Update", gg.ProcessTime)

    registerAnonymousEventHandler("sysGetHttpDone", gg.processWho)
end