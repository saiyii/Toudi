-- ubundows_78 on dc

local TILE_SIZE = 32
local TEX_SIZE = 16
local TILE_SCALE = TILE_SIZE / TEX_SIZE
local CHUNK_SIZE = 64

local TILE_AIR = 0
local TILE_GRASS_DIRT = 1
local TILE_DIRT = 2
local TILE_STONE = 3
local TILE_BEDROCK = 4
local TILE_WOOD = 5
local TILE_LEAVES = 6
local TILE_PLANKS = 7
local TILE_STICK = 8
local TILE_CRAFTING_TABLE = 9
local TILE_CHEST = 10
local TILE_FURNACE = 11
local TILE_WOOD_SLAB = 12
local TILE_STONE_BRICK = 13
local TILE_DIRT_BRICK = 14
local TILE_WOOD_WALL = 15
local TILE_STONE_WALL = 16
local TILE_LADDER = 17
local TILE_DOOR = 18
local TILE_TORCH = 19
local TILE_GLASS = 20
local TILE_MOSSY_STONE = 21
local TILE_DARK_PLANKS = 22
local TILE_LIGHT_PLANKS = 23
local TILE_PATH = 24
local TILE_BRICK_RED = 25
local TILE_ROCK = 26
local ITEM_FOOD = 27

local SURFACE_BASE = 14
local SURFACE_VARIATION = 7
local BEDROCK_Y = 90
local REACH_TILES = 5
local REACH_PX = REACH_TILES * TILE_SIZE
local ATTACK_RANGE = 70
local ATTACK_COOLDOWN = 0.22
local ATTACK_DAMAGE = 12

local worldSeed = 0
local editedTiles = {}
local surfaceCache = {}
local textures = {}
local chunks = {}

local camera = { x = 0, y = 0 }

local player = {
    x = 100,
    y = 120,
    w = 28,
    h = 44,
    speed = 220,
    vx = 0,
    vy = 0,
    gravity = 1800,
    jumpForce = 620,
    onGround = false,
    maxHp = 100,
    hp = 100,
    maxHunger = 100,
    hunger = 100,
    invuln = 0,
    attackTimer = 0
}

local jumpBufferTime = 0.12
local coyoteTime = 0.10
local jumpBufferTimer = 0
local coyoteTimer = 0

local breakState = {
    active = false,
    tx = 0,
    ty = 0,
    timer = 0,
    duration = 0
}

local mobs = {}
local mobTextures = {}
local mobSpawnTimer = 0
local MAX_FRIENDLY = 6
local MAX_HOSTILE = 5

local FOOD_HUNGER = 28
local FOOD_HEAL = 6
local FRIENDLY_GIFT_AMOUNT = 1
local FRIENDLY_DROP_AMOUNT = 1
local HOSTILE_DROP_AMOUNT = 2

local controls = {
    layout = "azerty" -- "azerty" or "qwerty"
}

local inventory = {
    [TILE_DIRT] = 0,
    [TILE_STONE] = 0,
    [TILE_WOOD] = 0,
    [TILE_LEAVES] = 0,
    [TILE_PLANKS] = 0,
    [TILE_STICK] = 0,
    [TILE_CRAFTING_TABLE] = 0,
    [TILE_CHEST] = 0,
    [TILE_FURNACE] = 0,
    [TILE_WOOD_SLAB] = 0,
    [TILE_STONE_BRICK] = 0,
    [TILE_DIRT_BRICK] = 0,
    [TILE_WOOD_WALL] = 0,
    [TILE_STONE_WALL] = 0,
    [TILE_LADDER] = 0,
    [TILE_DOOR] = 0,
    [TILE_TORCH] = 0,
    [TILE_GLASS] = 0,
    [TILE_MOSSY_STONE] = 0,
    [TILE_DARK_PLANKS] = 0,
    [TILE_LIGHT_PLANKS] = 0,
    [TILE_PATH] = 0,
    [TILE_BRICK_RED] = 0,
    [TILE_ROCK] = 0,
    [ITEM_FOOD] = 0
}

local hotbar = {
    TILE_DIRT,
    TILE_STONE,
    TILE_WOOD,
    TILE_PLANKS,
    TILE_STICK,
    TILE_WOOD_SLAB,
    TILE_STONE_BRICK,
    TILE_DIRT_BRICK,
    TILE_LADDER
}

local selectedSlot = 1
local inventoryOpen = false

local inventoryOrder = {
    TILE_DIRT,
    TILE_STONE,
    TILE_WOOD,
    TILE_LEAVES,
    TILE_PLANKS,
    TILE_STICK,
    TILE_CRAFTING_TABLE,
    TILE_CHEST,
    TILE_FURNACE,
    TILE_WOOD_SLAB,
    TILE_STONE_BRICK,
    TILE_DIRT_BRICK,
    TILE_WOOD_WALL,
    TILE_STONE_WALL,
    TILE_LADDER,
    TILE_DOOR,
    TILE_TORCH,
    TILE_GLASS,
    TILE_MOSSY_STONE,
    TILE_DARK_PLANKS,
    TILE_LIGHT_PLANKS,
    TILE_PATH,
    TILE_BRICK_RED,
    TILE_ROCK,
    ITEM_FOOD
}

local craftingOpen = false
local craftingGrid = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
local craftingResult = nil

local function isJumpKey(key)
    if key == "space" or key == "up" then return true end
    if controls.layout == "azerty" then
        return key == "z"
    else
        return key == "w"
    end
end

local function isLeftDown()
    if love.keyboard.isDown("left") then return true end
    if controls.layout == "azerty" then
        return love.keyboard.isDown("q")
    else
        return love.keyboard.isDown("a")
    end
end

local function isRightDown()
    return love.keyboard.isDown("right") or love.keyboard.isDown("d")
end

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function tileKey(tx, ty)
    return tx .. ":" .. ty
end

local function chunkKey(cx, cy)
    return cx .. ":" .. cy
end

local function worldToTileX(px)
    return math.floor(px / TILE_SIZE) + 1
end

local function worldToTileY(py)
    return math.floor(py / TILE_SIZE) + 1
end

local function tileCenter(tx, ty)
    return (tx - 0.5) * TILE_SIZE, (ty - 0.5) * TILE_SIZE
end

local function playerCenter()
    return player.x + player.w * 0.5, player.y + player.h * 0.5
end

local function inReach(tx, ty)
    local cx, cy = tileCenter(tx, ty)
    local px, py = playerCenter()
    local dx = cx - px
    local dy = cy - py
    return (dx * dx + dy * dy) <= (REACH_PX * REACH_PX)
end

