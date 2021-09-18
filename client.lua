local serverPlayers = {}
local streamedPlayers = {}
local panelState = false

local Friends = {}

local myName = false

local function updateFriends(data)
	if not data then
		return
	end

	Friends = {}
	for key, friend in pairs(data) do
		Friends[friend.other] = friend
	end

	return Friends
end

function requestPlayers()
	ESX.TriggerServerCallback("requestPlayerNames", function(result, friends)
		serverPlayers = result

		updateFriends(friends)
	end)
end
AddEventHandler("esx:playerLoaded", requestPlayers)

function getPedHeadCoords(ped)
	local coords = GetWorldPositionOfEntityBone(ped, 101)
	if coords == vector3(0, 0, 0) then
		coords = GetEntityCoords(ped) + vector3(0, 0, 1)
	else
		coords = coords + vector3(0, 0, 0.25)
	end
	return coords
end

function getPlayerData(serverID)
	if not tonumber(serverID) then
		return false
	end

	return serverPlayers[serverID]
end

function setPanelState(state)
	panelState = state
	SetNuiFocus(state, state)
	SendNUIMessage({
		visible = state,
	})

	ESX.TriggerServerCallback("requestPanelDatas", function(pendings, friends)
		SendNUIMessage({
			pendings = pendings,
			friends = updateFriends(friends),
		})
	end)
end

RegisterNetEvent(GetCurrentResourceName() .. "->updateDatas", function(pendings, friends)
	SendNUIMessage({
		pendings = pendings,
		friends = updateFriends(friends),
	})
end)

CreateThread(function()
	Wait(1000)

	requestPlayers()

	while true do
		streamedPlayers = {}
		collectgarbage("collect")

		local myPed = PlayerPedId()
		local myCoords = GetEntityCoords(myPed)

		for _, playerID in pairs(GetActivePlayers()) do
			if playerID == PlayerId() and myName or playerID ~= PlayerId() then
				local ped = GetPlayerPed(playerID)
				if DoesEntityExist(ped) then
					local coords = GetEntityCoords(ped)
					if #(coords - myCoords) < STREAM_DISTANCE then
						streamedPlayers[playerID] = {
							ped = ped,
							serverID = GetPlayerServerId(playerID),
							helmet = GetPedDrawableVariation(ped, 1) > 0,
						}
					end
				end
			end
		end

		Wait(1000)
	end
end)

CreateThread(function()
	while true do
		local myPed = PlayerPedId()
		local myCoords = GetEntityCoords(myPed)
		local _playerID = PlayerId()

		for playerID, data in pairs(streamedPlayers) do
			local coords = GetEntityCoords(data.ped)
			local dist = #(coords - myCoords)
			if dist < STREAM_DISTANCE then
				local scale = 1 - dist / STREAM_DISTANCE

				local headCoords = getPedHeadCoords(data.ped)
				local playerData = getPlayerData(data.serverID)
				if playerData then
					local talking = NetworkIsPlayerTalking(playerID)
					local color = talking and TALKING_COLOR or { r = 255, g = 255, b = 255 }

					local name = ""
					if Friends[playerData.license] or playerID == _playerID then
						name = data.helmet and "Maszkos alak " or playerData.name .. " "
					end

					DrawText3D(
						headCoords,
						name .. "(" .. data.serverID .. ")",
						-- data.license,
						scale,
						color.r,
						color.g,
						color.b,
						255 * scale
					)
				end
			end
		end

		Wait(1)
	end
end)

RegisterNUICallback("close", function()
	setPanelState(false)
end)

RegisterNUICallback("sendNew", function(data, cb)
	local targetPlayer = GetPlayerFromServerId(data.id)

	if targetPlayer and targetPlayer < 0 then
		cb({ success = false })
		notify("Hibás a megadott ID!", "error")
		return
	end

	ESX.TriggerServerCallback("newFriendRequest", function(result, message, pendings)
		if result then
			notify("Kérelem elküldve.")
		else
			notify(message, "error")
		end

		cb({ success = result, pendings = pendings })
	end, data.id)
end)

RegisterNUICallback("delete", function(data, cb)
	ESX.TriggerServerCallback("deleteFriend", function(result, resultData)
		if not result then
			cb({ success = false })
			notify("Sikertelen törlés!", "error")
			return
		end

		if data.page == "pendings" then
			cb({ success = true, pendings = resultData })
			notify("Kérelem törölve!", "error")
		elseif data.page == "friends" then
			updateFriends(resultData)

			cb({ success = true, friends = resultData })
			notify("Barát törölve.")
		end
	end, data.row, data.page)
end)

RegisterNUICallback("acceptPending", function(data, cb)
	ESX.TriggerServerCallback("acceptFriendPending", function(result, err, friends, pendings)
		if not result then
			cb({ success = false })
			notify(err, "error")
			return
		end

		notify("Barát kérelem elfogadva!")

		updateFriends(friends)
		cb({ success = true, friends = friends, pendings = pendings })
	end, data.row)
end)

function Command()
	setPanelState(not panelState)
end
RegisterCommand("barátaim", Command)
RegisterCommand("friends", Command)

RegisterCommand("togmyname", function()
	myName = not myName
end)
