--[[

All the propperties and objects added into the game

]]
function love.load()
    -- Creates a world the windowsize
    love.window.setMode(1000,768)
    --Import animationfigure package
    anim8 = require 'libraries/anim8/anim8'
    --Map importer
    sti = require 'libraries/Simple-Tiled-Implementation/sti/'
    -- Import camera
    cameraFile = require "libraries/hump/camera"

    -- creates the camera object 
    cam = cameraFile()


    -- Sounds table import
    sounds = {}

    sounds.jump = love.audio.newSource("audio/jump.wav", "static")
    sounds.music = love.audio.newSource("audio/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    sounds.music:play()


    -- Import the player sprites
    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    sprites.background = love.graphics.newImage('sprites/background.png')
    -- count the imagesize: 9210x1692 pixles, 15 columns wide = (9210/15 = 614), 3 rows tall = (1682/3 = 564)
    local grid = anim8.newGrid(614,564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100,79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())
    -- table for our animations
    animations = {}
    -- the idle animation
    animations.idle = anim8.newAnimation(grid('1-15',1), 0.05)
    -- jump anmiation
    animations.jump = anim8.newAnimation(grid('1-7',2), 0.05)
    -- run animation
    animations.run = anim8.newAnimation(grid('1-15',3), 0.05)
    -- enemy anmination
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03)

    --Import the package.
    wf = require 'libraries/windfield/windfield/'
    --Creates a world with gravity. second parameter gives the gravity forcedown like faling down like a mario game.
    world = wf.newWorld(0,800, false)
    world:setQueryDebugDrawing(true)
    -- Collistion class objects, that can be added to our objects as a table.
    -- This is usefull if we want to make somthing happens when thy are colliding
    world:addCollisionClass('Platform') -- first will be static
    world:addCollisionClass('Player'--[[ {ignores = {'Platform'}}]]) -- player falls in trough the platform
    world:addCollisionClass('Danger')

    -- Import the file. player.lua
    require('player')
    require('enemy') 
    require('libraries/show')
    -- Dangerus things -- 
    dangerZone = world:newRectangleCollider(-500,800,5000,50, {collision_class = 'Danger'})
    -- Make the dangerzone static
    dangerZone:setType('static')

    --fixed rotation
    player:setFixedRotation(true)

    platforms = {}

    flagX = 0
    flagY = 0
    

    saveData = {}
    saveData.currentLevel = "level1"

    if love.filesystem.getInfo("data.lua") then
        local data = love.filesystem.load("data.lua")
        data()
    end

    -- spawn map
    loadMap(saveData.currentLevel)
end

--[[
    
    Uppdates all the things happens
    
    ]]
    function love.update(dt)
    world:update(dt)   
    gameMap:update(dt)
    playerUpdate(dt)
    enemiesUpdate(dt)
    local px, py = player:getPosition()
    -- let us se the middle of the map
    cam:lookAt(px, love.graphics.getHeight() /2)

    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        if saveData.currentLevel == "level1" then
            loadMap("level2")
            saveData.currentLevel = "level2"
        elseif saveData.currentLevel == "level2" then
            saveData.currentLevel = "level1"
            loadMap("level1")
        end
    end
end


--[[

Draws all the grafics.

]]
function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    -- camera following the player, intendent
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        --GameDev liner
        --world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()

end


function love.keypressed(key)
    if key == 'space' then
        if player.isOnGround then
            sounds.jump:play()
            player:applyLinearImpulse(0, -4000)
        end 
    end
    if key == 'r' then
        loadMap('level2')
    end
end

-- delete all old platforms levels and enemies
function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i -1
    end
    local e = #enemies
    while e > -1 do
        if enemies[e] ~= nil then
            enemies[e]:destroy()
        end
        table.remove(enemies, e)
        e = e -1
    end
end


function love.mousepressed(x,y, button)
    
    --This collider will destroy the mousepressed and objects
    if button == 1 then
        local colliders = world:queryCircleArea(x, y, 200, {'Platform', 'Danger'}) -- here the objects in table will be destroy
        for i,c in ipairs(colliders) do
            c:destroy()
        end
    end
end

-- Functionf or spawning all the objects in the maps.
function spawnPlatform(x, y, width, height)
    if width > 0 and height > 0 then     
        -- Create a unmoving object
        local platform = world:newRectangleCollider(x, y, width, height, {collision_class = 'Platform'})
        -- platform will be static.
        platform:setType('static')
        table.insert(platforms, platform)
    end
end

--loads the map, spwen details and so on.
function loadMap(mapName)
    saveData.currentLevel = mapName
    -- Save funtion.
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
    destroyAll()
    gameMap = sti("maps/" .. mapName .. ".lua")
    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x 
        playerStartY = obj.y
    end
    player:setPosition(playerStartX,playerStartY)
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end

