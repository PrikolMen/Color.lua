-- from incredible-gmod.ru with love <3
-- https://github.com/Be1zebub/Color.lua

local Color = {}

local function IsColor(var)
	return getmetatable(var) == Color
end

do -- meta events
	Color.__index = Color

	function Color:__tostring()
		return string.format("Color(%d, %d, %d, %d)", self.r, self.g, self.b, self.a)
	end

	function Color:__concat(v)
		return tostring(self) .. (IsColor(v) and (" ".. tostring(v)) or v)
	end

	function Color:__unm()
		return self:Copy():Invert()
	end

	function Color:__add(other)
		return Color(self.r + other.r, self.g + other.g, self.b + other.b, self.a + other.a)
	end

	function Color:__sub(other)
		return Color(self.r - other.r, self.g - other.g, self.b - other.b, self.a - other.a)
	end

	function Color:__mul(other)
		if type(other) == "number" then
			return Color(self.r * other, self.g * other, self.b * other, self.a * other)
		end

		return Color(self.r * other.r, self.g * other.g, self.b * other.b, self.a * other.a)
	end

	function Color:__div(other)
		if type(other) == "number" then
			return Color(self.r / other, self.g / other, self.b / other, self.a / other)
		end

		return Color(self.r / other.r, self.g / other.g, self.b / other.b, self.a / other.a)
	end

	function Color:__eq(other)
		return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
	end

	function Color:__lt(other) -- is darker then other
		return select(3, self:ToHSL()) < select(3, other:ToHSL())
	end

	function Color:__le(other) -- is dark or darker then other
		return select(3, self:ToHSL()) <= select(3, other:ToHSL())
	end
end

do -- methods
	function Color:Unpack()
		return self.r, self.g, self.b, self.a
	end

	function Color:SetUnpacked(r, g, b, a)
		self.r, self.g, self.b, self.a = r or self.r, g or self.g, b or self.b, a or self.a
		return self
	end

	function Color:Normalize()
		self.r, self.g, self.b, self.a = self.r / 255, self.g / 255, self.b / 255, self.a / 255
		return self
	end

	function Color:GetNormalized()
		return Color(self.r / 255, self.g / 255, self.b / 255, self.a / 255)
	end

	function Color:String(str)
		return string.format("\27[38;2;%d;%d;%dm%s\27[0m", self.r, self.g, self.b, str)
	end

	function Color:ToString()
		return string.format("\27[38;2;%d;%d;%dm%s\27[0m", self.r, self.g, self.b, self)
	end

	function Color:Print(str)
		print(self:String(str))
		return self
	end

	function Color:Grey() -- reduce saturation to 0
		local h, _, v = self:ToHSV()
		self:From("hsv", h, 0, v)
		return self
	end

	function Color:Invert()
		self.r, self.g, self.b = math.abs(255 - self.r), math.abs(255 - self.g), math.abs(255 - self.b)
		return self
	end

	function Color:Copy()
		return Color(self.r, self.g, self.b, self.a)
	end

	function Color:ToTable()
		return {self.r, self.g, self.b, self.a}
	end

	function Color:ToVector()
		return Vector(self.r / 255, self.g / 255, self.b / 255)
	end

	function Color:Contrast(smooth)
		if smooth then
			local c = 255 - self:ToHexDecimal() / 0xffffff * 255
			return Color(c, c, c)
		else
			return self:ToHexDecimal() > 0xffffff / 2 and Color(0, 0, 0) or Color(255, 255, 255)
		end
	end
end

