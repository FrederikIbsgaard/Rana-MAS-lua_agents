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
Agent = require "ranalib_agent"



-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local group, MaxEnergy, energy, W, P, S, I, Q, M, ore_color
local oreStorage = 0
local STATE = "NOSTATE"
local baseID
local LATCHED_STATE = "NOSTATE"
local stepCounter, complete
local stepCounterTwo = 0
local searchTimeCounter = 0
local destX = Stat.randomInteger(0,ENV_WIDTH)
local destY = Stat.randomInteger(0,ENV_WIDTH)
local timeOut = false
local lookingForNewBase = false
local t = 0
local totalEnergyUsed = 0
local totalOresCollected = 0
local dataSent = false

function initializeAgent()
	GridMove = true
	oreStorage = 0
	table.insert(memory, {x=PositionX,y=PositionY})
	local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	MaxEnergy = parameters.E
	energy = MaxEnergy -- energy for robots
	W = parameters.W -- number of max ore
 	P = parameters.P -- initial perception scope
	S = parameters.S -- memory size of robots
	I = parameters.I -- fixed communication scope
	Q = parameters.Q -- cost of movemnt
	M = parameters.M -- mode
	G = parameters.G -- world size
	T = parameters.T

	 -- transporter
	complete = false
	local color = Shared.getTable("miner_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})
	--Collision.updatePosition(100, 100)
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "AcceptGroup" and STATE == "NOSTATE" and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= 1 then
		group = eventTable.group
		Agent.joinGroup(group)
		baseID = group
		say("Miner #" ..ID .. " assigned to " .. group)
		STATE = "idle"
	end
	if sourceID ~= ID and eventTable.group == group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
		if eventDescription == "dockingAccepted" then
			if M == 1 then
				oreStorage = 0
				energy = MaxEnergy
				if eventTable.extraOre ~= 0 then -- this means that the base is now full so go find new base
					oreStorage = eventTable.extraOre
					STATE = "findNewBase"
				end
			elseif M == 0 then
				oreStorage = 0
				energy = MaxEnergy
				if eventTable.extraOre ~= 0 then -- this means that the base is now full so go find new base
					oreStorage = eventTable.extraOre
					STATE = "baseDone"
				end
			end

		elseif eventDescription == "dockingRefused" then
				energy = MaxEnergy
				if M == 1 then
					STATE = "findNewBase"
				elseif M == 0 then
					STATE = "baseDone"
				end

		elseif eventDescription == "taskOffer" and STATE ~= "waitForObjective" and #memory ~= S then
			Event.emit{targetID=sourceID, speed=5000, description="taskResponse", table={capacity=S-#memory, group=group}}--(W-oreStorage)}}--, minDist=minDistance}}
			energy = energy - 1
			LATCHED_STATE = STATE
			stepCounter = 0
			STATE = "waitForObjective"

		elseif eventDescription == "taskObjective" and STATE == "waitForObjective" then
			ores = eventTable.ores
			local i = 1
			while #memory < S do
				if i > #ores then
					break
				end
				table.insert(memory, {x=ores[i].x, y=ores[i].y})
				i = i+1
			end

			STATE = LATCHED_STATE

		end
	elseif M == 1 and sourceID ~= ID and eventTable.group ~= group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
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
			Agent.changeColor({r=0, g=128, b=255})



		elseif eventDescription == "lookingForNewBase" and lookingForNewBase == false then
			Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group, baseID=baseID, basePos={x=memory[1].x, y=memory[1].y}}}
			energy = energy - 1
		end
	end
end

function takeStep()
	t = t + 1
	if t == T then
		timeOut = true
		STATE = "moveToBase"
	end
	--say("ID: " .. ID .. " STATE: " .. STATE .. " Latched State: " .. LATCHED_STATE)

	if STATE == "idle" then
		if #memory > 1  and energy == MaxEnergy then
			STATE = "moveToOre"
		else
			deloadAndRefill()
		end

	elseif STATE == "moveToOre" then

		if closestIndex == nil then
			closestIndex = findClosestOreIndex()
			oreX = memory[closestIndex].x
			oreY = memory[closestIndex].y
		end

		moveTo(oreX, oreY)
		if atPos(oreX, oreY) then
			if atOre() then
				table.remove(memory, closestIndex)
				STATE = "pickUpOre"
			elseif not atOre() then
				table.remove(memory, closestIndex)
				if #memory == 1 then
					STATE = "moveToBase"
				end
			end
			closestIndex = nil
		end

	elseif STATE == "pickUpOre" then
		mineOre()
		if oreStorage < W and #memory > 1 then
			STATE = "moveToOre"
		elseif oreStorage == W or #memory == 1 then
			STATE = "moveToBase"
		end

	elseif STATE == "moveToBase" then
		if not atBase() then
			moveTo(memory[1].x, memory[1].y)
		elseif atBase() and timeOut == true then
			STATE = "baseDone"
		else
			deloadAndRefill()
			STATE = "idle"
		end

	elseif STATE == "waitForObjective" then
		stepCounter = stepCounter + 1
		if stepCounter >= 4 then
			STATE = LATCHED_STATE
		end

	elseif STATE == "findNewBase" then
		lookingForNewBase = true
		moveTo(destX, destY)
		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		if stepCounterTwo >= P then--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
			STATE = "callForAgents"
		end
		if searchTimeCounter >= G then
			timeOut = true
			STATE = "moveToBase"
		end
		searchTimeCounter = searchTimeCounter + 1
		stepCounterTwo = stepCounterTwo + 1
	elseif STATE == "callForAgents" then
		Event.emit{speed=5000, description="lookingForNewBase", table={group=group}}
		energy = energy - 1
		STATE = "findNewBase"
		stepCounterTwo = 0

	elseif STATE == "baseDone" then
			-- BASE IS FULL SO STAY IN BASE
		if dataSent == true then

    else
			--say(totalOresCollected .. " " .. totalEnergyUsed)
			Event.emit{targetID=2, speed=5000, description="dataFromTransporter", table={oresCollected=totalOresCollected, energyUsed=totalEnergyUsed}}
			dataSent = true
		end
	end

	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "pickUpOre" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy <= 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,0,0})
	end
