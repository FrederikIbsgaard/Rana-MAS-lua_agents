--begin_license--
--
--Copyright 	2013 - 2016 	Søren Vissing Jørgensen.
--
--This file is part of RANA.
--
--RANA is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--RANA is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with RANA.  If not, see <http://www.gnu.org/licenses/>.
--
----end_license--

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


-- Import valid Rana lua libraries.
Move = require "ranalib_movement"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Collision = require "ranalib_collision"


--
_ids = Shared.getTable("amountC")

-- Initialization of the agent.
function initializeAgent()
	say("Agent #: " .. ID .. " has been initialized")
	--Moving = true
	--DestinationX = 1
	--DestinationY = 1
    Agent.changeColor{r=0, g=0, b=255}
	GridMove = true
end

Steps = 0
Moving = false
search_radius = 20


function takeStep()


	--local table = Map.radialMapColorScan(5	, 0, 255, 0)
	--local table = Map.radialMapColorScan(5, 0, 255, 0)
    local preyTable = findClosestPrey()
	if preyTable ~= nil then
		killPrey(preyTable.id)
	end
end


function findClosestPrey()
	--say(prey_color[1])
    local table = Collision.radialCollisionScan(search_radius)
	if table ~= nil then
		for i=1, #table do
			if table[i].id <= _ids[1]+1 then
				Move.to({x=table[i].posX, y=table[i].posY})
				return table[i]
			end
		end
	end
	move()
	return nil
end

function killPrey(id)

    Agent.removeAgent(id)
	say("Killed prey: ".. id)

end


function move()

	if Stat.randomInteger(1,20000) == 1 then Moving = false end

	if not Moving then
		Move.toRandom()
		Speed = 3
	end
end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
