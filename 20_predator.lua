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

--
local state
local preyPredator
local kills
local sp = 5
local G = 200
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
	GridMovement = true
	Moving = false
	Speed = sp
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
		--Move.to({x=preyTable.posX, y=preyTable.posY})
		moveTorus(preyTable.posX,preyTable.posY)
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

	--local table = Collision.radialCollisionScan(scanRadius, PredatorX, PredatorY)
	local table = squareSpiralTorusScanCollision(550)

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


function squareSpiralTorusScanCollision(dimension)
	local x = 0
	local y = 0
	local dx = 0
	local dy = -1
	local collisionTable = {}
	local checkColor = {}


	-- Spiral check starting from the Agent position and spiraling out
	for i=1, (dimension+1)*(dimension+1) do
		local checkX = PositionX + x
		local checkY = PositionY + y

		-- Check through walls
		if checkX >= G then checkX = checkX - G end
		if checkX < 0 then checkX = checkX + G end
		if checkY >= G then checkY = checkY - G end
		if checkY < 0 then checkY = checkY + G end


		-- Check if position is the given color
		--checkColor = Map.checkColor(checkX,checkY)
		--if compareTables(checkColor,color) then
			--table.insert(collisionTable, {posX=checkX, posY=checkY})
		--end
		checkColl = l_checkPosition(checkX,checkY)
		if checkColl[1] ~= nil then
			if checkColl[1] <= preyPredator[1]+1 then
				table.insert(collisionTable, {id=checkColl[1], posX=checkX, posY=checkY})
			end
		end

		-- Caluculating next position
		if x == y or (x < 0 and x == -y) or (x > 0 and x == 1-y) then
			local temp = dx
			dx = -dy
			dy = temp
		end

		-- Next position
		x = x+dx
		y = y+dy
	end

	-- Returns
	if #collisionTable > 0 then
		return collisionTable
	else
		return nil
	end
end




function move()

	if Stat.randomInteger(1,20000) == 1 then Moving = false end

	if not Moving then
		Move.toRandom()

		Speed = sp
	end
end

function moveTorus(x,y)

	local destX = x
	local destY = y
	local directionX = destX-PositionX
	local directionY = destY-PositionY

	-- Changing direction to go through the edge of the map if path is shorter
	if math.abs(directionX) > G/2 	then directionX = -directionX end
	if math.abs(directionY) > G/2 	then directionY = -directionY end

	-- Determining destination point
	if	directionX > 0 then destX = PositionX+1
	elseif	directionX < 0 then destX = PositionX-1
	else	destX = PositionX	end

	if	directionY > 0 then destY = PositionY+1
	elseif	directionY < 0 then destY = PositionY-1
	else	destY = PositionY	end

	-- Determining destination point if direction is through the edge of the map
	if destX < 0 then
		destX = G-1
	elseif destX >= G then
		destX = 0
	end

	if destY < 0 then
		destY = G-1
	elseif destY >= G then
		destY = 0
	end

	-- If no other agent is at the destination or the destination is the base
	if (not Collision.checkCollision(destX,destY)) or (destX == basePosX and destY == basePosY)  then
		-- Moving the Agent
		Collision.updatePosition(destX,destY)
	-- If there is a collision
	else
		-- If destination is on the same y
		if destX ~= PositionX and destY == PositionY then
			-- Change y with either -1 or 1
			local randStep = randomWithStep(-1,1,2)
			destY = PositionY+randStep

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Change y with the opposite as before
				destY = PositionY-randStep
			end

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Stay
				destX = PositionX
				destY = PositionY
			end

		-- If destination is on the same x
		elseif destY ~= PositionY and destX == PositionX then
			-- Change x with either -1 or 1
			local randStep = randomWithStep(-1,1,2)
			destX = PositionX+randStep

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Change x with the opposite as before
				destX = PositionX-randStep
			end

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Stay
				destX = PositionX
				destY = PositionY
			end

		-- If destination is diagonal
		elseif destY ~= PositionY and destX ~= PositionX then
			local tempDestX = destX
			local tempDestY = destY
			-- Change either y or x destination to position
			local randNum = Stat.randomInteger(0,1)
			if randNum == 0 then
				destY = PositionY
			else
				destX = PositionX
			end

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Change the opposite as before
				if randNum == 1 then
					destY = PositionY
					destX = tempDestX
				else
					destY = tempDestY
					destX = PositionX
				end
			end

			-- If still collision
			if Collision.checkCollision(destX,destY) then
				-- Stay
				destX = PositionX
				destY = PositionY
			end
		end

		-- Update position
		Collision.updatePosition(destX,destY)

	end

	DestinationX = destX
	DestinationY = destY
end

function cleanUp()
	say("Agent #: " .. ID .. " killed: " .. kills)
end