end

function mineOre()
	l_modifyMap(PositionX,PositionY, 0, 0, 0)
	oreStorage = oreStorage + 1
	energy = energy - 1
	totalOresCollected = totalOresCollected + 1
end

function findClosestOreIndex()
	local dist = ENV_WIDTH*1.5
	local closest = 1

	for i=2, #memory do
		local tempDist = torusModul.distanceToAgent(PositionX, PositionY, memory[i].x, memory[i].y)
		if tempDist < dist then
			dist = tempDist
			closest = i
		end
	end

	return closest
end

function distToBase()
	return torusModul.distanceToAgent(PositionX, PositionY, memory[1].x, memory[1].y)
end

function atOre()
	local r,g,b = l_checkMap(PositionX,PositionY)
	return (r == ore_color[1] and g == ore_color[2] and b == ore_color[3])
end

function atBase()
	if (PositionX==memory[1].x and PositionY==memory[1].y) then
		return true
	elseif distToBase() <= 2 then
		Collision.updatePosition(memory[1].x,memory[1].y)
		return true
	else
		return false
	end
end

function atPos(x, y)
	return PositionX==x and PositionY==y
end

function deloadAndRefill()
	Event.emit{targetID=baseID, speed=5000, description="dockingRequest", table={oreCount=oreStorage, usedEnergy=MaxEnergy-energy,group=group}}
	totalEnergyUsed = totalEnergyUsed + (MaxEnergy-energy)
end

function colorGround() --NOT WORKING ATM
	local color = Map.checkColor(PositionX,PositionY)
	local newC = color[2] + 10
	if newC < 255 then
		l_modifyMap(PositionX,PositionY, color[1], newC, color[3])
	end
end

function moveTo(x,y)
	--colorGround()
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	energy = energy - Q
end

function completed()
	STATE = "moveToBase"
	complete = true
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
