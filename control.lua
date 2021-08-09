player_time_text = 0
first_tick = true

function GetCraftTime(player)
    local queue = player.crafting_queue

    if not queue then
        return 0.0
    end

    local craftTime = 0.0
    
    for i, qItem in ipairs(queue) do
        local recipe = game.recipe_prototypes[qItem.recipe]
        local qItemCraftTime = recipe.energy * qItem.count / (1.0 + player.force.manual_crafting_speed_modifier)
        craftTime = craftTime + qItemCraftTime

        -- Reduce the crafting time using the progress on the current item being crafted
        if i == 1 then
            craftTime = craftTime - ((recipe.energy / (1.0 + player.force.manual_crafting_speed_modifier)) * player.crafting_queue_progress)
        end
        
    end

    return craftTime;
end

function SetupText()
    local player = game.get_player(1)
    local col = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    player_time_text = rendering.draw_text({text = "", surface = "nauvis", target = player.character, color = col})
end

function PrintCraftTime()

    if first_tick then
        first_tick = false
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

    rendering.set_text(player_time_text, "" .. string.format("%.1f", time) .. "s")
    -- end

    -- game.players[1].print("Time: " .. GetCraftTime(e.player_index) .. "s")
end

script.on_event(defines.events.on_tick, PrintCraftTime)
-- script.on_event(defines.events.on_pre_player_crafted_item, PrintCraftTime)
-- script.on_event(defines.events.on_player_crafted_item, PrintCraftTime)
-- script.on_event(defines.events.on_player_cancelled_crafting, PrintCraftTime)