-- Title: "Handle Sensor Hub ISL29023 Data" 
-- Type: Lua Exosite Platform script
-- Description:
-- This script will take data from Connected LaunchPad reported for the 
-- Sensor Hub Boosterpack's ISL29023 sensor and put it into individual dataports
-- The data is reported in a json formatted string originally.
--
-- Intersil ISL29023 ambient and infrared light sensor
-- 
-- Tiva C Series Demo App: 'senshub_iot'
-- Example format of ISL29023 data reported by the Connected LaunchPad Tiva C Series demo 
-- {"sISL29023Data_t":{"bActive":1,"fVisible":40.634,"fInfrared":0.000,"ui8Range":0}}
--
-- To Use: 
-- 1) Add your Connected LaunchPad per quick-start instructions
-- 2) Build the 'senshub_iot' demo for Tiva C Series and program your Connected LaunchPad
-- 3) Add this script to your LaunchPad client in Exosite (https://ti.exosite.com/manage/scripts)
-- 4) Build a custom dashboard to view the new data (https://ti.exosite.com/manage/dashboards)



debug('starting')

-- Table of dataports needed for ISL29023 data
local dstable = {
  {alias="isl29023_json",name="ISL29023 JSON Data",format="string",unit=nil,count=50}, -- sent from CLP
  {alias="isl29023_infrared",name="Infrared Light",format="float",unit="%"},
  {alias="isl29023_visible",name="Visible Light",format="float",unit="%"},
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

local isl29023_json = alias['isl29023_json']
local isl29023_infrared = alias['isl29023_infrared']
local isl29023_visible = alias['isl29023_visible']

debug('running handler')

while true do
  local ts1 = isl29023_json.wait()
  if ts1 ~= nil then
    local jsonobj = json.decode(isl29023_json[ts1])
    if jsonobj ~= nil then
      if jsonobj.sISL29023Data_t then
        -- Take JSON values and put into individual data ports
        
        -- Infrared Light Value
        if jsonobj.sISL29023Data_t.fInfrared then
          isl29023_infrared.value = round(jsonobj.sISL29023Data_t.fInfrared,2)
        end

        -- Visible Light Value
        if jsonobj.sISL29023Data_t.fVisible then
          isl29023_visible.value = round(jsonobj.sISL29023Data_t.fVisible,2)
        end

      end
    end
  end
  -- make sure we don't get behind if data reporting is faster than can be decoded and stored
  -- Note that some data may be missed by by doing this
  isl29023_json.last = now
end