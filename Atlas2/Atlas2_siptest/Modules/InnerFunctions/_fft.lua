local _fft = {}
local cplx = {__mt = {}}

function cplx.new(r, i)
    local new = {r = r, i = i or 0}
    setmetatable(new, cplx.__mt)
    return new
end

function cplx.__mt.__add(c1, c2)
    return cplx.new(c1.r + c2.r, c1.i + c2.i)
end

function cplx.__mt.__sub(c1, c2)
    return cplx.new(c1.r - c2.r, c1.i - c2.i)
end

function cplx.__mt.__mul(c1, c2)
    return cplx.new(c1.r * c2.r - c1.i * c2.i, c1.r * c2.i + c1.i * c2.r)
end

function cplx.expi(i)
    return cplx.new(math.cos(i), math.sin(i))
end

function cplx.__mt.__tostring(c)
    return "(" .. c.r .. "," .. c.i .. ")"
end

-- Cooley–Tukey FFT (in-place, divide-and-conquer)
-- Higher memory requirements and redundancy although more intuitive
function _fft.fft(vect)
    local n = #vect
    if n <= 1 then
        return vect
    end
    local odd, even = {}, {}
    for i = 1, n, 2 do
        odd[#odd + 1] = vect[i]
        even[#even + 1] = vect[i + 1]
    end
    -- conquer
    _fft.fft(even);
    _fft.fft(odd);
    -- combine
    for k = 1, n / 2 do
        local t = even[k] * cplx.expi(-2 * math.pi * (k - 1) / n)
        vect[k] = odd[k] + t;
        vect[k + n / 2] = odd[k] - t;
    end
    return vect
end

function _fft.toComplex(vectr)
    local vect = {}
    for i, r in ipairs(vectr) do
        vect[i] = cplx.new(r)
    end
    return vect
end

return _fft
