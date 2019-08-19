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
local memory = {}
local oreStorage, energi, W, P, S, I, Q
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

end

function initializeAgent()
	GridMove = true
	oreStorage = 0
	table.insert(memory, {x=PositionX,y=PositionY})
	local parameters = Shared.getTable("parameters")
	energi = parameters.E -- energi for robots
	W = parameters.W -- number of max ore
 	P = parameters.P -- initial perception scope
	S = parameters.S -- memory size of robots
	I = parameters.I -- fixed communication scope
	Q = parameters.Q -- cost of movemnt
end

function takeStep()
	local x = Stat.randomInteger(0,ENV_WIDTH)
	local y = Stat.randomInteger(0,ENV_WIDTH)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
end

function mineOre(x, y)
	if oreStorage < W then
		local r,g,b = l_checkMap(x,y)
		local color = Shared.getTable("ore_color")
		if r == color[1] and g == color[2] and b == color[3] then
			l_modifyMap(x,y, 0, 0, 0)
			oreStorage = oreStorage + 1
		end
	end
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
