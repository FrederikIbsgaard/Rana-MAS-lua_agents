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
local group, oreStorage, MaxEnergy, energy, W, P, S, I, Q, ore_color
local STATE = "idle"
local baseID

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
	group = 2
	Agent.joinGroup(group) -- transporter
	baseID = 2

	local color = Shared.getTable("miner_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})
	--Collision.updatePosition(100, 100)
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
  if eventDescription == "dockingAccepted" then
    oreStorage = 0
		energy = MaxEnergy

	elseif eventDescription == "taskOffer" then
		minDist = 0
		if #memory > 1 then
			idx = findClosestOreIndex()
			minDistance = torusModul.distanceToAgent(PositionX, PositionY, memory[idx].x, memory[idx].y)
		end
		Event.emit{targetID=sourceID, speed=5000, description="taskResponse", table={capacity=(W-#memory+1), minDist=minDistance}}

	elseif eventDescription == "taskObjective" then
		ores = eventTable.ores
		for i=1, #ores do
			table.insert(memory, {x=ores[i].x, y=ores[i].y})
		end
	end
end

function takeStep()

	if STATE == "idle" then
		if #memory > 1  and energy == MaxEnergy then
			STATE = "moveToOre"
		end

	elseif STATE == "moveToOre" then
		local closestIndex = findClosestOreIndex()
		local oreX = memory[closestIndex].x
		local oreY = memory[closestIndex].y

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
		end

	elseif STATE == "pickUpOre" then
		mineOre()
		if not oreStorage == W and #memory > 1 then
			STATE = "moveToOre"
		elseif oreStorage == W or #memory == 1 then
			STATE = "moveToBase"
		end

	elseif STATE == "moveToBase" then
		if not atBase() then
			moveTo(memory[1].x, memory[1].y)
		else
			deloadAndRefill()
			STATE = "idle"
		end
	end

	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "pickUpOre" or STATE == "idle") then
		STATE = "moveToBase"
	end
end

function mineOre()
	l_modifyMap(PositionX,PositionY, 0, 0, 0)
	oreStorage = oreStorage + 1
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
	return PositionX==memory[1].x and PositionY==memory[1].y
end

function atPos(x, y)
	return PositionX==x and PositionY==y
end

function deloadAndRefill()
	Event.emit{targetID=baseID, speed=5000, description="dockingRequest", table={oreCount=oreStorage, usedEnergy=MaxEnergy-energy}}
end

function moveTo(x,y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	energy = energy -1
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
