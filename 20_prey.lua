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
local Stat = require "ranalib_statistic"


-- Initialization of the agent.

function initializeAgent()
	say("Agent #: " .. ID .. " has been initialized")
	--Moving = true
	--DestinationX = 1
	--DestinationY = 1

    Agent.changeColor{r=0, g=255, b=0}

	GridMove = true
end

Steps = 0
Moving = false
function takeStep()

	move()
end


function move()

	if Stat.randomInteger(1,20000) == 1 then Moving = false end

	if Stat.randomInteger(1,50000) == 1 then
		Speed = 0
	end

	if not Moving then
		Move.toRandom()
		Speed = 1
	end
end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
