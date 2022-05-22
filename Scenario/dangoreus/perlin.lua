--[[
    Implemented as described here:
    http://flafla2.github.io/2014/08/09/perlinnoise.html
]]--

perlin = {}
perlin.p = {}
perlin.EXPONENT = 0.8 --This is used to change how the noise scales from the origin.

-- Hash lookup table as defined by Ken Perlin
-- This is a randomly arranged array of all numbers from 0-255 inclusive
global.permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}
global.permutation2 = {}

--This is a measured table of distributions along the X axis.  Measurement taken 11th Aprl 2018 (if algo changes, this will need to be updated)
perlin.MEASURED = {[-0.8]= 3e-06, [-0.78]= 1.9e-05, [-0.76]= 2.26e-05, [-0.74]= 7.85e-05, [-0.72]= 6.54e-05, [-0.7]= 0.0001065,
[-0.68]= 0.0001422, [-0.66]= 0.0001748, [-0.64]= 0.0003068, [-0.62]= 0.0005037, [-0.6]= 0.0006998, [-0.58]= 0.0009218, [-0.56]= 0.0015398,
[-0.54]= 0.002261, [-0.52]= 0.0029764, [-0.5]= 0.0041172, [-0.48]= 0.0074905, [-0.46]= 0.0065377, [-0.44]= 0.0067735, [-0.42]= 0.0071103,
[-0.4]= 0.0077329, [-0.38]= 0.0086249, [-0.36]= 0.0088168, [-0.34]= 0.0098334, [-0.32]= 0.0121038, [-0.3]= 0.0142444, [-0.28]= 0.0175389,
[-0.26]= 0.0200083, [-0.24]= 0.0229865, [-0.22]= 0.023516, [-0.2]= 0.0224692, [-0.18]= 0.0218644, [-0.16]= 0.023464, [-0.14]= 0.0295019,
[-0.12]= 0.0312897, [-0.1]= 0.0300214, [-0.08]= 0.0299038, [-0.06]= 0.0295616, [-0.04]= 0.0300028, [-0.02]= 0.0300583, [0]= 0.0344869,
[0.02]= 0.0339126, [0.04]= 0.0305977, [0.06]= 0.0292206, [0.08]= 0.0287079, [0.1]= 0.0287141, [0.12]= 0.0292377, [0.14]= 0.0308711,
[0.16]= 0.0289125, [0.18]= 0.0227944, [0.2]= 0.0221353, [0.22]= 0.0224589, [0.24]= 0.0243225, [0.26]= 0.0243281, [0.28]= 0.0202056,
[0.3]= 0.0179745, [0.32]= 0.0145356, [0.34]= 0.0117213, [0.36]= 0.0100536, [0.38]= 0.0090039, [0.4]= 0.0083324, [0.42]= 0.0082711,
[0.44]= 0.0074277, [0.46]= 0.0068863, [0.48]= 0.00662, [0.5]= 0.0070714, [0.52]= 0.0038948, [0.54]= 0.002906, [0.56]= 0.0024376,
[0.58]= 0.0017182, [0.6]= 0.0013078, [0.62]= 0.000955, [0.64]= 0.0007262, [0.66]= 0.000569, [0.68]= 0.0004113, [0.7]= 0.0002829,
[0.72]= 0.0001852, [0.74]= 0.0001868, [0.76]= 0.0001051, [0.78]= 6.05e-05, [0.8]= 2.32e-05, [0.82]= 1.84e-05, [0.84]= 4e-06,
[0.86]= 6.4e-06, [0.88]= 4.5e-06 }

function perlin.shuffle()
    --Now shuffle the table.
    local n = #global.permutation
    local seed = game.surfaces[1].map_gen_settings.seed
    local rng = game.create_random_generator()
    -- for i = 0, 255 do
    --     perlin.p[i] = global.permutation[(i + seed) % 256]
    --     perlin.p[i+256] = global.permutation[(i + seed) % 256]
    -- end
    while n > 2 do
        local k = rng(1, n)
        global.permutation[n], global.permutation[k] = global.permutation[k], global.permutation[n]
        n = n - 1
    end
    for i=0,255 do
        global.permutation2[i] = global.permutation[i+1]
        global.permutation2[i+256] = global.permutation[i+1]
    end
end

--     while n > 2 do
--         local k = math.random(n)
--         global.permutation[n], global.permutation[k] = global.permutation[k], global.permutation[n]
--         n = n - 1
--     end
-- end
-- p is used to hash unit cube coordinates to [0, 255]
-- for i=0,255 do
--     -- Convert to 0 based index table
--     perlin.p[i] = global.permutation[i+1]
--     -- Repeat the array to avoid buffer overflow in hash function
--     perlin.p[i+256] = global.permutation[i+1]
-- end


