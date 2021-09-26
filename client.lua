-- Localizing functions
local _ipairs = ipairs
local _PlayerId = PlayerId
local _PlayerPedId = PlayerPedId
local _tableunpack = table.unpack
local _GetEntityCoords = GetEntityCoords
local _Vdist = Vdist
local _IsControlPressed = IsControlJustPressed
local _GetSelectedPedWeapon = GetSelectedPedWeapon
local publiccopModel = GetHashKey( "s_m_y_sheriff_01" )
local player_ped
local x, y, z


-- Config variables for markers
local is_bobbing = false
local p19 = 2                           -- No clue what p19 does, ask CitizenFX why their documentation is bad. All it says is that it should be set to 2 most of the time
local is_facing_camera = false
local available_rgb = {r = 100, g = 255, b = 100}
local active_blue_rgb = {r = 100, g = 100, b = 255}
local active_red_rgb = {r = 255, g = 50, b = 50}
local cooldown_rgb = {r = 255, g = 200, b = 50}
local unavailable_rgb = {r = 255, g = 50, b = 50}
local current_color = available_rgb
local is_rotated = false
local marker_type = 29                  -- Sets the marker based on the list here: https://docs.fivem.net/docs/game-references/markers/
local draw_on_ents = false
local texture_dict = nil
local texture_name = nil
local z_offset = 0                      -- Offset to put marker on the floor, the Z coordinate in vMenu seems to start at the belt line.
local closest_marker = 1
local render_range = 20.0
local interaction_range = 1.5
local keybind = 38                      -- Currently set to E
local fists_hash = -1569615261
local blip_sprite = 108                 -- Set to dollar sign ($)
local blip_color = 2                    -- Set to Green (#71cb71)


-- Draws all robbery locations with blips
function draw_bank_blips()
    for i, v in _ipairs(coordinates) do
        blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, blip_sprite)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, blip_color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v.name)
        EndTextCommandSetBlipName(blip)
    end
end

-- Syncs client of banks on connection
TriggerServerEvent("predator_silent_alarm:sync_client")
RegisterNetEvent("predator_silent_alarm:sync_robbery")
AddEventHandler("predator_silent_alarm:sync_robbery", function(active, availabilty, location, cooldown, peacetime, onhold, inprogress)
    robbery_is_active = active
    robbery_is_available = availabilty
    robbery_location = location
    robbery_is_in_cooldown = cooldown
    is_peacetime_on = peacetime
    priority_onhold = onhold
    priority_inprogress = inprogress

    -- Draw all locations where a robbery can take place
    draw_bank_blips()
end)


-- Prints the help text in the top left
function help_text(msg)
    SetTextComponentFormat("STRING")
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end


-- Syncing all bank states
RegisterNetEvent("predator_silent_alarm:send_robbery_data")
AddEventHandler("predator_silent_alarm:send_robbery_data", function(active, availabilty, location, cooldown, onhold, inprogress)
    robbery_is_active, is_bobbing = active, active
    robbery_is_available = availabilty
    robbery_location = location
    robbery_is_in_cooldown = cooldown
    priority_onhold = onhold
    priority_inprogress = inprogress
end)


-- When priority is on hold or peacetime is on it will make all robberies unavailable
RegisterNetEvent("predator_silent_alarm:set_robbery_availability")
AddEventHandler("predator_silent_alarm:set_robbery_availability", function(available)
    priority_onhold = available
    if priority_onhold or is_peacetime_on then
        robbery_is_active = false
        robbery_is_available = false
    else
        robbery_is_active = false
        robbery_is_available = true
    end
end)


-- Does the peacetime check
RegisterNetEvent("predator_silent_alarm:set_robbery_availability_pt")
AddEventHandler("predator_silent_alarm:set_robbery_availability_pt", function(peacetime) 
    is_peacetime_on = peacetime
    if priority_onhold or is_peacetime_on then
        robbery_is_active = false
        robbery_is_available = false
    else
        robbery_is_active = false
        robbery_is_available = true
    end
end)


-- Sets priority in progress whenever it is activated
RegisterNetEvent("predator_silent_alarm:set_priority_inprogress_client")
AddEventHandler("predator_silent_alarm:set_priority_inprogress_client", function(inprogress, cooldown)
    priority_inprogress = inprogress
    robbery_is_in_cooldown = cooldown
end)


