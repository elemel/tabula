local M = {}

function M.find(t, v)
  for k, v2 in pairs(t) do
    if v2 == v then
      return k
    end
  end

  return nil
end

function M.findFirst(t, v)
  for i = 1, #t do
    if t[i] == v then
      return i
    end
  end

  return nil
end

function M.findLast(t, v)
  for i = #t, 1, -1 do
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

  for k in pairs(t) do
    table.insert(result, k)
  end

  return result
end

function M.keySet(t, result)
  result = result or {}

  for k in pairs(t) do
    result[k] = true
  end

  return result
end

function M.values(t, result)
  result = result or {}

  for _, v in pairs(t) do
    table.insert(result, v)
  end

  return result
end

function M.copy(source, target)
  target = target or {}

  for k, v in pairs(source) do
    target[k] = v
  end

  return target
end

function M.copyArray(source, i, n, target, j)
  i = i or 1
  n = n or #source
  target = target or {}
  j = j or 1

  for k = 0, n - 1 do
    target[j + k] = source[i + k]
  end

  return target
end

function M.sortedKeys(t, result)
  result = result or {}

  for k in pairs(t) do
    table.insert(result, k)
  end

  table.sort(result)
  return result
end

function M.clear(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

return M
