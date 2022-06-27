gg = gg or {}
gg.ui = gg.ui or {}
gg.ui.refreshInterval = .1
gg.ui.availColor = "cyan"
gg.ui.infoColor = "white"
gg.ui.offColor = "grey"
gg.ui.roomColor = "DarkOrange"

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

self.bleeding = function() return Vitals.bleeding ~= "0" end
self.blind = function() return Vitals.blind == "1" end
self.can_eat = function() return Vitals.herb == "1" end
self.can_focus = function() return Vitals.focus == "1" end
self.can_moss = function() return Vitals.moss == "1" end
self.can_renew = function() return Vitals.renew == "1" end
self.can_salve = function() return Vitals.salve == "1" end
self.can_sip = function() return Vitals.elixir == "1" end
self.can_smoke = function() return Vitals.pipe == "1" end
self.can_tree = function() return Vitals.tree == "1" end
self.cloaked = function() return Vitals.cloak == "1" end
self.deaf = function() return Vitals.deaf == "1" end
self.fallen = function() return Vitals.fallen ~= "0" end
self.fangbarrier = function() return Vitals.fangbarrier ~= "0" end
self.has_ability_balance = function() return Vitals.ability_bal == "1" end
self.has_balance = function() return Vitals.balance == "1" end
self.has_equilibrium = function() return Vitals.equilibrium == "1" end
self.has_left_arm = function() return Vitals.left_arm == "1" end
self.has_right_arm = function() return Vitals.right_arm == "1" end
self.mad = function() return Vitals.madness == "1" end
self.mounted = function() return Vitals.mounted == "1" end
self.phased = function() return Vitals.phased == "1" end
self.prone = function() return Vitals.prone == "1" end
self.writhing = function() return Vitals.writhing == "1" end

self.build = function() return Status.spec .." ".. Status.race .." ".. Status.class end
self.gold = function() return {banked = tonumber(Status.bank), held = tonumber(Status.gold)} end
self.stats = {
    hp = function() return (tonumber(Vitals.hp) / tonumber(Vitals.maxhp)) * 100 end,
    mp = function() return (tonumber(Vitals.mp) / tonumber(Vitals.maxmp)) * 100 end,
    ep = function() return (tonumber(Vitals.ep) / tonumber(Vitals.maxep)) * 100 end,
    wp = function() return (tonumber(Vitals.wp) / tonumber(Vitals.maxwp)) * 100 end,
    blood = function() return tonumber(Vitals.blood) end,
    to_next_level = function() return tonumber(Vitals.nl) end
}
self.wielding = {
    left = function() return Vitals.wield_left end,
    right = function() return Vitals.wield_right end
}