do -- convert rgb > X
	local bit = bit or bit32

	function Color:ToHexDecimal() -- 24bit
		return bit.bor(bit.lshift(self.r, 16), bit.lshift(self.g, 8), self.b)
	end

	function Color:ToHexaDecimal() -- Alpha support, 32bit
		return bit.bor(bit.lshift(self.r, 24), bit.lshift(self.g, 16), bit.lshift(self.b, 8), self.a)
	end

	function Color:ToHex(hash)
		if hash then
			return string.format("#%x", (self.r * 0x10000) + (self.g * 0x100) + self.b):upper()
		end

		return string.format("%x", (self.r * 0x10000) + (self.g * 0x100) + self.b):upper()
	end

	function Color:ToHexa(hash)
		if hash then
			return string.format("#%x", (self.r * 0x1000000) + (self.g * 0x10000) + (self.b * 0x100) + self.a):upper()
		end

		return string.format("%x", (self.r * 0x1000000) + (self.g * 0x10000) + (self.b * 0x100) + self.a):upper()
	end

	function Color:ToHSV()
		local h, s, v

		local min = math.min(self.r, self.g, self.b)
		local max = math.max(self.r, self.g, self.b)

		v = max

		local delta = max - min

		if max ~= 0 then
			s = delta / max
		else
			s = 0
			h = -1
			return h, math.floor(s * 100), v / 2.55
		end

		if self.r == max then
			h = (self.g - self.b) / delta
		elseif self.g == max then
			h = 2 + (self.b - self.r) / delta
		else
			h = 4 + (self.r - self.g) / delta
		end

		h = h * 60
		if h < 0 then
			h = h + 360
		end

		return h, math.floor(s * 100), v / 2.55
	end

	function Color:ToHWB()
		local h, s, v = self:ToHSV()
		return h, (100 - s) * v, 100 - v
	end

	function Color:ToHSL()
		local r, g, b = self.r / 255, self.g / 255, self.b / 255

		local min = math.min(r, g, b)
		local max = math.max(r, g, b)
		local delta = max - min

		local h, s, l = 0, 0, (min + max) / 2

		if l > 0 and l < 0.5 then s = delta / (max + min) end
		if l >= 0.5 and l < 1 then s = delta / (2 - max - min) end

		if delta > 0 then
			if max == r and max ~= g then h = h + (g - b) / delta end
			if max == g and max ~= b then h = h + 2 + (b - r) / delta end
			if max == b and max ~= r then h = h + 4 + (r - g) / delta end
			h = h / 6
		end

		if h < 0 then h = h + 1 end
		if h > 1 then h = h - 1 end

		return h * 360, s * 100, l * 100
	end

	function Color:ToCMYK()
		local max = math.max(self.r, self.g, self.b)
		return
			(max - self.r) / max * 100,
			(max - self.g) / max * 100,
			(max - self.b) / max * 100,
			math.min(self.r, self.g, self.b) / 2.55
	end
end

do -- convert X > rgb
	local convert = {}

	function convert.hex(hex)
		if type(hex) == "string" then
			hex = tonumber(hex:gsub("^[#0]x?", ""), 16)
		end

		return
			bit.rshift(bit.band(hex, 0xFF0000), 16),
			bit.rshift(bit.band(hex, 0xFF00), 8),
			bit.band(hex, 0xFF)
	end

	function convert.hexa(hexa)
		if type(hexa) == "string" then
			hexa = tonumber(hexa:gsub("^[#0]x?", ""), 16)
		end

		return
			bit.rshift(bit.band(hexa, 0xFF000000), 24),
			bit.rshift(bit.band(hexa, 0xFF0000), 16),
			bit.rshift(bit.band(hexa, 0xFF00), 8),
			bit.band(hexa, 0xFF)
	end

	function convert.hsv(h, s, v)
		h = h / 360
		s = s / 100
		v = v / 100
		local r, g, b

		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p = v * (1 - s)
		local q = v * (1 - f * s)
		local t = v * (1 - (1 - f) * s)

		i = i % 6

		if i == 0 then
			r, g, b = v, t, p
		elseif i == 1 then
			r, g, b = q, v, p
		elseif i == 2 then
			r, g, b = p, v, t
		elseif i == 3 then
			r, g, b = p, q, v
		elseif i == 4 then
			r, g, b = t, p, v
		elseif i == 5 then
			r, g, b = v, p, q
		end

		return
			r * v * 255,
			g * v * 255,
			b * v * 255
	end

	local function hsl2rgb(m, m2, h)
		if h < 0 then h = h + 1 end
		if h > 1 then h = h - 1 end
		if h * 6 < 1 then
			return m + (m2 - m) * h * 6
		elseif h * 2 < 1 then
			return m2
		elseif h * 3 < 2 then
			return m + (m2 - m) * (2 / 3 - h) * 6
		else
			return m
		end
	end

	function convert.hsl(h, s, l)
		h, s, l = h / 360, s / 100, l / 100

		local m2 = l <= 0.5 and l * (s + 1) or l + s - l * s
		local m = l * 2 - m2

		return
			hsl2rgb(m, m2, h + 1 / 3) * 255,
			hsl2rgb(m, m2, h) * 255,
			hsl2rgb(m, m2, h - 1 / 3) * 255
	end

	function convert.hwb(h, w, b)
		return convert.hsv(h, 100 - w / (100 - b), 100 - b)
	end

	function convert.cmyk(c, m, y, k)
		c, m, y, k = c / 100, m / 100, y / 100, k / 100
		local mk = 1 - k

		return
			(1 - c) * mk * 255,
			(1 - m) * mk * 255,
			(1 - y) * mk * 255
	end

	local constructor = {}

	function constructor:__index(model)
		local make = convert[model]
		if make then
			return function(...)
				local args = {...}
				local a = table.remove(args, debug.getinfo(make).nparams + 1)
				local r, g, b, a2 = make(unpack(args))

				return Color(r, g, b, a2 or a)
			end
		end
	end

	function constructor:__call(r, g, b, a)
		return setmetatable({r = r or 0, g = g or 0, b = b or 0, a = a or 255}, Color)
	end

	setmetatable(Color, constructor)

	function Color:From(model, ...)
		if convert[model] then
			return self:SetUnpacked(
				convert[model](...)
			)
		end
	end
