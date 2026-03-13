-- Vive la france et credit to ubundows_78 31/07/2024

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

local SURFACE_BASE = 14
local SURFACE_VARIATION = 7
local BEDROCK_Y = 90

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
    vy = 0,
    gravity = 1800,
    jumpForce = 620,
    onGround = false
}

local jumpBufferTime = 0.12
local coyoteTime = 0.10
local jumpBufferTimer = 0
local coyoteTimer = 0

local function isJumpKey(key)
    return key == "space" or key == "z" or key == "up"
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

local function checkCollision(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
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

            data:setPixel(x, y, clamp01(r), clamp01(g), clamp01(b), 1)
        end
    end

    local image = love.graphics.newImage(data)
    image:setFilter("nearest", "nearest")
    return image
end

local function buildTextures()
    textures[TILE_DIRT] = makeTileTexture(TILE_DIRT)
    textures[TILE_GRASS_DIRT] = makeTileTexture(TILE_GRASS_DIRT)
    textures[TILE_STONE] = makeTileTexture(TILE_STONE)
    textures[TILE_BEDROCK] = makeTileTexture(TILE_BEDROCK)
    textures[TILE_WOOD] = makeTileTexture(TILE_WOOD)
    textures[TILE_LEAVES] = makeTileTexture(TILE_LEAVES)
end

local function moveAndCollide(dt, dirX)
    local vx = dirX * player.speed
    local newX = player.x + vx * dt

    if vx > 0 then
        local tileX = worldToTileX(newX + player.w - 1)
        local topTile = worldToTileY(player.y + 1)
        local bottomTile = worldToTileY(player.y + player.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = (tileX - 1) * TILE_SIZE - player.w
                break
            end
        end
    elseif vx < 0 then
        local tileX = worldToTileX(newX)
        local topTile = worldToTileY(player.y + 1)
        local bottomTile = worldToTileY(player.y + player.h - 2)
        for ty = topTile, bottomTile do
            if isSolid(getTile(tileX, ty)) then
                newX = tileX * TILE_SIZE
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

function love.load()
    love.window.setTitle("Toudi")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.math.setRandomSeed(os.time())
    worldSeed = love.math.random() * 1000
    buildTextures()

    local spawnTileX = 0
    local spawnSurface = getSurfaceY(spawnTileX)
    player.x = spawnTileX * TILE_SIZE
    player.y = (spawnSurface - 3) * TILE_SIZE
end

function love.keypressed(key)
    if isJumpKey(key) then
        jumpBufferTimer = jumpBufferTime
    end
end

function love.update(dt)
    local dirX = 0
    if love.keyboard.isDown("q", "left") then
        dirX = dirX - 1
    end
    if love.keyboard.isDown("d", "right") then
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

    local sw, sh = love.graphics.getDimensions()
    camera.x = player.x + player.w * 0.5 - sw * 0.5
    camera.y = player.y + player.h * 0.5 - sh * 0.5
end

function love.mousepressed(x, y, button)
    local wx = x + camera.x
    local wy = y + camera.y
    local tx = worldToTileX(wx)
    local ty = worldToTileY(wy)

    if button == 1 then
        local t = getTile(tx, ty)
        if t ~= TILE_AIR and t ~= TILE_BEDROCK then
            setTile(tx, ty, TILE_AIR)
            refreshGrass(tx, ty + 1)
        end
    elseif button == 2 then
        if getTile(tx, ty) == TILE_AIR then
            local tileRect = {
                x = (tx - 1) * TILE_SIZE,
                y = (ty - 1) * TILE_SIZE,
                w = TILE_SIZE,
                h = TILE_SIZE
            }
            if not checkCollision(player, tileRect) then
                setTile(tx, ty, TILE_DIRT)
                refreshGrass(tx, ty)
                refreshGrass(tx, ty + 1)
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

    love.graphics.setColor(1, 0.12, 0.12)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("x:" .. math.floor(player.x) .. " y:" .. math.floor(player.y), 10, 10)
end
