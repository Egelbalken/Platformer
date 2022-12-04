playerStartX = 100
playerStartY = 50

-- Collider holds all physcical info
player = world:newRectangleCollider(playerStartX,playerStartY,40,100, {collision_class = 'Player'})
--player speed
player.speed = 240
--player animation
player.animation = animations.idle
--player is moving
player.isMoving = false
--player is jumping
player.isJumping = false
--player has falled to the ground
player.isOnGround = true
-- player direction
player.direction = 1


function playerUpdate(dt)
    if player.body then -- if the player still exists`
        local colliders = world:queryRectangleArea(player:getX() -20,player:getY() + 50, 40, 2, {'Platform'})
        if #colliders > 0 then
            player.isOnGround = true
        else
            player.isOnGround = false
        end

        player.isMoving = false
        player.isJumping = false
        local px, py = player:getPosition() 
        if love.keyboard.isDown('right') then
            player:setX(px + player.speed*dt)
            player.isMoving = true
            player.direction = 1
        end
        if love.keyboard.isDown('left') then
            player:setX(px - player.speed*dt)
            player.isMoving = true
            player.direction = -1
        end
        if player:enter('Danger') then
            player:setPosition(playerStartX,playerStartY)
        end
    end

    --We can only move if we are on the ground. And if not we are jumping
    if player.isOnGround then
        if player.isMoving then
            player.animation = animations.run
        else
            player.animation = animations.idle
        end
    else
        player.animation = animations.jump
    end

    player.animation:update(dt)
end

function drawPlayer() 
    local px, py = player:getPosition()
    player.animation:draw(sprites.playerSheet, px, py, nil, 0.25 * player.direction, 0.25, 130,300)
end