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
            trafficDensity = 0.10 -- Rush hour traffic is higher
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
    local players = GetActivePlayers()
    for _, player in pairs(players) do
        local playerPed = GetPlayerPed(player)
        local playerPos = GetEntityCoords(playerPed)
        
        -- Check if the player is driving a vehicle (so we don't apply speed limits on foot)
        if IsPedInAnyVehicle(playerPed, false) then
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            local nearbyCars = GetNearbyVehicles(playerPos, 100.0)
            for _, car in ipairs(nearbyCars) do
                -- Don't apply speed limit to the player's own vehicle
                if car ~= playerVehicle then
                    if density > 0.7 then
                        SetEntityMaxSpeed(car, 10.0)  -- Limit the max speed of AI vehicles to 10 km/h in heavy traffic
                    else
                        SetEntityMaxSpeed(car, 35.0)  -- Normal speed for AI vehicles during non-rush hours
                    end
                end
            end
        end
    end
end

function ModifyVehicleHandlingForRain(enable)
    -- Modifies handling for wet roads
    local handlingType = enable and 0.5 or 1.0
    SetVehicleHandlingField("wet_braking", handlingType) -- Adjust wet braking for rain
    SetVehicleHandlingField("traction_loss", handlingType) -- Adjust traction for rain
end

function ModifyVehicleHandlingForSnow(enable)
    -- Modifies handling for snow
    local handlingType = enable and 0.7 or 1.0
    SetVehicleHandlingField("traction_loss", handlingType) -- Adjust traction for snow
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
