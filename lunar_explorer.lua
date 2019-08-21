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
--Map = require "ranalib_map" -- DELETE
-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local transporterTable = {}
local ore_color, destX, destY, group, stepCounter, STATE, baseID, taskOfferState, color
local energy, MaxEnergy, scanDim, P, S, I, Q
local targetMiner = nil

local agentColor = "green" --DELETE
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
	taskOfferState = "emitOffer"
	--local color =  --{0,255,0}local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	color = Shared.getTable("explorer_color")
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

				table.insert(transporterTable, {ID=sourceID, capacity=eventTable.capacity})--, minDist=eventTable.minDist})

			elseif eventDescription == "dockingAccepted" then
				energy = MaxEnergy
			end
		end
	end
end

function takeStep()
	--say(STATE)
	if STATE == "idle" then
		destX = Stat.randomInteger(0,ENV_WIDTH)
		destY = Stat.randomInteger(0,ENV_WIDTH)
		STATE = "move"
		stepCounter = P
	elseif STATE == "move" then
		moveTo(destX, destY)

		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)

		end
		--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
		if stepCounter >= P then
			--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
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
		--STATE = "32"
	elseif STATE == "moveToBase" then
		--moveTo(memory[1].x, memory[1].y)
		destX = memory[1].x
		destY = memory[1].y
		moveTo(destX, destY)
		if atBase() then
			STATE = "recharge"
		end
	elseif STATE == "recharge" then
		if energy ~= MaxEnergy then
			Event.emit{targetID=baseID, speed=0, description="dockingRequest", table={oreCount=0,usedEnergy=MaxEnergy-energy}}
			energy = energy -1
		elseif #memory ~= 1 then
			STATE = "taskOffer"
		else
			STATE = "scanForOre"
			--destX = Stat.randomInteger(0,ENV_WIDTH)
			--destY = Stat.randomInteger(0,ENV_WIDTH)

		end
	elseif STATE == "taskOffer" then
		if taskOfferState == "emitOffer" then
			Event.emit{speed=5000, description="taskOffer"}
			--if #memory == 1 then
			--	STATE = "recharge"
			--end
			waitStepCounter = 0
			taskOfferState = "evaluateOffers"
		elseif taskOfferState == "evaluateOffers" then
			waitStepCounter = waitStepCounter + 1
			if #transporterTable > 0 then
				local highestCap = 0
				local cap = 0
				for i=1, #transporterTable do
					cap = transporterTable[i].capacity
					if cap > highestCap then
						highestCap = cap
						targetMiner = transporterTable[i].ID
					end
				end


				while #transporterTable > 0 do
					transporterTable [#transporterTable] = nil
				end

				if targetMiner ~= nil then
					taskOfferState = "emitTasks"
				elseif targetMiner == nil then
					-- FUCKING UGLY CODE, IF NOT TRANSPORTER DUMP MEMORY AND MOVE ON
					while #memory > 1 do
						memory [#memory] = nil
					end
					taskOfferState = "emitOffer"
					STATE = "recharge"
				end
			elseif waitStepCounter == 100 and #transporterTable == 0 then
				while #memory > 1 do
					memory [#memory] = nil
				end
				taskOfferState = "emitOffer"
				STATE = "recharge"
			elseif math.fmod(waitStepCounter,2) == 0 and #transporterTable == 0 then -- QUICKFIX
				Event.emit{speed=5000, description="taskOffer"}
			end
		elseif taskOfferState == "emitTasks" then
			emitObjective(targetMiner)
			targetMiner = nil

			taskOfferState = "emitOffer"
			STATE = "recharge"
		end
	end
	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "recharge" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy <= 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,255,255})
	end

end

function moveTo(x, y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	--colorGround()
	energy = energy - 1
end
function colorGround() --NOT WORKING ATM
	local color = Map.checkColor(PositionX,PositionY)
	local newR = color[1] + 10
	if newR < 255 then
		l_modifyMap(PositionX,PositionY, newR, 0, 0)
	end
end

function atBase() -- CLEAN THIS UP! MAKE THE DROP ZONE LARGER TO AVOID STUCK AGENTS
	if (PositionX==memory[1].x and PositionY==memory[1].y) or (PositionX==memory[1].x+1 and PositionY==memory[1].y) or (PositionX==memory[1].x and PositionY==memory[1].y+1) or (PositionX==memory[1].x-1 and PositionY==memory[1].y) or (PositionX==memory[1].x and PositionY==memory[1].y-1) then
		--Collision.updatePosition(memory[1].x,memory[1].y)
		return true
	elseif distToBase() <= 2 then
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

	if agentColor == "green" then -- DELETE THIS IS TO SEE WHEN IT SCANS
		Agent.changeColor({r=255, g=0, b=0})
		agentColor = "red"
	elseif agentColor == "red" then
		Agent.changeColor({r=0, g=255, b=0})
		agentColor = "green"
	end

	local scanDim = P
	local oreTable = torusModul.squareSpiralTorusScanColor(P, ore_color, ENV_WIDTH)
	energy = energy - P
	local x = 0
	local y = 0
	if oreTable ~= nil then
		for i=1, #oreTable do
			if #memory ~= S then
				table.insert(memory, {x=oreTable[i].posX, y=oreTable[i].posY})
			end
		end
		local oreCount = #oreTable
		for i=1, #oreTable do
			x = x + oreTable[i].posX
			y = y + oreTable[i].posY
			--oreCount = oreCount + 1
		end
		x = x/oreCount
		y = y/oreCount
		return {x, y}

		--end
	end
	return nil
end

function emitObjective(minerID)
	local objectiveList = {}
	for i=2, #memory do
		table.insert(objectiveList, memory[i])
	end
	Event.emit{targetID=minerID, speed=5000, description="taskObjective", table={ores=objectiveList}}
	while #memory > 1 do
		memory [#memory] = nil
	end
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
