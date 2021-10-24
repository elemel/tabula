local M = {}

function M.find(t, v)
  for k, v2 in pairs(t) do
    if v2 == v then
      return k
    end
  end

  return nil
end

function M.findLast(t, v)
  for i = 1, #t do
    if t[i] == v then
      return i
    end
  end

  return nil
end

function M.removeLast(t, v)
  local i = M.findLast(t, v)

  if i then
    table.remove(t, i)
  end

  return i
end

function M.get(t, k, v)
  if t[k] == nil then
    return v
  end

  return t[k]
end

function M.keys(t, result)
  result = result or {}

  for k, v in pairs(t) do
    result[#result + 1] = k
  end

  return result
end

function M.values(t, result)
  result = result or {}

  for k, v in pairs(t) do
    result[#result + 1] = v
  end

  return result
end

function M.copyArray(source, i, n, destination, j)
  i = i or 1
  n = n or #source
  destination = destination or {}
  j = j or 1

  for k = 0, n - 1 do
    destination[j + k] = source[i + k]
  end
end

return M
