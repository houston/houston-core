unless Array::each
  if Array::forEach
    Array::each = Array::forEach
  else
    Array::each = (block)->
      _.each(@, block)

Array::last = -> @[@length - 1]
Array::first = -> @[0]
