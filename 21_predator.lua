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

-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"
--
local state
local preyPredator
local kills
local sp
local G
local goToDest
local agentStates = {"moveRandom", "lookForPrey","stalkPrey"}
preyTable = {id=0,posX=0,posY=0}
local px
local py
local pid
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if sosourceID ~= ID then
		if eventDescription == "killed prey" then
			kills = kills + 1
		elseif eventDescription == "found prey"  then
			if torusModul.distanceToAgent(PositionX, PositionY, eventTable.posX, eventTable.posY) < 20 then
				state = agentStates[3]
				--preyTable = {id=eventTable.id,posX=eventTable.posX,posY=eventTable.posY}

				 px = eventTable.posX
				 py = eventTable.posX
				 pid = eventTable.posX
			end
		end
	end

end

-- Initialization of the agent.
function initializeAgent()
    Agent.changeColor{r=0, g=0, b=255}

	-- init local parameters
	state = agentStates[1]
	-- Change Agent color to the predator color determined in 21_master
	local color = Shared.getTable("predator_color")
	Agent.changeColor{r=color[1], g=color[2], b=color[3]}
	-- Get the grid dim
	local Grid = Shared.getTable("mapSize")
	G = Grid[1]
	-- The amount of preys and predators
	preyPredator = Shared.getTable("preyPredator")
	kills = 0
	sp = 5

	goToDest = {x=Stat.randomInteger(1,ENV_WIDTH),y=Stat.randomInteger(1,ENV_WIDTH)}
	--
	GridMove = true
	GridMovement = true
	Moving = false
	Speed = sp
	--Collision.updatePosition(1,50)

end

function takeStep()
	if state == agentStates[1] then
		-- running around scanning
		if Stat.randomInteger(1,2000) == 1 then
			goToDest.x = Stat.randomInteger(0,ENV_WIDTH)
			goToDest.y = Stat.randomInteger(0,ENV_WIDTH)
		end
		state = agentStates[2]
	end
	if state == agentStates[2] then
		preyTable = _ScanMap(10)
		--Shared.storeTable("preyTable",preyTable)
		if preyTable ~= nil then
			-- Prey found hunt!
			state = agentStates[3]
			px = preyTable.posX
			py = preyTable.posY
			pid = preyTable.id
			Event.emit{targetID=Predator, speed=80, description="found prey", table={posX=preyTable.posX,posY=preyTable.posY,id=preyTable.id}}
			distanceToPrey = torusModul.distanceToAgent(PositionX, PositionY, preyTable.posX, preyTable.posY)
		else
			state = agentStates[1]
		end
	end
	if state == agentStates[3] then
		--tempT = Shared.getTable("preyTable")
		--goToDest.x = preyTable.posX
		--goToDest.y = preyTable.posY
		--torusModul.moveTorus(preyTable.posX,preyTable.posY,G)
		--if math.sqrt(math.pow((PositionX-preyTable.posX),2) + math.pow((PositionY-preyTable.posY),2)) < 1 then

		if torusModul.distanceToAgent(PositionX, PositionY, px, py) < 1 then
			Event.emit{targetID=pid, speed=343, description="attack"}
			state = agentStates[1]
		elseif torusModul.distanceToAgent(PositionX, PositionY, px, py) <= distanceToPrey/2 then
			state = agentStates[2]
		end
	end
	if not Moving then
	--if false then
		Speed = sp
		-- Go though the egde if its shortere
		if state == agentStates[3] then
			torusModul.moveTorus(px, py, G)
		else
			torusModul.moveTorus(goToDest.x, goToDest.y, G)
		end
		Move.to({x=DestinationX,y=DestinationY})
	end

end


function _ScanMap(scanRadius)

	local dist = 10000
	-- scan for Agants using collision
	local table = torusModul.squareSpiralTorusScanCollision(scanRadius,G, ID)
	if table ~= nil then
		-- Go though the table to find the closes agent
		for i = 1, #table do
			if table[i].id <= preyPredator[1]+1 then -- target only preys
				temp_dist = torusModul.distanceToAgent(PositionX, PositionY, math.floor(table[i].posX), math.floor(table[i].posY))
				if temp_dist < dist then
					dist = temp_dist
					targetPrey = table[i]
				end
			end
		end
		return targetPrey
	end
	return
end

function cleanUp()
	say("Agent #: " .. ID .. " killed: " .. kills)
end
