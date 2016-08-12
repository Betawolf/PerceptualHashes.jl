# PerceptualHashes

[![Build Status](https://travis-ci.org/Betawolf/PerceptualHashes.jl.svg?branch=master)](https://travis-ci.org/Betawolf/PerceptualHashes.jl)

This `Julia` library aims to implement a range of perceptual hashing techniques.

Perceptual hashing is the process of generating a hash value for an image (or more abstractly, a video or audio file) which represents the _essential qualities_ of the file regarding properties which are important to a human observer. For example, comparing an image `X` with a compressed version of the image `x` should result in the same or highly similar hash values. This is in contrast to non-perceptual hashing techniques such as `MD5` or `SHA-1`, which are sensitive to imperceptible changes in the file. 

Perceptual hashing is a useful tool for detecting duplicates of images which are intentionally or accidentally transformed in imperceptible ways. 

This library currently implements:

 + The Block Mean Value hash described by [Zauner (2010)](http://phash.org/docs/pubs/thesis_zauner.pdf)


Usage is simple.

```{julia}
using PerceptualHashes

# Hash an image identified by its filename.
a_hash = perceptual_hash("images/architecture1.bmp")
b_hash = perceptual_hash("images/architecture1-compressed.jpg")
c_hash = perceptual_hash("images/doodle.bmp")

# Compare images with their hash Hamming distance
hdist(a_hash, b_hash)
# 2 low value, some compression impact.

hdist(a_hash, c_hash)
# 122 high value, totally different image.
```

There is also a library function to resolve all images in a given directory.

```{julia}
# Call with a directory name and a 'tolerance' value for image similarity (default=0)
resolve_images("images", 5)
#Dict{Any,Any} with 16 entries:
#  "images//diamondskull-compressed.jpg"   => Any["images//diamondskull.bmp"]
#  "images//england.bmp"                   => Any["images//england-compressed.jpg"]
#  "images//bamarket115.bmp"               => Any["images//bamarket115-compressed.jpg"]
#  "images//doodle-compressed.jpg"         => Any["images//doodle.bmp"]
#  "images//doodle.bmp"                    => Any["images//doodle-compressed.jpg"]
#  "images//england-compressed.jpg"        => Any["images//england.bmp"]
#  "images//architecture_2-compressed.jpg" => Any["images//architecture_2.bmp"]
#  "images//bamarket115-compressed.jpg"    => Any["images//bamarket115.bmp"]
#  "images//architecture1.bmp"             => Any["images//architecture1-compressed.jpg"]
#  "images//architecture_2.bmp"            => Any["images//architecture_2-compressed.jpg"]
#  "images//wallacestevens-compressed.jpg" => Any["images//wallacestevens.bmp"]
#  "images//englandpath-compressed.jpg"    => Any["images//englandpath.bmp"]
#  "images//wallacestevens.bmp"            => Any["images//wallacestevens-compressed.jpg"]
#  "images//architecture1-compressed.jpg"  => Any["images//architecture1.bmp"]
#  "images//diamondskull.bmp"              => Any["images//diamondskull-compressed.jpg"]
#  "images//englandpath.bmp"               => Any["images//englandpath-compressed.jpg"]
```
