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

def mask_lshift_width(mask)
  blanks = 0
  while mask >> blanks & 0b1 == 0
    blanks += 1
  end
  return blanks
end
