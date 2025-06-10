RegisterNetEvent('TxBanana:server:executeAction', function(data)
	if not IsPlayerAceAllowed(source, 'txbanana.canLaunchPlayers') then return end

	if data.type == 'delete' then
		local target = NetworkGetEntityFromNetworkId(data.targetId)
		if IsPedAPlayer(target) then return end
		if DoesEntityExist(target) then
			DeleteEntity(target)
		end
	elseif data.type == 'launch' then
		if data.isPlayer then
			local targetPed = GetPlayerPed(data.targetId)
			if not DoesEntityExist(targetPed) then return end
			local pos1 = GetEntityCoords(GetPlayerPed(source))
			local pos2 = GetEntityCoords(targetPed)
			local vec = (pos1 - pos2) * vector3(-25.0, -25.0, 10.0)

			SetPedToRagdoll(targetPed, 1000, 1000, 0, true, true, false)
			SetEntityVelocity(targetPed, vec.x, vec.y, vec.z)
		else
			local target = NetworkGetEntityFromNetworkId(data.targetId)
			if not DoesEntityExist(target) then return end
			local pos1 = GetEntityCoords(GetPlayerPed(source))
			local pos2 = GetEntityCoords(targetPed)
			local vec = (pos1 - pos2) * vector3(-25.0, -25.0, 10.0)

			if GetEntityType(target) == 1 then
				SetPedToRagdoll(target, 1000, 1000, 0, true, true, false)
			end
			SetEntityVelocity(target, vec.x, vec.y, vec.z)
		end
	end
end)

lib.addCommand('txBanana', {
	help = 'bananaaaaaaaaa',
	restricted = 'group.admin'
}, function(source, args, raw)
	TriggerClientEvent('TxBanana:client:toggle', source)
end)