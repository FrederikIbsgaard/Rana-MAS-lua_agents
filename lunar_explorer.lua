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
local ore_color, destX, destY, group, stepCounter, STATE, baseID, taskOfferState, color, complete
local energy, MaxEnergy, scanDim, P, S, I, Q, M, G
local targetMiner = nil
local STATE = "NOSTATE"
local agentColor = "green" --DELETE
local stepCounterTwo = 0
local searchTimeCounter = 0
local timeOut = false
local lookingForNewBase = false
local t = 0
local totalEnergyUsed = 0
local dataSent = false
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
	M = parameters.M
	G = parameters.G
	T = parameters.T

	stepCounter = P
	taskOfferState = "emitOffer"
	complete = false
	ore_color = Shared.getTable("ore_color")
	color = Shared.getTable("explorer_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})

end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "AcceptGroup" and STATE == "NOSTATE" and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= 1 then
		group = eventTable.group
		Agent.joinGroup(group)
		baseID = group
		say("Explore #" ..ID .. " assigned to " .. group)
		STATE = "idle"
	end
	if sourceID ~= ID and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
		if  eventTable.group == group then
			if eventDescription == "explore ping"  and eventTable.group == group then
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

			elseif eventDescription == "dockingRefused" then
					energy = MaxEnergy
					if M == 1 then
						STATE = "findNewBase"
					elseif M == 0 then
						STATE = "baseDone"
					end
			end
		elseif M == 1 and eventTable.group ~= group then
			if eventDescription == "joinBase" then
					baseID = eventTable.baseID
					group = eventTable.group
					local newBase = eventTable.basePos
					while #memory > 0 do
						memory [#memory] = nil
					end
					table.insert(memory, {x=newBase.x, y=newBase.y})
					lookingForNewBase = false
					STATE = "moveToBase"

						-- color change to see base swap
					Agent.changeColor({r=0, g=255, b=128})



			elseif eventDescription == "lookingForNewBase" and lookingForNewBase == false then
				Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group, baseID=baseID, basePos={x=memory[1].x, y=memory[1].y}}}
				energy = energy - 1
			end
		end
	end
end

function takeStep()
	t = t + 1
	if t == T then
		timeOut = true
		STATE = "moveToBase"
	end
	--say("EXPLORER: " .. STATE)
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
		if stepCounter >= P*1.5 then
			STATE = "scanForOre"
		end
		stepCounter = stepCounter + 1
	elseif STATE == "scanForOre" then
		newDest = _scanForOre()

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
		if (not atBase()) then
			destX = memory[1].x
			destY = memory[1].y
			moveTo(destX, destY)
		elseif atBase() and timeOut == true then
			STATE = "baseDone"
		else
			STATE = "recharge"
		end
	elseif STATE == "recharge" then
			if energy ~= MaxEnergy then
				Event.emit{targetID=baseID, speed=0, description="dockingRequest", table={oreCount=0,usedEnergy=MaxEnergy-energy,group=group}}
				totalEnergyUsed = totalEnergyUsed + (MaxEnergy-energy)
			elseif #memory ~= 1 then
				STATE = "taskOffer"
			else
				STATE = "scanForOre"
			end

	elseif STATE == "taskOffer" then
		if taskOfferState == "emitOffer" then
			Event.emit{speed=5000, description="taskOffer", table={group=group}}
			energy = energy - 1
			waitStepCounter = 0
			taskOfferState = "evaluateOffers"
		elseif taskOfferState == "evaluateOffers" then
			waitStepCounter = waitStepCounter + 1
			if #transporterTable > 0 and waitStepCounter >= 1 then
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
				end
			elseif waitStepCounter >= 60 and #transporterTable == 0 then
				while #memory > 1 do
					memory [#memory] = nil
				end
				taskOfferState = "emitOffer"
				STATE = "recharge"
			elseif (waitStepCounter == 20 or waitStepCounter == 40) and #transporterTable == 0 then -- QUICKFIX
				Event.emit{speed=5000, description="taskOffer", table={group=group}}
				energy = energy - 1
			end
		elseif taskOfferState == "emitTasks" then
			emitObjective(targetMiner)
			targetMiner = nil

			taskOfferState = "emitOffer"
			STATE = "recharge"
		end

	elseif STATE == "findNewBase" then
		lookingForNewBase = true
		moveTo(destX, destY)
		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		if stepCounterTwo >= I then
			STATE = "callForAgents"
		end
		if searchTimeCounter >= G then
			timeOut = true
			STATE = "moveToBase"
		end
		searchTimeCounter = searchTimeCounter +1
		stepCounterTwo = stepCounterTwo + 1
	elseif STATE == "callForAgents" then
		Event.emit{speed=5000, description="lookingForNewBase", table={group=group}}
		energy = energy - 1
		STATE = "findNewBase"
		stepCounterTwo = 0

	elseif STATE == "baseDone" then
		if dataSent == true then

		else
			--say(0 .. " " .. totalEnergyUsed)
			Event.emit{targetID=2, speed=5000, description="dataFromExplorer", table={oresCollected=0, energyUsed=totalEnergyUsed}}
			dataSent = true
		end
	end
	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "recharge" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy <= 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,0,0})
	end

end

function moveTo(x, y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	--colorGround()
	energy = energy - Q
end
function colorGround() --NOT WORKING ATM
	local color = Map.checkColor(PositionX,PositionY)
	local newR = color[1] + 10
	if newR < 255 then
		l_modifyMap(PositionX,PositionY, newR, 0, 0)
	end
end

function atBase() -- CLEAN THIS UP! MAKE THE DROP ZONE LARGER TO AVOID STUCK AGENTS
	if (PositionX==memory[1].x and PositionY==memory[1].y) then
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
	Event.emit{targetID=minerID, speed=5000, description="taskObjective", table={ores=objectiveList,group=group}}
	energy = energy - 1
	while #memory > 1 do
		memory [#memory] = nil
	end
end

function completed()
	STATE = "moveToBase"
	complete = true
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
