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
Event = require "ranalib_event"
Move = require "ranalib_movement"
Map = require "ranalib_map"
Shared = require "ranalib_shared"
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Collision = require "ranalib_collision"

local state
local preyPredator
local kills
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "killed prey" then
		kills = kills + 1
	end

end

-- Initialization of the agent.
function initializeAgent()
	--say("Agent #: " .. ID .. " has been initialized")
	--Moving = true
	--DestinationX = 1
	--DestinationY = 1
    Agent.changeColor{r=0, g=0, b=255}

	-- init local parameters
	state = 0
	preyPredator = Shared.getTable("preyPredator")
	kills = 0
	--
	GridMove = true
	Moving = false
	Speed = 6
end

function takeStep()

	if state == 0 then
		move()
		preyTable = _ScanMap(10)
		if preyTable ~= nil then
			state = 1
			distanceToPrey = math.sqrt(math.pow((PositionX-preyTable.posX),2) + math.pow((PositionY-preyTable.posY),2))
		end
	end
	if state == 1 then
		Move.to({x=preyTable.posX, y=preyTable.posY})
		if math.sqrt(math.pow((PositionX-preyTable.posX),2) + math.pow((PositionY-preyTable.posY),2)) < 1 then
			--Agent.removeAgent(stalked_prey.id)
			Event.emit{targetID=preyTable.id, speed=343, description="attack"}
		end
		if math.sqrt(math.pow((PositionX-preyTable.posX),2) + math.pow((PositionY-preyTable.posY),2)) <= distanceToPrey/2 then
			state = 0
		end
	end

end


function _ScanMap(scanRadius)

	local dist = 10000

	local table = Collision.radialCollisionScan(scanRadius, PredatorX, PredatorY)
	if table ~= nil then
		--say(#table)
		for i = 1, #table do
			local r,g,b = l_checkMap(table.posX,table.posY)
			if table[i].id <= preyPredator[1]+1 then -- target only preys
				temp_dist = math.sqrt(math.pow((PositionX-table[i].posX),2) + math.pow((PositionY-table[i].posY),2))
				if temp_dist < dist then
					dist = temp_dist
					targetPrey = table[i]
				end
			end
			--say(table[i].id)
			--say(temp_dist)
		end
		--say("targetPrey")
		return targetPrey
	end
	return
end


function move()

	if Stat.randomInteger(1,20000) == 1 then Moving = false end

	if not Moving then
		Move.toRandom()
	end
end


function cleanUp()
	say("Agent #: " .. ID .. " killed: " .. kills)
end