local function checkCollision(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

local function addItem(tile, amount)
    local count = inventory[tile]
    if count == nil then return end
    inventory[tile] = count + amount
end

local function canSpend(tile, amount)
    local count = inventory[tile]
    if count == nil then return false end
    return count >= amount
end

local function spendItem(tile, amount)
    if canSpend(tile, amount) then
        inventory[tile] = inventory[tile] - amount
        return true
    end
    return false
end

local function tileToItem(tile)
    if tile == TILE_GRASS_DIRT then
        return TILE_DIRT
    end
    if inventory[tile] ~= nil then
        return tile
    end
    return nil
end

local function isPlaceable(tile)
    return tile ~= ITEM_FOOD
end

local function matchesPattern(grid, pattern)
    for i = 1, 9 do
        if grid[i] ~= pattern[i] then
            return false
        end
    end
    return true
end

local I = {
    D = TILE_DIRT,
    S = TILE_STONE,
    W = TILE_WOOD,
    P = TILE_PLANKS,
    L = TILE_LEAVES,
    K = TILE_STICK
}

local recipes = {
    { pattern = {0,0,0,0,I.W,0,0,0,0}, output = TILE_PLANKS, count = 4 },
    { pattern = {0,I.P,0,0,I.P,0,0,0,0}, output = TILE_STICK, count = 4 },
    { pattern = {I.P,I.P,0,I.P,I.P,0,0,0,0}, output = TILE_CRAFTING_TABLE, count = 1 },
    { pattern = {I.P,I.P,I.P,I.P,0,I.P,I.P,I.P,I.P}, output = TILE_CHEST, count = 1 },
    { pattern = {I.S,I.S,I.S,I.S,0,I.S,I.S,I.S,I.S}, output = TILE_FURNACE, count = 1 },
    { pattern = {I.P,I.P,I.P,0,0,0,0,0,0}, output = TILE_WOOD_SLAB, count = 6 },
    { pattern = {I.S,I.S,I.S,0,0,0,0,0,0}, output = TILE_STONE_BRICK, count = 4 },
    { pattern = {I.D,I.D,0,I.D,I.D,0,0,0,0}, output = TILE_DIRT_BRICK, count = 4 },
    { pattern = {I.W,I.W,0,I.W,I.W,0,0,0,0}, output = TILE_WOOD_WALL, count = 4 },
    { pattern = {I.S,I.S,0,I.S,I.S,0,0,0,0}, output = TILE_STONE_WALL, count = 4 },
    { pattern = {0,I.K,0,0,I.K,0,0,I.K,0}, output = TILE_LADDER, count = 3 },
    { pattern = {0,I.P,0,0,I.P,0,0,I.P,0}, output = TILE_DOOR, count = 3 },
    { pattern = {0,I.W,0,0,I.K,0,0,0,0}, output = TILE_TORCH, count = 4 },
    { pattern = {I.S,0,I.S,0,I.K,0,I.S,0,I.S}, output = TILE_GLASS, count = 2 },
    { pattern = {I.S,0,I.S,0,I.D,0,I.S,0,I.S}, output = TILE_MOSSY_STONE, count = 4 },
    { pattern = {I.P,0,0,I.P,0,0,I.P,0,0}, output = TILE_DARK_PLANKS, count = 6 },
    { pattern = {0,0,I.P,0,0,I.P,0,0,I.P}, output = TILE_LIGHT_PLANKS, count = 6 },
    { pattern = {I.D,I.D,I.D,0,0,0,0,0,0}, output = TILE_PATH, count = 6 },
    { pattern = {I.D,0,I.D,0,I.D,0,I.D,0,I.D}, output = TILE_BRICK_RED, count = 4 },
    { pattern = {0,I.S,0,I.S,0,I.S,0,I.S,0}, output = TILE_ROCK, count = 4 }
}

local function updateCraftingResult()
    for _, r in ipairs(recipes) do
        if matchesPattern(craftingGrid, r.pattern) then
            craftingResult = { tile = r.output, count = r.count }
            return
        end
    end
    craftingResult = nil
end

local function clearCraftingGrid()
    for i = 1, 9 do
        if craftingGrid[i] ~= 0 then
            addItem(craftingGrid[i], 1)
            craftingGrid[i] = 0
        end
    end
    craftingResult = nil
end

local function setCraftingOpen(open)
    if craftingOpen and not open then
        clearCraftingGrid()
    end
    craftingOpen = open
end

local function getCraftingUI()
    local sw, sh = love.graphics.getDimensions()
    local slot = 32
    local gap = 6
    local gridW = slot * 3 + gap * 2
    local gridH = slot * 3 + gap * 2
    local panelW, panelH = gridW + slot + 80, gridH + 70
    local px = math.floor((sw - panelW) / 2)
    local py = math.floor((sh - panelH) / 2)
    local gridX = px + 20
    local gridY = py + 40
    local outX = gridX + gridW + 30
    local outY = gridY + math.floor((gridH - slot) / 2)

    return {
        x = px,
        y = py,
        w = panelW,
        h = panelH,
        slot = slot,
        gap = gap,
        gridX = gridX,
        gridY = gridY,
        outX = outX,
        outY = outY
    }
end

local function getInventoryUI()
    local sw, sh = love.graphics.getDimensions()
    local slot = 32
    local gap = 6
    local cols = 9
    local rows = 3
    local gridW = cols * slot + (cols - 1) * gap
    local gridH = rows * slot + (rows - 1) * gap
    local panelW = gridW + 40
    local panelH = gridH + slot + 90
    local px = math.floor((sw - panelW) / 2)
    local py = math.floor((sh - panelH) / 2)
    local gridX = px + 20
    local gridY = py + 40
    local hotbarY = gridY + gridH + 22

    return {
        x = px,
        y = py,
        w = panelW,
        h = panelH,
        slot = slot,
        gap = gap,
        cols = cols,
        rows = rows,
        gridX = gridX,
        gridY = gridY,
        hotbarY = hotbarY
    }
end

local function inventoryHit(mx, my)
    local ui = getInventoryUI()
    for i = 1, ui.cols * ui.rows do
        local row = math.floor((i - 1) / ui.cols)
        local col = (i - 1) % ui.cols
        local x = ui.gridX + col * (ui.slot + ui.gap)
        local y = ui.gridY + row * (ui.slot + ui.gap)
        if mx >= x and mx <= x + ui.slot and my >= y and my <= y + ui.slot then
            return { kind = "grid", index = i }
        end
    end
    for i = 1, #hotbar do
        local x = ui.gridX + (i - 1) * (ui.slot + ui.gap)
        local y = ui.hotbarY
        if mx >= x and mx <= x + ui.slot and my >= y and my <= y + ui.slot then
            return { kind = "hotbar", index = i }
        end
    end
    return nil
end

local function craftingSlotAt(mx, my)
    local ui = getCraftingUI()
    for row = 0, 2 do
        for col = 0, 2 do
            local x = ui.gridX + col * (ui.slot + ui.gap)
            local y = ui.gridY + row * (ui.slot + ui.gap)
            if mx >= x and mx <= x + ui.slot and my >= y and my <= y + ui.slot then
                return row * 3 + col + 1
            end
        end
    end

    if mx >= ui.outX and mx <= ui.outX + ui.slot and my >= ui.outY and my <= ui.outY + ui.slot then
        return "output"
    end

    return nil
end

local function getSurfaceY(tx)
    local cached = surfaceCache[tx]
    if cached then
        return cached
    end
    local n = love.math.noise(tx * 0.035, worldSeed)
    local sy = SURFACE_BASE + math.floor((n - 0.5) * SURFACE_VARIATION)
    surfaceCache[tx] = sy
    return sy
end

local function getBaseTile(tx, ty)
    if ty <= 0 then
        return TILE_AIR
    end

    local surface = getSurfaceY(tx)
    if ty >= BEDROCK_Y then
        return TILE_BEDROCK
    end
    if ty < surface then
        return TILE_AIR
    end
    if ty == surface then
        return TILE_GRASS_DIRT
    end
    if ty == surface + 1 then
        return (love.math.noise(tx * 0.27, ty * 0.27, worldSeed) < 0.82) and TILE_DIRT or TILE_STONE
    end
    if ty == surface + 2 then
        return (love.math.noise(tx * 0.23, ty * 0.23, worldSeed + 11) < 0.35) and TILE_DIRT or TILE_STONE
    end

    return (love.math.noise(tx * 0.12, ty * 0.12, worldSeed + 37) < 0.08) and TILE_DIRT or TILE_STONE
end

local function getChunk(cx, cy)
    local key = chunkKey(cx, cy)
    local chunk = chunks[key]
    if chunk then
        return chunk
    end

    chunk = { tiles = {} }
    chunks[key] = chunk

    local startTx = cx * CHUNK_SIZE + 1
    local startTy = cy * CHUNK_SIZE + 1

    for ly = 0, CHUNK_SIZE - 1 do
        local ty = startTy + ly
        local row = {}
        for lx = 0, CHUNK_SIZE - 1 do
            local tx = startTx + lx
            row[lx + 1] = getBaseTile(tx, ty)
        end
        chunk.tiles[ly + 1] = row
    end

    return chunk
end

local function getChunkTile(tx, ty)
    if ty <= 0 then
        return TILE_AIR
    end
    local cx = math.floor((tx - 1) / CHUNK_SIZE)
    local cy = math.floor((ty - 1) / CHUNK_SIZE)
    local chunk = getChunk(cx, cy)
    local lx = (tx - 1) - cx * CHUNK_SIZE + 1
    local ly = (ty - 1) - cy * CHUNK_SIZE + 1
    return chunk.tiles[ly][lx]
end

local function isTreeAt(tx)
    local n = love.math.noise(tx * 0.08, worldSeed + 123)
    if n <= 0.82 then
        return false
    end
    local n2 = love.math.noise((tx - 3) * 0.08, worldSeed + 123)
    return n2 <= 0.82
end

local function treeHeight(tx)
    return 4 + math.floor(love.math.noise(tx * 0.2, worldSeed + 321) * 2)
end

local function getTreeTile(tx, ty)
    for ox = -2, 2 do
        local cx = tx - ox
        if isTreeAt(cx) then
            local surface = getSurfaceY(cx)
            local height = treeHeight(cx)
            local trunkTop = surface - height

            if tx == cx and ty <= surface - 1 and ty >= trunkTop then
                return TILE_WOOD
            end

            local leafTop = trunkTop - 1
            local leafBottom = trunkTop + 1
            if ty >= leafTop and ty <= leafBottom then
                local radius = 2 - math.abs(ty - trunkTop)
                if math.abs(tx - cx) <= radius then
                    return TILE_LEAVES
                end
            end

            if ty == trunkTop - 2 and math.abs(tx - cx) <= 1 then
                return TILE_LEAVES
            end
        end
    end
    return nil
end

local function getTile(tx, ty)
    local edited = editedTiles[tileKey(tx, ty)]
    if edited ~= nil then
        return edited
    end
    local base = getChunkTile(tx, ty)
    if base == TILE_AIR then
        local treeTile = getTreeTile(tx, ty)
        if treeTile then
            return treeTile
        end
    end
    return base
end

local function setTile(tx, ty, tileType)
    local key = tileKey(tx, ty)
    local base = getChunkTile(tx, ty)
    if tileType == TILE_AIR then
        local hasTree = getTreeTile(tx, ty) ~= nil
        if base == TILE_AIR and not hasTree then
            editedTiles[key] = nil
        else
            editedTiles[key] = TILE_AIR
        end
        return
    end

    if tileType == base then
        editedTiles[key] = nil
    else
        editedTiles[key] = tileType
    end
end

local function tileDurability(tile)
    if tile == TILE_DIRT or tile == TILE_GRASS_DIRT then
        return 0.35
    elseif tile == TILE_STONE then
        return 0.9
    elseif tile == TILE_WOOD then
        return 0.6
    elseif tile == TILE_LEAVES then
        return 0.2
    elseif tile == TILE_PLANKS or tile == TILE_WOOD_SLAB or tile == TILE_DARK_PLANKS or tile == TILE_LIGHT_PLANKS then
        return 0.45
    elseif tile == TILE_STICK or tile == TILE_LADDER or tile == TILE_TORCH then
        return 0.2
    elseif tile == TILE_CRAFTING_TABLE or tile == TILE_CHEST or tile == TILE_DOOR or tile == TILE_WOOD_WALL then
        return 0.55
    elseif tile == TILE_DIRT_BRICK or tile == TILE_PATH then
        return 0.5
    elseif tile == TILE_STONE_WALL then
        return 0.8
    elseif tile == TILE_STONE_BRICK or tile == TILE_MOSSY_STONE or tile == TILE_BRICK_RED or tile == TILE_ROCK or tile == TILE_FURNACE then
        return 1.0
    elseif tile == TILE_GLASS then
        return 0.25
    end
    return nil
end

local function saveWorld()
    local lines = {}
    for key, tile in pairs(editedTiles) do
        local tx, ty = key:match("(-?%d+):(-?%d+)")
        if tx and ty and tile ~= nil then
            lines[#lines + 1] = tx .. "," .. ty .. "," .. tostring(tile)
        end
    end
    love.filesystem.write("world_edits.txt", table.concat(lines, "\n"))
end

local function loadWorld()
    editedTiles = {}
    if not love.filesystem.getInfo("world_edits.txt") then
        return
    end
    for line in love.filesystem.lines("world_edits.txt") do
        local tx, ty, tile = line:match("(-?%d+),(-?%d+),(-?%d+)")
        if tx and ty and tile then
            editedTiles[tx .. ":" .. ty] = tonumber(tile)
        end
    end
end

local function isSolid(tile)
    if tile == TILE_AIR then return false end
    if tile == TILE_WOOD or tile == TILE_LEAVES then return false end
    return true
end

local function refreshGrass(tx, ty)
    local t = getTile(tx, ty)
    if t ~= TILE_DIRT and t ~= TILE_GRASS_DIRT then
        return
    end
    if getTile(tx, ty - 1) == TILE_AIR then
        setTile(tx, ty, TILE_GRASS_DIRT)
    else
        setTile(tx, ty, TILE_DIRT)
    end
end

local function makeTileTexture(tileType)
    local data = love.image.newImageData(TEX_SIZE, TEX_SIZE)

    for y = 0, TEX_SIZE - 1 do
        for x = 0, TEX_SIZE - 1 do
            local n = love.math.noise((x + tileType * 19) * 0.28, (y + tileType * 31) * 0.28, worldSeed)
            local r, g, b = 0, 0, 0
            local a = 1

            if tileType == TILE_STONE then
                r, g, b = 0.45, 0.45, 0.46
                local d = (n - 0.5) * 0.16
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_BEDROCK then
                r, g, b = 0.08, 0.08, 0.09
                local d = (n - 0.5) * 0.10
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_WOOD then
                r, g, b = 0.45, 0.30, 0.16
                local d = (n - 0.5) * 0.10
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_LEAVES then
                r, g, b = 0.18, 0.55, 0.20
                local d = (n - 0.5) * 0.18
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_PLANKS then
                r, g, b = 0.55, 0.38, 0.20
                local stripe = ((y + math.floor(n * 4)) % 4 == 0) and -0.08 or 0
                local d = (n - 0.5) * 0.10
                r, g, b = r + d + stripe, g + d + stripe, b + d + stripe
            elseif tileType == TILE_STICK then
                r, g, b = 0.56, 0.38, 0.18
                local d = (n - 0.5) * 0.08
                if x == 7 or x == 8 then
                    d = d + 0.10
                else
                    d = d - 0.05
                end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_CRAFTING_TABLE then
                r, g, b = 0.54, 0.36, 0.18
                local d = (n - 0.5) * 0.08
                local line = (x % 5 == 0) or (y % 5 == 0)
                if line then d = d - 0.08 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_CHEST then
                r, g, b = 0.50, 0.32, 0.16
                local d = (n - 0.5) * 0.08
                if x == 0 or y == 0 or x == TEX_SIZE - 1 or y == TEX_SIZE - 1 then
                    d = d - 0.12
                end
                if x >= 7 and x <= 8 and y >= 6 and y <= 9 then
                    r, g, b = 0.25, 0.20, 0.08
                else
                    r, g, b = r + d, g + d, b + d
                end
            elseif tileType == TILE_FURNACE then
                r, g, b = 0.36, 0.36, 0.38
                local d = (n - 0.5) * 0.10
                if x == 0 or y == 0 or x == TEX_SIZE - 1 or y == TEX_SIZE - 1 then
                    d = d - 0.12
                end
                if x >= 4 and x <= 11 and y >= 6 and y <= 11 then
                    d = d - 0.10
                end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_WOOD_SLAB then
                r, g, b = 0.50, 0.34, 0.18
                local stripe = ((y + math.floor(n * 5)) % 4 == 0) and -0.06 or 0
                local d = (n - 0.5) * 0.08
                r, g, b = r + d + stripe, g + d + stripe, b + d + stripe
            elseif tileType == TILE_STONE_BRICK then
                r, g, b = 0.52, 0.52, 0.54
                local d = (n - 0.5) * 0.10
                if x % 6 == 0 or y % 6 == 0 then d = d - 0.10 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_DIRT_BRICK then
                r, g, b = 0.46, 0.30, 0.14
                local d = (n - 0.5) * 0.10
                if x % 6 == 0 or y % 6 == 0 then d = d - 0.08 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_WOOD_WALL then
                r, g, b = 0.52, 0.36, 0.18
                local d = (n - 0.5) * 0.08
                if x % 4 == 0 then d = d - 0.06 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_STONE_WALL then
                r, g, b = 0.48, 0.48, 0.50
                local d = (n - 0.5) * 0.10
                if x % 4 == 0 or y % 4 == 0 then d = d - 0.08 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_LADDER then
                r, g, b = 0.56, 0.38, 0.20
                local d = (n - 0.5) * 0.08
                if x == 3 or x == 12 or y % 4 == 0 then d = d - 0.08 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_DOOR then
                r, g, b = 0.52, 0.34, 0.18
                local d = (n - 0.5) * 0.08
                if x % 5 == 0 then d = d - 0.08 end
                if x == 12 and y == 8 then
                    r, g, b = 0.70, 0.60, 0.30
                else
                    r, g, b = r + d, g + d, b + d
                end
            elseif tileType == TILE_TORCH then
                r, g, b = 0.46, 0.30, 0.16
                local d = (n - 0.5) * 0.10
                if x >= 7 and x <= 8 and y >= 4 and y <= 6 then
                    r, g, b = 0.95, 0.75, 0.20
                else
                    r, g, b = r + d, g + d, b + d
                end
            elseif tileType == TILE_GLASS then
                r, g, b = 0.60, 0.75, 0.85
                local d = (n - 0.5) * 0.08
                if (x + y) % 7 == 0 then d = d + 0.10 end
                r, g, b = r + d, g + d, b + d
                a = 0.55
            elseif tileType == TILE_MOSSY_STONE then
                r, g, b = 0.46, 0.46, 0.48
                local d = (n - 0.5) * 0.12
                if n > 0.6 then
                    g = g + 0.12
                end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_DARK_PLANKS then
                r, g, b = 0.40, 0.26, 0.12
                local stripe = ((y + math.floor(n * 4)) % 4 == 0) and -0.07 or 0
                local d = (n - 0.5) * 0.10
                r, g, b = r + d + stripe, g + d + stripe, b + d + stripe
            elseif tileType == TILE_LIGHT_PLANKS then
                r, g, b = 0.66, 0.50, 0.30
                local stripe = ((y + math.floor(n * 4)) % 4 == 0) and -0.06 or 0
                local d = (n - 0.5) * 0.08
                r, g, b = r + d + stripe, g + d + stripe, b + d + stripe
            elseif tileType == TILE_PATH then
                r, g, b = 0.52, 0.36, 0.16
                local d = (n - 0.5) * 0.10
                if y < 3 and n > 0.6 then
                    g = g + 0.06
                end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_BRICK_RED then
                r, g, b = 0.56, 0.18, 0.16
                local d = (n - 0.5) * 0.10
                if x % 6 == 0 or y % 6 == 0 then d = d - 0.10 end
                r, g, b = r + d, g + d, b + d
            elseif tileType == TILE_ROCK then
                r, g, b = 0.30, 0.30, 0.32
                local d = (n - 0.5) * 0.14
                r, g, b = r + d, g + d, b + d
            elseif tileType == ITEM_FOOD then
                r, g, b = 0.75, 0.12, 0.12
                local d = (n - 0.5) * 0.10
                local dx = x - 7.5
                local dy = y - 8.5
                local dist = dx * dx + dy * dy
                if dist > 46 then
                    r, g, b = 0.1, 0.1, 0.1
                else
                    r, g, b = r + d, g + d, b + d
                end
                if y <= 3 and x >= 6 and x <= 9 then
                    r, g, b = 0.12, 0.55, 0.18
                end
            else
                local grassTop = (tileType == TILE_GRASS_DIRT and y < 4)
                if grassTop then
                    r, g, b = 0.20, 0.62, 0.22
                    local d = (n - 0.5) * 0.18
                    r, g, b = r + d, g + d, b + d
                else
                    r, g, b = 0.45, 0.29, 0.11
                    local d = (n - 0.5) * 0.14
                    r, g, b = r + d, g + d, b + d
                end
            end

            data:setPixel(x, y, clamp01(r), clamp01(g), clamp01(b), a)
        end
    end

    local image = love.graphics.newImage(data)
    image:setFilter("nearest", "nearest")
    return image
end

local function buildTextures()
    local tiles = {
        TILE_DIRT,
        TILE_GRASS_DIRT,
        TILE_STONE,
        TILE_BEDROCK,
        TILE_WOOD,
        TILE_LEAVES,
        TILE_PLANKS,
        TILE_STICK,
        TILE_CRAFTING_TABLE,
        TILE_CHEST,
        TILE_FURNACE,
        TILE_WOOD_SLAB,
        TILE_STONE_BRICK,
        TILE_DIRT_BRICK,
        TILE_WOOD_WALL,
        TILE_STONE_WALL,
        TILE_LADDER,
        TILE_DOOR,
        TILE_TORCH,
        TILE_GLASS,
        TILE_MOSSY_STONE,
        TILE_DARK_PLANKS,
        TILE_LIGHT_PLANKS,
        TILE_PATH,
        TILE_BRICK_RED,
        TILE_ROCK,
        ITEM_FOOD
    }
    for _, t in ipairs(tiles) do
        textures[t] = makeTileTexture(t)
    end
end

local function makeMobTexture(kind)
    local data = love.image.newImageData(TEX_SIZE, TEX_SIZE)
    for y = 0, TEX_SIZE - 1 do
        for x = 0, TEX_SIZE - 1 do
            local n = love.math.noise((x + (kind == "friendly" and 8 or 28)) * 0.22, (y + 11) * 0.22, worldSeed)
            local r, g, b = 0, 0, 0
            local inBody = (x >= 3 and x <= 12 and y >= 3 and y <= 14)

            if kind == "friendly" then
                if inBody then
                    r, g, b = 0.86, 0.80, 0.72
                    local d = (n - 0.5) * 0.10
                    if y >= 10 then d = d - 0.05 end
                    r, g, b = r + d, g + d, b + d
                else
                    r, g, b = 0.1, 0.1, 0.1
                end
                -- belly
                if x >= 5 and x <= 10 and y >= 9 and y <= 12 then
                    r, g, b = 0.92, 0.87, 0.80
                end
                -- eyes
                if (x == 5 or x == 10) and y == 6 then
                    r, g, b = 0.08, 0.08, 0.08
                end
                -- cheeks
                if (x == 4 or x == 11) and y == 8 then
                    r, g, b = 0.92, 0.70, 0.70
                end
            else
                if inBody then
                    r, g, b = 0.16, 0.50, 0.20
                    local d = (n - 0.5) * 0.16
                    if y >= 11 then d = d - 0.05 end
                    r, g, b = r + d, g + d, b + d
                else
                    r, g, b = 0.06, 0.06, 0.06
                end
                -- horns
                if y <= 3 and (x == 4 or x == 11) then
                    r, g, b = 0.65, 0.65, 0.68
                end
                -- eyes
                if (x == 5 or x == 10) and y == 6 then
                    r, g, b = 0.85, 0.12, 0.12
                end
                -- mouth
                if x >= 6 and x <= 9 and y == 9 then
                    r, g, b = 0.10, 0.05, 0.05
                end
            end

            -- outline
            if inBody and (x == 3 or x == 12 or y == 3 or y == 14) then
                r, g, b = r * 0.7, g * 0.7, b * 0.7
            end

            data:setPixel(x, y, clamp01(r), clamp01(g), clamp01(b), 1)
        end
    end
    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

local function buildMobTextures()
    mobTextures.friendly = makeMobTexture("friendly")
    mobTextures.hostile = makeMobTexture("hostile")
end

local function countMobs(kind)
    local count = 0
    for i = 1, #mobs do
        if mobs[i].kind == kind then
            count = count + 1
        end
    end
    return count
end

local function spawnMob(kind, tx)
    local h = 24
    local w = 24
    local surface = getSurfaceY(tx)
    local mob = {
        kind = kind,
        x = (tx - 1) * TILE_SIZE + (TILE_SIZE - w) * 0.5,
        y = (surface - 1) * TILE_SIZE - h,
        w = w,
        h = h,
        vx = 0,
        vy = 0,
        dir = (love.math.random() < 0.5) and -1 or 1,
        wanderTimer = love.math.random() * 2,
        giftCooldown = 3 + love.math.random() * 5,
        attackCooldown = 0,
        onGround = false,
        maxHp = (kind == "hostile") and 40 or 30,
        hp = (kind == "hostile") and 40 or 30,
        hitTimer = 0
    }
    mobs[#mobs + 1] = mob
end

local function moveMobAndCollide(mob, dt, dirX)
    local accel = mob.onGround and 1800 or 1200
    local friction = mob.onGround and 1400 or 500
    local maxSpeed = (mob.kind == "hostile") and 140 or 110

    if dirX ~= 0 then
        mob.vx = mob.vx + dirX * accel * dt
    else
        if mob.vx > 0 then
            mob.vx = math.max(0, mob.vx - friction * dt)
        elseif mob.vx < 0 then
            mob.vx = math.min(0, mob.vx + friction * dt)
        end
    end

    if mob.vx > maxSpeed then mob.vx = maxSpeed end
    if mob.vx < -maxSpeed then mob.vx = -maxSpeed end

    local newX = mob.x + mob.vx * dt
    if mob.vx > 0 then
        local tileX = worldToTileX(newX + mob.w - 1)
        local topTile = worldToTileY(mob.y + 1)
        local bottomTile = worldToTileY(mob.y + mob.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = (tileX - 1) * TILE_SIZE - mob.w
                mob.vx = 0
                break
            end
        end
    elseif mob.vx < 0 then
        local tileX = worldToTileX(newX)
        local topTile = worldToTileY(mob.y + 1)
        local bottomTile = worldToTileY(mob.y + mob.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = tileX * TILE_SIZE
                mob.vx = 0
                break
            end
        end
    end
    mob.x = newX

    mob.vy = mob.vy + player.gravity * dt
    if mob.vy > 900 then mob.vy = 900 end
    local newY = mob.y + mob.vy * dt
    mob.onGround = false

    if mob.vy > 0 then
        local tileY = worldToTileY(newY + mob.h - 1)
        local leftTile = worldToTileX(mob.x + 1)
        local rightTile = worldToTileX(mob.x + mob.w - 2)
        for tx = leftTile, rightTile do
            if isSolid(getTile(tx, tileY)) then
                newY = (tileY - 1) * TILE_SIZE - mob.h
                mob.vy = 0
                mob.onGround = true
                break
            end
        end
    elseif mob.vy < 0 then
        local tileY = worldToTileY(newY)
        local leftTile = worldToTileX(mob.x + 1)
        local rightTile = worldToTileX(mob.x + mob.w - 2)
        for tx = leftTile, rightTile do
            if isSolid(getTile(tx, tileY)) then
                newY = tileY * TILE_SIZE
                mob.vy = 0
                break
            end
        end
    end

    mob.y = newY
end

local function updateMobs(dt)
    local px, py = playerCenter()
    for i = #mobs, 1, -1 do
        local mob = mobs[i]
        mob.wanderTimer = mob.wanderTimer - dt
        if mob.giftCooldown > 0 then
            mob.giftCooldown = mob.giftCooldown - dt
        end
        if mob.attackCooldown > 0 then
            mob.attackCooldown = mob.attackCooldown - dt
        end
        if mob.hitTimer > 0 then
            mob.hitTimer = math.max(0, mob.hitTimer - dt)
        end

        local mx = mob.x + mob.w * 0.5
        local my = mob.y + mob.h * 0.5
        local dx = px - mx
        local dy = py - my
        local dist2 = dx * dx + dy * dy
        local dirX = 0

        if mob.kind == "hostile" then
            if dist2 < 240 * 240 then
                dirX = (dx > 0) and 1 or -1
            elseif mob.wanderTimer <= 0 then
                mob.wanderTimer = 1.2 + love.math.random()
                mob.dir = (love.math.random() < 0.5) and -1 or 1
            end
        else
            if dist2 < 90 * 90 then
                dirX = (dx > 0) and -1 or 1
            elseif mob.giftCooldown <= 0 and dist2 < 150 * 150 then
                dirX = (dx > 0) and 1 or -1
            elseif mob.wanderTimer <= 0 then
                mob.wanderTimer = 1.5 + love.math.random() * 1.5
                mob.dir = (love.math.random() < 0.5) and -1 or 1
            end
        end

        if dirX == 0 and mob.wanderTimer > 0 then
            dirX = mob.dir
        end

        if dirX ~= 0 and mob.onGround then
            local aheadX = mob.x + (dirX > 0 and mob.w + 1 or -1)
            local footY = mob.y + mob.h - 2
            local headY = mob.y + 4
            local tileAhead = getTile(worldToTileX(aheadX), worldToTileY(footY))
            local tileAbove = getTile(worldToTileX(aheadX), worldToTileY(headY))
            if isSolid(tileAhead) and not isSolid(tileAbove) then
                mob.vy = -player.jumpForce * 0.55
                mob.onGround = false
            end
        end

        moveMobAndCollide(mob, dt, dirX)

        if mob.kind == "friendly" and dist2 < 70 * 70 and mob.giftCooldown <= 0 then
            addItem(ITEM_FOOD, FRIENDLY_GIFT_AMOUNT)
            mob.giftCooldown = 8 + love.math.random() * 4
        end

        if mob.kind == "hostile" and checkCollision(mob, player) then
            if player.invuln <= 0 then
                player.hp = math.max(0, player.hp - 12)
                player.invuln = 0.6
            end
        end

        if mob.hp <= 0 then
            if mob.kind == "hostile" then
                addItem(ITEM_FOOD, HOSTILE_DROP_AMOUNT)
            else
                addItem(ITEM_FOOD, FRIENDLY_DROP_AMOUNT)
            end
            table.remove(mobs, i)
        end
    end

    mobSpawnTimer = mobSpawnTimer - dt
    if mobSpawnTimer <= 0 then
        mobSpawnTimer = 3 + love.math.random() * 2
        local baseTx = worldToTileX(player.x)
        local offset = love.math.random(10, 28)
        if love.math.random() < 0.5 then offset = -offset end
        local tx = baseTx + offset

        if countMobs("friendly") < MAX_FRIENDLY then
            spawnMob("friendly", tx)
        elseif countMobs("hostile") < MAX_HOSTILE then
            spawnMob("hostile", tx)
        end
    end
end

local function drawMobs()
    for i = 1, #mobs do
        local mob = mobs[i]
        local img = mobTextures[mob.kind]
        if img then
            local scale = mob.w / TEX_SIZE
            if mob.hitTimer > 0 then
                scale = scale * 1.08
                love.graphics.setColor(1, 0.55, 0.55)
            else
                love.graphics.setColor(1, 1, 1)
            end
            local drawX = mob.x - (scale * TEX_SIZE - mob.w) * 0.5
            local drawY = mob.y - (scale * TEX_SIZE - mob.h) * 0.5
            love.graphics.draw(img, drawX, drawY, 0, scale, scale)
        else
            love.graphics.setColor(1, 0, 1)
            love.graphics.rectangle("fill", mob.x, mob.y, mob.w, mob.h)
        end
    end
end

local function drawBar(x, y, w, h, value, maxValue, r, g, b, label)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, w, h)
    local ratio = 0
    if maxValue > 0 then
        ratio = math.max(0, math.min(1, value / maxValue))
    end
    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * ratio, h - 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h)
    if label then
        love.graphics.print(label .. " " .. math.floor(value), x + 4, y + 1)
    end
end

local function moveAndCollide(dt, dirX)
    local accel = player.onGround and 4200 or 2600
    local friction = player.onGround and 3600 or 600

    if dirX ~= 0 then
        player.vx = player.vx + dirX * accel * dt
    else
        if player.vx > 0 then
            player.vx = math.max(0, player.vx - friction * dt)
        elseif player.vx < 0 then
            player.vx = math.min(0, player.vx + friction * dt)
        end
    end

    if player.vx > player.speed then player.vx = player.speed end
    if player.vx < -player.speed then player.vx = -player.speed end

    local newX = player.x + player.vx * dt

    if player.vx > 0 then
        local tileX = worldToTileX(newX + player.w - 1)
        local topTile = worldToTileY(player.y + 1)
        local bottomTile = worldToTileY(player.y + player.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = (tileX - 1) * TILE_SIZE - player.w
                player.vx = 0
                break
            end
        end
    elseif player.vx < 0 then
        local tileX = worldToTileX(newX)
        local topTile = worldToTileY(player.y + 1)
        local bottomTile = worldToTileY(player.y + player.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = tileX * TILE_SIZE
                player.vx = 0
                break
            end
        end
    end

    player.x = newX
    -- simple gravity with terminal speed
    player.vy = player.vy + player.gravity * dt
    if player.vy > 1200 then player.vy = 1200 end
    local newY = player.y + player.vy * dt
    player.onGround = false

    if player.vy > 0 then
        local tileY = worldToTileY(newY + player.h - 1)
        local leftTile = worldToTileX(player.x + 1)
        local rightTile = worldToTileX(player.x + player.w - 2)
        for tx = leftTile, rightTile do
            if isSolid(getTile(tx, tileY)) then
                newY = (tileY - 1) * TILE_SIZE - player.h
                player.vy = 0
                player.onGround = true
                break
            end
        end
    elseif player.vy < 0 then
        local tileY = worldToTileY(newY)
        local leftTile = worldToTileX(player.x + 1)
        local rightTile = worldToTileX(player.x + player.w - 2)
        for tx = leftTile, rightTile do
            if isSolid(getTile(tx, tileY)) then
                newY = tileY * TILE_SIZE
                player.vy = 0
                break
            end
        end
    end

    if newY < -2000 then
        newY = -2000
        player.vy = 0
    end

    player.y = newY
end

local function respawnPlayer()
    local spawnTileX = 0
    local spawnSurface = getSurfaceY(spawnTileX)
    player.x = spawnTileX * TILE_SIZE
    player.y = (spawnSurface - 3) * TILE_SIZE
    player.vx = 0
    player.vy = 0
    player.hp = player.maxHp
    player.hunger = player.maxHunger
    player.invuln = 0
end

function love.load()
    love.window.setTitle("Toudi")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.math.setRandomSeed(os.time())
    worldSeed = love.math.random() * 1000
    buildTextures()
    buildMobTextures()
    respawnPlayer()

    for i = 1, 3 do
        spawnMob("friendly", worldToTileX(player.x) + love.math.random(-12, 12))
    end
    spawnMob("hostile", worldToTileX(player.x) + love.math.random(16, 24))
end

function love.keypressed(key)
    if isJumpKey(key) then
        jumpBufferTimer = jumpBufferTime
    end
    if key == "f1" then
        controls.layout = (controls.layout == "azerty") and "qwerty" or "azerty"
    end
    if key == "f5" then
        saveWorld()
    end
    if key == "f9" then
        loadWorld()
    end
    if key == "f" then
        local tile = hotbar[selectedSlot]
        if tile == ITEM_FOOD and spendItem(ITEM_FOOD, 1) then
            player.hunger = math.min(player.maxHunger, player.hunger + FOOD_HUNGER)
            player.hp = math.min(player.maxHp, player.hp + FOOD_HEAL)
        end
    end
    if key == "e" then
        setCraftingOpen(not craftingOpen)
        if craftingOpen then
            inventoryOpen = false
        end
    end
    if key == "i" then
        inventoryOpen = not inventoryOpen
        if inventoryOpen then
            setCraftingOpen(false)
        end
    end
    if key == "escape" then
        setCraftingOpen(false)
        inventoryOpen = false
    end
    if key >= "1" and key <= "9" then
        selectedSlot = tonumber(key)
    end
end

function love.update(dt)
    local dirX = 0
    if isLeftDown() then
        dirX = dirX - 1
    end
    if isRightDown() then
        dirX = dirX + 1
    end

    jumpBufferTimer = math.max(0, jumpBufferTimer - dt)
    if player.onGround then
        coyoteTimer = coyoteTime
    else
        coyoteTimer = math.max(0, coyoteTimer - dt)
    end

    if jumpBufferTimer > 0 and coyoteTimer > 0 then
        player.vy = -player.jumpForce
        player.onGround = false
        jumpBufferTimer = 0
        coyoteTimer = 0
    end

    moveAndCollide(dt, dirX)

    player.invuln = math.max(0, player.invuln - dt)
    player.attackTimer = math.max(0, player.attackTimer - dt)
    player.hunger = math.max(0, player.hunger - dt * 1.0)
    if player.hunger <= 0 then
        player.hp = math.max(0, player.hp - dt * 6.0)
    end
    if player.hp <= 0 then
        respawnPlayer()
    end

    updateMobs(dt)

    local sw, sh = love.graphics.getDimensions()
    camera.x = player.x + player.w * 0.5 - sw * 0.5
    camera.y = player.y + player.h * 0.5 - sh * 0.5
    camera.x = math.floor(camera.x + 0.5)
    camera.y = math.floor(camera.y + 0.5)

    if player.attackTimer <= 0 and not craftingOpen and not inventoryOpen and love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        local wx = mx + camera.x
        local wy = my + camera.y
        local tx = worldToTileX(wx)
        local ty = worldToTileY(wy)
        local tile = getTile(tx, ty)
        local dur = tileDurability(tile)

        if dur and inReach(tx, ty) then
            if not breakState.active or breakState.tx ~= tx or breakState.ty ~= ty then
                breakState.active = true
                breakState.tx = tx
                breakState.ty = ty
                breakState.timer = 0
                breakState.duration = dur
            end
            breakState.timer = breakState.timer + dt
            if breakState.timer >= breakState.duration then
                local drop = tileToItem(tile)
                if drop then
                    addItem(drop, 1)
                end
                setTile(tx, ty, TILE_AIR)
                refreshGrass(tx, ty + 1)
                breakState.active = false
            end
        else
            breakState.active = false
        end
    else
        breakState.active = false
    end
end

function love.mousepressed(x, y, button)
    if inventoryOpen then
        local hit = inventoryHit(x, y)
        if hit and button == 1 then
            if hit.kind == "hotbar" then
                selectedSlot = hit.index
            elseif hit.kind == "grid" then
                local tile = inventoryOrder[hit.index]
                if tile and (inventory[tile] or 0) > 0 then
                    hotbar[selectedSlot] = tile
                end
            end
        end
        return
    end

    if craftingOpen then
        local slot = craftingSlotAt(x, y)
        if slot == "output" then
            if craftingResult then
                addItem(craftingResult.tile, craftingResult.count)
                for i = 1, 9 do
                    craftingGrid[i] = 0
                end
                craftingResult = nil
            end
            return
        end

        if type(slot) == "number" then
            if button == 1 and craftingGrid[slot] == 0 then
                local tile = hotbar[selectedSlot]
                if tile and spendItem(tile, 1) then
                    craftingGrid[slot] = tile
                    updateCraftingResult()
                end
            elseif button == 2 and craftingGrid[slot] ~= 0 then
                addItem(craftingGrid[slot], 1)
                craftingGrid[slot] = 0
                updateCraftingResult()
            end
            return
        end
    end

    if button == 1 then
        local wx = x + camera.x
        local wy = y + camera.y
        local px, py = playerCenter()
        if player.attackTimer <= 0 then
            local bestIndex = nil
            local bestDist2 = (ATTACK_RANGE * ATTACK_RANGE)
            for i = 1, #mobs do
                local mob = mobs[i]
                if wx >= mob.x and wx <= mob.x + mob.w and wy >= mob.y and wy <= mob.y + mob.h then
                    local mx = mob.x + mob.w * 0.5
                    local my = mob.y + mob.h * 0.5
                    local dx = mx - px
                    local dy = my - py
                    local d2 = dx * dx + dy * dy
                    if d2 <= bestDist2 then
                        bestDist2 = d2
                        bestIndex = i
                    end
                end
            end

            if bestIndex then
                local mob = mobs[bestIndex]
                mob.hp = mob.hp - ATTACK_DAMAGE
                local dir = (mob.x + mob.w * 0.5) > px and 1 or -1
                mob.vx = mob.vx + dir * 220
                mob.vy = -220
                mob.hitTimer = 0.12
                player.attackTimer = ATTACK_COOLDOWN
                return
            end
        end
    end

    local wx = x + camera.x
    local wy = y + camera.y
    local tx = worldToTileX(wx)
    local ty = worldToTileY(wy)

    if button == 2 then
        local placeTile = hotbar[selectedSlot]
        if placeTile and isPlaceable(placeTile) and inReach(tx, ty) and getTile(tx, ty) == TILE_AIR then
            local tileRect = {
                x = (tx - 1) * TILE_SIZE,
                y = (ty - 1) * TILE_SIZE,
                w = TILE_SIZE,
                h = TILE_SIZE
            }
            if not checkCollision(player, tileRect) then
                if spendItem(placeTile, 1) then
                    setTile(tx, ty, placeTile)
                    refreshGrass(tx, ty)
                    refreshGrass(tx, ty + 1)
                end
            end
        end
    end
end

function love.draw()
    local sw, sh = love.graphics.getDimensions()
    local startX = worldToTileX(camera.x) - 1
    local endX = worldToTileX(camera.x + sw) + 1
    local startY = worldToTileY(camera.y) - 1
    local endY = worldToTileY(camera.y + sh) + 1

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    love.graphics.setColor(1, 1, 1)
    for ty = startY, endY do
        for tx = startX, endX do
            local t = getTile(tx, ty)
            if t ~= TILE_AIR then
                local img = textures[t]
                local px = (tx - 1) * TILE_SIZE
                local py = (ty - 1) * TILE_SIZE
                love.graphics.draw(img, px, py, 0, TILE_SCALE, TILE_SCALE)
            end
        end
    end

    drawMobs()

    love.graphics.setColor(1, 0.12, 0.12)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("x:" .. math.floor(player.x) .. " y:" .. math.floor(player.y), 10, 10)
    drawBar(10, 28, 180, 14, player.hp, player.maxHp, 0.85, 0.2, 0.2, "HP")
    drawBar(10, 46, 180, 14, player.hunger, player.maxHunger, 0.95, 0.6, 0.12, "Hunger")

    if not inventoryOpen then
        local slotSize = 32
        local pad = 6
        local barX = 10
        local barY = sh - slotSize - 10
        for i = 1, #hotbar do
            local x = barX + (i - 1) * (slotSize + pad)
            local y = barY
            if i == selectedSlot then
                love.graphics.setColor(1, 1, 0.2)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.rectangle("line", x, y, slotSize, slotSize)

            local tile = hotbar[i]
            local img = textures[tile]
            if img then
                love.graphics.setColor(1, 1, 1)
                local scale = (slotSize - 6) / TEX_SIZE
                love.graphics.draw(img, x + 3, y + 3, 0, scale, scale)
            end

            local count = inventory[tile] or 0
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(count), x + 2, y + slotSize - 14)
        end
    end

    if craftingOpen then
        local ui = getCraftingUI()
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", ui.x, ui.y, ui.w, ui.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Crafting", ui.x + 10, ui.y + 10)

        for row = 0, 2 do
            for col = 0, 2 do
                local idx = row * 3 + col + 1
                local x = ui.gridX + col * (ui.slot + ui.gap)
                local y = ui.gridY + row * (ui.slot + ui.gap)
                love.graphics.rectangle("line", x, y, ui.slot, ui.slot)
                local tile = craftingGrid[idx]
                local img = textures[tile]
                if img then
                    local scale = (ui.slot - 6) / TEX_SIZE
                    love.graphics.draw(img, x + 3, y + 3, 0, scale, scale)
                end
            end
        end

        -- output slot
        love.graphics.rectangle("line", ui.outX, ui.outY, ui.slot, ui.slot)
        if craftingResult then
            local img = textures[craftingResult.tile]
            if img then
                local scale = (ui.slot - 6) / TEX_SIZE
                love.graphics.draw(img, ui.outX + 3, ui.outY + 3, 0, scale, scale)
            end
            love.graphics.print("x" .. tostring(craftingResult.count), ui.outX + 2, ui.outY + ui.slot - 14)
        end
    end

    if inventoryOpen then
        local ui = getInventoryUI()
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", ui.x, ui.y, ui.w, ui.h)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
        love.graphics.rectangle("line", ui.x, ui.y, ui.w, ui.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Inventory", ui.x + 10, ui.y + 10)

        local function drawSlot(x, y, highlight)
            love.graphics.setColor(0.18, 0.18, 0.18)
            love.graphics.rectangle("fill", x, y, ui.slot, ui.slot)
            if highlight then
                love.graphics.setColor(0.85, 0.85, 0.20)
            else
                love.graphics.setColor(0.35, 0.35, 0.35)
            end
            love.graphics.rectangle("line", x, y, ui.slot, ui.slot)
        end

        for i = 1, ui.cols * ui.rows do
            local row = math.floor((i - 1) / ui.cols)
            local col = (i - 1) % ui.cols
            local x = ui.gridX + col * (ui.slot + ui.gap)
            local y = ui.gridY + row * (ui.slot + ui.gap)
            drawSlot(x, y, false)
            local tile = inventoryOrder[i]
            if tile and (inventory[tile] or 0) > 0 then
                local img = textures[tile]
                if img then
                    local scale = (ui.slot - 6) / TEX_SIZE
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.draw(img, x + 3, y + 3, 0, scale, scale)
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(tostring(inventory[tile]), x + 2, y + ui.slot - 14)
            end
        end

        for i = 1, #hotbar do
            local x = ui.gridX + (i - 1) * (ui.slot + ui.gap)
            local y = ui.hotbarY
            drawSlot(x, y, i == selectedSlot)
            local tile = hotbar[i]
            local img = textures[tile]
            if img then
                local scale = (ui.slot - 6) / TEX_SIZE
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img, x + 3, y + 3, 0, scale, scale)
            end
            local count = inventory[tile] or 0
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(count), x + 2, y + ui.slot - 14)
        end
    end
end
