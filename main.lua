-- Global variables
local player = "player"
local wall = "wall"
local bullet = "small_proj"
local cooldowns = {0, 0, 0} -- [1]: Bullet Cooldown, [2]: Dash Cooldown, [3]: Melee Coldown
local ticks = 0
local dodgedBulllet = 0

local dmg_melee_player = 20
local dmg_bullet = 10
local dmg_outside_ring = 1
local range_to_check = 300

-- Initialize bot
function bot_init(me)
end

-- Main bot function
function bot_main(me)
    updateCooldowns()
    decisionMaking(me)
end

-- Update Cooldowns
function updateCooldowns()
    ticks = ticks + 1
    for i = 1, 3 do
        if cooldowns[i] > 0 then
            cooldowns[i] = cooldowns[i] - 1
        end
    end
end

-- Decision Making 
-- 1. Hit Melee
-- 2. Dodge Bullets
-- 3. Circle
-- 4. Dodge People
-- 5. Risk Moving
function decisionMaking(me)
    if (hitMelee(me) == false) then
        if (goToCircle(me) == false) then
            if (dodgeBullets(me) == false) then
                if (socialAnxiety(me) == false) then
                    riskAvoidance(me)
                end
            end
        end
    end
end

-- Hit Melee
function hitMelee(me)
    for _, entity in ipairs(me:visible()) do
        if (entity:type() == player) then
            if (vec.distance(entity:pos(), me:pos()) <= 2 and cooldowns[3] == 0) then
                cooldowns[3] = 50
                me:cast(2, entity:pos():sub(me:pos()))
                return true
            elseif (vec.distance(entity:pos(), me:pos()) <= 4 and cooldowns[1] == 0) then
                cooldowns[1] = 60
                me:cast(1, entity:pos():sub(me:pos()))
                return true
            end
        end
    end
    return false
end

-- Dodge Bullets
function dodgeBullets(me)
    if (dodgedBullet ~= 0) then
        local tmp_dodgedbullet = dodgedBullet
        dodgedBullet = 0
        return dodgeMovement(me, tmp_dodgedbullet)
    else
        for _, entity in ipairs(me:visible()) do
            if (entity:type() == bullet and entity.owner_id() ~= me:id()) then
                if (vec.distance(me:pos(), entity:pos()) <= 8) then
                    dodgedBullet = goToCenter(me)
                    if (wally(me, dodgedBullet) == true) then
                        dodgedBullet = dodgedBullet + 4
                    end
                    return dodgeMovement(me, dodgedBullet)
                end
            end
        end
    end
    return false
end

-- Dodging bullet according to the value of the parameter. Takes an action, it moves, so you can't invoke another action next
function dodgeMovement(me, dodgedBullet)
    if (dodgedBullet == 1) then
        me:move(vec.new(0, 1))
    elseif (dodgedBullet == 2) then
        me:move(vec.new(1, 1))
    elseif (dodgedBullet == 3) then
        me:move(vec.new(1, 0))
    elseif (dodgedBullet == 4) then
        me:move(vec.new(1, -1))
    elseif (dodgedBullet == 5) then
        me:move(vec.new(0, -1))
    elseif (dodgedBullet == 6) then
        me:move(vec.new(-1, -1))
    elseif (dodgedBullet == 7) then
        me:move(vec.new(-1, 0))
    elseif (dodgedBullet == 8) then
        me:move(vec.new(-1, 1))
    end
    return true
end

-- Wall Detection
function wally(me, futureMovement)
    if (futureMovement > 8) then
        local movement = getXY(futureMovement-8, true)
        movement = movement:add(me:pos())
        if (movement:x() >= 500 or movement:y() >= 500 or movement:x() <= 0 or movement:y() <= 0) then return true
        elseif (isWall(me, vec.new(movement:x(), movement:y())) == true) then return true
        else return false end
    else
        local movement = getXY(futureMovement, false)
        movement = movement:add(me:pos())
        if (movement:x() >= 500 or movement:y() >= 500 or movement:x() <= 0 or movement:y() <= 0) then return true
        elseif (isWall(me, vec.new(movement:x(), movement:y())) == true) then return true
        else return false end
    end
end

-- Is This a Wall?
function isWall(me, futureMovement)
    for _, entity in ipairs(me:visible()) do
        if (entity:type() == wall) then
            if (entity:pos() == futureMovement) then
                return true
            end
        end
    end
    return false
end


