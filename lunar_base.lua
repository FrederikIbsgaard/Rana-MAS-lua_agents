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
local neededOre, group, STATE, mode, newBase, I, full

function initializeAgent()
    local parameters = Shared.getTable("parameters")
    neededOre = parameters.C
    I = parameters.I
    mode = parameters.M
    group = ID
    newBase = {}
    full = false
    STATE = "idle"

end
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
    if sourceID ~= ID and eventTable.group == group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
        say("BASE event own group: " .. eventDescription)
        if eventDescription == "dockingRequest" then
            globallyUsedEnergy = globallyUsedEnergy + eventTable.usedEnergy

            if collectedOre >= neededOre then
                Event.emit{targetID=sourceID, speed=5000, description="dockingRefused",table={group=group}}
            elseif collectedOre <= neededOre then --elseif collectedOre+eventTable.oreCount <= neededOre then
                collectedOre = collectedOre + eventTable.oreCount
                Event.emit{targetID=sourceID, speed=5000, description="dockingAccepted", table={group=group,basePos={x=PositionX, y=PositionY}}}
            end

        --elseif eventDescription == "changebase" then
        --    Event.emit{targetID=sourceID, speed=5000, description="dockingAccepted",table={group=group,basePos={x=PositionX, y=PositionY}}}

            --table.insert(newBase, {id=eventTable.id,x=eventTable.x,y=eventTable.y})
            --say("New base found")
            --STATE = "newBaseFound"
        end
    elseif sourceID ~= ID and eventTable.group ~= group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
      say("BASE event other group: " .. eventDescription)
      if eventDescription == "lookingForNewBase" then
        Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group, baseID=ID, basePos={x=PositionX, y=PositionY}}}
      end
    end

end

function takeStep()
    --say("BASE: " .. STATE)
    if STATE == "idle" then
        Event.emit{speed=5000, description="AcceptGroup", table={group=ID}}
        --STATE = "wait"
        STEP_RESOLUTION = 5 -- runs takeStep every 5 steps
    --elseif STATE == "wait" then
    --    if mode then
    --        Event.emit{targetGroup=group, speed=0, description="baseHere",table={group=group}}
    --    end
        --if collectedOre >= neededOre then
        --    full = true
        --    if not(mode) then
        --        Event.emit{targetGroup=group, speed=0, description="allOreCollected",table={group=group}}
        --        say(ID.." All ore collected returning agents")
        --
        --        --STATE = "complete"
        --    elseif mode then
        --        STATE = "findNewBase"
        --    end
        --end
    --elseif STATE == "findNewBase" then
        --Event.emit{targetGroup=group, speed=0, description="findNearestBase",table={group=group}}
    --elseif STATE == "newBaseFound" then
    --    Event.emit{targetGroup=group, speed=0, description="changeBaseTo", table={id=newBase[1].id,x=newBase[1].x,y=newBase[1].y,group=group}}
        STATE = "done"
    elseif STATE == "done" then

    end
end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
  say("Number of collected Ore: " .. collectedOre)
  say("Total Energy Consumption: " .. globallyUsedEnergy)
end
