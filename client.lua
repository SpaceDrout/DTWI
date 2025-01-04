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

        -- Apply weather-related driving effects
        if isRaining then
            -- Modify car handling for wet roads
            ModifyVehicleHandlingForRain(true)
        elseif isSnowing then
            -- Modify car handling for snow
            ModifyVehicleHandlingForSnow(true)
        elseif isFoggy then
            -- Reduce visibility effects (you can add fog behavior here)
            SetVehicleHandlingField("visibility", 0.5)
        else
            -- Reset normal conditions
            ModifyVehicleHandlingForRain(false)
            ModifyVehicleHandlingForSnow(false)
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
                local carSpeed = GetEntitySpeed(car)
                if carSpeed > 5.0 then  -- If the car is moving too fast, reduce its speed to simulate traffic
                    SetEntityMaxSpeed(car, 10.0)  -- Limit the max speed of the cars to 10 km/h
                end
            end
        end
    else
        -- Reset vehicles to normal speeds during non-rush hour
        local players = GetActivePlayers()  -- Corrected function to get active players
        for _, player in pairs(players) do
            local playerPed = GetPlayerPed(player)
            local playerPos = GetEntityCoords(playerPed)
            
            local nearbyCars = GetNearbyVehicles(playerPos, 100.0)
            for _, car in ipairs(nearbyCars) do
                SetEntityMaxSpeed(car, 35.0)  -- Normal speed when traffic density is low
            end
        end
    end
end

function ModifyVehicleHandlingForRain(enable)
    -- Modifies handling for wet roads using SetVehicleHandlingField
    local handlingType = enable and 0.6 or 1.0
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle then
        -- Adjust traction for wet roads (wet braking and traction loss)
        SetVehicleHandlingField(vehicle, "fWetBrakes", handlingType)  -- Wet brake handling
        SetVehicleHandlingField(vehicle, "fTractionLoss", handlingType)  -- Traction loss
    end
end

function ModifyVehicleHandlingForSnow(enable)
    -- Modifies handling for snow using SetVehicleHandlingField
    local handlingType = enable and 0.7 or 1.0
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle then
        -- Adjust traction for snow (higher traction loss in snow)
        SetVehicleHandlingField(vehicle, "fTractionLoss", handlingType)  -- Traction loss
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
