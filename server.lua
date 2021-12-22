local Names = {}
local pendingFriends = {}
local Friends = {}

function loadPendingFriends()
	pendingFriends = {}

	local p = promise.new()

	dbQuery(function(result)
		for _, row in pairs(result) do
			if not pendingFriends[row.sourceLicense] then
				pendingFriends[row.sourceLicense] = {}
			end

			if not pendingFriends[row.targetLicense] then
				pendingFriends[row.targetLicense] = {}
			end

			table.insert(pendingFriends[row.sourceLicense], {
				dbID = tonumber(row.id),
				other = row.targetLicense,
				date = row.time,
			})

			table.insert(pendingFriends[row.targetLicense], {
				dbID = tonumber(row.id),
				other = row.sourceLicense,
				date = row.time,
				accept = true,
			})
		end

		p:resolve()
	end, "SELECT * FROM pendingFriends")

	return p
end
CreateThread(function()
	loadPendingFriends()
end)

CreateThread(function()
	dbQuery(function(result)
		for _, row in pairs(result) do
			if row then
				Names[row.identifier] = row.firstname .. " " .. row.lastname
			end
		end
	end, "SELECT identifier, firstname, lastname FROM users")
end)

AddEventHandler("esx:playerLoaded", function(player)
	local xPlayer = ESX.GetPlayerFromId(player)
	if xPlayer then
		Names[xPlayer.identifier] = xPlayer.getName()

		loadPlayerFriends(player)
	end
end)

ESX.RegisterServerCallback("requestPlayerNames", function(source, cb)
	local result = {}

	for _, player in pairs(GetPlayers()) do
		local xPlayer = ESX.GetPlayerFromId(player)

		if xPlayer then
			result[tonumber(player)] = {
				name = xPlayer.getName(),
				license = xPlayer.identifier,
			}
		end
	end

	cb(result, getPlayerFriends(source))
end)

function checkPending(license, target)
	if pendingFriends[license] then
		for _, value in pairs(pendingFriends[license]) do
			if value.other == target then
				return true
			end
		end
	end
	return false
end

function checkFriend(one, two)
	if Friends[one] then
		for _, friend in pairs(Friends[one]) do
			if friend.other == two then
				return true
			end
		end
	end
	return false
end

ESX.RegisterServerCallback("newFriendRequest", function(player, cb, targetPlayer)
	local xPlayer = ESX.GetPlayerFromId(player)
	local xTarget = ESX.GetPlayerFromId(targetPlayer)

	if not xPlayer or not xTarget then
		cb(false, "Hiba történt")
		return
	end

	local sourceLicense = xPlayer.identifier
	local targetLicense = xTarget.identifier

	if checkPending(sourceLicense, targetLicense) or checkPending(targetLicense, sourceLicense) then
		cb(false, "Már jelöltétek egymást barátnak!")
		return
	end

	if checkFriend(sourceLicense, targetLicense) or checkFriend(targetLicense, sourceLicense) then
		cb(false, "Már barátok vagytok!")
		return
	end

	local result = dbQuery(
		"INSERT INTO pendingFriends SET sourceLicense = ?, targetLicense = ?, time = ?",
		sourceLicense,
		targetLicense,
		os.time()
	)

	if result and result.insertId then
		dbQuery(function(result)
			if result and result[1] then
				local row = result[1]
				if not pendingFriends[row.sourceLicense] then
					pendingFriends[row.sourceLicense] = {}
				end
				if not pendingFriends[row.targetLicense] then
					pendingFriends[row.targetLicense] = {}
				end

				table.insert(pendingFriends[row.sourceLicense], {
					dbID = tonumber(row.id),
					other = row.targetLicense,
					date = row.time,
				})

				table.insert(pendingFriends[row.targetLicense], {
					dbID = tonumber(row.id),
					other = row.sourceLicense,
					date = row.time,
					accept = true,
				})

				updateOtherPlayer(xTarget.identifier, xPlayer.getName() .. " barátnak jelölt.")

				cb(true, _, getPlayerPendings(player))
			end
		end, "SELECT * FROM pendingFriends WHERE id = ?", result.insertId)

		return
	end
	cb(false, "Adatbázis hiba.")
end)

function getPlayerPendings(player)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return {}
	end

	local license = xPlayer.identifier

	if pendingFriends[license] then
		for key, value in pairs(pendingFriends[license]) do
			pendingFriends[license][key].name = Names[value.other] or "Ismeretlen"
		end
		return pendingFriends[license]
	end
	return {}
end

