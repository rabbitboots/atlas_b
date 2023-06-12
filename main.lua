-- (BETA)
-- AtlasB demonstration.
require("demo_lib.strict")
local quickPrint = require("demo_lib.quick_print.quick_print")


love.keyboard.setKeyRepeat(true)


local atlasB = require("atlas_b")


local spritesheet1 = love.image.newImageData("demo_res/boxes.png")
local spritesheet2 = love.image.newImageData("demo_res/circles.png")


local demo_font = love.graphics.newFont(14)
local demo_padding = 0
local demo_extrude = false
local demo_gran = false
local demo_render_boxes = false

local demo_incl_s1 = true
local demo_incl_s2 = true


local qp = quickPrint.new()


-- The atlas object.
local atl


-- Resulting ImageData, and a texture that we'll use to show the results.
local i_data
local img


-- The two images loaded above have the same layout, so this list of quads is applicable to both.
local quads = {
	four         = {x =   8, y =   8, w =   4, h =   4},
	eight        = {x =  16, y =   8, w =   8, h =   8},
	twelve       = {x =  28, y =   8, w =  12, h =  12},
	sixteen      = {x =   8, y =  20, w =  16, h =  16},
	twenty       = {x =  28, y =  24, w =  20, h =  20},
	twenty_four  = {x =  52, y =   8, w =  24, h =  24},
	twenty_eight = {x =   8, y =  48, w =  28, h =  28},
	thirty_two   = {x =  40, y =  48, w =  32, h =  32},
	thirty_six   = {x =  80, y =   8, w =  36, h =  36},
	forty        = {x =  80, y =  48, w =  40, h =  40},
	forty_four   = {x =   8, y =  88, w =  44, h =  44},
	forty_eight  = {x =  56, y =  92, w =  48, h =  48},
	fifty_two    = {x =   8, y = 144, w =  52, h =  52},
	fifty_six    = {x =  64, y = 144, w =  56, h =  56},
	sixty        = {x = 132, y =  12, w =  60, h =  60},
	sixty_four   = {x = 128, y =  84, w =  64, h =  64},
	sixty_eight  = {x = 124, y = 152, w =  68, h =  68},
	tablet1      = {x = 196, y =  12, w =  12, h =  16},
	tablet2      = {x = 212, y =  12, w =  12, h =  16},
	tablet3      = {x = 196, y =  32, w =  12, h =  16},
	tablet4      = {x = 212, y =  32, w =  12, h =  16},
}


local function setupAtlas()

	atl = atlasB.newAtlas(demo_padding, demo_extrude, demo_gran)

	if demo_incl_s1 then
		for id, quad in pairs(quads) do
			atl:addBox(quad.x, quad.y, quad.w, quad.h, spritesheet1, "sq_" .. id)
		end
	end
	if demo_incl_s2 then
		for id, quad in pairs(quads) do
			atl:addBox(quad.x, quad.y, quad.w, quad.h, spritesheet2, "ci_" .. id)
		end
	end

	local size = atl:arrange(1, 4096)
	if not size then
		print("atlas:arrange() failed.")
		return
	end
	print("atlas size: " .. size)

	if i_data then
		i_data:release()
	end
	i_data = atl:renderImageData()

	if img then
		img:release()
	end
	img = love.graphics.newImage(i_data)

	print("Box output:")
	for i, box in ipairs(atl.boxes) do
		print("#" .. i
			.. " ID: " .. box.id
			.. " XYWH: " .. box.x .. ", " .. box.y .. ", " .. box.w .. ", " .. box.h
		)
	end
end
setupAtlas()


function love.keypressed(kc, sc)

	if kc == "escape" then
		love.event.quit()

	elseif kc == "left" then
		demo_padding = math.max(0, demo_padding - 1)
		setupAtlas()

	elseif kc == "right" then
		demo_padding = demo_padding + 1
		setupAtlas()

	elseif kc == "lshift" or kc == "rshift" then
		demo_gran = not demo_gran
		setupAtlas()

	elseif kc == "space" then
		demo_extrude = not demo_extrude
		setupAtlas()

	elseif kc == "tab" then
		demo_render_boxes = not demo_render_boxes

	elseif kc == "1" then
		demo_incl_s1 = not demo_incl_s1
		setupAtlas()

	elseif kc == "2" then
		demo_incl_s2 = not demo_incl_s2
		setupAtlas()
	end
end


function love.draw()

	-- Background
	love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Atlas body indicator
	if demo_render_boxes and atl.arranged_size then
		love.graphics.setColor(0.0, 0.0, 0.0, 0.5)
		love.graphics.rectangle("fill", 0, 0, atl.arranged_size, atl.arranged_size)
		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	end

	-- Atlas texture
	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	if img then
		love.graphics.draw(img, 0, 0)
	end

	-- Atlas boxes
	if demo_render_boxes and atl.arranged_size then
		for i, box in ipairs(atl.boxes) do
			love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
		end
	end

	-- HUD / status
	love.graphics.origin()

	qp:reset()
	local hud_h = (demo_font:getHeight() + 2) * 3
	local hud_y = love.graphics.getHeight() - hud_h
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, hud_y, love.graphics.getWidth(), hud_h)
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(demo_font)
	qp:movePosition(0, hud_y + 2)
	qp:write("Left/Right: Padding (", demo_padding, ")\tSpace: Extrusion (", demo_extrude, ")\tShift: granular (", demo_gran, ")\tTab: show layout (", demo_render_boxes, ")\t1,2: toggle spritesheet inclusion")
	qp:down()
	qp:write("Esc: quit")
	if atl.arranged_size then
		qp:write("\tAtlas size: ", atl.arranged_size)
	end
end
