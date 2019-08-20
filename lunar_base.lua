--The following global values are set via the simulation core:
-- ------------------------------------
-- IMMUTABLES.
-- ------------------------------------
-- ID -- id of the agent.
-- STEP_RESOLUTION 	-- resolution of steps, in the simulation core.
-- EVENT_RESOLUTION	-- resolution of event distribution.
-- ENV_WIDTH -- Width of the environment in meters.
-- ENV_HEIGHT -- Height of the environment in meters.
-- ------------------------------------
-- VARIABLES.
-- ------------------------------------
-- PositionX	 	-- Agents position in the X plane.
-- PositionY	 	-- Agents position in the Y plane.
-- DestinationX 	-- Agents destination in the X plane.
-- DestinationY 	-- Agents destination in the Y plane.
-- StepMultiple 	-- Amount of steps to skip.
-- Speed 			-- Movement speed of the agent in meters pr. second.
-- Moving 			-- Denotes wether this agent is moving (default = false).
-- GridMove 		-- Is collision detection active (default = false).
-- ------------------------------------
-- Import Rana lua modules.
Event = require "ranalib_event"
Shared = require "ranalib_shared"

-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local globallyUsedEnergy = 0
local collectedOre = 0

-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
  if eventDescription == "dockingRequest" then
    globallyUsedEnergy = globallyUsedEnergy + eventTable.usedEnergy
    collectedOre = collectedOre + eventTable.oreCount
    Event.emit{targetID=sourceID, speed=343, description="dockingAccepted"}
  end
end

function initializeAgent()


end

function takeStep()

end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
