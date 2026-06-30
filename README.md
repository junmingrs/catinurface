# **Cat In Your Face**

Shows images of cat at bottom right corner depending on number of errors in current buffer

## Requirements
1. Must have Chafa installed

## Usage
Lazy
```lua
return {
  "junmingrs/catinurface",
  opts = {}
}
```

## Default Config
```lua
{
  height = 10,
  width = 20,
  threshold = {
    [0] = "lua/catinurface/images/no.jpg",
    [1] = "lua/catinurface/images/small.jpg",
    [5] = "lua/catinurface/images/medium.jpg",
    [10] = "lua/catinurface/images/big.jpg",
  }
}
```

## Add your own threshold and images
Example
```lua
opts = {
  threshold = {
    [2] = "path/to/image"
  }
}
```

# Todo
1. [x] add height and width to opts
2. [x] add your own images
3. [x] custom image paths