end

function Color.test()
	local alpha = 175

	Color(255, 255, 0):Print("from incredible-gmod.ru with <3")

	print("\nconverters:")

	print("\trgb > color\t", Color(0, 255, 0, alpha):ToString())
	print("\thex > color\t", Color.hex("#de621f", alpha):ToString())
	print("\thexdec > color\t", Color.hex(0xDED81F, alpha):ToString())
	print("\thexa > color\t", Color.hexa(0x82DE1FAF):ToString())
	print("\thsv > color\t", Color.hsv(120, 86, 87, alpha):ToString())
	print("\thsl > color\t", Color.hsl(150, 75, 50, alpha):ToString())
	print("\thwb > color\t", Color.hwb(0, 0, 0, alpha):ToString())
	print("\tcmyk > color\t", Color.cmyk(86, 37, 0, 13, alpha):ToString())

	print("")

	print("\tcolor > hex\t", Color(0, 255, 0, alpha):ToHex())
	print("\tcolor > hexa\t", Color(222, 98, 31, alpha):ToHexa())
	print("\tcolor > hexdecimal", Color(222, 216, 31, alpha):ToHexDecimal())
	print("\tcolor > hexadecimal", Color(130, 222, 31, alpha):ToHexaDecimal())
	print("\tcolor > hsv\t", table.concat({Color(27, 193, 27, alpha):ToHSV()}, ", "))
	print("\tcolor > hsl\t", table.concat({Color(31, 223, 127, alpha):ToHSL()}, ", "))
	print("\tcolor > hwb\t", table.concat({Color(255, 0, 0, alpha):ToHWB()}, ", "))
	print("\tcolor > cmyk\t", table.concat({Color(31, 139, 221, alpha):ToCMYK()}, ", "))

	print("meta events:")

	print("\t__tostring\t", tostring(Color(123)))
	print("\t__concat\t", "test ".. Color(100) .. " :)")
	print("\t__unm\t\t", -Color(1, 2, 3))
	print("\t__add\t\t", Color(25, 25, 25) + Color(150, 75, 0, 0))
	print("\t__sub\t\t", Color(255, 255, 255) - Color(0, 255, 255, 0))
	print("\t__mul\t\t", Color(100, 50, 0, 100) * 2)
	print("\t__div\t\t", Color(200, 50, 0) / 2)
	print("\t__eq\t\t", Color(255, 0, 0) == Color(255, 0, 0), Color(255, 0, 0) == Color(0, 0, 0))
	print("\t__lt\t\t", Color(255, 0, 0) < Color(0, 0, 0))
	print("\t__le\t\t", Color(255, 0, 0) <= Color(255, 1, 0))

	print("methods:")

	print("\tUnpack\t\t", table.concat({Color(255, 0, 0):Unpack()}, ", "))
	print("\tSetUnpacked\t", Color(255, 0, 0):SetUnpacked(0, 255, 0))
	print("\tNormalize\t", Color(255, 50, 100):Normalize())
	print("\tGetNormalized\t", Color(255, 50, 100):GetNormalized())
	print("\tString\t\t", Color.hex("#16a085"):String("hello"))
	print("\tGrey\t\t", Color(255, 255):Grey())
	print("\tInvert\t\t", Color(255, 100):Invert())
	print("\tCopy\t\t", Color(100):Copy())
	print("\tToTable\t\t", Color(123):ToTable())
	print("\tToVector\t", Vector and Color(0, 255):ToVector() or "Cant convert to Vector, because Vector class is not defind")
	print("\tContrast\t", Color(180, 150):Contrast(true))
end

-- Color.test()

return Color, IsColor
