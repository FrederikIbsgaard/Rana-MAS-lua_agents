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

-- Import Rana lua libraries
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Draw = require "ranalib_draw"


background_color = {0,0,0}
prey_color = {0,255,0}
predator_color = {0,0,255}

preyPredator = {50, 1}

function initializeAgent()

    --StepMultiple = 1000
    say("Master Agent#: " .. ID .. " has been initialized")

    Shared.storeTable("background_color", background_color)
    Shared.storeTable("prey_color", prey_color)
    Shared.storeTable("predator_color", predator_color)
    Shared.storeTable("preyPredator", preyPredator)
    for i=0, ENV_WIDTH do
        for j=0, ENV_HEIGHT do
            Map.modifyColor(i,j, background_color)
        end
    end
    say("Map has been initialized")

    local data_table = {}

	local ids = {}

    for i = 1, preyPredator[1] do
        local ID = Agent.addAgent("20_prey.lua")
        table.insert(ids, ID)
        data_table[ID] = {call_amount = 0}
    end
    say("All prey agents initialized, amount: ".. preyPredator[1])

    for i=1, preyPredator[2] do
        local ID = Agent.addAgent("20_predator.lua")
        table.insert(ids, ID)
        data_table[ID] = {call_amount = 0}
    end
    say("All predator agents initialized, amount: ".. preyPredator[2])

end

function takeStep()
	Agent.removeAgent(ID)
    say("Master agent removed")
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
