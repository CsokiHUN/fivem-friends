local serverPlayers = {}
local streamedPlayers = {}
local panelState = false

local Friends = {}

local myName = true

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

local function requestPlayers()
	CreateThread(function()
		Wait(1000)
		ESX.TriggerServerCallback("requestPlayerNames", function(result, friends)
			serverPlayers = result

			updateFriends(friends)
		end)
	end)
end
CreateThread(requestPlayers)
AddEventHandler("esx:playerLoaded", requestPlayers)

local function getPedHeadCoords(ped)
	local coords = GetWorldPositionOfEntityBone(ped, 101)
	if coords == vector3(0, 0, 0) then
		coords = GetEntityCoords(ped) + vector3(0, 0, 1)
	else
		coords = coords + vector3(0, 0, 0.25)
	end

	local frameTime = GetFrameTime()
	local vel = GetEntityVelocity(ped)

	coords = vector3(coords.x + vel.x * frameTime, coords.y + vel.y * frameTime, coords.z + vel.z * frameTime)

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
				if not (DoesEntityExist(ped) and HasEntityClearLosToEntity(myPed, ped, 17)) then
					goto skip
				end

				local coords = GetEntityCoords(ped)
				if #(coords - myCoords) < STREAM_DISTANCE then
					streamedPlayers[playerID] = {
						ped = ped,
						serverID = GetPlayerServerId(playerID),
						helmet = GetPedDrawableVariation(ped, 1) > 0,
					}
				end
				::skip::
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
			if not DoesEntityExist(data.ped) then
				goto skip
			end

			local coords = GetEntityCoords(data.ped)
			local dist = #(coords - myCoords)
			if dist > STREAM_DISTANCE then
				goto skip
			end

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
					scale,
					color.r,
					color.g,
					color.b,
					255 * scale
				)
			end

			::skip::
		end

		Wait(5)
	end
end)

RegisterNUICallback("close", function()
	setPanelState(false)
end)

RegisterNUICallback("sendNew", function(data, cb)
	local targetPlayer = GetPlayerFromServerId(data.id)

	if targetPlayer and targetPlayer < 0 then
		cb({ success = false })
		notify("Hib??s a megadott ID!", "error")
		return
	end

	if data.id == GetPlayerServerId(PlayerId()) then
		cb({ success = false })
		notify("Saj??t magadat nem tudod bar??tnak jel??lni!", "error")
		return
	end

	ESX.TriggerServerCallback("newFriendRequest", function(result, message, pendings)
		if result then
			notify("K??relem elk??ldve.")
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
			notify("Sikertelen t??rl??s!", "error")
			return
		end

		if data.page == "pendings" then
			cb({ success = true, pendings = resultData })
			notify("K??relem t??r??lve!", "error")
		elseif data.page == "friends" then
			updateFriends(resultData)

			cb({ success = true, friends = resultData })
			notify("Bar??t t??r??lve.")
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

		notify("Bar??t k??relem elfogadva!")

		updateFriends(friends)
		cb({ success = true, friends = friends, pendings = pendings })
	end, data.row)
end)

function Command()
	setPanelState(not panelState)
end
RegisterCommand("bar??taim", Command)
RegisterCommand("friends", Command)

RegisterCommand("togmyname", function()
	myName = not myName
end)
