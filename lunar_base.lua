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
local globallyUsedEnergy = 0
local collectedOre = 0
local neededOre, group, STATE, T, M, newBase, I, full
local timeCounter = 0
local dataSent = false

function initializeAgent()
    local parameters = Shared.getTable("parameters")
    neededOre = parameters.C
    I = parameters.I
    M = parameters.M
    T = parameters.T
    group = ID
    newBase = {}
    full = false
    STATE = "idle"

end
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
    if sourceID ~= ID and eventTable.group == group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
        --say("BASE event own group: " .. eventDescription)
        if eventDescription == "dockingRequest" then
            globallyUsedEnergy = globallyUsedEnergy + eventTable.usedEnergy
            if collectedOre >= neededOre then
                Event.emit{targetID=sourceID, speed=5000, description="dockingRefused",table={group=group}}
            elseif collectedOre + eventTable.oreCount < neededOre then
                collectedOre = collectedOre + eventTable.oreCount
                Event.emit{targetID=sourceID, speed=5000, description="dockingAccepted", table={group=group,basePos={x=PositionX, y=PositionY}, extraOre=0}}
            elseif collectedOre + eventTable.oreCount >= neededOre then
                collectedOre = neededOre
                Event.emit{targetID=sourceID, speed=5000, description="dockingAccepted", table={group=group,basePos={x=PositionX, y=PositionY}, extraOre=(collectedOre+eventTable.oreCount-neededOre)}}
            end
        end
    elseif M == 1 and sourceID ~= ID and eventTable.group ~= group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
      --say("BASE event other group: " .. eventDescription)
      if eventDescription == "lookingForNewBase" and collectedOre < neededOre then
        Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group, baseID=ID, basePos={x=PositionX, y=PositionY}}}
      end
    end

end

function takeStep()
    --say("BASE: " .. STATE)
    timeCounter = timeCounter + 1
    if STATE == "idle" then
        Event.emit{speed=5000, description="AcceptGroup", table={group=ID}}
        STEP_RESOLUTION = 5 -- runs takeStep every 5 steps
        STATE = "operation"
    elseif STATE == "operation" then
        if collectedOre >= neededOre or timeCounter == T then
            Agent.changeColor({r=255, g=255, b=255})
            --say("Base ID: " .. ID .. " Done")
            STATE = "done"
        end
    elseif STATE == "done" then
      if dataSent == true then

      else
        --say("Base " .. collectedOre .. " " .. globallyUsedEnergy)
        Event.emit{targetID=2, speed=5000, description="dataFromBase", table={oresCollected=collectedOre, energyUsed=globallyUsedEnergy}}
        dataSent = true
      end
    end
end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
  say("Base ID: " .. ID .. " Number of collected Ore: " .. collectedOre .. " Total Energy Consumption: " .. globallyUsedEnergy)
end
