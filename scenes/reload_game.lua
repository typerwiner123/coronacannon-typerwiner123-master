-- This a helper buffer scene.
-- It reloads game scene (game scene can't reload by itself) and shows a loading animation.

local composer = require('composer')
local relayout = require('libs.relayout')

local scene = composer.newScene()

function scene:create()
    local _W, _H, _CX, _CY = relayout._W, relayout._H, relayout._CX, relayout._CY

    local group = self.view

    local background = display.newImage( group, 'images/background/nope.png', _W, _H)
  	background.x=display.contentCenterX
  	background.y=display.contentCenterY

    --local background = display.newRect(group, _CX, _CY, _W, _H)
    --background.fill = {
        --type = 'gradient',you
        --color1 = {0.5, 0.9, 0.5},
        --color2 = {0.8, 1, 1}
    --}
    relayout.add(background)

    local label = display.newText({
		parent = group,
		text = 'PLEASE WAIT...',
		x = _W - 32, y = _H - 32,
		font = native.systemFontBold,
		fontSize = 32
	})
    label.anchorX, label.anchorY = 1, 1
    relayout.add(label)

    local ballsGroup = display.newGroup()
	ballsGroup.x, ballsGroup.y = _CX, _CY
	group:insert(ballsGroup)
	relayout.add(ballsGroup)

    -- Display three revolving cannon balls
    for i = 0, 2 do
        local ball = display.newImageRect(ballsGroup, 'images/ammo/normal.png', 64, 64)
        ball.x, ball.y = 0, 0
        ball.anchorX = -0.5
        ball.rotation = 120 * i
        transition.to(ball, {time = 1500, rotation = 360, delta = true, iterations = -1})
    end
end

function scene:show(event)
    if event.phase == 'will' then
        -- Preload the scene
        composer.loadScene('scenes.game', {params = event.params})
    elseif event.phase == 'did' then
        -- Show it after a moment
        timer.performWithDelay(500, function()
            composer.gotoScene('scenes.game', {params = event.params})
        end)
    end
end

scene:addEventListener('create')
scene:addEventListener('show')

return scene