-- Handles the message sent to the cops if there is an active robbery
RegisterNetEvent("predator_silent_alarm:send_to_cops")
AddEventHandler("predator_silent_alarm:send_to_cops", function() 
    TriggerServerEvent("predator_silent_alarm:send_alarm_message", IsPedModel(_PlayerPedId(), publiccopModel))
end)

-- Thread that gets the closest marker
Citizen.CreateThread(function()
    while true do
        player_ped = _PlayerPedId()
        x, y, z = _tableunpack(_GetEntityCoords(player_ped, true))
        for i, v in _ipairs(coordinates) do
            local dist = _Vdist(v.x, v.y, v.z, x, y, z)
            if dist <= render_range then
                closest_marker = i
                break
            end
        end
        Citizen.Wait(500)
    end
end)


-- If robbery is active, marker will flash red and blue
Citizen.CreateThread(function()
    local index = 1
    while true do
        if closest_marker == robbery_location then
            if robbery_is_active then
                if index == 1 then
                    current_color = active_blue_rgb
                    index = 2
                else
                    current_color = active_red_rgb
                    index = 1
                end
            end
        end
        Citizen.Wait(400)
    end
end)


-- The marker will be drawn here
Citizen.CreateThread(function()
    local rotation_angle = 0.0
    while true do
        if rotation_angle >= 360.0 then
            rotation_angle = 0.0
        end
        DrawMarker(marker_type,
        coordinates[closest_marker].x, coordinates[closest_marker].y, coordinates[closest_marker].z - z_offset,             -- Position in x,y,z
        0.0, 0.0, 0.0,                                                                                                      -- Direction in x,y,z
        0.0, 0.0, rotation_angle,                                                                                           -- Rotation in x,y,z
        1.0, 1.0, 1.0,                                                                                                      -- Scale in x,y,z
        current_color.r, current_color.g, current_color.b, 125,                                                             -- RGBA values
        is_bobbing, is_facing_camera, p19, is_rotated, texture_dict, texture_name, draw_on_ents)

        local dist = _Vdist(coordinates[closest_marker].x, coordinates[closest_marker].y, coordinates[closest_marker].z, x, y, z)

        if dist < render_range and (priority_onhold or is_peacetime_on) then              --- When priority is on hold it will make robberies unavailable
            if dist < interaction_range then help_text("Robberies are currently unavailable.") end
            current_color = unavailable_rgb
            is_bobbing = false

        elseif dist < render_range and robbery_is_in_cooldown then
            if dist < interaction_range then help_text("Robberies are currently on cool down, come back later.") end        -- Cooldown check
            current_color = cooldown_rgb
            is_bobbing = false
    
        elseif dist < render_range and robbery_is_active and not robbery_is_available and closest_marker ~= robbery_location then                   -- This block makes it
            if dist < interaction_range then help_text("There is currently a robbery at a different location, please come back later.") end         -- so that robberies
            current_color = unavailable_rgb                                                                                                         -- are unavailable
            is_bobbing = false                                                                                                                      -- when one is active

        elseif dist < render_range and not robbery_is_active and priority_inprogress then
            if dist < interaction_range then help_text("There is currently another priority in progress.") end
            current_color = unavailable_rgb
            is_bobbing = false

        elseif dist < render_range and not robbery_is_active and robbery_is_available then
            current_color = available_rgb
            if dist < interaction_range and _GetSelectedPedWeapon(player_ped) ~= fists_hash then
                help_text("Press E to start the robbery!")
                if _IsControlPressed(0, keybind) then
                    TriggerServerEvent("predator_silent_alarm:send_bank_data", true, false, closest_marker)
                end
            elseif dist < interaction_range and _GetSelectedPedWeapon(player_ped) == fists_hash then
                help_text("Equip a weapon to be able to start the robbery.")
            end
        end

        if dist < render_range and robbery_is_active and closest_marker == robbery_location then       -- For those who enter the area where a robbery is
            is_bobbing = true                                                                          -- currently taking place
        elseif dist < render_range and robbery_is_active and closest_marker ~= robbery_location then
            if dist < interaction_range then help_text("There is currently a robbery at a different location, please come back later.") end     -- For some reason there is
            is_bobbing = false                                                                                                                  -- a bug where it doesn't
            current_color = unavailable_rgb                                                                                                     -- load the state correctly
        end                                                                                                                                     -- when the user connects.
        rotation_angle = rotation_angle + 1.0                                                                                                   -- This should fix it.
        Citizen.Wait(5)
    end
end)