Event	= require "ranalib_event"
Core	= require "ranalib_core"
Stat	= require "ranalib_statistic"
Shared 	= require "ranalib_shared"
Utility = require "ranalib_utility"
Agent = require "ranalib_agent"

local baseDataTable = {} -- type, id, ores, energy
local transporterDataTable = {}
local explorerDataTable = {}

local C, D, E, G, I, M, N, P, Q, S, T, W, X, Y, T

function initializeAgent()
  local parameters = Shared.getTable("parameters")
  C = parameters.C
  D = parameters.D
  E = parameters.E
  G = parameters.G
  I = parameters.I
  M = parameters.M
  N = parameters.N
  P = parameters.P
  Q = parameters.Q
  S = parameters.S
  T = parameters.T
  W = parameters.W
  X = parameters.X
  Y = parameters.Y
  Agent.changeColor({r=0, g=0, b=0})
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

  if eventDescription == "dataFromBase" then
    table.insert(baseDataTable, {id=sourceID, ores=eventTable.oresCollected, energy=eventTable.energyUsed})

  elseif eventDescription == "dataFromTransporter" then
    table.insert(transporterDataTable, {id=sourceID, ores=eventTable.oresCollected, energy=eventTable.energyUsed})

  elseif eventDescription == "dataFromExplorer" then
    table.insert(explorerDataTable, {id=sourceID, ores=eventTable.oresCollected, energy=eventTable.energyUsed})
  end

end

function cleanUp()
  file = io.open("MAS_X_Y_P_I_E_S_W_".. X .. "_" .. Y .. "_" .. P .. "_" .. I .. "_" .. E .. "_" .. S .. "_" .. W .. ".csv", "w")
  file:write("Variables,"..C..","..D..","..E..","..G..","..I..","..M..","..N..","..P..","..Q..","..S..","..T..","..P..","..X..","..Y..","..T.."\n")
  for i=1,#baseDataTable do
    file:write("base,"..baseDataTable[i].id..","..baseDataTable[i].ores..","..baseDataTable[i].energy.."\n")
  end
  for i=1,#transporterDataTable do
    file:write("transporter,"..transporterDataTable[i].id..","..transporterDataTable[i].ores..","..transporterDataTable[i].energy.."\n")
  end
  for i=1,#explorerDataTable do
    file:write("explorer,"..explorerDataTable[i].id..","..explorerDataTable[i].ores..","..explorerDataTable[i].energy.."\n")
  end
  file:close()
end
