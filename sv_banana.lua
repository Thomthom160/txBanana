RegisterNetEvent('TxBanana:server:launchPlayer', function(data)
	if not IsPlayerAceAllowed(source, 'txbanana.canLaunchPlayers') then return end
	local targetPed = GetPlayerPed(data.target)
	if not DoesEntityExist(targetPed) then return end
	local pos1 = GetEntityCoords(GetPlayerPed(source))
	local pos2 = GetEntityCoords(targetPed)
	local vec = (pos1 - pos2) * vector3(-25.0, -25.0, 10.0)

	SetPedToRagdoll(targetPed, 1000, 1000, 0, true, true, false)
	SetEntityVelocity(targetPed, vec.x, vec.y, vec.z)

end)