module PerceptualHashes

using Images, Colors

import Base.convert

function greyscale(x)
  avg = mean([x.b, x.g, x.r])
  return RGB(avg, avg, avg)
end


function imapply(func, image)
  return Image(map(func, data(image)), colorspace=image.properties["colorspace"], spatialorder=image.properties["spatialorder"])
end


"""
 convert(::Type{Int32}, hash::BitArray{1})

Converts a bitarray into an Int. I feel like I shouldn't have to write this, 
but `reinterpret` doesn't seem to work. 
"""
function convert(::Type{UInt32}, hsh::BitArray{1})
  i = 0x00000000
  for hbit in hsh
    if hbit
      i = i + 0x1
    end
    i = i << 1
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
  `bmv(image, imgsize=256, blocksize=16)`

  Implements the Block Mean Value hashing system proposed by Yang et al (2006),
  discarding the index encryption step in line with Zauner (2010). Returns a 
  hash represented as a `BitArray`, with a default length of 256 bits 
  (32 bytes). 
"""
function bmv(image::Image, imgsize=256, blocksize=16)
  greyed = imapply(greyscale, image)
  prepped = Images.imresize(greyed, (imgsize, imgsize))
  raw = data(prepped)

  blockmeans = []
  #Move a blocksize-square window over the image, taking the mean.
  for i in 0:blocksize:(imgsize-blocksize), j in 0:blocksize:(imgsize-blocksize) 
    block = raw[i+1:i+blocksize,j+1:j+blocksize]
    blockmean = mean(map(x->x.b, block))
    push!(blockmeans, blockmean)
  end

  #Identifiy the median block and code all blocks as >= or not.
  medblock = median(blockmeans)
  hash = BitArray(map(bm-> bm >= medblock, blockmeans))
  return hash
end


"""
  `resolve_images(dirname, tolerance=0)`

  Given a directory name, produces a dictionary mapping all contained images to 
  those other images similar within a tolerance of `tolerance`.     
"""
function resolve_images(dirname, tolerance=0)
  fnames = readdir(dirname)
  if length(fnames) < 2
   return Dict()
  end
  fnames = map(x-> string(dirname,"/",x), fnames) 
  hashes = map(perceptual_hash, fnames)
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
  `perceptual_hash(filename, method=bmv)`

  Create a perceptual hash of an image file found at `filename` using `method`.
  
  See also: `bmv`
"""
function perceptual_hash(filename, method=bmv)
  imfile = load(filename)
  return method(imfile)
end

export perceptual_hash, bmv, hdist, resolve_images

end