-- Get x, y
function getXY(pos, dash)
    local length
    if (dash == false) then
        length = 1
    else
        length = 10
    end
    local x = 0
    local y = 0
    if (pos == 2) then
        y = length
    elseif (pos == 3) then
        x = math.cos(math.pi/4)*length
        y = math.sin(math.pi/4)*length
    elseif (pos == 4) then
        x = length
    elseif (pos == 5) then
        x = math.cos(math.pi/4)*length
        y = -math.sin(math.pi/4)*length
    elseif (pos == 6) then
        y = -length
    elseif (pos == 7) then
        x = -math.cos(math.pi/4)*length
        y = -math.sin(math.pi/4)*length
    elseif (pos == 8) then
        x = -length
    elseif (pos == 9) then
        x = -math.cos(math.pi/4)*length
        y = math.sin(math.pi/4)*length
    end
    return vec.new(x, y)
end

-- Go To Center
function goToCenter(me)
    if (vec.distance(me:pos(), me:cod()) >= me:cod():radius() - 1) then
        me:cod():sub(me:pos())
        if (me:cod():sub(me:pos()):x() == 0 and me:cod():sub(me:pos()):y() > 0) then return 1
        elseif (me:cod():sub(me:pos()):x() > 0 and me:cod():sub(me:pos()):y() > 0) then return 2
        elseif (me:cod():sub(me:pos()):x() > 0 and me:cod():sub(me:pos()):y() == 0) then return 3
        elseif (me:cod():sub(me:pos()):x() > 0 and me:cod():sub(me:pos()):y() < 0) then return 4
        elseif (me:cod():sub(me:pos()):x() == 0 and me:cod():sub(me:pos()):y() < 0) then return 5
        elseif (me:cod():sub(me:pos()):x() < 0 and me:cod():sub(me:pos()):y() < 0) then return 6
        elseif (me:cod():sub(me:pos()):x() < 0 and me:cod():sub(me:pos()):y() == 0) then return 7
        elseif (me:cod():sub(me:pos()):x() < 0 and me:cod():sub(me:pos()):y() > 0) then return 8
        end
    else
        return math.random(1, 8)
    end
end

-- Go To Circle
function goToCircle(me)
    if (me:cod():x() ~= -1 and me:cod():y() ~= -1 and vec.distance(me:pos(), me:cod()) >= me:cod():radius() - 2) then
        me:move(vec.new(me:cod():x(), me:cod():y()):sub(me:pos()))
        return true
    elseif (me:cod():x() ~= -1 and me:cod():y() ~= -1 and vec.distance(me:pos(), me:cod()) < me:cod():radius() - 2 and me:cod():radius() >= 90) then
        if (vec.distance(me:pos(), me:cod()) < (me:cod():radius() - 2)/2) then
            me:move(vec.new(me:cod():x(), me:cod():y()):sub(me:pos()))
        else
            me:move(vec.new(math.random(-1, 1), math.random(-1, 1)))
        end
    elseif (me:cod():x() ~= -1 and me:cod():y() ~= -1 and vec.distance(me:pos(), me:cod()) < me:cod():radius() - 2) then
        if (cooldowns[1] ~= 0) then
            cooldowns[1] = 60
            me:cast(0, vec.new(math.random(-1, 1), math.random(-1, 1)))
        else
            me:move(vec.new(math.random(-1, 1), math.random(-1, 1)))
        end
    else
        return false
    end
end

-- Social Anxiety
function socialAnxiety(me)
    for _, entity in ipairs(me:visible()) do
        if (entity:type() == player) then
            if (vec.distance(entity:pos(), me:pos()) <= 3) then
                me:move(entity:pos():sub(me:pos()):neg())
                return true
            end
        end
    end
    return false
end

-- Risk Avoidance
function riskAvoidance(me)
    decisionMakingRisk(me, calculateRisks(me))
end

-- Calculate Risks
function calculateRisks(me)
    -- List of risks we will return
    local risks = {}
    local calc_dmg

    for i = 1, 9 do
        calc_dmg = closeThreatsRange(me, i, false)
        table.insert(risks, dmg_melee_player*calc_dmg[1] + dmg_bullet*calc_dmg[2] + distanceCOD(me, i, false))
    end
    for i = 2, 9 do
        calc_dmg = closeThreatsRange(me, i, true)
        table.insert(risks, dmg_melee_player*calc_dmg[1] + dmg_bullet*calc_dmg[2] + distanceCOD(me, i, true))
    end

    return risks
end

