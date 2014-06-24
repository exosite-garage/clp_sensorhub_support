-- Title: "Handle Sensor Hub Compliemntary DCM Data" 
-- Type: Lua Exosite Platform script
-- Description:
-- This script will take data from Connected LaunchPad reported for the 
-- Sensor Hub Boosterpack's 9 axis MEMS motion tracking sensor and put it into individual dataports
-- The data is reported in a json formatted string originally.
--
-- The InvenSense MPU-9150: 9-axis MEMS motion tracking
-- 
-- Tiva C Series Demo App: 'senshub_iot'
-- Example format of CompDCM data reported by the Connected LaunchPad Tiva C Series demo 
-- {"sCompDCMData_t":{"bActive":1,"fEuler":[-0.000,-0.000,2.147],"fAcceleration":[0.100,-0.000,9.379],"fAngularVelocity":[0.011,0.005,-0.000],"fMagneticField":[-0.000,-0.000,0.000],"fQuaternion":[0.476,0.002,-0.000,0.879]}}
--
-- Note: Data is sent at a relatively slow rate (seconds) compared to most useful applications for this type of data
-- 
-- To Use: 
-- 1) Add your Connected LaunchPad per quick-start instructions
-- 2) Build the 'senshub_iot' demo for Tiva C Series and program your Connected LaunchPad
-- 3) Add this script to your LaunchPad client in Exosite (https://ti.exosite.com/manage/scripts)
-- 4) Build a custom dashboard to view the new data (https://ti.exosite.com/manage/dashboards)



debug('starting')

-- Table of dataports needed for CompDCM data
local dstable = {
  {alias="compdcm_json",name="Complimentary DCM JSON Data",format="string",unit=nil,count=50}, -- sent from CLP
}


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

local compdcm_json = alias['compdcm_json']


-- nothing to do with data, script will end.
