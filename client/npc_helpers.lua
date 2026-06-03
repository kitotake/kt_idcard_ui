-- client/npc_helpers.lua
-- Helpers partagés pour fiabiliser le spawn et les interactions des PNJ.

NPC = NPC or {}

local function resourceStarted(name)
    return name and GetResourceState(name) == "started"
end

function NPC.LoadModel(model, timeout)
    local hash = type(model) == "number" and model or GetHashKey(model)

    if not IsModelInCdimage(hash) or not IsModelAPed(hash) then
        print(("^1[PNJ]^7 Modèle invalide ou non-ped : %s"):format(tostring(model)))
        return nil
    end

    if HasModelLoaded(hash) then return hash end

    RequestModel(hash)

    local startedAt = GetGameTimer()
    local maxWait = timeout or 10000

    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() - startedAt >= maxWait then
            print(("^1[PNJ]^7 Timeout chargement modèle : %s"):format(tostring(model)))
            return nil
        end
    end

    return hash
end

function NPC.ResolveGroundCoords(coords)
    local x, y, z = coords.x, coords.y, coords.z

    RequestCollisionAtCoord(x, y, z)

    local foundGround, groundZ = false, nil
    local startedAt = GetGameTimer()

    while GetGameTimer() - startedAt < 2500 do
        foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
        if foundGround then break end
        Wait(50)
    end

    if foundGround and groundZ then
        return x, y, groundZ
    end

    return x, y, z
end

function NPC.SpawnPed(cfg, tag)
    if not cfg or not cfg.model or not cfg.coords then
        print(("^1[%s]^7 Configuration PNJ invalide"):format(tag or "PNJ"))
        return nil
    end

    local hash = NPC.LoadModel(cfg.model)
    if not hash then return nil end

    local x, y, z = NPC.ResolveGroundCoords(cfg.coords)

    print(("^3[%s]^7 Spawn %s à %.2f %.2f %.2f"):format(tag or "PNJ", tostring(cfg.model), x, y, z))

    local ped = CreatePed(4, hash, x, y, z, cfg.heading or 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        print(("^1[%s]^7 CreatePed a échoué pour %s"):format(tag or "PNJ", tostring(cfg.model)))
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityHeading(ped, cfg.heading or 0.0)
    PlaceObjectOnGroundProperly(ped)
    FreezeEntityPosition(ped, cfg.frozen ~= false)
    SetEntityInvincible(ped, cfg.invincible ~= false)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if cfg.scenario and cfg.scenario ~= "" then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    print(("^2[%s]^7 PNJ créé : %s"):format(tag or "PNJ", tostring(ped)))
    return ped
end

function NPC.DeletePed(ped)
    if not ped or not DoesEntityExist(ped) then return end
    ClearPedTasksImmediately(ped)
    SetEntityAsMissionEntity(ped, true, true)
    DeleteEntity(ped)
end

function NPC.TryAddTargetEntity(ped, cfg, eventName)
    if not ped or not DoesEntityExist(ped) or not eventName then return false end
    if not Config or not Config.resources or not resourceStarted(Config.resources.interact) then return false end

    local interact = exports[Config.resources.interact]
    if not interact or not interact.AddTargetEntity then return false end

    local data = {
        {
            label = cfg.label or (cfg.interact and cfg.interact.label) or "Interagir",
            icon = cfg.icon or (cfg.interact and cfg.interact.icon) or "fas fa-circle",
            distance = cfg.distance or (cfg.interact and cfg.interact.distance) or 2.5,
            event = eventName,
        }
    }

    local ok = pcall(function()
        interact:AddTargetEntity(ped, data)
    end)

    if ok then return true end

    ok = pcall(function()
        interact:AddTargetEntity(ped, {
            options = data,
            distance = data[1].distance,
        })
    end)

    return ok
end

function NPC.RemoveTargetEntity(ped)
    if not ped or not DoesEntityExist(ped) then return end
    if not Config or not Config.resources or not resourceStarted(Config.resources.interact) then return end

    local interact = exports[Config.resources.interact]
    if interact and interact.RemoveTargetEntity then
        pcall(function() interact:RemoveTargetEntity(ped) end)
    end
end

function NPC.StartFallbackInteraction(name, getPed, cfg, eventName)
    CreateThread(function()
        local label = cfg.label or (cfg.interact and cfg.interact.label) or "Interagir"
        local distance = cfg.distance or (cfg.interact and cfg.interact.distance) or 2.5

        while true do
            local wait = 750
            local ped = getPed()

            if ped and DoesEntityExist(ped) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local pedCoords = GetEntityCoords(ped)
                local dist = #(playerCoords - pedCoords)

                if dist <= distance then
                    wait = 0
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName(("Appuyez sur ~INPUT_CONTEXT~ pour %s"):format(label))
                    EndTextCommandDisplayHelp(0, false, false, -1)

                    if IsControlJustPressed(0, 38) then
                        TriggerEvent(eventName)
                        Wait(500)
                    end
                end
            end

            Wait(wait)
        end
    end)
end
