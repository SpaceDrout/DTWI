-- Config for road types and base speed limits
local roadConfig = {
    highway = 65,  -- Base speed limit for highways (65 mph)
    city = 40,     -- Base speed limit for city streets (40 mph)
    rural = 50,    -- Base speed limit for rural roads (50 mph)
    default = 45   -- Default speed limit if no road type is found (45 mph)
}

local isRaining = false
local isSnowing = false
local isFoggy = false
local trafficDensity = 0.5  -- 0.0 to 1.0 (0 being low, 1 being high)
local timeOfDay = GetClockHours()

-- Define different weather conditions and their effects
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        -- Check the current weather using the correct function
        local weather = GetWeatherTypeTransition()

        -- Adjust traffic density based on time of day (rush hour)
        timeOfDay = GetClockHours()
        
        if timeOfDay >= 7 and timeOfDay <= 9 or timeOfDay >= 16 and timeOfDay <= 18 then
            trafficDensity = 0.8 -- Rush hour traffic is higher
        else
            trafficDensity = 0.5 -- Regular traffic density
        end
        
        -- Adjust traffic density based on weather
        if weather == 'RAIN' then
            isRaining = true
            trafficDensity = trafficDensity + 0.3 -- More cars on the road in the rain
        elseif weather == 'SNOW' then
            isSnowing = true
            trafficDensity = trafficDensity - 0.2 -- Snow causes some cars to stay home
        elseif weather == 'FOG' then
            isFoggy = true
            trafficDensity = trafficDensity - 0.1 -- Fewer cars in foggy conditions
        else
            isRaining = false
            isSnowing = false
            isFoggy = false
        end

        -- Apply weather-related driving effects only to NPCs
        if isRaining then
            -- Modify NPC handling for wet roads
            ModifyNPCVehicleHandlingForRain(true)
        elseif isSnowing then
            -- Modify NPC handling for snow
            ModifyNPCVehicleHandlingForSnow(true)
        elseif isFoggy then
            -- Reduce visibility effects (you can add fog behavior here)
            SetVehicleHandlingField("visibility", 0.5)
        else
            -- Reset normal conditions
            ModifyNPCVehicleHandlingForRain(false)
            ModifyNPCVehicleHandlingForSnow(false)
        end

        -- Adjust traffic spawn rate and behavior based on density
        AdjustTraffic(trafficDensity)
    end
end)

function AdjustTraffic(density)
    -- Traffic jam simulation during rush hours
    if density > 0.7 then
        -- Increase vehicle spawning in dense areas to simulate a traffic jam
        local players = GetActivePlayers()  -- Corrected function to get active players
        for _, player in pairs(players) do
            local playerPed = GetPlayerPed(player)
            local playerPos = GetEntityCoords(playerPed)
            
            -- You can adjust the range to where traffic should be more dense
            local nearbyCars = GetNearbyVehicles(playerPos, 100.0)
            for _, car in ipairs(nearbyCars) do
                -- Apply weather effects only to NPCs, not the player's vehicle
                if car ~= GetVehiclePedIsIn(PlayerPedId(), false) then  -- Skip player's vehicle
                    -- Adjust NPC speed based on road type and weather conditions
                    AdjustNPCSpeed(car, playerPos)
                end
            end
        end
    else
        -- Reset NPC vehicles to normal speeds during non-rush hour
        local players = GetActivePlayers()  -- Corrected function to get active players
        for _, player in pairs(players) do
            local playerPed = GetPlayerPed(player)
            local playerPos = GetEntityCoords(playerPed)
            
            local nearbyCars = GetNearbyVehicles(playerPos, 100.0)
            for _, car in ipairs(nearbyCars) do
                -- NPC speed is now normal again
                if car ~= GetVehiclePedIsIn(PlayerPedId(), false) then
                    SetEntityMaxSpeed(car, 45.0)  -- Set NPC speed to 45 mph
                    -- NPCs move normally in better conditions
                    AdjustNPCSpeed(car, playerPos)
                end
            end
        end
    end
end

function AdjustNPCSpeed(car, playerPos)
    -- Adjust the NPC vehicle driving behavior based on the weather or traffic conditions
    local currentSpeed = GetEntitySpeed(car)
    
    -- Get road type based on the player’s current location
    local roadType = GetRoadType(playerPos)
    local baseSpeed = roadConfig[roadType] or roadConfig.default  -- Default speed if road type not found

    -- Apply speed reduction based on weather conditions
    local targetSpeed = baseSpeed
    if isRaining then
        targetSpeed = targetSpeed - math.random(10, 15)  -- Reduce by 10-15 mph in rain
    elseif isSnowing then
        targetSpeed = targetSpeed - math.random(15, 20)  -- Reduce by 15-20 mph in snow
    end

    -- Limit the NPC speed to the target speed
    if currentSpeed > targetSpeed then
        SetEntityMaxSpeed(car, targetSpeed)  -- Apply the target max speed
    end
end

function GetRoadType(position)
    -- Logic to determine the road type based on player position (simplified)
    -- In a real case, you might want to use predefined areas or road zones to determine this

    -- Placeholder logic: assuming highways are in the upper part of the map, and city streets are everywhere else
    if position.x > 2000 then
        return "highway"  -- If player is on a highway area
    elseif position.x > 1000 then
        return "city"  -- If player is on city streets
    else
        return "rural"  -- Default to rural roads
    end
end

function ModifyNPCVehicleHandlingForRain(enable)
    -- Modifies handling for wet roads using SetVehicleHandlingField (only for NPC vehicles)
    local handlingType = enable and 0.6 or 1.0
    local vehicles = GetNearbyVehicles(GetEntityCoords(PlayerPedId()), 100.0) -- Get all nearby vehicles
    for _, vehicle in ipairs(vehicles) do
        -- Skip player's own vehicle
        if vehicle == GetVehiclePedIsIn(PlayerPedId(), false) then
            goto continue
        end
        
        -- Adjust traction for wet roads (wet braking and traction loss)
        SetVehicleHandlingField(vehicle, "fWetBrakes", handlingType)  -- Wet brake handling
        SetVehicleHandlingField(vehicle, "fTractionLoss", handlingType)  -- Traction loss
        ::continue::
    end
end

function ModifyNPCVehicleHandlingForSnow(enable)
    -- Modifies handling for snow using SetVehicleHandlingField (only for NPC vehicles)
    local handlingType = enable and 0.7 or 1.0
    local vehicles = GetNearbyVehicles(GetEntityCoords(PlayerPedId()), 100.0) -- Get all nearby vehicles
    for _, vehicle in ipairs(vehicles) do
        -- Skip player's own vehicle
        if vehicle == GetVehiclePedIsIn(PlayerPedId(), false) then
            goto continue
        end
        
        -- Adjust traction for snow (higher traction loss in snow)
        SetVehicleHandlingField(vehicle, "fTractionLoss", handlingType)  -- Traction loss
        ::continue::
    end
end

function GetNearbyVehicles(position, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success

    repeat
        local carPos = GetEntityCoords(vehicle)
        if Vdist(position.x, position.y, position.z, carPos.x, carPos.y, carPos.z) < radius then
            table.insert(vehicles, vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return vehicles
end
