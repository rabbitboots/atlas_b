**NOTE:** This is a beta.

# AtlasB

AtlasB is a texture atlas packing library for the [LÖVE](https://love2d.org/) framework. It uses a binary packing algorithm to place smaller graphics into a combined square image with power-of-two dimensions.


# Workflow

1. Create an atlas object: `atlasB.newAtlas`

2. Add LÖVE ImageData objects to the atlas: `atlas:addBox()` or `atlas:addBoxes()`

3. Arrange the atlas, specifying a minimum and maximum allowed size: `atlas:arrange()`

4. If the arrangement was successful, render the atlas out to a new ImageData: `atlas:renderImageData()`

5. Get the new rectangle positions from `atlas.boxes`: `box.x`, `box.y`, `box.iw`, `box.ih`

See *main.lua* for an interactive example.


# API

## atlasB.newAtlas

Makes an atlas object.

`local atlas = atlasB.newAtlas(padding, extrude)`

* `padding`: *(0)* The amount of padding (in pixels) to apply around boxes. When padding is an odd number, the graphic is biased towards the upper-left.
* `extrude`: *(false)* Whether to extrude (or "bleed") the edges of each graphic in a one-pixel perimeter. When used, *padding* must be at least 2.

**Returns:** The new atlas object.


## atlas:addBox

Adds a box (a table with ImageData and coordinate information) to the atlas. Use this if you want to pull in multiple rectangles from a single ImageData.

`local success = atlas:addBox(i_data, image_id, x, y, w, h)`

* `i_data`: The source ImageData.
* `image_id`: Optional variable to use for tie-breaking when sorting boxes. This is typically the source image filename.
* `x`, `y`, `w`, `h`: The rectangular pixel area to use.

**Returns:** The new box table, for tagging with additional bookkeeping info.


## atlas:addBoxes

Adds a set of boxes from an array of ImageData objects, with one box per ImageData. Use this if your graphics are stored as single images instead of spritesheets.

`atlas:addBoxes(i_datas, image_ids)`

* `i_datas`: Sequence of LÖVE ImageData objects.
* `image_ids`: Optional hash table where the keys are the ImageData objects featured in `i_datas`. The values are strings (typically an image's filename) which are used as tie-breakers when sorting the boxes.


## atlas:arrange

Tries to arrange the atlas boxes in a square layout.

`local success = atlas:arrange(min, max)`

* `min`: The minimum allowed atlas pixel size. Either this value or the total area of all boxes is used, whichever is greater.
* `max`: The maximum allowed atlas pixel size.

**Returns:** The final size of the layout on success, or `false` on failure. On success, the array of boxes are modified in place.


## atlas:renderImageData

Renders the atlas layout to an ImageData.

`local image_data = atlas:renderImageData(pixel_format, r, g, b, a)`

* `pixel_format` Optional [PixelFormat](https://love2d.org/wiki/PixelFormat) string to use when creating the ImageData.
* `r`, `g`, `b`, `a`: An optional initial color for the ImageData. Range: (0.0 - 1.0).

**Returns:** An ImageData based on the atlas box layout.


# MIT License

Copyright (c) 2023 RBTS

Binary tree packing code is based on:
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
