unless Array::each
  if Array::forEach
    Array::each = Array::forEach
  else
    Array::each = (block)->
      _.each(@, block)

Array::first = -> @[0]
Array::last = -> @[@length - 1]
Array::min = -> Math.min(@...)
Array::max = -> Math.max(@...)
