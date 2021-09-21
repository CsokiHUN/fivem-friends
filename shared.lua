STREAM_DISTANCE = 40 --Ilyen távolságból látszanak a nevek.
TALKING_COLOR = { r = 255, g = 0, b = 0 }

function notify(message, type, target)
	if LocalPlayer then
		TriggerEvent("dopeNotify2:Alert", "Barát rendszer", message, 4000, "info")
	else
		TriggerClientEvent("dopeNotify2:Alert", target, "Barát rendszer", message, 4000, type or "info")
	end
end

--Dont touch this
function DrawText3D(coords, text, scale, r, g, b, alpha)
	scale = scale or 1

	r = r or 255
	g = g or 255
	b = b or 255

	SetDrawOrigin(coords)

	SetTextScale(0.3 * scale, 0.3 * scale)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextColour(r, g, b, math.floor(alpha))
	SetTextOutline()
	SetTextCentre(1)
	BeginTextCommandDisplayText("STRING")
	AddTextComponentString(text)
	EndTextCommandDisplayText(0, 0)
end

function split(inputstr, sep)
	sep = sep or "%s"
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end
