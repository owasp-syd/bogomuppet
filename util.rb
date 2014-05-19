def bits_set(i)
  return i.to_s(2).count('1')
end

def mask_width(data)
  count = 0

  while (data != 0)
    data &= (data-1)
    count += 1
  end

  return count
end
