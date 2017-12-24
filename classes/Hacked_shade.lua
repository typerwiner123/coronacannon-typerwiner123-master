-- Shade
-- Shades the background group and makes it impossible to touch.
-- Used to show the sidebar or the end level popup.

local relayout = require('libs.relayout')

local _M = {}

function _M.newHacked_Shade(group)
	local Hacked_shade = display.newRect(group, relayout._CX, relayout._CY, relayout._W, relayout._H)
	Hacked_shade:setFillColor(0)
	Hacked_shade.alpha = 0
	transition.to(Hacked_shade, {time = 200, alpha = 0.5})

	-- Prevent tapping
	function Hacked_shade:tap()
		return true
	end
	Hacked_shade:addEventListener('tap')

	-- Prevent touching
	function Hacked_shade:touch()
		return true
	end
	Hacked_shade:addEventListener('touch')

	function Hacked_shade:hide()
		transition.to(self, {time = 200, alpha = 0, onComplete = function(object)
			object:removeSelf()
		end})
	end

	relayout.add(Hacked_shade)

	return Hacked_shade
end

return _M
