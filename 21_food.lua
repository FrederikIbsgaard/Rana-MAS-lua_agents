
local Event = require "ranalib_event"
local Collision = require "ranalib_collision"
local Agent = require "ranalib_agent"
local Shared = require "ranalib_shared"



function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)


end

function initializeAgent()

    local color = Shared.getTable("food_color")
    Agent.changeColor{r=color[1], g=color[2], b=color[3]}


end

function takeStep()

end



function cleanUp()

end