function getPlayerFriends(player)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return {}
	end

	local license = xPlayer.identifier

	if Friends[license] then
		for key, value in pairs(Friends[license]) do
			Friends[license][key].name = Names[value.other] or "Ismeretlen"
		end
	end

	return Friends[license]
end

ESX.RegisterServerCallback("requestPanelDatas", function(player, cb)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		cb(false)
		return
	end

	cb(getPlayerPendings(player), getPlayerFriends(player))
end)

ESX.RegisterServerCallback("deleteFriend", function(player, cb, row, page)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return cb(false, {})
	end

	if page == "pendings" then
		local result = dbExec("DELETE FROM pendingFriends WHERE id = ?", row.dbID)
		Citizen.Await(loadPendingFriends())

		updateOtherPlayer(row.other, xPlayer.getName() .. " elutasította a barát jelölésed.")

		cb(result, getPlayerPendings(player))
	else
		local result = dbExec("DELETE FROM friends WHERE id = ?", row.dbID)

		local license = xPlayer.identifier

		if Friends[license] then
			for key, value in pairs(Friends[license]) do
				Friends[license][key].name = Names[value.other] or "Ismeretlen"

				if value.dbID == row.dbID then
					table.remove(Friends[license], key)
				end
			end
		end

		if Friends[row.other] then
			for key, value in pairs(Friends[row.other]) do
				Friends[row.other][key].name = Names[value.other] or "Ismeretlen"

				if value.dbID == row.dbID then
					table.remove(Friends[row.other], key)
				end
			end
		end

		updateOtherPlayer(row.other, xPlayer.getName() .. " törölt a barátai közül.")

		cb(result, Friends[license])
	end
end)

ESX.RegisterServerCallback("acceptFriendPending", function(player, cb, row)
	dbExec("DELETE FROM pendingFriends WHERE id = ?", { row.dbID })
	Citizen.Await(loadPendingFriends())

	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return cb(false, "Hiba történt!")
	end

	local result = dbQuery(
		"INSERT INTO friends SET license1 = ?, license2 = ?, time = ?",
		{ xPlayer.identifier, row.other, os.time() }
	)

	if result and result.insertId then
		local fresult = dbQuery("SELECT * FROM friends WHERE id = ?", result.insertId)

		loadFriend(fresult[1], function()
			updateOtherPlayer(row.other, xPlayer.getName() .. " elfogadta a barátnak jelölésed!")

			cb(true, _, getPlayerFriends(player), getPlayerPendings(player))
		end)
		return
	end

	cb(false, "Adatbázis hiba!")
end)

function loadFriend(row, cb)
	if not row then
		return
	end

	if not Friends[row.license1] then
		Friends[row.license1] = {}
	end

	if not Friends[row.license2] then
		Friends[row.license2] = {}
	end

	table.insert(Friends[row.license1], {
		dbID = row.id,
		other = row.license2,
		date = row.time,
	})

	table.insert(Friends[row.license2], {
		dbID = row.id,
		other = row.license1,
		date = row.time,
	})

	if type(cb) == "function" then
		cb()
	end
end

function loadAllFriends()
	Friends = {}

	dbQuery(function(result)
		for _, row in pairs(result) do
			loadFriend(row)
		end
	end, "SELECT * FROM friends")
end
CreateThread(loadAllFriends)

function loadPlayerFriends(player)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return {}
	end

	Friends[xPlayer.identifier] = {}

	dbQuery(
		function(result)
			for _, row in pairs(result) do
				table.insert(Friends[xPlayer.identifier], {
					dbID = row.id,
					other = row.license1 == xPlayer.identifier and row.license2 or row.license1,
					date = row.time,
				})
			end
		end,
		"SELECT * FROM friends WHERE license1 = ? OR license2 = ?",
		{
			xPlayer.identifier,
			xPlayer.identifier,
		}
	)
end

--[[
function findPlayerByLicense(license)
	for _, player in pairs(GetPlayers()) do
		local xPlayer = ESX.GetPlayerFromId(player)

		if xPlayer and xPlayer.identifier == license then
			return xPlayer.source
		end
	end

	return false
end
]]

function updateOtherPlayer(license, msg)
	-- local targetPlayer = findPlayerByLicense(license)
	local targetPlayer = ESX.GetPlayerFromIdentifier(license)
	if targetPlayer then
		TriggerClientEvent(
			GetCurrentResourceName() .. "->updateDatas",
			targetPlayer,
			getPlayerPendings(targetPlayer),
			getPlayerFriends(targetPlayer)
		)

		notify(msg, "info", targetPlayer)
	end
end
