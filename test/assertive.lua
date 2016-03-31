local assertive = require 'assertive'



-- make a bunch of local aliases to show how it might be done.
-- alternatively, to add to the global namespace for any reason:
-- for k,v in pairs(assertive) do
--     if  type(v) == 'function'
--     and k:sub(1, 6) == 'assert'
--     then
--         _G[k] = v
--         -- alias assertNotEquals -> assert_not_equals
--         _G[k:gsub('(%u)', '_%1'):lower()] = v
--     end
-- end

local assertError  = assertive.assertError
local assert_error = assertive.assertError

local assertEquals  = assertive.assertEquals
local assert_equals = assertive.assertEquals

local assertNotEquals   = assertive.assertNotEquals
local assert_not_equals = assertive.assertNotEquals

local assertAlmostEquals   = assertive.assertAlmostEquals
local assert_almost_equals = assertive.assertAlmostEquals

-- assert<Type>s

local assertBoolean  = assertive.assertBoolean
local assert_boolean = assertive.assertBoolean

local assertFunction  = assertive.assertFunction
local assert_function = assertive.assertFunction

local assertNil  = assertive.assertNil
local assert_nil = assertive.assertNil

local assertNumber  = assertive.assertNumber
local assert_number = assertive.assertNumber

local assertTable  = assertive.assertTable
local assert_table = assertive.assertTable

local assertString  = assertive.assertString
local assert_string = assertive.assertString

-- assertNot<Type>s

local assertNotBoolean   = assertive.assertNotBoolean
local assert_not_boolean = assertive.assertNotBoolean

local assertNotFunction   = assertive.assertNotFunction
local assert_not_function = assertive.assertNotFunction

local assertNotNil   = assertive.assertNotNil
local assert_not_nil = assertive.assertNotNil

local assertNotNumber   = assertive.assertNotNumber
local assert_not_number = assertive.assertNotNumber

local assertNotTable   = assertive.assertNotTable
local assert_not_table = assertive.assertNotTable

local assertNotString   = assertive.assertNotString
local assert_not_string = assertive.assertNotString


---- TEST ASSERTIVE SETTINGS --------------------------------------
assert(assertive:getDelta() == 1e-12) -- default value
assert(assertive:getExpectedActual() == false) -- default value
    
assertive:setExpectedActual(true)
assertive:setDelta(0.5)
assertError("expected: 5, actual: 'green'",
            assertEquals, 5, 'green')
assertError('values differ beyond allowed tolerance of 0.5 :'..
            '\n\tactual   : 6\n\texpected : 5',
            assertAlmostEquals, 5, 6)
assert(assertive:getExpectedActual() == true)

-- reset defaults and check behavior
assertive:setExpectedActual()
assertive:setDelta()
assert(assertive:getDelta() == 1e-12)
assert(assertive:getExpectedActual() == false)
assertError("expected: 'green', actual: 5",
            assertEquals, 5, 'green')
assertError('values differ beyond allowed tolerance of 1e-12 :'..
            '\n\tactual   : 5\n\texpected : 5.3',
            assertAlmostEquals, 5, 5.3)



---- TEST ASSERT ERROR ---------------------------------------------
local function f() end
local ok, err

ok, err = pcall( error, "coucou" )
assert( not ok )
ok = pcall( assertError, error, "coucou" )
assert( ok )
assertError( error, "coucou" )

ok = pcall( f )
assert( ok )
ok = pcall( assertError, f ) -- no error raised is bad in this case
assert( not ok )

-- multiple arguments
local function multif(a,b,c)
    if a == b and b == c then return end
    error("three arguments not equal")
end

assertError(multif, 1, 1, 3)
    
-- multif error should generate the provided message
-- note that 'filename:linenum:' has been stripped!
assertError('three arguments not equal', multif, 1, 3, 1)
    
-- like above, but in event of test passing or message mismatch
-- will output the given message
assertError('in event of error', 'three arguments not equal',
            multif, 1, 3, 1)
    
-- inner call raises no err
assertError(assertError, multif, 1, 1, 1)
assertError('No error generated', assertError, multif, 1, 1, 1)
    
-- error message does not match expected
assertError(assertError, 'assertion failed', multif, 3, 's', 1)
   
-- demonstrate that failing assertError generates specified message
assertError('this if messages do not match',
            assertError, 'this if messages do not match', 
                         'error error error',
                         -- ~= 'three arguments not equal' 
                         multif, 1, 3, 1)
    
-- like above, but does not care about test function error message
assertError('problem: three args equal',
            assertError, 'problem: three args equal', 
                         nil, 
                         multif, 1, 1, 1) -- multif generates no error
    
-- 'informative' error raised if assertError gets wrong arg order
assertError(
[=[assertError received args in an unrecognized pattern!
requires: (function, ...) or (string, function, ...) or (string, string|nil, function, ...)
but was:  (nil, function, ...)]=],
    assertError, nil, multif, 1,2,2)



