--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball_1 = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball_1 random starting velocity
    self.ball_1.dx = math.random(-100, 100)
    self.ball_1.dy = math.random(-50, -60)


    -- timer for random initiation of powerup
    powerupTimer = 0
    randomTime = math.random(5, 8)

    --create ball table
    self.balltable = {}
    self.balltable[1] = self.ball_1
    self.balltable[1].inplay = true

    -- variable for counting how many balls go below bounds
    outOfPlay = 0
end

-- variable to track score increase since last variable zero
scoreTrack = 0
function PlayState:update(dt)
-- Pause functionality
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end


    --generate powerup at random time
    powerupTimer = powerupTimer + dt
    if math.modf(powerupTimer) == randomTime and not self.powerup then
        self.powerup = Powerup()
    end

    -- update paddle and ball(s) positions based on velocity

    self.paddle:update(dt)
    for i = 1, 3, 1 do
        if self.balltable[i] then
            if self.balltable[i].inplay then
                self.balltable[i]:update(dt)
            end
        end
    end
   

    -- if powerup is initialized, update position and check for collisions with paddle
    
    if self.powerup then
        if self.powerup.inplay then
            self.powerup:update(dt)
            if self.powerup:collides(self.paddle) then
                self.ball_2 = Ball()
                self.ball_2.x = self.paddle.x + (self.paddle.width / 2) - 4
                self.ball_2.y = self.paddle.y - 8
                self.ball_2.skin = math.random(7)
                self.ball_2.dx = math.random(-100, 100)
                self.ball_2.dy = math.random(-50, -60)
                self.ball_2.inplay = true

                self.ball_3 = Ball()
                self.ball_3.x = self.paddle.x + (self.paddle.width / 2) - 4
                self.ball_3.y = self.paddle.y - 8
                self.ball_3.skin = math.random(7)
                self.ball_3.dx = math.random(-100, 100)
                self.ball_3.dy = math.random(-50, -60)
                self.ball_3.inplay = true

                self.balltable[2] = self.ball_2
                self.balltable[3] = self.ball_3
            end
        end
    end
    


    
    -- if powerup is inplay, detect passing through screen bottom
    if self.powerup then
        if self.powerup.inplay and self.powerup.y > VIRTUAL_HEIGHT then
            self.powerup.inplay = false
            self.powerup = false
            gSounds['hurt']:play()
            powerupTimer = 0
        end
    end

 

    -- detect collision of ball(s) with paddle
    
    for i = 1, 3, 1 do
        if self.balltable[i] then                   
            if self.balltable[i]:collides(self.paddle) then
                -- raise ball_1 above paddle in case it goes below it, then reverse dy
                self.balltable[i].y = self.paddle.y - 8
                self.balltable[i].dy = -self.balltable[i].dy
                --
                -- tweak angle of bounce based on where it hits the paddle
                --
                -- if we hit the paddle on its left side while moving left...
                if self.balltable[i].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                    self.balltable[i].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.balltable[i].x))

                -- else if we hit the paddle on its right side while moving right...
                elseif self.balltable[i].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                    self.balltable[i].dx = 50 +
                    (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.balltable[i].x))
                end

                gSounds['paddle-hit']:play()
            end
        end
    end

    -- detect collision across all bricks with all ball(s)
    for i = 1, 3, 1 do
        if self.balltable[i] then
            if self.balltable[i].inplay then
                
                for k, brick in pairs(self.bricks) do

                    -- only check collision if brick is in play
                    if brick.inPlay and self.balltable[i]:collides(brick) then

                        -- add to score
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)
                        -- increment scoreTrack for paddle size increase
                        scoreTrack = scoreTrack + (brick.tier * 200 + brick.color * 25)

                        if scoreTrack > 1000 then
                            if self.paddle.size < 4 then
                                self.paddle.size = self.paddle.size + 1
                            end
                            scoreTrack = 0
        
                        end

                        -- trigger the brick's hit function, which removes it from play
                        brick:hit()

                        -- if we have enough points, recover a point of health
                        if self.score > self.recoverPoints then
                            -- can't go above 3 health
                            self.health = math.min(3, self.health + 1)

                            -- multiply recover points by 2
                            self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                            -- play recover sound effect
                            gSounds['recover']:play()
                        end

                        -- go to our victory screen if there are no more bricks left
                        if self:checkVictory() then
                            gSounds['victory']:play()

                            gStateMachine:change('victory', {
                                level = self.level,
                                paddle = self.paddle,
                                health = self.health,
                                score = self.score,
                                highScores = self.highScores,
                                ball = self.ball_1,
                                recoverPoints = self.recoverPoints
                            })
                        end

                        --
                        -- collision code for bricks
                        --
                        -- we check to see if the opposite side of our velocity is outside of the brick;
                        -- if it is, we trigger a collision on that side. else we're within the X + width of
                        -- the brick and should check to see if the top or bottom edge is outside of the brick,
                        -- colliding on the top or bottom accordingly 
                        --

                        -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                        -- so that flush corner hits register as Y flips, not X flips
                        if self.balltable[i].x + 2 < brick.x and self.balltable[i].dx > 0 then
                            
                            -- flip x velocity and reset position outside of brick
                            self.balltable[i].dx = -self.balltable[i].dx
                            self.balltable[i].x = brick.x - 8
                        
                        -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                        -- so that flush corner hits register as Y flips, not X flips
                        elseif self.balltable[i].x + 6 > brick.x + brick.width and self.balltable[i].dx < 0 then
                            
                            -- flip x velocity and reset position outside of brick
                            self.balltable[i].dx = -self.balltable[i].dx
                            self.balltable[i].x = brick.x + 32
                        
                        -- top edge if no X collisions, always check
                        elseif self.balltable[i].y < brick.y then
                            
                            -- flip y velocity and reset position outside of brick
                            self.balltable[i].dy = -self.balltable[i].dy
                            self.balltable[i].y = brick.y - 8
                        
                        -- bottom edge if no X collisions or top collision, last possibility
                        else
                            
                            -- flip y velocity and reset position outside of brick
                            self.balltable[i].dy = -self.balltable[i].dy
                            self.balltable[i].y = brick.y + 16
                        end

                        -- slightly scale the y velocity to speed up the game, capping at +- 150
                        if math.abs(self.balltable[i].dy) < 150 then
                            self.balltable[i].dy = self.balltable[i].dy * 1.02
                        end

                        -- only allow colliding with one brick, for corners
                        break
                    end
                end
            end
        end
    end
    -- below bounds - if a ball goes below bounds set to not in play. if all balls have gone below bounds, revert to serve state and decrease health

    for i = 1, 3, 1 do
        if self.balltable[i] then
            if self.balltable[i].inplay then
                if self.balltable[i].y >= VIRTUAL_HEIGHT then
                    self.balltable[i].inplay = false
                    outOfPlay = outOfPlay + 1
                    if outOfPlay == 3 or (not self.balltable[2] and not self.balltable[3]) then
                        self.health = self.health - 1
                        -- reduce paddle size if paddle is not small already
                        if self.paddle.size > 1 then
                            self.paddle.size = self.paddle.size - 1
                        end
                        -- if necessary, change paddle width parameter so that ball is centered on paddle in serve state
                        if self.paddle.size == 1 then
                            self.paddle.width = 32
                        elseif self.paddle.size == 2 then
                            self.paddle.width = 64
                        elseif self.paddle.size == 3 then
                            self.paddle.width = 96
                        else
                            self.paddle.width = 128
                        end
                        gSounds['hurt']:play()
                        if self.health == 0 then
                            gStateMachine:change('game-over', {
                                score = self.score,
                                highScores = self.highScores
                            })
                        else
                            gStateMachine:change('serve', {
                                paddle = self.paddle,
                                bricks = self.bricks,
                                health = self.health,
                                score = self.score,
                                highScores = self.highScores,
                                level = self.level,
                                recoverPoints = self.recoverPoints
                            })
                        end
                    end
                end
            end
        end
    end
    

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- escape key quit functionality
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    --self.balltable[1]:render()
    if self.powerup and self.powerup.inplay then
        self.powerup:render()
    end

    for i = 1, 3, 1 do
        if self.balltable[i] then
            if self.balltable[i].inplay then
                self.balltable[i]:render()
            end
        end
    end
    renderScore(self.score)
    renderHealth(self.health)

--print powerupTimer for debuggin
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf(tostring(math.modf(powerupTimer)), 50, 100, VIRTUAL_WIDTH, 'left')
    love.graphics.printf(tostring(randomTime), 50, 150, VIRTUAL_WIDTH, 'left')
    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end