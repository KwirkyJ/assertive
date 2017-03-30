---Library providing assert routines for common patterns:
-- 
-- assertError([msg,] [exp_errmsg,] f, ...)
-- assertEquals(a, b[, msg])
-- assertNotEquals(a, b[, msg])
-- assertAlmostEquals(a, b[, delta][, msg])
-- assert<Type>(a[, msg])
-- assertNot<Type>(a[, msg])
--
-- Derived from LuaUnit authored by:
--   Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
--   Philippe Fremy <phil@freehackers.org>
--   Ryan P. <rjpcomputing@gmail.com>
-- 
-- Author:  J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Date:    2016
-- Version: 1.1.0
-- License: MIT (X11) License



local Tables = require 'moretables'

local USE_EXPECTED_ACTUAL = false
local DEFAULT_DELTA = 1e-12

local typenames = {"Nil", "Boolean", "Number", "String", "Table",
                   "Function", "Thread", "Userdata"}



-- table/class for module settings
local assertive = {}
assertive._VERSION = "1.1.0"
assertive.delta    = DEFAULT_DELTA
assertive.use_ea   = USE_EXPECTED_ACTUAL

assertive.getDelta = function(self)
    return self.delta
end

assertive.setDelta = function(self, d)
    d = d or DEFAULT_DELTA
    assert(type(d) == 'number', 'delta must be number')
    self.delta = d
end

assertive.getExpectedActual = function(self)
    return self.use_ea
end

assertive.setExpectedActual = function(self, use_ea)
    use_ea = use_ea or USE_EXPECTED_ACTUAL
    assert(type(use_ea) == 'boolean', 'use_ea must be boolean')
    self.use_ea = use_ea
end



---- UTILITY ROUTINES ------------------------------------------------------

---Wrapper for tostring to differentiate string types.
-- @param v Value to convert to string.
-- @return {String} tostring(v) iff not already a string;
--                  else '<v>'.
local function wrapValue(s)
    if type(s) == 'string' then 
        return "'".. s .. "'" 
    end
    return Tables.tostring(s)
end

---Trim a string like 'test_file.lua:125: assertion failed!\n' 
-- to 'assertion failed!'
-- @param s {String}
-- @error Iff s is not a {String}.
-- @return {String}
local function stripErrMsgHeader(s)
    assert (type(s) == 'string', 's must be a string!')
    s = s:gsub('^%s*(.-)%s*$', '%1') -- remove whitspace
    return s:gsub('.*:%d+: (.-)', '%1') -- assuming ':%d+: ' is the line num
end



---- ASSERT ROUTINES -------------------------------------------------------

---assertError(f, ...)
-- assertError(errmsg, f, ...)
-- assertError(msg, errmsg, f, ...)
-- Assert that the provided function raises an error:
-- e.g., assertError(f,1,2) -> f(1,2) raises error.
-- @param msg {String} Optional custom error message.
-- @param errmsg {String} Optional string expected to match message generated
--               by failing function; iff (errmsg, f,...) errmsg must exist;
--               iff (msg, errmsg, f,...) errmsg must be string or nil.
-- @param f   {Function} Function expected to cause error
-- @param ... {any} Additional arguments to pass to 'f'.
-- @error Raised (1) iff the given function raises no error or
--        (2) iff the raised error does not produce the expected message;
--        if no custom message is provided, one is generated.
assertive.assertError = function(arg1, arg2, arg3, ...)
    local f, msg, errmsg, success, err
    if  type(arg1) == 'string'
    and (type(arg2) == 'string' or arg2 == nil)
    and type(arg3) == 'function'
    then
        msg, errmsg, f = arg1, arg2, arg3
        success, err = pcall(f, ...)
    elseif type(arg1) == 'string' 
    and    type(arg2) == 'function'
    then
        errmsg, f = arg1, arg2
        success, err = pcall(f, arg3, ...)
    elseif type(arg1) == 'function' then
        success = pcall(arg1, arg2, arg3, ...)
    else
        msg = 'assertError received args in an unrecognized pattern!\n'..
              'requires: (function, ...) or (string, function, ...) '..
              'or (string, string|nil, function, ...)\nbut was:  ('
        local args = {arg1, arg2, arg3, ...}
        for i=1, #args do
            msg = msg .. type(args[i]) .. ', '
            if type(args[i]) == 'function' then
                msg = msg .. '...'
                break
            end
            --msg = string.format('%s\n  %s', msg, type(args[i]))
        end
        if msg:sub(-2, -1) == ', ' then
            msg = msg:sub(1, -3)
        end
        msg = msg .. ')'
        error(msg) -- not level 2; error is in assertError
    end
    
    if success then
        error(msg or 'No error generated', 2)
    elseif errmsg then
        err = stripErrMsgHeader(err)
        if err ~= errmsg then 
            error(msg or 'Error messages do not match'..
                         "\nexpected: "..wrapValue(errmsg)..
                         "\nactual:   "..wrapValue(err),
                  2)
        end
    end