---- TEST ASSERT EQUALS ----------------------------------------------
assertEquals(1, 1)
assertEquals(1, 1, 'msg')
assertError('expected: 2, actual: 1',
            assertEquals, 1, 2)
assertError('msg',
            assertEquals, 1, 2, 'msg')
assertEquals({1,2,b=5,{4}}, {1,b=5,2,{4}})
assertEquals({'green'}, {'green'}, 'msg')
local f = function() return 3 end
assertEquals(f, f, 'msg')
assertEquals("string", "string", 'msg')
assertEquals(true, true)
    
assertError('msg', assertEquals, nil, 'string', 'msg')
assertError(assertEquals, 'string', nil, 'msg')
assertError('err', assertEquals, 5, nil, 'err')
-- local toString = LuaUnit._toString
assertError( -- default behavior is to print both tables
[=[table expected:
{
  [1] = 4
}
actual:
{
  [1] = {
    [1] = 4
  }
}]=],    assertEquals,{{4}}, {4})
assertError('order diff', assertEquals, {1,{6}}, {{6},1}, 'order diff')
assertError(assertEquals, false, f, 'false not function')



---- TEST ASSERT TYPES ----------------------------------------------
--TODO? userdata and thread types
local f = function() return end
assertBoolean(true)
assertFunction(f)
assertNil(nil)
assertNil(nil, 'user-defined message')
assertNumber(5.3)
assertNumber(-0x4f)
assertString('s')
assertTable({4})
  
assertError('expected function type but was boolean',
            assertFunction, false)
assertError('expected number type but was nil',
            assertNumber, nil)
assertError('expected nil type but was number',
            assertNil, 5)
assertError('user message',
            assertNil, 5, 'user message')



---- TEST ASSERT NOT TYPES ------------------------------------------
--TODO? userdata and thread types
local f = function() return end
assertNotBoolean(4)
assertNotFunction(false)
assertNotNil(f)
assertNotNumber(nil)
assertNotNumber(f)
assertNotString({})
assertNotString(nil, 'msg')
    
assertError(assertNotBoolean, true)
assertError('unexpected boolean',
            assertNotBoolean, true)
assertError('unexpected function',
            assertNotFunction, f)
assertError('unexpected nil',
            assertNotNil, nil)
assertError('unexpected string',
            assertNotString, 's')
assertError('my message',
            assertNotString, 's', 'my message')



---- TEST ASSERT NOT EQUALS ------------------------------------
assertNotEquals(5, 2)
assertNotEquals(5, 2, 'msg')
assertNotEquals("eggs", "spam", 'msg')
assert_not_equals("table", {})
assert_not_equals({}, {3})
    
assertError('unexpected equivalent values: 5',
            assertNotEquals, 5, 5)
assertError("unexpected equivalent values: 'hello kitty!'",
            assertNotEquals, "hello kitty!", 'hello kitty!')
assertError("kitty",
            assertNotEquals, "hello kitty!", 'hello kitty!', 'kitty')
assertError(assertNotEquals, {3, nil, "orange"}, {3, nil, "orange"})



---- TEST ASSERT ALMOST EQUALS --------------------------------------
local default_delta = assertive:getDelta()
assertAlmostEquals(5, 5)
assertAlmostEquals(0, 5e-13) -- default delta 1e-12
assertAlmostEquals(5, 5.00001, 1e-4)
assertAlmostEquals(5.00001, 5.0, 0.1, "if fail")
assert_almost_equals(0.1, 0.1, nil, 'alias works too')
    
assertive:setDelta(1e-5)
assertAlmostEquals(5.0, 5.0000001, nil, "if fail")
assertive:setDelta(default_delta)
    
assertError("actual must be a number but was 'blue'",
            assertAlmostEquals, "blue", "blue", 0.01)
assertError("expected must be a number but was a table",
            assertAlmostEquals, 5, {}, 0.01)
assertError("actual must be a number but was nil",
            assertAlmostEquals, nil, "blue", 0.01)
assertError('values differ beyond allowed tolerance of 1e-12 :\n'..
            '\tactual   : 5\n'..
            '\texpected : 5.000001',
            assertAlmostEquals, 5, 5.000001)
assertError('values differ beyond allowed tolerance of 0.001 :\n'..
            '\tactual   : 5\n'..
            '\texpected : 5.1', assertAlmostEquals, 5, 5.1, 1e-3)
assertError("delta must be a number but was 'orange'",
            assertAlmostEquals, 3, 3.00001, "orange")
assertError("non-string messages are ignored", nil,
            assertAlmostEquals, 3, 3.00001, nil, {})
    
assertError('my msg',
            assertAlmostEquals, 1, 2, nil, 'my msg')
assertError('my msg',
            assertAlmostEquals, 1, 2, 0.5, 'my msg')



print('==== TEST_ASSERTIVE PASSED ====')

