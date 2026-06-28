-- Contents of this file have been modified from the original version available at:
-- SWeini - Train Signal Visualizer v0.1.1
-- https://mods.factorio.com/mod/train-signal-visualizer
-- MIT License
-- Copyright 2022 SWeini
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the “Software”),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom
-- the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


local function get_rail_segment(rail, direction)
    local rail_end, dir_end = rail.get_rail_segment_end(direction)
    return { rail = rail_end, direction = dir_end }
end

local function get_rail_direction(source, target)
    for i = 0, 1 do
        for j = 0, 2 do
            if source.get_connected_rail { rail_direction = i, rail_connection_direction = j } == target then
                return i
            end
        end
    end
end

local function get_rail_outgoing_segments(segment)
    local result = {}
    for i = 0, 2 do
        local rail_out = segment.rail.get_connected_rail { rail_direction = segment.direction, rail_connection_direction = i }
        if rail_out ~= nil then
            local dir_out = get_rail_direction(rail_out, segment.rail)
            local rail_end, dir_end = rail_out.get_rail_segment_end(1 - dir_out)
            table.insert(result, { rail = rail_end, direction = dir_end })
        end
    end

    return result
end

local function get_rail_incoming_segments(segment)
    local rail_start, dir_start = segment.rail.get_rail_segment_end(1 - segment.direction)
    local result = {}
    for i = 0, 2 do
        local rail_in = rail_start.get_connected_rail { rail_direction = dir_start, rail_connection_direction = i }
        if rail_in ~= nil then
            local dir_in = get_rail_direction(rail_in, rail_start)
            table.insert(result, { rail = rail_in, direction = dir_in })
        end
    end

    return result
end

local function is_signal(entity)
    if entity == nil then
        return false
    end

    return entity.type == 'rail-signal' or entity.type == 'rail-chain-signal'
end

local function get_segment_id(segment)
    return segment.rail.unit_number * 2 + segment.direction
end

local segment_states = {
    undefined = nil,
    exit_blocked = 1,
    entrance_avoided = 2
}

local function is_rail_segment_exit_blocked(segment)
    local ent_end = segment.rail.get_rail_segment_signal(segment.direction, false)
    local ent_end_opp = segment.rail.get_rail_segment_signal(segment.direction, true)
    return is_signal(ent_end_opp) and not is_signal(ent_end)
end

local function is_rail_segment_entry_blocked(segment)
    local ent_start = segment.rail.get_rail_segment_signal(1 - segment.direction, true)
    local ent_start_opp = segment.rail.get_rail_segment_signal(1 - segment.direction, false)
    return is_signal(ent_start_opp) and not is_signal(ent_start)
end

local function is_rail_segment_blocked(segment)
    return is_rail_segment_entry_blocked(segment) or is_rail_segment_exit_blocked(segment)
end

local function calculate_rail_segments(entities)
    local mark_stack = {}
    for _, signal in ipairs(entities) do
        for _, rail in ipairs(signal.get_connected_rails()) do
            for direction = 0, 1 do
                local segment = get_rail_segment(rail, direction)
                if is_rail_segment_blocked(segment) then
                    table.insert(mark_stack, segment)
                end
            end
        end
    end

    local result = {}
    local segments = {}
    while #mark_stack > 0 do
        local segment = table.remove(mark_stack)
        local segment_id = get_segment_id(segment)
        if result[segment_id] == segment_states.undefined then
            result[segment_id] = segment_states.exit_blocked
            segments[segment_id] = segment
            for _, outgoing in ipairs(get_rail_outgoing_segments(segment)) do
                local outgoing_id = get_segment_id(outgoing)
                if result[outgoing_id] == segment_states.undefined then
                    local reachable = false
                    for _, incoming in ipairs(get_rail_incoming_segments(outgoing)) do
                        local incoming_id = get_segment_id(incoming)
                        if result[incoming_id] == segment_states.undefined then
                            reachable = true
                        end
                    end

                    if not reachable then
                        table.insert(mark_stack, outgoing)
                    end
                end
            end
        end
    end

    for id, _ in pairs(result) do
        local segment = segments[id]
        for _, incoming in ipairs(get_rail_incoming_segments(segment)) do
            if result[get_segment_id(incoming)] == segment_states.undefined then
                table.insert(mark_stack, incoming)
            end
        end
    end

    while #mark_stack > 0 do
        local segment = table.remove(mark_stack)
        local segment_id = get_segment_id(segment)
        if result[segment_id] == segment_states.undefined then
            local avoid = true
            for _, outgoing in ipairs(get_rail_outgoing_segments(segment)) do
                local outgoing_id = get_segment_id(outgoing)
                if result[outgoing_id] == segment_states.undefined then
                    avoid = false
                end
            end

            if avoid then
                result[segment_id] = segment_states.entrance_avoided
                segments[segment_id] = segment

                for _, incoming in ipairs(get_rail_incoming_segments(segment)) do
                    table.insert(mark_stack, incoming)
                end
            end
        end
    end

    return result
end

--- @enum drive_directions
local DRIVE_DIRECTIONS = {
    normal = 1,
    reversed = 2,
    omnidirectional = 3
}

local drive_direction_functions = {
    [DRIVE_DIRECTIONS.normal] = function(d) return d end,
    [DRIVE_DIRECTIONS.reversed] = function(d) return -d end,
    [DRIVE_DIRECTIONS.omnidirectional] = function(d) return math.abs(d) end
}

local function get_rail_drive_direction(rail, segments)
    local state_front = segments[get_segment_id(get_rail_segment(rail, defines.rail_direction.front))]
    local state_back = segments[get_segment_id(get_rail_segment(rail, defines.rail_direction.back))]

    if (state_back == segment_states.undefined) and (state_front ~= segment_states.undefined) then
        return DRIVE_DIRECTIONS.normal
    end
    if (state_front == segment_states.undefined) and (state_back ~= segment_states.undefined) then
        return DRIVE_DIRECTIONS.reversed
    end
    return DRIVE_DIRECTIONS.omnidirectional
end

local function get_all_rail_drive_directions(signals, rails)
    local segments = calculate_rail_segments(signals)
    local result = {}
    for _, rail in ipairs(rails) do
        local direction = get_rail_drive_direction(rail, segments)
        result[rail.unit_number] = direction
    end
    return result
end

local drive_directions = {}

drive_directions.get_all = get_all_rail_drive_directions
drive_directions.mapper = drive_direction_functions

return drive_directions
