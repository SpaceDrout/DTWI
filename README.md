# Dynamic Traffic and Weather Impact for FiveM

## Overview

The **Dynamic Traffic and Weather Impact** script enhances the driving experience in FiveM by dynamically adjusting traffic density, vehicle behavior, and road conditions based on weather and time of day. This creates a more immersive and realistic environment where players must adapt to changing road conditions like rain, snow, and fog, and experience traffic jams during rush hour.

## Features

- **Dynamic Traffic Density**:
  - Traffic density increases during rush hours (7-9 AM and 4-6 PM).
  - Traffic density changes based on weather conditions (more cars during rain or snow, fewer cars during fog).
  
- **Weather Impact on Vehicles**:
  - **Rain**: Vehicles experience reduced traction and longer braking distances.
  - **Snow**: Vehicles slip more, and low-traction cars struggle to move.
  - **Fog**: Visibility is reduced, requiring slower driving.

- **Traffic Jam Simulation**:
  - During rush hours or in bad weather, traffic moves slower and vehicles pile up, simulating traffic jams.

## Installation

1. **Download the Script**:
   - Place the **dynamic_traffic_weather** folder in your **resources** folder in your FiveM server.

2. **Add the Resource to Your Server**:
   - Open your `server.cfg` file.
   - Add the following line to ensure the script is loaded:
     ```
     ensure dynamic_traffic_weather
     ```

3. **Start Your Server**:
   - Start the server as usual, and the script will automatically run.

## Configuration

The script automatically adjusts traffic and vehicle behavior based on time of day and weather. If you want to modify specific settings (e.g., traffic density, weather effects), you can do so by editing the **client.lua** file.

## Requirements

- **FiveM** server with Lua support.

## License

This script is free to use and modify. Please credit the author if you use it in public servers.

## Credits

- Developed by: [SpaceDrout]
- Inspired by real-life traffic and weather conditions.
