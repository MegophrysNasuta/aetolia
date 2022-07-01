enableTrigger("gg.autonews")
gg = gg or {}
if io.exists(getMudletHomeDir() .."/adb.lua") then
    table.load(getMudletHomeDir() .."/adb.lua", gg.adb)
end
gg.adb = gg.adb or {}
gg.ui = gg.ui or {}
gg.defKeepupInterval = 2
gg.ui.refreshInterval = .1

gg.ui.availColor = "cyan"
gg.ui.infoColor = "white"
gg.ui.keepColor = "SpringGreen"
gg.ui.loseColor = "OrangeRed"
gg.ui.offColor = "grey"
gg.ui.roomColor = "DarkOrange"
gg.ui.timeColor = "LightSkyBlue"
gg.ui.oneSecWarnColor = "red"
gg.ui.twoSecWarnColor = "orange"
gg.ui.threeSecWarnColor = "yellow"

gg.ui.whoColors = gg.ui.whoColors or {}
gg.ui.whoColors.Bloodloch = "ansiRed"
gg.ui.whoColors.Spinesreach = "ansiMagenta"
gg.ui.whoColors.Duiran = "DarkOliveGreen"
gg.ui.whoColors.Enorian = "SteelBlue"

gg.self = gg.self or {}
gg.target = gg.target or {}
gg.time = gg.time or {}
gg.who = gg.who or {}

gg.self.buffs = gg.self.buffs or {}
gg.self.debuffs = gg.self.debuffs or {}
gg.self.inv = gg.self.inv or {}
gg.self.keepup = gg.self.keepup or {}
gg.self.room = gg.self.room or {}
gg.self.room.contents = gg.self.room.contents or {}
gg.self.room.players = gg.self.room.players or {}
gg.self.skills = gg.self.skills or {}
gg.self.vitals = gg.self.vitals or {}
if io.exists(getMudletHomeDir() .."/keepDefs.lua") then
    table.load(getMudletHomeDir() .."/keepDefs.lua", gg.self.keepup)
end

gg.target.buffs = gg.target.buffs or {}
gg.target.debuffs = gg.target.debuffs or {}


local itemAttribMap = {
    w = "worn items", W = "wearable items", l = "wielded",
    g = "groupable", c = "containers", t = "takeables",
    m = "mobs", d = "corpses", mx = "friendlies", u = "unknown items"
}


function gg.drawUI()
    local width, _ = getMainWindowSize()
    setBorderBottom(100)
    setBorderRight(width / 3)

    gg.drawUIBottomPanel()
    gg.drawUIRightPanel()
end


