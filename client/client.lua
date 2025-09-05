local hover = { visible = false, lastTick = 0, pos = nil, text = nil }

local function showHover(text, pos)
    if not Config.HoverTextEnabled then return end
    hover.visible = true
    hover.lastTick = GetGameTimer()
    hover.text = text
    hover.pos = pos

    if not hover.visible then
        lib.showTextUI(text)
        hover.visible = true
    end
end

local function hideHover()
    if hover.visible then
        lib.hideTextUI()
        hover.visible = false
        hover.pos = nil
        hover.text = nil
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if hover.visible then
            if GetGameTimer() - hover.lastTick > 150 then
                hideHover()
            elseif hover.text and hover.pos then
                lib.showTextUI(hover.text)
            end
        end
    end
end)

local function hasAllowedWeapon()
    if not Config.RequireMeleeWeapon then return true end
    local ped = PlayerPedId()
    local _, hash = GetCurrentPedWeapon(ped, true)
    for _, w in ipairs(Config.AllowedWeapons) do
        if hash == w then return true end
    end
    return false
end

local function closestTyreIndexByBone(ped, veh)
    local pcoords = GetEntityCoords(ped)
    local bestBone, bestDist, bestIdx = nil, 9999.0, nil
    for _, name in ipairs(Config.WHEEL_BONES) do
        local bone = GetEntityBoneIndexByName(veh, name)
        if bone ~= -1 then
            local coords = GetWorldPositionOfEntityBone(veh, bone)
            local dist = #(pcoords - coords)
            if dist < bestDist then
                bestDist = dist
                bestBone = name
                bestIdx  = Config.BONE_TO_TYRE[name]
            end
        end
    end
    return bestIdx, bestBone, bestDist
end

local function doSlashAnim(duration)
    local ped = PlayerPedId()
    RequestAnimDict('melee@knife@streamed_core')
    while not HasAnimDictLoaded('melee@knife@streamed_core') do
        Wait(0)
    end
    TaskPlayAnim(ped, 'melee@knife@streamed_core', 'ground_attack_on_spot', 8.0, -8.0, duration, 1, 0.0, false, false,
        false)
    Wait(duration)
    StopAnimTask(ped, 'melee@knife@streamed_core', 'ground_attack_on_spot', 1.0)
end

local function slashNearestTyre(veh)
    if not DoesEntityExist(veh) then return end
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == veh then return end

    local tyreIndex = nil
    local idx, dist = closestTyreIndexByBone(ped, veh)

    if idx ~= nil and dist and dist <= (Config.TargetDistance + 0.5) then
        tyreIndex = idx
    end

    doSlashAnim(Config.ActionMs)

    if tyreIndex then
        SetVehicleTyreBurst(veh, tyreIndex, true, Config.TyreDamage)
        if not IsVehicleTyreBurst(veh, tyreIndex, false) then
            for i = 0, 7 do
                SetVehicleTyreBurst(veh, i, true, Config.TyreDamage)
                if IsVehicleTyreBurst(veh, i, false) then break end
            end
        end
    else
        for i = 0, 7 do
            SetVehicleTyreBurst(veh, i, true, Config.TyreDamage)
        end
    end
end

local function canInteractCommon(entity, distance)
    if not entity or entity == 0 then return false end
    if distance and distance > Config.TargetDistance + 0.2 then return false end
    if not DoesEntityExist(entity) then return false end
    if not IsEntityAVehicle(entity) then return false end
    if IsEntityDead(entity) then return false end
    if not hasAllowedWeapon() then return false end
    return true
end

CreateThread(function()
    while not exports.ox_target or GetResourceState('ox_target') ~= 'started' do
        Wait(100)
    end
    exports.ox_target:addGlobalVehicle({
        {
            name = 'si_slashtire:slashwheel',
            icon = 'fa-solid fa-knife',
            label = 'Pinchar Rueda',
            distance = Config.TargetDistance,
            canInteract = function(entity, distance, hitCoords, boneId)
                if not entity or entity == 0 then return false end
                if distance and distance > (Config.TargetDistance + 0.2) then return false end
                if not DoesEntityExist(entity) then return false end
                if IsEntityDead(entity) then return false end
                if GetEntityType(entity) ~= 2 then return false end -- vehicle
                if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
                if not hasAllowedWeapon() then return false end

                if Config.HoverTextEnabled then
                    local pos
                    if boneId and boneId ~= -1 then
                        local bx, by, bz = table.unpack(GetWorldPositionOfEntityBone(entity, boneId))
                        pos = vec3(bx, by, bz + 0.05)
                    elseif hitCoords then
                        pos = hitCoords + vec3(0.0, 0.0, 0.05)
                    else
                        local x, y, z = table.unpack(GetEntityCoords(entity))
                        pos = vec3(x, y, z + 0.5)
                    end
                    showHover(Config.HoverText or 'Pinchar rueda', pos)
                end

                return true
            end,
            onSelect = function(data)
                local veh = data and data.entity or 0
                if veh ~= 0 then
                    slashNearestTyre(veh)
                end
            end
        }
    })
end)

RegisterNetEvent('si_slashtire:slashWheel', function(data)
    local veh = data and data.entity or 0
    if veh == 0 or not veh then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            veh = GetVehiclePedIsIn(ped, false)
        else
            local pcoords = GetEntityCoords(ped)
            local closest, cdist = 0, 9999.0
            for vehc in EnumerateVehicles() do
                local dist = #(GetEntityCoords(vehc) - pcoords)
                if dist < cdist and dist <= 3.0 then
                    closest, cdist = vehc, dist
                end
            end
            veh = closest
        end
    end

    if veh and veh ~= 0 and canInteractCommon(veh, Config.TargetDistance) then
        slashNearestTyre(veh)
    end
end)

local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}
function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
        local enum = { handle = iter, destructor = disposeFunc }
        setmetatable(enum, entityEnumerator)
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end
