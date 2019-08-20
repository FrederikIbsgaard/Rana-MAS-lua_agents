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
Move = require "ranalib_movement"
Shared = require "ranalib_shared"
Agent = require "ranalib_agent"
Collision = require "ranalib_collision"
Map = require "ranalib_map" -- DELETE
-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local ore_color, destX, destY, group, stepCounter, STATE, baseID, taskOfferState
local energy, MaxEnergy, P, S, I, Q
-- EventHandler


function initializeAgent()
	GridMove = true
	table.insert(memory, {x=PositionX,y=PositionY})
	local parameters = Shared.getTable("parameters")
	MaxEnergy = parameters.E -- energi for tge robot
	energy = MaxEnergy
	P = parameters.P -- initial perception scope
	S = parameters.S -- memory size of robots
	I = parameters.I -- fixed communication scope
	Q = parameters.Q -- cost of movemnt

	group = 1
	Agent.joinGroup(group)
	stepCounter = P
 	STATE = "idle"
	baseID = 2
	taskOfferState == "emitOffer"
	--local color =  --{0,255,0}local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	local color = Shared.getTable("explorer_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})

end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if sourceID ~= ID then
		if torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
			if eventDescription == "explore ping" then
				--say(eventTable.dest.x)
				if torusModul.distanceToAgent(destX, destY, eventTable.dest.x, eventTable.dest.y) <= 100 then
					local x = Stat.randomInteger(0,ENV_WIDTH)
					local y = Stat.randomInteger(0,ENV_WIDTH)
					while torusModul.distanceToAgent(x, y, eventTable.dest.x, eventTable.dest.y) >= 100 do
						x = Stat.randomInteger(0,ENV_WIDTH)
						y = Stat.randomInteger(0,ENV_WIDTH)
					end

					destX = x
					destY = y
				end
			elseif eventDescription == "taskResponse" then
				local capacity = eventTable.capacity
				local minDist = eventTable.minDist
			elseif eventDescription == "dockingAccepted" then
				energy = MaxEnergy
			end
		end
	end
end

function takeStep()
	if STATE == "idle" then
		destX = Stat.randomInteger(0,ENV_WIDTH)
		destY = Stat.randomInteger(0,ENV_WIDTH)
		STATE = "move"
	elseif STATE == "move" then
		moveTo(destX, destY)
		if stepCounter >= P then
			Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
			STATE = "scanForOre"
		end
		stepCounter = stepCounter + 1
	elseif STATE == "scanForOre" then
		newDest = _scanForOre()

		--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
		if newDest ~= nil then
			destX = newDest[1]
			destY = newDest[2]
		else
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		stepCounter = 0
		if #memory >= S then
			STATE = "moveToBase"
		else
			STATE = "move"
		end
	elseif STATE == "moveToBase" then
		moveTo(memory[1].x, memory[1].y)
		if atBase() then
			while #memory > 1 do -- DELETE!
				Map.modifyColor(memory[#memory].x, memory[#memory].y, Shared.getTable("background_color"))
				table.remove(memory,#memory)
			end
			STATE = "recharge"
		end
	elseif STATE == "recharge" then
		if energy ~= MaxEnergy then
			Event.emit{targetID=baseID, speed=343, description="dockingRequest", table={oreCount=0,usedEnergy=MaxEnergy-energy}}
		elseif #memory ~= 1 then
			STATE = "taskOffer"
		else
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
			STATE = "move"
		end
	elseif STATE == "taskOffer" then
		if taskOfferState == "emitOffer" then
			Event.emit{targetID=baseID, speed=343, description="taskOffer"}
		elseif taskOfferState == "evaluateOffers" then

		elseif taskOfferState == "emitTasks" then


			taskOfferState = "emitOffer"
			STATE = recharge
		end
	end
	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "recharge" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy == 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,0,0})
	end

end

function moveTo(x, y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	energy = energy - 1
end

function atBase()
	if PositionX==memory[1].x and PositionY==memory[1].y then
		return true
	elseif distToBase() <= 1.1 then
		Collision.updatePosition(memory[1].x,memory[1].y)
		return true
	else
		return false
	end
end

function distToBase()
	return torusModul.distanceToAgent(PositionX, PositionY, memory[1].x, memory[1].y)
end

function _scanForOre()
	local scanDim = P
	local oreTable = torusModul.squareSpiralTorusScanColor(P, ore_color, ENV_WIDTH)
	local orePicked = 0
	local x = 0
	local y = 0

	if oreTable ~= nil then
		for i=1, #oreTable do
			if #memory ~= S then
				table.insert(memory, {x=oreTable[orePicked+1].posX, y=oreTable[orePicked+1].posY})
				orePicked = orePicked + 1
			end

		end
		if orePicked > 0 and orePicked ~= #oreTable then
			local oreCount = 0
			for i=orePicked, #oreTable do
				x = x + oreTable[i].posX
				y = y + oreTable[i].posX
				oreCount = oreCount + 1
			end
			x = x/oreCount
			y = y/oreCount
			return {x, y}
		end

	end
	return nil
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end


--[[local dx = math.abs(sourceX - PositionX)
local dy = math.abs(sourceY - PositionY)
local x, y, sourceScanP
x= 0
y= 0
sourceScanP = eventTable.scanP
if PositionX > sourceX then
	if PositionY > sourceY then
		x = sourceX + sourceScanP/2
		y = sourceY + sourceScanP/2
	end
	if PositionY <= sourceY then
		x = sourceX + sourceScanP/2
		y = sourceY - sourceScanP/2
	elseif math.abs(PositionX - x) < math.abs(PositionY - y) then
		destX = x + P
		destY = PositionY
	else
		destX = PositionX
		destY = y + P
	end
elseif PositionX < sourceX then
	if PositionY > sourceY then
		x = sourceX - sourceScanP/2
		y = sourceY + sourceScanP/2
	elseif PositionY <= sourceY then
		x = sourceX - sourceScanP/2
		y = sourceY - sourceScanP/2
	end

	if math.abs(PositionX - x) < math.abs(PositionY - y) then
		destX = x - P
		destY = PositionY
	else
		destX = PositionX
		destY = y - P
	end
end
say("here")
--]]
