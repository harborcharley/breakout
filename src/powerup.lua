--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a powerup which spawns randomly and which, if caught by the player, 
    adds two new Ball objects which behave identically to the original should spawn and
    remain in play until the player wins the level
]]

Powerup = Class {}

function Powerup:init()
    -- positional variables
    self.x = VIRTUAL_WIDTH / 2 - 8
    self.y = 50
    -- size variables
    self.width = 16
    self.height = 16
    -- velocity variables
    self.dx = 0
    self.dy = 50
    -- should powerup be rendered?
    self.inplay = true
end
function Powerup:collides(target)
    --first check to see if the left edge of either is farther to the right
    -- than the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end
    -- then check to see if the bottom edge of either is is higher than
    -- the top edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true they overlap
    self.inplay = false
    return true
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    if self.inplay == true then
        love.graphics.draw(gTextures['main'], gFrames['powerup'], self.x, self.y)
    end
    
end

