-- Import Rana lua libraries
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Map = require "ranalib_map"
Shared = require "ranalib_shared"

-- amount of bases
N = 3
-- density of ore [procentage]
D = 0.05
--D = 0.05
-- base capacity of ore
C = 100
-- energi for robots [units]
E = 1000
-- grid size
G = ENV_WIDTH
-- fixed communication scope
I = 10
--I = 20
-- coordination mode, cooperative = 1 or competitive 0
M = 1
-- initial perception scope
P = 10
--P = 10
-- cost of motion
Q = 1
-- Max number of cycles
T = 3000
-- max number of ore a miner can carry
W = 1
--W = 20
-- number of explores
--X = Shared.getNumber(2)
X = 10
-- number of miners
--Y = Shared.getNumber(3)
Y = 10
-- memory size of robots
--S = X+Y-1
S = 19
-- VARIABLES
background_color = {0,0,0}
ore_color = {139,69,19}
explorer_color = {0,255,0}
miner_color = {0,0,255}

numberOfIterations = 10

function initializeAgent()
    --StepMultiple = 1000
    say("Master Agent#: " .. ID .. " has been initialized")
    local parameters = {numberOfIterations=numberOfIterations, N=N, D=D, C=C, E=E, G=G, I=I, M=M, P=P, Q=Q, S=S, T=T, W=W, X=X, Y=Y}
    Shared.storeTable("background_color", background_color)
    Shared.storeTable("ore_color", ore_color)
    Shared.storeTable("explorer_color", explorer_color)
    Shared.storeTable("miner_color", miner_color)

    Shared.storeTable("parameters", parameters)

    for i=0, ENV_WIDTH do
        for j=0, ENV_HEIGHT do
            Map.modifyColor(i,j, background_color)
        end
    end
    local amountOfOre = (G*G)*D
    say("amount of ore: ".. amountOfOre)
    for i=1, amountOfOre do
        local placed = false
        while not placed do
            x = Stat.randomInteger(0,ENV_WIDTH)
            y = Stat.randomInteger(0,ENV_WIDTH)
            local color = Map.checkColor(x,y)
            if color[1] == 0 and color[2] == 0 and color[3] == 0 then
                Map.modifyColor(x,y, ore_color)
                placed = true
            end

        end

    end
    say("Map has been initialized")

    local data_table = {}
	  local ids = {}
    local ID = Agent.addAgent("lunar_dataCollector.lua",0,0)
    table.insert(ids, ID)
    data_table[ID] = {call_amount = 0}

    local baseCordinates = {}
    for i = 1, N do
        local placed = false
        while not placed do
            x = Stat.randomInteger(0,ENV_WIDTH)
            y = Stat.randomInteger(0,ENV_WIDTH)
            local color = Map.checkColor(x,y)
            if color[1] == 0 and color[2] == 0 and color[3] == 0 then
                local ID = Agent.addAgent("lunar_base.lua",x,y)
                table.insert(ids, ID)
                data_table[ID] = {call_amount = 0}
                table.insert(baseCordinates, {x,y})
                placed = true
                for i=1,X do
                    local ID = Agent.addAgent("lunar_explorer.lua",x,y)
                    table.insert(ids, ID)
                    data_table[ID] = {call_amount = 0}
                end
                -- gave each base miners
                for i=1,Y do
                    local ID = Agent.addAgent("lunar_miner.lua",x,y)
                    table.insert(ids, ID)
                    data_table[ID] = {call_amount = 0}
                end
            end
        end
    end

    say("All agents initialized")

end

function takeStep()
	Agent.removeAgent(ID)

    say("Master agent removed")
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
