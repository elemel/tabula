local abs = assert(math.abs)

local M = {}

-- See: http://love2d.org/wiki/HSL_color
function M.hslToRgb(h, s, l)
  if s <= 0 then
    return l, l, l
  end

  local h, s, l = h * 6, s, l
  local c = (1 - abs(2 * l - 1)) * s
  local x = (1 - abs(h % 2 - 1)) * c
  local m, r, g, b = (l - 0.5 * c), 0, 0, 0

  if h < 1 then
    r, g, b = c, x, 0
  elseif h < 2 then
    r, g, b = x, c, 0
  elseif h < 3 then
    r, g, b = 0, c, x
  elseif h < 4 then
    r, g, b = 0, x, c
  elseif h < 5 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  return r + m, g + m, b + m
end

return M