-- Close Risk Range
function closeThreatsRange(me, pos, dash)
    local newPos = getXY(pos, dash)
    local sum_players = 0
    local sum_bullets = 0
    for _, entity in ipairs(me:visible()) do
        local dist = vec.distance(newPos, entity:pos())
        if (dist < range_to_check) then
            if (entity:type() == player) then
                sum_players = sum_players + 1/dist
            elseif(entity:type() == bullet) then
                sum_bullets = sum_bullets + 1/dist
            end

        end
    end
    return {sum_players, sum_bullets}
end

-- Distance from COD
function distanceCOD(me, pos, dash)
    if (me:cod():x() == -1 and me:cod():y() == -1) then return 0 end
    
    local newPos = getXY(pos, dash)
    newPos = newPos:add(me:pos())
    local center = me:cod()
    local centerPos = vec.new(center:x()+center:radius(), center:y()+center:radius())
    return vec.distance(newPos, centerPos)
end

-- Decision-Making
function decisionMakingRisk(me, risks)
    local shoot = 2
    local minI = 1
    for i = 2, 9 do
        if (risks[1] <= risks[i]) then
            shoot = shoot + 1
        elseif (risks[minI] > risks[i]) then
            minI = i
        end
        if (risks[minI] > (risks[i+8] + 50) and cooldowns[2] == 0) then
            minI = i+8
        end
    end
    if (shoot == 10 and cooldowns[1] == 0) then
        if (me:cod():x() ~= -1 and me:cod():y() ~= -1) then
            me:cast(0, vec.new(me:cod():x(), me:cod():y()))
            cooldowns[1] = 60
        else
            cooldowns[1] = 60
            me:cast(0, closestEnemy(me):pos():sub(me:pos()))
        end
    else
        if (minI == 2) then
            if (wally(me, minI-1) == true) then me:move(vec.new(0, 1):neg())
            else me:move(vec.new(0, 1)) end
        elseif (minI == 3) then
            if (wally(me, minI-1) == true) then me:move(vec.new(1, 1):neg())
            else me:move(vec.new(1, 1)) end
        elseif (minI == 4) then
            if (wally(me, minI-1) == true) then me:move(vec.new(1, 0):neg())
            else me:move(vec.new(1, 0)) end
        elseif (minI == 5) then
            if (wally(me, minI-1) == true) then me:move(vec.new(1, -1):neg())
            else me:move(vec.new(1, -1)) end
        elseif (minI == 6) then
            if (wally(me, minI-1) == true) then me:move(vec.new(0, -1):neg())
            else me:move(vec.new(0, -1)) end
        elseif (minI == 7) then
            if (wally(me, minI-1) == true) then me:move(vec.new(-1, -1):neg())
            else me:move(vec.new(-1, -1)) end
        elseif (minI == 8) then
            if (wally(me, minI-1) == true) then me:move(vec.new(-1, 0):neg())
            else me:move(vec.new(-1, 0)) end
        elseif (minI == 9) then
            if (wally(me, minI-1) == true) then me:move(vec.new(-1, 1):neg())
            else me:move(vec.new(-1, 1)) end
        elseif (minI == 10) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(0, 1):neg())
            else me:cast(1, vec.new(0, 1)) end
        elseif (minI == 11) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(1, 1):neg())
            else me:cast(1, vec.new(1, 1)) end
        elseif (minI == 12) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(1, 0):neg())
            else me:cast(1, vec.new(1, 0)) end
        elseif (minI == 13) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(1, -1):neg())
            else me:cast(1, vec.new(1, -1)) end
        elseif (minI == 14) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(0, -1):neg())
            else me:cast(1, vec.new(0, -1)) end
        elseif (minI == 15) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(-1, -1):neg())
            else me:cast(1, vec.new(-1, -1)) end
        elseif (minI == 16) then
            if (wally(me, minI-1) == true) then  me:cast(1, vec.new(-1, 0):neg())
            else me:cast(1, vec.new(-1, 0)) end
        elseif (minI == 17) then
            if (wally(me, minI-1) == true) then me:cast(1, vec.new(-1, 1):neg())
            else me:cast(1, vec.new(-1, 1)) end
        end
    end  
end

-- Closest Enemy
function closestEnemy(me)
    local enemy = nil
    local minDist = math.huge

    for _, entity in ipairs(me:visible()) do
        if (entity:type() == player) then
            local dist = vec.distance(me:pos(), entity:pos())
            if (minDist > dist) then
                enemy = entity
                minDist = dist
            end
        end
    end
    return enemy
end