-- Cannon ball
-- There are two types of canonn balls: normal and bomb

local physics = require('physics')
local sounds = require('libs.sounds')

local _M = {}

local newPuff = require('classes.puff').newPuff

function _M.newHacked_Ball(params)
	local Hacked_ball = display.newImageRect(params.g, 'images/ammo/' .. params.type .. '.png', 48, 48)
	Hacked_ball.x, Hacked_ball.y = params.x, params.y
	-- While the ball rests near the cannon, it's static
	physics.addBody(Hacked_ball, 'static', {density = 2, friction = 0.5, bounce = 0.5, radius = Hacked_ball.width / 2})
	Hacked_ball.isBullet = true -- More accurate collision detection
	Hacked_ball.angularDamping = 3 -- Prevent the ball from rolling for too long
	Hacked_ball.type = params.type

	function Hacked_ball:launch(dir, force)
		dir = math.rad(dir) -- We need the direction angle in radians for calculations below
		Hacked_ball.bodyType = 'dynamic' -- Change to dynamic so it can move
		Hacked_ball:applyLinearImpulse(force * math.cos(dir), force * math.sin(dir), Hacked_ball.x, Hacked_ball.y)
		Hacked_ball.isLaunched = true
	end

	function Hacked_ball:explode()
		sounds.play('explosion')
		local radius = 600 -- Explosion radius, all objects touching this area will be affected by the explosion
		local area = display.newCircle(params.g, self.x, self.y, radius)
		area.isVisible = false
		physics.addBody(area, 'dynamic', {isSensor = true, radius = radius})

		-- The trick is to create a large circle, grab all collisions and destroy it
		local affected = {} -- Keep affected bodies here
		function area:collision(event)
			if event.phase == 'began' then
				if not affected[event.other] then
					affected[event.other] = true
					local x, y = event.other.x - self.x, event.other.y - self.y
					local dir = math.atan2(y, x) * 180 / math.pi
					local force = (radius - math.sqrt(x ^ 2 + y ^ 2)) * 4 -- Reduce the force with the distance from the explosion
					-- If an object touches the explosion, the force will be at least this big
					if force < 80 then
						force = 80
					end
					event.other:applyLinearImpulse(force * math.cos(dir), force * math.sin(dir), event.other.x, event.other.y)
				end
			end
		end
		area:addEventListener('collision')
		timer.performWithDelay(1, function()
			area:removeSelf()
		end)

		self:removeSelf()
	end

	function Hacked_ball:destroy()
		-- The ball can either be destroyed as a normal one or as bomb with an explosions
		newPuff({g = params.g, x = self.x, y = self.y, isExplosion = self.type == 'bomb'})
		if self.type == 'bomb' or self.type == 'balls' then
			self:explode()
		else
			sounds.play('ball_destroy')
			self:removeSelf()
		end
	end

	return Hacked_ball
end

return _M