end

---Check that two values are the same;
-- assertEquals(actual, expected[, msg])
-- arg order 'expected, actual' iff USE_EXPECTED_ACTUAL;
-- compares nested contents of tables if applicable.
-- @param actual
-- @param expected
-- @param msg {String} Optional custom error message.
-- @error Raised iff <expected> ~= <actual>.
assertive.assertEquals = function(actual, expected, msg)
    if assertive:getExpectedActual() then
        expected, actual = actual, expected
    end
    
    if 'table' == type(expected) then
        if 'table' ~= type(actual) 
        or not Tables.alike(actual, expected, 0, true) 
        then
            error(msg or "table expected:\n"..
                          wrapValue(expected).."\nactual:\n"..
                          wrapValue(actual),
                  2)
        end
    elseif actual ~= expected then
        error(msg or "expected: "..wrapValue(expected)..
                     ", actual: "..wrapValue(actual),
              2)
    end
end

---assert<Type>(v[, msg])
-- @param v Value to check for expected type.
-- @param msg {String} Optional error message.
-- @error Raised iff type(<v>) ~= <type>.
for _, Typename in ipairs(typenames) do
    local typename = Typename:lower()
    local fName = 'assert'..Typename
    assertive[fName] = function(v, msg)
        local actualtype = type(v)
        if actualtype ~= typename then
            error(msg or "expected "..typename.." type but was "..actualtype,
                  2)
        end
    end
end

---assertNot<Type>(v[, msg])
-- @param v Value to check for expected type.
-- @param msg {String} Optional error message.
-- @error Raised iff type(<v>) == <type>.
for _, Typename in ipairs(typenames) do
    local typename = Typename:lower()
    local fName = "assertNot"..Typename
    assertive[fName] = function(v, msg)
        if type(v) == typename then
            error(msg or 'unexpected '..typename, 2)
        end
    end
end

---assertNotEquals(v1, v2[, msg])
-- Check that two values are not the same;
-- compares nested contents of tables if applicable.
-- @param v1
-- @param v2
-- @param msg {String} Optional custom error message.
-- @error Raised iff v1 == v2.
assertive.assertNotEquals = function(v1, v2, msg)
    if type(v1) == type(v2) then
        if (type(v1) == 'table' and Tables.alike(v1, v2, 0, true))
        or v1 == v2
        then
            error(msg or ("unexpected equivalent values: "..wrapValue(v1)), 2)
        end
    end
end

---Used to determine of two numbers are nearly equal;
-- assertAlmostEquals(actual, expected [, delta] [, msg])
-- arg order 'expected, actual' iff asserts:getExpectedActual().
-- @param actual   {Number}
-- @param expected {Number}
-- @param delta    {Number} Optional tolerance (default: assertive.delta).
-- @param msg      {String} Optional user-defined error message.
-- @error Raised iff |(|expected| - |actual|)| > delta.
assertive.assertAlmostEquals = function(actual, expected, delta, msg)
    if assertive:getExpectedActual() then
        actual,expected = expected, actual
    end
    delta = delta or assertive.delta
    
    local d_type, e_type, a_type = type(delta), type(expected), type(actual)
    if d_type ~= 'number' then
        error (string.format ("delta must be a number but was %s",
                              d_type),
               2)
    end
    if a_type ~= e_type then
        error (string.format ("type mismatch: expected %s but was %s", 
                              e_type, a_type),
               2)
    end
    if type(msg) ~= 'string' then msg = nil end
    if a_type == 'number' then
        if math.abs(actual - expected) > delta then
            msg = msg or 
                  'values differ beyond allowed tolerance of ' .. delta .. 
                  ' :\n\tactual   : ' .. actual .. '\n\texpected : '.. expected
            error(msg, 2)
        end
    elseif a_type == 'table' then
        local ok, err = Tables.alike (actual, expected, delta)
        if not ok then 
            error (msg or err, 2)
        end
    else 
        if assertive:getExpectedActual() then 
            -- re-invert
            return assertive.assertEquals (expected, actual, msg)
        else
            return assertive.assertEquals (actual, expected, msg)
        end
    end
end



return assertive

