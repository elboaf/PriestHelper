-- Addon Name
PriestHelper = {}

-- Addon Constants
local SPELL_PWF = "Power Word: Fortitude"
local SPELL_LESSER_HEAL = "Heal(rank 1)"
local SPELL_RENEW = "Renew"
local SPELL_SMITE = "Smite"
local SPELL_SHOOT = "Shoot"
local SPELL_SWP = "Shadow Word: Pain"
local SPELL_MIND_BLAST = "Mind Blast"
local SPELL_QDM = "Quel'dorei Meditation"
local SPELL_PWS = "Power Word: Shield"
local SPELL_FADE = "Fade"
local SPELL_PSCREAM = "Psychic Scream"
local SPELL_INNER_FIRE = "Inner Fire"
local SPELL_DISPEL = "Dispel Magic"
local SPELL_CURE_DISEASE = "Cure Disease"
local HEALTH_THRESHOLD = 70 -- Heal if health is below 90%

-- List of debuffs to dispel with Dispel Magic
local debuffsToDispel = {
    "ShadowWordPain",
    "Polymorph",
    -- Add more debuff names here as needed
}

-- List of debuffs to cure with Cure Disease
local diseasesToCure = {
    "NullifyDisease",
    "CallofBone",
    -- Add more disease debuff names here as needed
}

-- Helper function to check if a unit has a specific debuff
local function HasDebuff(unit, debuffList)
    for i = 1, 16 do
        local name = UnitDebuff(unit, i)
        if name then
            for _, debuff in ipairs(debuffList) do
                if strfind(name, debuff) then
                    return true
                end
            end
        end
    end
    return false
end

-- Function to buff a unit with Power Word: Fortitude if they are not already buffed
local function BuffUnit(unit)
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and not buffed(SPELL_PWF, unit) then
        CastSpellByName(SPELL_PWF)
        SpellTargetUnit(unit)
        return true
    end
    return false
end

-- Function to dispel a unit with Dispel Magic
local function DispelUnit(unit)
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
        CastSpellByName(SPELL_DISPEL)
        SpellTargetUnit(unit)
        return true
    end
    return false
end

-- Function to cure a unit with Cure Disease
local function CureDiseaseUnit(unit)
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
        CastSpellByName(SPELL_CURE_DISEASE)
        SpellTargetUnit(unit)
        return true
    end
    return false
end

-- Function to buff Inner Fire on the player
local function BuffInnerFire()
    if not buffed(SPELL_INNER_FIRE, "player") then
        CastSpellByName(SPELL_INNER_FIRE)
    end
end

-- Function to buff party members and myself with Power Word: Fortitude
local function BuffParty()
    -- Buff myself first
    if BuffUnit("player") then
        return
    end

    -- Buff party members
    for i = 1, 4 do
        local partyMember = "party" .. i
        if BuffUnit(partyMember) then
            return
        end
    end
end

-- Function to dispel debuffs from party members and myself
local function DispelParty()
    if HasDebuff("player", debuffsToDispel) then
        if UnitExists("target") and UnitCanAttack("player", "target") then
            ClearTarget()
        end
        if DispelUnit("player") then
            return
        end
    end

    for i = 1, 4 do
        local partyMember = "party" .. i
        if HasDebuff(partyMember, debuffsToDispel) then
            if UnitExists("target") and UnitCanAttack("player", "target") then
                ClearTarget()
            end
            if DispelUnit(partyMember) then
                return
            end
        end
    end
end

-- Function to cure diseases from party members and myself
local function CureDiseaseParty()
    if HasDebuff("player", diseasesToCure) then
        if UnitExists("target") and UnitCanAttack("player", "target") then
            ClearTarget()
        end
        if CureDiseaseUnit("player") then
            return
        end
    end

    for i = 1, 4 do
        local partyMember = "party" .. i
        if HasDebuff(partyMember, diseasesToCure) then
            if UnitExists("target") and UnitCanAttack("player", "target") then
                ClearTarget()
            end
            if CureDiseaseUnit(partyMember) then
                return
            end
        end
    end
end

