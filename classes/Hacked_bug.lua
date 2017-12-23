-- Bugs
-- Main enemies in the game

local physics = require('physics')
local sounds = require('libs.sounds')

local _M = {}

local newPuff = require('classes.puff').newPuff

function _M.newHacked_Bug(params)
	local Hacked_bug = display.newImageRect(params.g, 'images/enemy.png', 64, 64)
	Hacked_bug.x, Hacked_bug.y = params.x, params.y
	physics.addBody(Hacked_bug, 'dynamic', {density = 2, friction = 0.5, bounce = 0.5, radius = Hacked_bug.width * 0.4})
	Hacked_bug.angularDamping = 3  -- Prevent from rolling for too long
	Hacked_bug.isAlive = true

	function Hacked_bug:destroy()
		sounds.play('bug')
		self.isAlive = false
		newPuff({g = params.g, x = self.x, y = self.y})
		timer.performWithDelay(1, function()
			self:removeSelf()
		end)
	end

	function Hacked_bug:postCollision(event)
		-- Increase this value to make the bugs stronger
		if event.force > 30 and self.isAlive then
			self:destroy()
		end
	end
	Hacked_bug:addEventListener('postCollision')

	return Hacked_bug
end

return _M
