-- Import Rana lua modules.
Event = require "ranalib_event"
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Agent = require "ranalib_agent"
Map = require "ranalib_map"

function initializeAgent()
	say("Agent #: " .. ID .. " has been initialized")
	GridMove = true
	Agent.changeColor{r=0, g=255, b=0}
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

	if eventDescription == "attack" then
		say("Prey: "..ID .." was attacked by Predator: "..sourceID .."")
		--Event.emit{targetGroup=Prey, speed=343, description="warning cry"}
		Agent.removeAgent(ID)

	elseif eventDescription == "warning cry" then
		say("Agent: "..ID.." received a warning cry from agent: ".. sourceID)
		Speed = 5
	end
end

function takeStep()
	if not Moving then
		--Move.toRandom()
		Move.byAngle(Stat.randomInteger(0,360))
		Speed = 1
	end
	if Stat.randomInteger(1,10000) == 1 then
		Speed = 0
		Moving = false
  end
end

function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
