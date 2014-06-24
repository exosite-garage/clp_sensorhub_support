-- Title: "Handle SHT21 Data" 
-- Type: Lua Exosite Platform script
-- Description:
-- This script will take data from Connected LaunchPad reported for the 
-- Sensor Hub Boosterpack's SHT21 sensor and put it into individual dataports
-- The data is reported in a json formatted string originally.
-- 
-- Tiva C Series Demo App: 'senshub_iot'
-- Example format of SHT21 data reported by the Connected LaunchPad Tiva C Series demo 
-- {"sSHT21Data_t":{"bActive":1,"fTemperature":27.925,"fHumidity":0.317}}
--
-- To Use: 
-- 1) Add your Connected LaunchPad per quick-start instructions
-- 2) Build the 'senshub_iot' demo for Tiva C Series and program to your Connected LaunchPad
-- 3) Add this script to your LaunchPad client in Exosite (https://ti.exosite.com/manage/scripts)
-- 4) Build a custom dashboard to view the new data (https://ti.exosite.com/manage/dashboards)



debug('starting')

-- Table of dataports needed for SHT21 data
local dstable = {
  {alias="sht21_json",name="SHT21 JSON Data",format="string",unit=nil,count=50}, -- incoming data from CLP
  {alias="sht21_tempc",name="SHT21 Temperature C",format="float",unit="C"},
  {alias="sht21_tempf",name="SHT21 Temperature F",format="float",unit="F"},
  {alias="sht21_humid",name="SHT21 Humidity",format="float",unit="%RH"}
}

local function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end


local function fahrenheit (tempC)
  return (tempC * 9.0/5) + 32
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

local sht21_json = alias['sht21_json']
local sht21_tempc = alias['sht21_tempc']
local sht21_tempf = alias['sht21_tempf']
local sht21_humid = alias['sht21_humid']



debug('running handler')

while true do
  local ts1 = sht21_json.wait()
  if ts1 ~= nil then
    local jsonobj = json.decode(sht21_json[ts1])
    if jsonobj ~= nil then
      if jsonobj.sSHT21Data_t then
        -- Take JSON values and put into individual data ports
        
        -- Temp
        if jsonobj.sSHT21Data_t.fTemperature then
          -- sht21_tempc.value = round(jsonobj.sSHT21Data_t.fTemperature,2)  -- uncomment if you want Temp in C
          sht21_tempf.value = round(fahrenheit(jsonobj.sSHT21Data_t.fTemperature),2) -- if getting Temp in F, need to convert
        end
        -- Humidity
        if jsonobj.sSHT21Data_t.fHumidity then
          sht21_humid.value = round(jsonobj.sSHT21Data_t.fHumidity * 100,2) --note, multiply by 100 to get %
        end
      end
    end
  end
  -- make sure we don't get behind if data reporting is faster than can be decoded and stored
  -- Note that some data 'could' be passed by by doing this
  sht21_json.last = now
end