-- Return range: [-1, 1]
function perlin.noise(x, y, z)
    if x > 0 then
        x = math.abs(x)^perlin.EXPONENT / 30 + 0.001
    else
        x = -math.abs(x)^perlin.EXPONENT / 30 + 0.001
    end
    if y > 0 then
        y = math.abs(y)^perlin.EXPONENT / 30 + 0.001
    else
        y = -math.abs(y)^perlin.EXPONENT / 30 + 0.001
    end
    z = (math.abs(x) + math.abs(y)) * 50 / 10000
    --z = z or 0

    -- Calculate the "unit cube" that the point asked will be located in
    local xi = bit32.band(math.floor(x),255)
    local yi = bit32.band(math.floor(y),255)
    local zi = bit32.band(math.floor(z),255)

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    -- We also fade the location to smooth the result
    local u = perlin.fade(x)
    local v = perlin.fade(y)
    local w = perlin.fade(z)

    -- Hash all 8 unit cube coordinates surrounding input coordinate
    local p = global.permutation2
    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = p[xi  ] + yi
    AA  = p[A   ] + zi
    AB  = p[A+1 ] + zi
    AAA = p[ AA ]
    ABA = p[ AB ]
    AAB = p[ AA+1 ]
    ABB = p[ AB+1 ]

    B   = p[xi+1] + yi
    BA  = p[B   ] + zi
    BB  = p[B+1 ] + zi
    BAA = p[ BA ]
    BBA = p[ BB ]
    BAB = p[ BA+1 ]
    BBB = p[ BB+1 ]

    -- Take the weighted average between all 8 unit cube coordinates
    return perlin.lerp(w,
        perlin.lerp(v,
            perlin.lerp(u,
                perlin:grad(AAA,x,y,z),
                perlin:grad(BAA,x-1,y,z)
            ),
            perlin.lerp(u,
                perlin :grad(ABA,x,y-1,z),
                perlin:grad(BBA,x-1,y-1,z)
            )
        ),
        perlin.lerp(v,
            perlin.lerp(u,
                perlin:grad(AAB,x,y,z-1), perlin:grad(BAB,x-1,y,z-1)
            ),
            perlin.lerp(u,
                perlin:grad(ABB,x,y-1,z-1), perlin:grad(BBB,x-1,y-1,z-1)
            )
        )
    )
end

-- Iterate from 0 to 10,000,000 and count how many points fall within each range.
-- Print the table to a file in sequental order of keys so we can paste it back here and use it for determining a table for ore distributions.
function perlin.measure()
    local count = {}
    for i = 0, 10000000 do
        local noise = perlin.noise(i, 0)
        for n = -49, 49 do
            local n2 = n/50
            if noise < n2 then
                if not count[n2] then count[n2] = 0 end
                count[n2] = count[n2] + 1
                break
                -- goto break1
            end
        end
    end
    game.write_file("perlin_data.txt", "{")
    for n = -49, 49 do
        local n2 = n/50
        if count[n2] then
            game.write_file("perlin_data.txt", "[" .. n2 .. "]= " .. count[n2] / 10000000 .. ", ", true)
        end
    end
    game.write_file("perlin_data.txt", "}", true)

    --game.write_file("perlin_data.txt", serpent.line(count))
end

-- Gradient function finds dot product between pseudorandom gradient vector
-- and the vector from input coordinate to a unit cube vertex
perlin.dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end,
    [0x4]=function(x,y,z) return  x + z end,
    [0x5]=function(x,y,z) return -x + z end,
    [0x6]=function(x,y,z) return  x - z end,
    [0x7]=function(x,y,z) return -x - z end,
    [0x8]=function(x,y,z) return  y + z end,
    [0x9]=function(x,y,z) return -y + z end,
    [0xA]=function(x,y,z) return  y - z end,
    [0xB]=function(x,y,z) return -y - z end,
    [0xC]=function(x,y,z) return  y + x end,
    [0xD]=function(x,y,z) return -y + z end,
    [0xE]=function(x,y,z) return  y - x end,
    [0xF]=function(x,y,z) return -y - z end
}
function perlin:grad(hash, x, y, z)
    return perlin.dot_product[bit32.band(hash,0xF)](x,y,z)
end

-- Fade function is used to smooth final output
function perlin.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function perlin.lerp(t, a, b)
    return a + t * (b - a)
end

--Event.register(-1, perlin.shuffle)
return perlin
