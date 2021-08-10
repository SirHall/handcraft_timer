player_time_text = player_time_text or nil

-- Because of my supreme laziness this is a modified version of: https://stackoverflow.com/a/45376848
function FormatTime(time)
    local days = math.floor(time/86400)
    local hours = math.floor(math.fmod(time, 86400)/3600)
    local minutes = math.floor(math.fmod(time,3600)/60)
    local seconds = math.floor(math.fmod(time,60))

    local printDays = days > 0
    local printHours = hours > 0 or printDays
    local printMinutes = minutes > 0 or printHours

    return "" .. (printDays and (days .. " ") or "") .. (printHours and (hours .. ":") or "") .. (printMinutes and (minutes .. ":") or "") .. seconds .. "s"
end

function GetCraftTime(player)
    local queue = player.crafting_queue

    if not queue then
        return 0.0
    end

    local craftTime = 0.0
    
    for i, qItem in ipairs(queue) do
        local recipe = game.recipe_prototypes[qItem.recipe]
        local qItemCraftTime = recipe.energy * qItem.count / (1.0 + player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier)
        craftTime = craftTime + qItemCraftTime

        -- Reduce the crafting time using the progress on the current item being crafted
        if i == 1 then
            craftTime = craftTime - ((recipe.energy / (1.0 + player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier)) * player.crafting_queue_progress)
        end
        
    end

    return craftTime;
end

function SetupText()
    if player_time_text ~= nil then
        return
    end
    
    local player = game.get_player(1)
    local col = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    player_time_text = rendering.draw_text({text = "", surface = "nauvis", target = player.character, color = col})
end

function PrintCraftTime()

    if player_time_text == nil then
        SetupText()
    end
    
    -- Go back to using the for loop to make this multiplayer compatible
    -- for i, player in ipairs(game.players) do
    local player = game.get_player(1)
    if (not player) or (not player.character) then
        rendering.set_visible(player_time_text, false)
        return
    end

    local time = GetCraftTime(player)

    -- Only update visibility if it has changed
    if (time > 0.1) ~= rendering.get_visible(player_time_text) then
        rendering.set_visible(player_time_text, time > 0.1)
    end

    -- rendering.set_text(player_time_text, "" .. string.format("%.1f", time) .. "s")
    rendering.set_text(player_time_text, FormatTime(time))
    -- end

    -- game.players[1].print("Time: " .. GetCraftTime(e.player_index) .. "s")
end

script.on_event(defines.events.on_tick, PrintCraftTime)
-- script.on_event(defines.events.on_pre_player_crafted_item, PrintCraftTime)
-- script.on_event(defines.events.on_player_crafted_item, PrintCraftTime)
-- script.on_event(defines.events.on_player_cancelled_crafting, PrintCraftTime)