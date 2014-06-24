-- Title: "Handle Sensor Hub TMP006 Data" 
-- Type: Lua Exosite Platform script
-- Description:
-- This script will take data from Connected LaunchPad reported for the 
-- Sensor Hub Boosterpack's TMP006 sensor and put it into individual dataports
-- The data is reported in a json formatted string originally.
--
-- The TMP006 sensor is TI Infrared Thermopile Sensor
-- 
-- Tiva C Series Demo App: 'senshub_iot'
-- Example format of TMP006 data reported by the Connected LaunchPad Tiva C Series demo 
-- {"sTMP006Data_t":{"bActive":1,"fAmbient":28.031,"fObject":25.526}}
--
-- To Use: 
-- 1) Add your Connected LaunchPad per quick-start instructions
-- 2) Build the 'senshub_iot' demo for Tiva C Series and program your Connected LaunchPad
-- 3) Add this script to your LaunchPad client in Exosite (https://ti.exosite.com/manage/scripts)
-- 4) Build a custom dashboard to view the new data (https://ti.exosite.com/manage/dashboards)



debug('starting')

-- Table of dataports needed for TMP006 data
local dstable = {
  {alias="tmp006_json",name="TMP006 JSON Data",format="string",unit=nil,count=50},  -- incoming data from CLP
  {alias="tmp006_object_tempc",name="TMP006 Object Temperature C",format="float",unit="C"},
  {alias="tmp006_object_tempf",name="TMP006 Object Temperature F",format="float",unit="F"},
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

local tmp006_json = alias['tmp006_json']
local tmp006_object_tempc = alias['tmp006_object_tempc']
local tmp006_object_tempf = alias['tmp006_object_tempf']

debug('running handler')

while true do
  local ts1 = tmp006_json.wait()
  if ts1 ~= nil then
    local jsonobj = json.decode(tmp006_json[ts1])
    if jsonobj ~= nil then
      if jsonobj.sTMP006Data_t then
        -- Take JSON values and put into individual data ports
        
        -- Non-contact Object Temperature
        if jsonobj.sTMP006Data_t.fObject then
          tmp006_object_tempc.value = round(jsonobj.sTMP006Data_t.fObject,2)
          tmp006_object_tempf.value = round(fahrenheit(jsonobj.sTMP006Data_t.fObject) ,2)
        end

      end
    end
  end
  -- make sure we don't get behind if data reporting is faster than can be decoded and stored
  -- Note that some data 'could' be passed by by doing this
  tmp006_json.last = now
end