local bananaing = false
local banana = nil
local target = nil

local function CleanupBanana()
    if not banana then return end

    SetEntityAsMissionEntity(banana)
    DeleteObject(banana)
end

local function StartBanana()

    -- Banana Object Handling
    local bananaHash = lib.requestModel("ng_proc_food_nana1a")

    CleanupBanana()
    banana = CreateObject(bananaHash, x, y, z, true, false, true)
    SetModelAsNoLongerNeeded(bananaHash)

    PlaceObjectOnGroundProperly(banana)
    SetEntityAsMissionEntity(banana)
    AttachEntityToEntity(banana, cache.ped, GetPedBoneIndex(cache.ped, 18905), 0.2, 0.03, 0.03, 20.0, 190.0, -45.0, true, true, false, true, 1, true)

    -- Animation Handling
    lib.requestAnimDict("anim@mp_point")

    SetPedCurrentWeaponVisible(cache.ped, false, true, true, true)
    SetPedConfigFlag(cache.ped, 36, 1)
	TaskMoveNetworkByName(cache.ped, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)
    RemoveAnimDict("anim@mp_point")
end

local function StopBanana()
    target = nil

    -- Animation Handling
	RequestTaskMoveNetworkStateTransition(cache.ped, 'Stop')
    if not IsPedInjured(cache.ped) then ClearPedSecondaryTask(cache.ped) end
    if not IsPedInAnyVehicle(cache.ped, true) then SetPedCurrentWeaponVisible(cache.ped, true, true, true, true) end

    SetPedConfigFlag(cache.ped, 36, 0)
    ClearPedSecondaryTask(cache.ped)
end

-- This crashes the client if used on a Player Ped =(
local function OutlineTarget(enabled)
    SetEntityDrawOutline(banana, enabled)
    SetEntityDrawOutlineColor(255.0, 255.0, 0.0, 0)
    if not enabled then target = nil end
end

local function RotationToDirection(rotation)
	local adjustedRotation = {
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera()
	local cameraCoord = GetGameplayCamCoord()
    local entityCoord = cache.coords
	local direction = RotationToDirection(GetGameplayCamRot())
    local distance = 50.0
	local destination = vector3(cameraCoord.x + direction.x * distance, cameraCoord.y + direction.y * distance, cameraCoord.z + direction.z * distance)

	local _, _, _, _, entityHit = GetShapeTestResult(StartShapeTestRay(entityCoord.x, entityCoord.y, entityCoord.z+0.6, destination.x, destination.y, destination.z, -1, cache.ped, 0))
    -- DrawLine(entityCoord.x, entityCoord.y, entityCoord.z+0.6, destination.x, destination.y, destination.z, 255, 255, 0, 0.5)
    return entityHit
end

local function toggleBanana()
    CleanupBanana()
    if not cache.vehicle then
        bananaing = not bananaing
        if bananaing then StartBanana() end

        CreateThread(function()
            while bananaing do

                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                -- Raycasting Logic
                local entityHit = RayCastGamePlayCamera()

                -- Point Location Logic
                SetTaskMoveNetworkSignalFloat(cache.ped, "Pitch", camPitch)
                SetTaskMoveNetworkSignalFloat(cache.ped, "Heading", camHeading * -1.0 + 1.0)
                SetTaskMoveNetworkSignalBool(cache.ped, "isBlocked", false)
                SetTaskMoveNetworkSignalBool(cache.ped, "isFirstPerson", GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)

                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)

                -- Detect Entity Hit
                local entityType = GetEntityType(entityHit)
                if entityHit ~= 0 and (entityType == 1 or entityType == 2) then

                    if entityHit ~= target then
                        if target then OutlineTarget(false) end
                        target = entityHit
                        OutlineTarget(true)
                        print('Pointing at Player ID', GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                    end

                    if target then
                        -- Handle Left Click
                        if IsDisabledControlJustPressed(0, 24) and target then
                            if IsPedAPlayer(entityHit) then
                                ExecuteCommand('tx '..GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                                print('Shot Player ID', GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                            else
                                TriggerServerEvent('TxBanana:server:executeAction', { type = 'delete' , targetId = NetworkGetNetworkIdFromEntity(entityHit), })
                            end
                        end

                        -- Handle Right Click
                        if IsDisabledControlJustPressed(0, 25) then
                            if IsPedAPlayer(entityHit) then
                                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(target))
                                print('Right Clicked ID', targetId)
                                TriggerServerEvent('TxBanana:server:executeAction', { type = 'launch', targetId = targetId, isPlayer = true })
                            else
                                TriggerServerEvent('TxBanana:server:executeAction', { type = 'launch', targetId = NetworkGetNetworkIdFromEntity(entityHit)})
                            end
                        end
                    end
                elseif target then
                    print('Stopped Point at ID', GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)))
                    target = nil
                    OutlineTarget(false)
                end
                Wait(0)
            end

            -- Once bananaing is done, cleanup
            StopBanana()
        end)
    end
end

RegisterNetEvent('TxBanana:client:toggle', function()
    toggleBanana()
end)

-- Handle Cleanup on Resource Stop
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then CleanupBanana() end
end)

-- Handle Keymapping
--RegisterKeyMapping('txBanana', 'Toggles Banana', 'keyboard', 'B')
lib.onCache('ped', function(new, old) end)
local temp = lib.points.new({coords = vector3(0.0, 0.0, 0.0), distance = 2.0})
temp:remove()