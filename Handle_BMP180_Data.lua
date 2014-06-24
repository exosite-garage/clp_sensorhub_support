-- Title: "Handle Sensor Hub BMP180 Data" 
-- Type: Lua Exosite Platform script
-- Description:
-- This script will take data from Connected LaunchPad reported for the 
-- Sensor Hub Boosterpack's BMP180 sensor and put it into individual dataports
-- The data is reported in a json formatted string originally.
-- 
-- The BMP180 is a Bosch Sensortec digital barometric pressure sensor
--  
-- Tiva C Series Demo App: 'senshub_iot'
-- Example format of BMP180 data reported by the Connected LaunchPad Tiva C Series demo 
-- {"sBMP180Data_t":{"bActive":1,"fPressure":97902.703,"fTemperature":27.979,"fAltitude":288.898}}
--
-- To Use: 
-- 1) Add your Connected LaunchPad per quick-start instructions
-- 2) Build the 'senshub_iot' demo for Tiva C Series and program your Connected LaunchPad
-- 3) Add this script to your LaunchPad client in Exosite (https://ti.exosite.com/manage/scripts)
-- 4) Build a custom dashboard to view the new data (https://ti.exosite.com/manage/dashboards)



debug('starting')

-- Table of dataports needed for BMP180 data
local dstable = {
  {alias="bmp180_json",name="BMP180 JSON Data",format="string",unit=nil,count=50}, -- incoming data from CLP
  {alias="bmp180_press",name="BMP180 Pressure",format="float",unit="Pa"},
  {alias="bmp180_alt",name="BMP180 Altitude",format="float",unit="m"}
}

local function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

-- Check if dataports exist, if not create them
for i, ds in ipairs(dstable) do
  if not manage.lookup("aliased" ,ds.alias) then
    local description = {
      format = ds.format
     ,name = ds.name
     ,retention = {count = ds.count or "infinity" ,duration = "infinity"}
     ,visibility = "private"
    }
    local success ,rid = manage.create("dataport" ,description)
    if not success then
      debug("error initializing dataport: ".. rid or "")
      return
    else
      debug("creating dataport: "..ds.alias)
    end
    
    manage.map("alias" ,rid ,ds.alias)
  end
end

local bmp180_press = alias['bmp180_press']
local bmp180_json = alias['bmp180_json']
local bmp180_alt = alias['bmp180_alt']

debug('running handler')

while true do
  local ts1 = bmp180_json.wait()
  if ts1 ~= nil then
    local jsonobj = json.decode(bmp180_json[ts1])
    if jsonobj ~= nil then
      if jsonobj.sBMP180Data_t then
        -- Take JSON values and put into individual data ports
        
        -- Pressure
        if jsonobj.sBMP180Data_t.fPressure then
          bmp180_press.value = round(jsonobj.sBMP180Data_t.fPressure,2) 
        end

        -- Altitude
        if jsonobj.sBMP180Data_t.fAltitude then
          bmp180_alt.value = round(jsonobj.sBMP180Data_t.fAltitude,2) 
        end
      end
    end
  end
  -- make sure we don't get behind if data reporting is faster than can be decoded and stored
  -- Note that some data 'could' be passed by by doing this
  bmp180_json.last = now
end