function gg.drawUIBottomPanel()
    if not gg.ui.bottomPanel then
        gg.ui.bottomPanel = Geyser.Container:new({
            name="gg.ui.bottomPanel", x=0, y="-100", width="67%", height="10%"})
    end

    local Status = gmcp.Char.Status
    local Vitals = gmcp.Char.Vitals
    local color

    -- bottom panel
    -- row 1
    if gg.self.has_balance() then color = gg.ui.availColor else color = gg.ui.offColor end
    if not gg.ui.balBadge then
        gg.ui.balBadge = Geyser.Label:new({
            name="gg.ui.balBadge", x=0, y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.balBadge:echo("<center>BAL</center>")
        gg.ui.balBadge:setClickCallback(function() send("") end)
    end

    if gg.self.has_equilibrium() then color = gg.ui.availColor else color = gg.ui.offColor end
    if not gg.ui.eqBadge then
        gg.ui.eqBadge = Geyser.Label:new({
            name="gg.ui.eqBadge", x="7.5%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.eqBadge:echo("<center>EQ</center>")
        gg.ui.eqBadge:setClickCallback(function() send("") end)
    end

    if gg.self.can_eat() then color = gg.ui.availColor else color = gg.ui.offColor end
    if not gg.ui.eatBadge then
        gg.ui.eatBadge = Geyser.Label:new({
            name="gg.ui.eatBadge", x="15%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.eatBadge:echo("<center>EAT</center>")
        gg.ui.eatBadge:setClickCallback(function() send("") end)
    end

    if not gg.ui.focusBadge then
        if gg.self.can_focus() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.focusBadge = Geyser.Label:new({
            name="gg.ui.focusBadge", x="22.5%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.focusBadge:echo("<center>FOCUS</center>")
        gg.ui.focusBadge:setClickCallback(function() send("focus") end)
    end

    if not gg.ui.mossBadge then
        if gg.self.can_moss() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.mossBadge = Geyser.Label:new({
            name="gg.ui.mossBadge", x="30%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.mossBadge:echo("<center>MOSS</center>")
        gg.ui.mossBadge:setClickCallback(function() send("touch moss") end)
    end

    if not gg.ui.renewBadge then
        if gg.self.can_renew() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.renewBadge = Geyser.Label:new({
            name="gg.ui.renewBadge", x="37.5%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.renewBadge:echo("<center>RENEW</center>")
        gg.ui.renewBadge:setClickCallback(function() send("renew") end)
    end

    if not gg.ui.salveBadge then
        if gg.self.can_salve() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.salveBadge = Geyser.Label:new({
            name="gg.ui.salveBadge", x="45%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.salveBadge:echo("<center>SALVE</center>")
        gg.ui.salveBadge:setClickCallback(function() send("") end)
    end

    if not gg.ui.sipBadge then
        if gg.self.can_sip() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.sipBadge = Geyser.Label:new({
            name="gg.ui.sipBadge", x="52.5%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.sipBadge:echo("<center>SIP</center>")
        gg.ui.sipBadge:setClickCallback(function() send("") end)
    end

    if not gg.ui.smokeBadge then
        if gg.self.can_smoke() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.smokeBadge = Geyser.Label:new({
            name="gg.ui.smokeBadge", x="60%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.smokeBadge:echo("<center>SMOKE</center>")
        gg.ui.smokeBadge:setClickCallback(function() send("") end)
    end

    if not gg.ui.treeBadge then
        if gg.self.can_tree() then color = gg.ui.availColor else color = gg.ui.offColor end
        gg.ui.treeBadge = Geyser.Label:new({
            name="gg.ui.treeBadge", x="67.5%", y=0, width="7.5%", height=33, fontSize=8,
            fgColor=color, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.treeBadge:echo("<center>TREE</center>")
        gg.ui.treeBadge:setClickCallback(function() send("touch tree") end)
    end

    if not gg.ui.lvlProgressBar then
        gg.ui.lvlProgressBar = Geyser.Gauge:new({
            name="gg.ui.lvlProgressBar", x="75%", y=0, width="25%", height=33,
            fontSize=8, bgColor="transparent"}, gg.ui.bottomPanel)
        gg.ui.lvlProgressBar.front:setStyleSheet("backround-color: silver;")
        gg.ui.lvlProgressBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.lvlProgressBar:setValue(tonumber(Vitals.nl), 100, "<center>Lvl ".. Status.level .."</center>")

    -- row 2
    if not gg.ui.hpBar then
        gg.ui.hpBar = Geyser.Gauge:new({
            name="gg.ui.hpBar", x=0, y=33, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.hpBar.front:setStyleSheet("background-color: green;")
        gg.ui.hpBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.hpBar:setValue(tonumber(Vitals.hp), tonumber(Vitals.maxhp),
                         "<center>HP: ".. gg.round(gg.self.stats.hp(), 2) .."%</center>")

    if not gg.ui.mpBar then
        gg.ui.mpBar = Geyser.Gauge:new({
            name="gg.ui.mpBar", x="33%", y=33, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.mpBar.front:setStyleSheet("background-color: navy;")
        gg.ui.mpBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.mpBar:setValue(tonumber(Vitals.mp), tonumber(Vitals.maxmp),
                         "<center>MP: ".. gg.round(gg.self.stats.mp(), 2) .."%</center>")

    if not gg.ui.bloodBar then
        gg.ui.bloodBar = Geyser.Gauge:new({
            name="gg.ui.bloodBar", x="66%", y=33, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.bloodBar.front:setStyleSheet("background-color: maroon;")
        gg.ui.bloodBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.bloodBar:setValue(tonumber(Vitals.blood), 100,
                            "<center>Blood: ".. Vitals.blood .."%</center>")

    -- row 3
    if not gg.ui.epBar then
        gg.ui.epBar = Geyser.Gauge:new({
            name="gg.ui.epBar", x=0, y=66, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.epBar.front:setStyleSheet("background-color: goldenrod;")
        gg.ui.epBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.epBar:setValue(tonumber(Vitals.ep), tonumber(Vitals.maxep),
                         "<center>EP: ".. gg.round(gg.self.stats.ep(), 2) .."%</center>")

    if not gg.ui.wpBar then
        gg.ui.wpBar = Geyser.Gauge:new({
            name="gg.ui.wpBar", x="33%", y=66, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.wpBar.front:setStyleSheet("background-color: purple;")
        gg.ui.wpBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.wpBar:setValue(tonumber(Vitals.wp), tonumber(Vitals.maxwp),
                         "<center>WP: ".. gg.round(gg.self.stats.wp(), 2) .."%</center>")

    if not gg.ui.soulBar then
        gg.ui.soulBar = Geyser.Gauge:new({
            name="gg.ui.soulBar", x="66%", y=66, width="32%", height=33,
            fontSize=8}, gg.ui.bottomPanel)
        gg.ui.soulBar.front:setStyleSheet("background-color: dodgerblue;")
        gg.ui.soulBar.back:setStyleSheet("background-color: black;")
    end
    gg.ui.soulBar:setValue(tonumber(Vitals.soul), 100,
                            "<center>Soul: ".. Vitals.soul .."%</center>")
end


function gg.drawUIRightPanel()
    if not gg.ui.rightPanel then
        gg.ui.rightPanel = Geyser.Container:new({
            name="gg.ui.rightPanel", x="-33%", y=0, width="33%", height="100%"})
    end

    local RoomInfo = (gmcp.Room and gmcp.Room.Info) or {}
    local Status = gmcp.Char.Status
    local width, height = getMainWindowSize()

    -- right panel
    -- row 1
    if not gg.ui.nameBadge then
        gg.ui.nameBadge = Geyser.Label:new({
            name="gg.ui.nameBadge", x=0, y=0, width="60%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.nameBadge:setClickCallback(function() send("honours ".. Status.name ) end)
    end
    gg.ui.nameBadge:echo("<center>".. Status.fullname .."</center>")

    if not gg.ui.cityBadge then
        gg.ui.cityBadge = Geyser.Label:new({
            name="gg.ui.cityBadge", x="60%", y=0, width="40%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.cityBadge:setClickCallback(function() send("help ".. Status.city ) end)
    end
    gg.ui.cityBadge:echo("<center>".. Status.city .."</center>")

    -- row 2
    if not gg.ui.specBadge then
        gg.ui.specBadge = Geyser.Label:new({
            name="gg.ui.specBadge", x=0, y=18, width="50%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.specBadge:setClickCallback(function() send("honours ".. Status.name) end)
    end
    gg.ui.specBadge:echo(("<center>".. Status.gender:title() .." ".. Status.spec ..
                          " ".. Status.race .." ".. Status.class .."</center>"))

    if not gg.ui.houseBadge then
        gg.ui.houseBadge = Geyser.Label:new({
            name="gg.ui.houseBadge", x="50%", y=18, width="50%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.houseBadge:setClickCallback(function() send("honours ".. Status.name) end)
    end
    gg.ui.houseBadge:echo(("<center> Guild: ".. Status.guild .." Order: "..
                           Status.order .."</center>"))

    -- row 3
    if not gg.ui.defsBadge then
        gg.ui.defsBadge = Geyser.Label:new({
            name="gg.ui.defsBadge", x=0, y=36, width="25%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.defsBadge:setClickCallback(function() send("def") end)
    end
    gg.ui.defsBadge:echo("<center>Defs: ".. tostring(#gg.self.buffs) .."</center>")

    if not gg.ui.affsBadge then
        gg.ui.affsBadge = Geyser.Label:new({
            name="gg.ui.affsBadge", x="25%", y=36, width="25%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.affsBadge:setClickCallback(function() send("diagnose") end)
    end
    gg.ui.affsBadge:echo("<center>Affs: ".. tostring(#gg.self.debuffs) .."</center>")

    if not gg.ui.goldBadge then
        gg.ui.goldBadge = Geyser.Label:new({
            name="gg.ui.goldBadge", x="50%", y=36, width="50%", height=18, fontSize=8,
            fgColor=gg.ui.infoColor}, gg.ui.rightPanel)
        gg.ui.goldBadge:setClickCallback(function() sendAll("currency report", "credit report") end)
    end
    gg.ui.goldBadge:echo("<center>Gold: " .. Status.gold .." - Banked: ".. Status.bank .."</center>")

    -- row 4
    if not gg.ui.dateBadge then
        gg.ui.dateBadge = Geyser.Label:new({
            name="gg.ui.dateBadge", x=0, y=54, width="100%", height=18, fontSize=8,
            fgColor=gg.ui.timeColor}, gg.ui.rightPanel)
        gg.ui.dateBadge:setClickCallback(function() send("calendar") end)
    end
    if gmcp.IRE and gmcp.IRE.Time then
        gg.ui.dateBadge:echo("<center>".. gg.time.date .."</center>")
    end

    -- row 5
    if not gg.ui.timeBadge then
        gg.ui.timeBadge = Geyser.Label:new({
            name="gg.ui.timeBadge", x=0, y=72, width="100%", height=18, fontSize=8,
            fgColor=gg.ui.timeColor}, gg.ui.rightPanel)
        gg.ui.timeBadge:setClickCallback(function() send("calendar") end)
    end
    if gmcp.IRE and gmcp.IRE.Time then
        gg.ui.timeBadge:echo("<center>".. gg.time.time .."</center>")
    end

    -- row 6
    if not gg.ui.roomBadge then
        gg.ui.roomBadge = Geyser.Label:new({
            name="gg.ui.roomBadge", x=0, y=90, width="100%", height=36, fontSize=8,
            fgColor=gg.ui.roomColor}, gg.ui.rightPanel)
        gg.ui.roomBadge:setClickCallback(function() send("look") end)
        gg.ui.roomBadge:setStyleSheet("qproperty-wordWrap: true;")
    end

    local exits = {}
    for dir, roomNum in pairs(RoomInfo.exits or {}) do exits[#exits + 1] = dir end
    gg.ui.roomBadge:cecho(("<center><".. gg.ui.roomColor ..">".. (RoomInfo.name or "?") .." ("..
                           (RoomInfo.environment or "unknown") ..", ".. (RoomInfo.area or "unknown") .."; exits: <"..
                           gg.ui.infoColor ..">"..tostring(#exits) .."<".. gg.ui.roomColor ..
                           ">)</center>"))

    -- map
    openMapWidget(width * .67, 268, width * .33, 380)

    -- targets window
    if not gg.ui.roomContentsWindow then
        gg.ui.roomContentsWindow = Geyser.MiniConsole:new({
            name="gg.ui.roomContentsWindow", scrollBar=true, autoWrap=true,
            x="-33%", y=543, width="33%", height=400, fontSize=8,
            fgColor=gg.ui.infoColor, color="black", wrapAt=80})
    end
    gg.ui.roomContentsWindow:clear()
    if gg.self.room and gg.self.room.contents then
        for obj_type, objs in pairs(gg.self.room.contents) do
            gg.ui.roomContentsWindow:cecho("\n".. obj_type:title() ..": ")
            for _, obj in ipairs(objs) do
                cechoLink("gg.ui.roomContentsWindow", obj.name,
                          function()
                            sendAll("p ".. obj.id, "st ".. obj.id)
                          end, "", true)
                if _ ~= #objs then
                    gg.ui.roomContentsWindow:cecho(", ")
                else
                    gg.ui.roomContentsWindow:cecho("\n")
                end
            end
        end
    end
    gg.ui.roomContentsWindow:cecho("\nPlayers: ")
    if gg.self.room and gg.self.room.players then
        for _, player in ipairs(gg.self.room.players) do
            cechoLink("gg.ui.roomContentsWindow", player,
                      function() sendAll("look at ".. player, "st ".. player) end, "", true)
            if _ ~= #gg.self.room.players then
                gg.ui.roomContentsWindow:cecho(", ")
            end
        end
    end

    -- who window
    if not gg.ui.whoWindow then
        gg.ui.whoWindow = Geyser.MiniConsole:new({
            name="gg.ui.whoWindow", scrollBar=true, autoWrap=true, color="black",
            x="-33%", y=950, width="33%", height=200, fontSize=8,
            fgColor=gg.ui.infoColor, wrapAt=80})
    end
    gg.ui.whoWindow:clear()
    if gg.ready and gg.who then
        for _, player in ipairs(gg.who) do
            local color = "white"
            local extraFmt = ""
            if gg.adb[player] then
                if gg.adb[player].city then
                    color = gg.ui.whoColors[gg.adb[player].city]
                end
                if gg.adb[player].city_enemy then
                    extraFmt = extraFmt .. "<i>"
                end
                if gg.adb[player].enemy then
                    extraFmt = extraFmt .. "<b>"
                end
            end
            cechoLink("gg.ui.whoWindow", "<".. color ..">".. extraFmt .. player,
                      function() expandAlias("whois ".. player) end, "", true)
            if _ ~= #gg.who then
                gg.ui.whoWindow:cecho(", ")
            end
        end
    end

    -- chat window
    if not gg.ui.chatConsole then
        local width, _ = getMainWindowSize()
        gg.ui.chatConsole = Geyser.MiniConsole:new({
            name="gg.ui.chatConsole", scrollBar=true, autoWrap=true, color="black",
            x=width * .67, y=1155, width=width * .33, height=400, fontSize=8,
            fgColor=gg.ui.infoColor, wrapAt=80})
    end
end


function gg.init()
    if not gmcp.Char then
        echo("Waiting for GMCP to fully load before initializing UI...")
        tempTimer(2, gg.init)
        return
    end

    gg.self.bleeding = function() return gmcp.Char.Vitals.bleeding ~= "0" end
    gg.self.blind = function() return gmcp.Char.Vitals.blind == "1" end
    gg.self.can_eat = function() return gmcp.Char.Vitals.herb == "1" end
    gg.self.can_focus = function() return gmcp.Char.Vitals.focus == "1" end
    gg.self.can_moss = function() return gmcp.Char.Vitals.moss == "1" end
    gg.self.can_renew = function() return gmcp.Char.Vitals.renew == "1" end
    gg.self.can_salve = function() return gmcp.Char.Vitals.salve == "1" end
    gg.self.can_sip = function() return gmcp.Char.Vitals.elixir == "1" end
    gg.self.can_smoke = function() return gmcp.Char.Vitals.pipe == "1" end
    gg.self.can_tree = function() return gmcp.Char.Vitals.tree == "1" end
    gg.self.cloaked = function() return gmcp.Char.Vitals.cloak == "1" end
    gg.self.deaf = function() return gmcp.Char.Vitals.deaf == "1" end
    gg.self.fallen = function() return gmcp.Char.Vitals.fallen ~= "0" end
    gg.self.fangbarrier = function() return gmcp.Char.Vitals.fangbarrier ~= "0" end
    gg.self.has_ability_balance = function() return gmcp.Char.Vitals.ability_bal == "1" end
    gg.self.has_balance = function() return gmcp.Char.Vitals.balance == "1" end
    gg.self.has_equilibrium = function() return gmcp.Char.Vitals.equilibrium == "1" end
    gg.self.has_left_arm = function() return gmcp.Char.Vitals.left_arm == "1" end
    gg.self.has_right_arm = function() return gmcp.Char.Vitals.right_arm == "1" end
    gg.self.mad = function() return gmcp.Char.Vitals.madness == "1" end
    gg.self.mounted = function() return gmcp.Char.Vitals.mounted == "1" end
    gg.self.phased = function() return gmcp.Char.Vitals.phased == "1" end
    gg.self.prone = function() return gmcp.Char.Vitals.prone == "1" end
    gg.self.writhing = function() return gmcp.Char.Vitals.writhing == "1" end

    gg.self.build = function() return gmcp.Char.Status.spec .." ".. gmcp.Char.Status.race .." ".. gmcp.Char.Status.class end
    gg.self.gold = function() return {banked = tonumber(gmcp.Char.Status.bank), held = tonumber(gmcp.Char.Status.gold)} end
    gg.self.stats = {
        hp = function() return (tonumber(gmcp.Char.Vitals.hp) / tonumber(gmcp.Char.Vitals.maxhp)) * 100 end,
        mp = function() return (tonumber(gmcp.Char.Vitals.mp) / tonumber(gmcp.Char.Vitals.maxmp)) * 100 end,
        ep = function() return (tonumber(gmcp.Char.Vitals.ep) / tonumber(gmcp.Char.Vitals.maxep)) * 100 end,
        wp = function() return (tonumber(gmcp.Char.Vitals.wp) / tonumber(gmcp.Char.Vitals.maxwp)) * 100 end,
        blood = function() return tonumber(gmcp.Char.Vitals.blood) end,
        to_next_level = function() return tonumber(gmcp.Char.Vitals.nl) end
    }
    gg.self.wielding = {
        left = function() return gmcp.Char.Vitals.wield_left end,
        right = function() return gmcp.Char.Vitals.wield_right end
    }

    gg.setupGMCPEventHandlers()
    gg.refreshUI()
    gg.refreshSlowAPIs()
    gg.updateADBTriggers()
    send("def")
    tempTimer(5, function() send("look") gg.ready = true end)
end


function gg.event(event, message, eventColor)
    raiseEvent(event, message)
    local log_message = "\n<white>["
    if eventColor then log_message = log_message .."<".. eventColor ..">" end
    log_message = log_message .. event .. "<white>] ".. (message or "BLANK") .."\n"
    cecho(log_message)
end


function gg.keepDef(def, command)
    for _, defInfo in ipairs(gg.self.keepup) do
        if defInfo.name == def then return end
    end

    gg.self.keepup[#gg.self.keepup + 1] = {name=def, command=command}
    gg.event("Keepup+", def, gg.ui.keepColor)
end


function gg.loseDef(def)
    for index, defInfo in ipairs(gg.self.keepup) do
        if defInfo.name == def then
            table.remove(gg.self.keepup, index)
            break
        end
    end

    gg.event("Keepup-", def, gg.ui.loseColor)
    if command then send(command) end
end


function gg.onExit()
    send("incall")
    table.save(getMudletHomeDir() .."/adb.lua", gg.adb or {})
    table.save(getMudletHomeDir() .."/keepDefs.lua", gg.self.keepup or {})
end


function gg.onPrompt()
    if not gg.ready then return end
    gg.lastReaction = gg.lastReaction or getEpoch()
    if math.abs(getEpoch() - gg.lastReaction) < 0.75 then return end
    gg.defKeepupCooldowns = gg.defKeepupCooldowns or {}
    for _, def in ipairs(gg.self.keepup) do
        local defIsUp = false
        for _, currentDef in ipairs(gg.self.buffs) do
            local timeSinceLastDefup = math.abs(getEpoch() - (gg.defKeepupCooldowns[currentDef.name] or getEpoch()))
            local defIsOnCooldown = timeSinceLastDefup > gg.defKeepupInterval
            if currentDef.name == def.name then
                defIsUp = true
                gg.defKeepupCooldowns[currentDef.name] = getEpoch()
                break
            end
        end
        if not defIsUp and not defIsOnCooldown and gg.self.has_balance() and gg.self.has_equilibrium() then send(def.command) end
    end
end


function gg.playerNote(playerName, playerInfo)
    if table.is_empty(playerInfo or {}) then return end
    playerName = tostring(playerName):title()
    local playerEntry = gg.adb[playerName] or {}
    for _, possible_key in ipairs({"city", "guild", "order",
                                   "city_enemy", "guild_enemy", "order_enemy",
                                   "personal_enemy", "personal_ally", "notes"}) do
        if playerInfo[possible_key] then
            local value = playerInfo[possible_key]
            if possible_key == "city" then value = value:title() end
            playerEntry[possible_key] = value
        end
    end
    gg.adb[playerName] = playerEntry
    gg.event("PlayerUpdate", playerName, "gold", playerEntry)
    gg.updateADBTriggers()
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

    gg.self.debuffs = affs
end


function gg.processDefs()
    local Defences = gmcp.Char.Defences
    local defs = table.deepcopy(gg.self.buffs)

    local needToAdd
    for _, defInfo in ipairs(Defences.List) do
        needToAdd = true
        for index, def in ipairs(defs) do
            if defInfo.name == def.name then
                needToAdd = false
                break
            end
        end
        if needToAdd then defs[#defs + 1] = defInfo end
    end

    needToAdd = true
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

    gg.self.buffs = defs
end


function gg.processExtraDef(name, desc)
    for _, def in ipairs(gg.self.buffs) do
        if name == def.name then return end
    end
    gg.self.buffs[#gg.self.buffs + 1] = {name=name, desc=desc}
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
        if Items.Add and Items.Add.Item and item.id == Items.Add.Item.id then needToAdd = false end
    end

    if Items.Add and Items.Add.Item and Items.Add.location == type_filter and needToAdd then
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

    for _, player in ipairs(Room.Players or {}) do
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
    gg.self.room.players = players
end


function gg.processTime()
    if not gmcp.IRE.Time then return end
    local time = table.deepcopy(gmcp.IRE.Time.List)
    if not time then return end

    if gmcp.IRE.Time.Update then
        for key, _ in pairs(time) do
            local updated_value = gmcp.IRE.Time.Update[key]
            if updated_value then time[key] = updated_value end
        end
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


function gg.refreshUI()
    gg.drawUI()
    if gg.ui.updateTimer then killTimer(gg.ui.updateTimer) end
    gg.ui.updateTimer = tempTimer(gg.ui.refreshInterval or .1, gg.refreshUI)
end

function gg.refreshSlowAPIs()
    getHTTP("https://api.aetolia.com/characters.json")  -- fetch who list
    sendGMCP([[IRE.Time.Request]])  -- request time in game
    if gg.ui.slowUpdateTimer then killTimer(gg.ui.slowUpdateTimer) end
    gg.ui.slowUpdateTimer = tempTimer(1, gg.refreshSlowAPIs)
end


function gg.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
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
            gg.self.room.contents = gg.processItems("room")
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
        function() gg.event("Player entered", gmcp.Room.AddPlayer.name, gg.ui.keepColor) end)

    deleteNamedEventHandler("gg.event", "gmcp.Room.RemovePlayer")
    registerNamedEventHandler("gg.event", "gmcp.Room.RemovePlayer", "gmcp.Room.RemovePlayer",
        function() gg.event("Player left", gmcp.Room.RemovePlayer, gg.ui.loseColor) end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Defences.Add")
    registerNamedEventHandler("gg.event", "gmcp.Char.Defences.Add", "gmcp.Char.Defences.Add",
        function() gg.event("Def+", gmcp.Char.Defences.Add.name, gg.ui.keepColor) end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Defences.Remove")
    registerNamedEventHandler("gg.event", "gmcp.Char.Defences.Remove", "gmcp.Char.Defences.Remove",
        function() gg.event("Def-", gmcp.Char.Defences.Remove[1], gg.ui.loseColor) end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Add")
    registerNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Add", "gmcp.Char.Afflictions.Add",
        function() gg.event("Aff+", gmcp.Char.Afflictions.Add.name, gg.ui.loseColor) end)

    deleteNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Remove")
    registerNamedEventHandler("gg.event", "gmcp.Char.Afflictions.Remove", "gmcp.Char.Afflictions.Remove",
        function() gg.event("Aff-", gmcp.Char.Afflictions.Remove[1], gg.ui.keepColor) end)
end


deleteNamedEventHandler("gg.init", "sysConnectionEvent")
registerNamedEventHandler("gg.init", "sysConnectionEvent", "sysConnectionEvent", function()
    tempTimer(2, gg.init) end)


function gg.updateADBTriggers()
    for _, adbInfo in ipairs(gg.adb or {}) do
        if not adbInfo.has_trigger then
            tempTrigger(adb.name, function()
                selectString(adb.name)
                if adbInfo.city and gg.ui.whoColors[adbInfo.city:title()] then
                    fg(gg.ui.whoColors[adbInfo.city:title()])
                end
                if adbInfo.city_enemy then setItalics() end
                if adbInfo.enemy then setBold() end
            end)
            adbInfo.has_trigger = true
        end
    end
end


function gg.usedBalance(balType, timeToReturn)
    timeToReturn = tonumber(timeToReturn)

    local badgeLookup = {
        Balance={name="balBadge", label="BAL"},
        Equilibrium={name="eqBadge", label="EQ"},
        Elixir={name="sipBadge", label="SIP"},
    }

    if table.contains(badgeLookup, balType) then
        local badgeInfo = badgeLookup[balType]
        local uiWidget = gg.ui[badgeInfo.name]
        if not uiWidget then error("ui widget for ".. balType .."(".. badgeInfo.name ..") not found") end
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
end
