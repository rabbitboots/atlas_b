-- (BETA)
--[[
AtlasB: A texture atlas generator using a binary packing algorithm.
The resulting textures are always square and power-of-two in size.
--]]

--[[
MIT License

AtlasB: Copyright (c) 2023 RBTS


packBin is based on:
https://github.com/jakesgordon/bin-packing/blob/master/js/packer.js

Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 Jake Gordon and contributors
Lua version (c) 2020, 2023 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local atlasB = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local packBin = require(REQ_PATH .. "pack_bin")


local _mt_ab = {}
_mt_ab.__index = _mt_ab


-- * General *


local function errMustBeIntGE1(arg_n)
	error("argument #" .. arg_n .. ": must be an integer >= 1.", 2)
end


local function errOptionalIntGE0(arg_n)
	error("argument #" .. arg_n .. ": expected false/nil or an integer >= 0.", 2)
end


local function errArgType(n, expected, val)
	error("argument #" .. n .. ": bad type (expected " .. expected .. ", got " .. type(val) .. ")", 2)
end


-- * / General *


function atlasB.newAtlas(padding, extrude)

	-- Assertions
	-- [[
	if padding and (type(padding) ~= "number" or math.floor(padding) ~= padding) then errOptionalIntGE0(1) end
	--]]

	if extrude and padding and padding < 2 then
		error("when extruding, padding must be at least 2 pixels.")
	end

	local self = setmetatable({}, _mt_ab)

	self.padding = padding or 0
	self.extrude = extrude or false

	-- Is a number when boxes are successfully arranged.
	self.arranged_size = false

	self.boxes = {}

	return self
end


-- The default sorting function.
function _mt_ab.boxSort(a, b)

	-- Order tallest to shortest
	if a.h ~= b.h then
		return a.h > b.h

	-- Tiebreaker: Widest to thinnest
	elseif a.w ~= b.w then
		return a.w > b.w

	-- Tiebreaker: Lowest Y
	elseif a.y ~= b.y then
		return a.y > b.y

	-- Tiebreaker: Lowest X
	elseif a.x ~= b.x then
		return a.x > b.x

	-- Tiebreaker: Order alphabetically by provided ID (typically a filename)
	elseif a.id and b.id then
		return a.id > b.id

	-- User didn't provide ID strings: give up
	else
		return tostring(a.i_data) > tostring(b.i_data)
	end
end


function _mt_ab:calculateArea()

	local area = 0

	for i, box in ipairs(self.boxes) do
		area = area + box.w * box.h
	end

	return area
end


function _mt_ab:addBox(i_data, image_id, x, y, w, h)

	-- Assertions
	-- [[
	if type(i_data) ~= "userdata" then errArgType(1, "userdata (LÖVE ImageData)", type(i_data))
	-- 'image_id' is optional and can be anything that is usable with a comparison operator.
	-- TODO: coordinate and dimension checks.
	end
	--]]

	local box = {}
	box.i_data = i_data
	if image_id then
		box.id = image_id
	end

	-- Source rectangle within the ImageData
	box.ix = x
	box.iy = y
	box.iw = w
	box.ih = h

	-- Padded destination rectangle (to be placed later)
	box.x = 0
	box.y = 0
	box.w = w + self.padding
	box.h = h + self.padding

	table.insert(self.boxes, box)

	return box
end


function _mt_ab:addBoxes(i_datas, image_ids)

	for i, i_data in ipairs(i_datas) do
		self:addBox(i_data, image_ids[i_data], 0, 0, i_data:getWidth(), i_data:getHeight())
	end
end


function _mt_ab:arrange(min, max)

	-- Assertions
	-- [[
	if type(min) ~= "number" or min < 1 or math.floor(min) ~= min then errMustBeIntGE1(1)
	elseif type(max) ~= "number" or max < 1 or math.floor(max) ~= max then errMustBeIntGE1(2) end
	--]]

	self.arranged_size = false

	table.sort(self.boxes, self.boxSort)

	local pad = self.padding

	local area_sq = math.sqrt(self:calculateArea())
	local size = 1

	local success
	while size <= max do
		-- Skip sizes that are smaller than the combined area of all boxes and padding.
		if size - pad >= area_sq and size >= min then
			local bin = packBin.newBin(size - pad, size - pad)

			if bin:fitBoxes(self.boxes) then
				success = true
				break
			end
		end

		size = size * 2
	end

	if not success then
		return false
	end

	-- Apply padding offset to all boxes. In case of odd padding, shift box to the upper-left.
	local pad_12 = math.floor(pad/2)
	for _, box in ipairs(self.boxes) do
		box.x = box.x + pad_12
		box.y = box.y + pad_12
	end

	self.arranged_size = size

	return size
end


local def_r, def_g, def_b, def_a = 0, 0, 0, 0
local function mapPixel_setDefaultColor(x, y, r, g, b, a)
	return def_r, def_g, def_b, def_a
end


function _mt_ab:renderImageData(pixel_format, r, g, b, a)

	if not self.arranged_size then
		error("atlas boxes must be successfully arranged before an ImageData can be rendered.")
	end

	local i_data = love.image.newImageData(self.arranged_size, self.arranged_size, pixel_format)
	if r then
		def_r, def_g, def_b, def_a = r, g, b, a
		i_data:mapPixel(mapPixel_setDefaultColor)
	end

	for i, box in ipairs(self.boxes) do
		-- [[DBG]] print(i, box, box.x, box.y, box.iw, box.ih, box.i_data)
		i_data:paste(box.i_data, box.x, box.y, box.ix, box.iy, box.iw, box.ih)

		if self.extrude then
			--[[
			+-+---+-+
			|5| 1 |6|
			+-+---+-+
			| |   | |
			|3|   |4|
			| |   | |
			+-+---+-+
			|7| 2 |8|
			+-+---+-+
			--]]
			-- Edges: top, bottom, left, right
			if box.y > 0 then
				i_data:paste(box.i_data, box.x, box.y - 1, box.ix, box.iy, box.iw, 1)
			end
			if box.y + box.ih <= self.arranged_size then
				i_data:paste(box.i_data, box.x, box.y + box.ih, box.ix, box.iy + box.ih - 1, box.iw, 1)
			end
			if box.x > 0 then
				i_data:paste(box.i_data, box.x - 1, box.y, box.ix, box.iy, 1, box.ih)
			end
			if box.x + box.iw <= self.arranged_size then
				i_data:paste(box.i_data, box.x + box.iw, box.y, box.ix + box.iw - 1, box.iy, 1, box.ih)
			end

			-- Corner pixels: upper-left, upper-right, bottom-left, bottom-right
			if box.x > 0 and box.y > 0 then
				i_data:paste(box.i_data, box.x - 1, box.y - 1, box.ix, box.iy, 1, 1)
			end
			if box.x + box.iw <= self.arranged_size and box.y > 0 then
				i_data:paste(box.i_data, box.x + box.iw, box.y - 1, box.ix + box.iw - 1, box.iy, 1, 1)
			end
			if box.x > 0 and box.y + box.ih <= self.arranged_size then
				i_data:paste(box.i_data, box.x - 1, box.y + box.ih, box.ix, box.iy + box.ih - 1, 1, 1)
			end
			if box.x + box.iw <= self.arranged_size and box.y + box.ih <= self.arranged_size then
				i_data:paste(box.i_data, box.x + box.iw, box.y + box.ih, box.ix + box.iw - 1, box.iy + box.ih - 1, 1, 1)
			end
		end
	end

	return i_data
end


return atlasB