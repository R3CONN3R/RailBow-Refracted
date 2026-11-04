local curved_rail_a = require("scripts.masks.curved_rail_a")
local curved_rail_b = require("scripts.masks.curved_rail_b")
local straight_rail = require("scripts.masks.straight_rail")
local half_diagonal_rail = require("scripts.masks.half_diagonal_rail")
local elevated_available = false
local naked_available = false

--- @class TileInfo
--- @field pos Vector
--- @field n Vector
--- @field o boolean

--- @class Mask
--- @field table table<integer, TileInfo[]>|nil

local masks = {
    ["curved-rail-a"] = curved_rail_a,
    ["curved-rail-b"] = curved_rail_b,
    ["straight-rail"] = straight_rail,
    ["half-diagonal-rail"] = half_diagonal_rail,
}

if script.active_mods["elevated-rails"] then
    elevated_available = true
    masks["elevated-curved-rail-a"] = masks["curved-rail-a"]
    masks["elevated-curved-rail-b"] = masks["curved-rail-b"]
    masks["elevated-straight-rail"] = masks["straight-rail"]
    masks["elevated-half-diagonal-rail"] = masks["half-diagonal-rail"]
    masks["rail-ramp"] = require("scripts.masks.rail_ramp")
end

for mod_name in pairs(script.active_mods) do
    if string.find(mod_name, "naked-rails", 1, true) then
        naked_available = true
    end
end

if naked_available then
    masks["naked-curved-rail-a"] = masks["curved-rail-a"]
    masks["naked-curved-rail-b"] = masks["curved-rail-b"]
    masks["naked-straight-rail"] = masks["straight-rail"]
    masks["naked-half-diagonal-rail"] = masks["half-diagonal-rail"]
    masks["sleepy-curved-rail-a"] = masks["curved-rail-a"]
    masks["sleepy-curved-rail-b"] = masks["curved-rail-b"]
    masks["sleepy-straight-rail"] = masks["straight-rail"]
    masks["sleepy-half-diagonal-rail"] = masks["half-diagonal-rail"]
end

if elevated_available and naked_available then
    masks["naked-rail-ramp"] = require("scripts.masks.rail_ramp")
    
    masks["naked-elevated-curved-rail-a"] = masks["curved-rail-a"]
    masks["naked-elevated-curved-rail-b"] = masks["curved-rail-b"]
    masks["naked-elevated-straight-rail"] = masks["straight-rail"]
    masks["naked-elevated-half-diagonal-rail"] = masks["half-diagonal-rail"]
    
    masks["sleepy-elevated-curved-rail-a"] = masks["curved-rail-a"]
    masks["sleepy-elevated-curved-rail-b"] = masks["curved-rail-b"]
    masks["sleepy-elevated-straight-rail"] = masks["straight-rail"]
    masks["sleepy-elevated-half-diagonal-rail"] = masks["half-diagonal-rail"]
end

return masks
