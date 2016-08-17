module PerceptualHashes

using Images, Colors, FixedPointNumbers

import Base.convert

function greyscale(image::Image)
  return convert(Image{Gray{UFixed{UInt8, 8}}}, image)
end


function imapply(func, image)
  return Image(map(func, data(image)), colorspace=image.properties["colorspace"], spatialorder=image.properties["spatialorder"])
end


"""
 convert(::Type{UInt32}, hash::BitArray{1})

Converts a bitarray into an UInt. I feel like I shouldn't have to write this, 
but `reinterpret` doesn't seem to work. 
"""
function convert(::Type{UInt32}, hsh::BitArray{1})
  return uintof(0x00000000, hsh)
end

"""
 convert(::Type{UInt32}, hash::BitArray{1})

Converts a bitarray into an UInt. I feel like I shouldn't have to write this, 
but `reinterpret` doesn't seem to work. 
"""
function convert(::Type{UInt64}, hsh::BitArray{1})
  return uintof(0x0000000000000000, hsh)
end

function uintof(i, hsh)
  for hbit in hsh
    i = i << 1
    if hbit
      i = i + 0x1
    end
  end
  return i
end



"""
  `hdist(hashone, hashtwo)`

  Returns the Hamming distance between two hashes, expressed as `BitArrays`.
"""
function hdist(hashone, hashtwo)
  return sum(hashone $ hashtwo)
end


"""
  `bmv_hash(image, imgsize=256, blocksize=16)`

  Implements the Block Mean Value hashing system proposed by Yang et al (2006),
  discarding the index encryption step in line with Zauner (2010). Returns a 
  hash represented as a `BitArray`, with a default length of 256 bits 
  (32 bytes). 
"""
function bmv_hash(image::Image, imgsize=256, blocksize=16)
  greyed = greyscale(image)
  prepped = Images.imresize(greyed, (imgsize, imgsize))
  raw = map(x -> gray(x), data(prepped))

  blockmeans = []
  #Move a blocksize-square window over the image, taking the mean.
  for i in 0:blocksize:(imgsize-blocksize), j in 0:blocksize:(imgsize-blocksize) 
    block = raw[i+1:i+blocksize,j+1:j+blocksize]
    blockmean = mean(block)
    push!(blockmeans, blockmean)
  end

  #Identifiy the median block and code all blocks as >= or not.
  medblock = median(blockmeans)
  hash = BitArray(map(bm-> bm >= medblock, blockmeans))
  return hash
end



function dct_matrix(size)
  c = Matrix(size,size)
  coeff = sqrt(2/size)
  div = 2*size
  for n in 0:(size-1)
    for m in 0:(size-1)
      c[n+1, m+1] =  coeff * cos( (((2*m) + 1) * n * pi) / div )
    end
  end
  return c
end


"""
  `dct_hash(image)`

  Implements a perceptual hash based on the discrete cosine transform, as
  described by Zauner (2010) and implemented by the [pHash library](http://www.phash.org/docs/design.html)
  While in some sense functional, this implementation seems to be flawed in
  a manner not yet resolved by the author. Returns a 64-bit hash as a
  `BitArray`. 

  You may want to use `convert(UInt64, BitArray)`.
"""
function dct_hash(image::Image, imgsize=32)
  greyed = greyscale(image)

  mfilter = imaverage((7,7))
  smoothed = imfilter(greyed, mfilter)

  prepped = Images.imresize(smoothed, (imgsize, imgsize))

  singular = map(x -> gray(x), data(prepped))
  dcted = dct(singular)

  #This is the implementation given by pHash, but it seems stupid to me when
  #compared to the option of taking the low-frequency components from each of
  #the 8x8 grid points usually used in compression. 
  #It also produces different values to that of their library, for no reason
  #I can understand from comparing their source to mine.
  pixvals = []
  for i in 2:9
    for j in 2:9
      push!(pixvals, dcted[j,i])
    end
  end
  
  med = median(pixvals)
  hash = BitArray(map(x -> x >= med, pixvals))
  return hash
end
  


"""
  `resolve_images(dirname, tolerance=0, method=bmv)`

  Given a directory name, produces a dictionary mapping all contained images to 
  those other images similar within a tolerance of `tolerance`.     
"""
function resolve_images(dirname, tolerance=0, method=bmv_hash)
  fnames = readdir(dirname)
  if length(fnames) < 2
   return Dict()
  end
  fnames = map(x-> string(dirname,"/",x), fnames) 
  hashes = map(x -> perceptual_hash(x, method), fnames)
  joint = zip(fnames, hashes)
  imgmap = Dict()
  for pair in combinations(collect(joint), 2)
    imgone = pair[1]
    imgtwo = pair[2]
    if ! (imgone[1] in keys(imgmap))
      imgmap[imgone[1]] = []
    end
    if ! (imgtwo[1] in keys(imgmap))
      imgmap[imgtwo[1]] = []
    end
    if hdist(imgone[2], imgtwo[2]) <= tolerance
      push!(imgmap[imgone[1]], imgtwo[1])
      push!(imgmap[imgtwo[1]], imgone[1])
    end
  end
  return imgmap
end


"""
  `perceptual_hash(filename, method=bmv_hash)`

  Create a perceptual hash of an image file found at `filename` using `method`.
  
  See also: `bmv`
"""
function perceptual_hash(filename, method=bmv_hash)
  imfile = load(filename)
  return method(imfile)
end

export perceptual_hash, bmv_hash, dct_hash, hdist, resolve_images

end
