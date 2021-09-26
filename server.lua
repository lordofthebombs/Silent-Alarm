random_cooldown = 0
cooldown_timer = 0

-- Registering event that sends the current bank robbery's locations
RegisterNetEvent("predator_silent_alarm:send_bank_data")
AddEventHandler("predator_silent_alarm:send_bank_data", function(active, availabilty, location, cooldown)
    -- Checks to see if the player is actually a certified civilian
    if not IsPlayerAceAllowed(source, "predatorRank:CertifiedCivilian") then
        TriggerClientEvent( "chat:addMessage", source, {
            color = { 100, 255, 100 },
            multiline = true,
            args = { "^*Bank Guard^r", "You can only trigger this event if you are a ^2^*Certified Civilian^r^7! Apply on the forums: ^1^*https://predatornetwork.com/forums/" }
        } )
        return
    end

    robbery_is_active = active
    robbery_is_available = availabilty
    robbery_location = location
    robbery_is_in_cooldown = cooldown
    TriggerClientEvent("predator_silent_alarm:send_robbery_data", -1, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown)
    TriggerClientEvent("predator_silent_alarm:send_to_cops", -1)
end)


-- Syncs clients to robbery states
RegisterNetEvent("predator_silent_alarm:sync_client")
AddEventHandler("predator_silent_alarm:sync_client", function()
    TriggerClientEvent("predator_silent_alarm:sync_robbery", source, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown, is_peacetime_on, priority_onhold, priority_inprogress)
end)

-- Sets the state for all bank robberies, mostly used for when priorities are changed
RegisterNetEvent("predator_silent_alarm:sync_server")
AddEventHandler("predator_silent_alarm:sync_server", function(active, available)
    robbery_is_active = active
    robbery_is_available = available
    TriggerClientEvent("predator_silent_alarm:send_robbery_data", -1, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown, is_peacetime_on, priority_onhold, priority_inprogress)
end)

-- Sets banks on a cooldown if priority is on cooldown
AddEventHandler("predator_silent_alarm:cooldown_robbery", function(cooldown)
    cooldown_timer = cooldown
    priority_onhold = false
    priority_inprogress = false
    robbery_is_active = false
    robbery_is_available = false
    robbery_is_in_cooldown = true
    while cooldown_timer > 0 do
        cooldown_timer = cooldown_timer - 1
        TriggerClientEvent("predator_silent_alarm:send_robbery_data", -1, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown, priority_onhold, priority_inprogress)
        Citizen.Wait(60000)
    end
    robbery_is_in_cooldown = false
    robbery_is_available = true
    TriggerClientEvent("predator_silent_alarm:send_robbery_data", -1, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown, priority_onhold, priority_inprogress)
    
end)


-- Cancels robbery cooldown when priority cooldown occurs
RegisterNetEvent("predator_silent_alarm:cancel_robbery_cooldown")
AddEventHandler("predator_silent_alarm:cancel_robbery_cooldown", function()
    if not IsPlayerAceAllowed(source, "cooldown") then return end
    
    while cooldown_timer > 0 do
        cooldown_timer = cooldown_timer - 1
        Citizen.Wait(100)
        if cooldown_timer == 0 then
            robbery_is_in_cooldown = false
            robbery_is_available = true
            TriggerClientEvent("predator_silent_alarm:send_robbery_data", -1, robbery_is_active, robbery_is_available, robbery_location, robbery_is_in_cooldown, priority_onhold, priority_inprogress)
        end
    end
end)


-- Checks if peacetime was enabled
AddEventHandler("predator_silent_alarm:set_peacetime_event", function(flag)
    is_peacetime_on = flag
    TriggerClientEvent("predator_silent_alarm:set_robbery_availability_pt", -1, is_peacetime_on)
end)


-- Checks to see if priorities are set on hold
AddEventHandler("predator_silent_alarm:set_priority_onhold_event", function(flag) 
    priority_onhold = flag
    TriggerClientEvent("predator_silent_alarm:set_robbery_availability", -1, priority_onhold)
end)


-- Sets priority to be in progress
AddEventHandler("predator_silent_alarm:set_priority_inprogress_server", function()
    priority_inprogress = true
    robbery_is_in_cooldown = false
    TriggerClientEvent("predator_silent_alarm:set_priority_inprogress_client", -1, priority_inprogress, robbery_is_in_cooldown)
end)


-- Sends special message to law enforcement
RegisterNetEvent("predator_silent_alarm:send_alarm_message")
AddEventHandler("predator_silent_alarm:send_alarm_message", function(public_cop)
    if IsPlayerAceAllowed(source, "sem_intmenu.leo") or IsPlayerAceAllowed(source, "sem_intmenu.fire") or public_cop then
        TriggerClientEvent("chat:addMessage", source, {
            color = { 100, 255, 100 },
            multiline = true,
            args = {"^*" .. coordinates[robbery_location].name .. "^r", "Silent alarm ^1^*triggered^r! Send law enforcement here immediately! ^4(Postal: ^r" .. coordinates[robbery_location].postal .. "^4)^r"}
        })
    end
end)