-- Function to heal the lowest health party member (including myself)
local function HealParty()
    local lowestHealthUnit = nil
    local lowestHealthPercent = 100

    -- Check player's health
    if not UnitIsDeadOrGhost("player") then
        local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
        if playerHealth < lowestHealthPercent then
            lowestHealthUnit = "player"
            lowestHealthPercent = playerHealth
        end
    end

    -- Check party members' health
    for i = 1, 4 do
        local partyMember = "party" .. i
        if UnitExists(partyMember) and not UnitIsDeadOrGhost(partyMember) then
            local health = UnitHealth(partyMember) / UnitHealthMax(partyMember) * 100
            if health < lowestHealthPercent then
                lowestHealthUnit = partyMember
                lowestHealthPercent = health
            end
        end
    end

    -- Heal the lowest health unit based on thresholds
    if lowestHealthUnit then
        function db(k)
            for i = 1, 16 do
                if strfind(tostring(UnitDebuff(lowestHealthUnit, i)), k) then
                    return 1
                end
            end
        end

        function b(k)
            for i = 1, 16 do
                if strfind(tostring(UnitBuff(lowestHealthUnit, i)), k) then
                    return 1
                end
            end
        end

        -- cast fade if we took damage and its off cd
        if UnitAffectingCombat("player") and UnitHealth("player") / UnitHealthMax("player") * 100 < 25 then
            local c, s = CastSpellByName, SPELL_PSCREAM
            local i = nil
            for j = 1, 180 do
                local n = GetSpellName(j, BOOKTYPE_SPELL)
                if n and strfind(n, s) then
                    i = j
                    break
                end
            end
            if i then
                if GetSpellCooldown(i, BOOKTYPE_SPELL) < 1 then
                    c(s)
                end
            end
        end

        if UnitAffectingCombat("player") and UnitHealth("player") / UnitHealthMax("player") * 100 < 65 then
            local c, s = CastSpellByName, SPELL_FADE
            local i = nil
            for j = 1, 180 do
                local n = GetSpellName(j, BOOKTYPE_SPELL)
                if n and strfind(n, s) then
                    i = j
                    break
                end
            end
            if i then
                if GetSpellCooldown(i, BOOKTYPE_SPELL) < 1 then
                    c(s)
                end
            end
        end

        -- Cast Power Word: Shield if health is below 90% and not affected by weakened soul
        if lowestHealthPercent < 90 and not db("AshesToAshes") and UnitAffectingCombat(lowestHealthUnit) and (UnitMana("player") / UnitManaMax("player")) * 100 > 5 then
            CastSpellByName(SPELL_PWS)
            SpellTargetUnit(lowestHealthUnit)
            return true
        end

        -- cast renew
        if lowestHealthPercent < 90 and not b("Renew") and (UnitMana("player") / UnitManaMax("player")) * 100 > 10 then
            CastSpellByName(SPELL_RENEW)
            SpellTargetUnit(lowestHealthUnit)
            return true
        end

        -- Cast Lesser Heal if health is below 70%
        if lowestHealthPercent < 60 and (UnitMana("player") / UnitManaMax("player")) * 100 > 15 then
            CastSpellByName(SPELL_LESSER_HEAL)
            SpellTargetUnit(lowestHealthUnit)
            return true
        end
    end

    return false -- No healing was needed
end

-- Function to assist a party member by casting Smite on their target
local function AssistPartyMember()
    local mana = (UnitMana("player") / UnitManaMax("player")) * 100
    for i = 1, 4 do
        local partyMember = "party" .. i
        if UnitExists(partyMember) and not UnitIsDeadOrGhost(partyMember) then
            local target = partyMember .. "target"
            if UnitExists(target) and UnitCanAttack("player", target) then
                AssistUnit(partyMember)

                if mana > 50 and not buffed(SPELL_SWP, target) then
                    CastSpellByName(SPELL_SWP)
                elseif mana > 80 and buffed(SPELL_SWP, target) then
                    local c, s = CastSpellByName, SPELL_MIND_BLAST
                    local i = nil
                    for j = 1, 180 do
                        local n = GetSpellName(j, BOOKTYPE_SPELL)
                        if n and strfind(n, s) then
                            i = j
                            break
                        end
                    end
                    if i then
                        if GetSpellCooldown(i, BOOKTYPE_SPELL) < 1 then
                            c(s)
                        else
                            for i = 1, 120 do
                                if IsAutoRepeatAction(i) then
                                    return
                                end
                            end
                            CastSpellByName("Shoot")
                        end
                    end
                elseif mana < 80 and buffed(SPELL_SWP, target) then
                    for i = 1, 120 do
                        if IsAutoRepeatAction(i) then
                            return
                        end
                    end
                    CastSpellByName("Shoot")
                elseif mana < 50 then
                    for i = 1, 120 do
                        if IsAutoRepeatAction(i) then
                            return
                        end
                    end
                    CastSpellByName("Shoot")
                end
            end
        end
    end
end

-- Function to follow a party member
local function FollowPartyMember()
    for i = 1, 4 do
        local partyMember = "party" .. i
        if UnitExists(partyMember) and not UnitIsDeadOrGhost(partyMember) then
            FollowUnit(partyMember)
            return
        end
    end
end

-- Function to handle out-of-mana situations
local function OOM()
    local mana = (UnitMana("player") / UnitManaMax("player")) * 100
    if mana < 15 then
        local c, s = CastSpellByName, SPELL_QDM
        local i = nil
        for j = 1, 180 do
            local n = GetSpellName(j, BOOKTYPE_SPELL)
            if n and strfind(n, s) then
                i = j
                break
            end
        end
        if i then
            if GetSpellCooldown(i, BOOKTYPE_SPELL) < 1 then
                c(s)
            end
        end
    end
end

-- Slash command to trigger all functionality
SLASH_PRIESTHELPER1 = "/ph"
SlashCmdList["PRIESTHELPER"] = function()
    -- Check if healing is needed
    local healingNeeded = HealParty()

    -- If no healing is needed, proceed to buff and assist
    if not healingNeeded then
        DispelParty()
        CureDiseaseParty()
        BuffParty()
        BuffInnerFire()
        AssistPartyMember()
        FollowPartyMember()
    end

    OOM()
end