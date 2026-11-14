local curved_rail_a = require("scripts.masks.curved_rail_a")
local curved_rail_b = require("scripts.masks.curved_rail_b")
local straight_rail = require("scripts.masks.straight_rail")
local half_diagonal_rail = require("scripts.masks.half_diagonal_rail")
local rail_ramp = require("scripts.masks.rail_ramp")

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
    ["rail_ramp"] = rail_ramp,
}

--- Search for official DLC mods elevated rails
if script.active_mods["elevated-rails"] then
    elevated_available = true
end

--- Search for all mods containing the string to accomodate for forks
for mod_name in pairs(script.active_mods) do
    if string.find(mod_name, "naked-rails", 1, true) then
        naked_available = true
    end
end

--- add naked rails only
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

-- add elevated naked rails only
if elevated_available then
    masks["elevated-curved-rail-a"] = masks["curved-rail-a"]
    masks["elevated-curved-rail-b"] = masks["curved-rail-b"]
    masks["elevated-straight-rail"] = masks["straight-rail"]
    masks["elevated-half-diagonal-rail"] = masks["half-diagonal-rail"]
    masks["rail-ramp"] = masks["rail_ramp"]
end

--- add naked elevated rails
if elevated_available and naked_available then
    masks["naked-rail-ramp"] = masks["rail_ramp"]
    
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
