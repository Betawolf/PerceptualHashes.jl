# PerceptualHash

[![Build Status](https://travis-ci.org/Betawolf/PerceptualHash.jl.svg?branch=master)](https://travis-ci.org/Betawolf/PerceptualHash.jl)

This `Julia` library aims to implement a range of perceptual hashing techniques.

Perceptual hashing is the process of generating a hash value for an image (or more abstractly, a video or audio file) which represents the _essential qualities_ of the file regarding properties which are important to a human observer. For example, comparing an image `X` with a compressed version of the image `x` should result in the same or highly similar hash values. This is in contrast to non-perceptual hashing techniques such as `MD5` or `SHA-1`, which are sensitive to imperceptible changes in the file.

Perceptual hashing is a useful tool for detecting duplicates of images which are intentionally or accidentally transformed in imperceptible ways. 

This library currently implements:

 + The Block Mean Value hash described by [Zauner (2010)](http://phash.org/docs/pubs/thesis_zauner.pdf)


Usage is simple.

```{julia}
# Hash an image identified by its filename.
a_hash = perceptual_hash("images/architecture1.bmp")
b_hash = perceptual_hash("images/architecture1-compressed.jpg")
b_hash = perceptual_hash("images/doodle.bmp")

# Compare images with their hash Hamming distance
hdist(a_hash, b_hash)
# 0

hdist(a_hash, c_hash)
# 20
```

There is also a library function to resolve all images in a given directory.

```{julia}
# Call with a directory name and a 'tolerance' value for image similarity
resolve_images("images", tolerance=5)

```
