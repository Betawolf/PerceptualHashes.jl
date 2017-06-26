using PerceptualHashes
using Base.Test

if VERSION > v"0.4.5"
  using Combinatorics
end

if VERSION >= v"0.7"
  using FFTW
end

arc1n = perceptual_hash("images/architecture1.bmp")
arc1c = perceptual_hash("images/architecture1-compressed.jpg")
arc2n = perceptual_hash("images/architecture_2.bmp")
arc2c = perceptual_hash("images/architecture_2-compressed.jpg")

@test hdist(arc1n, arc1c) == 4
@test hdist(arc2n, arc2c) == 0
@test hdist(arc1n, arc2n) == 130

dlist = readdir("images")
@test length(dlist) == 16

compressed  = map(x -> "images/"*x, filter(x -> contains(x, "compressed.jpg"), dlist))
normal      = map(x -> "images/"*x, filter(x -> contains(x, ".bmp"), dlist))

bmv_compressed  = map(perceptual_hash, compressed)
bmv_normal      = map(perceptual_hash, normal)
bmv_cmbo        = zip(bmv_compressed, bmv_normal)
bmv_diff        = map(x -> hdist(x[1],x[2]), bmv_cmbo)
@test sum(bmv_diff) <= 8

dct_compressed  = map(x -> perceptual_hash(x, dct_hash), compressed)
dct_normal      = map(x -> perceptual_hash(x, dct_hash), normal)
dct_cmbo        = zip(dct_compressed, dct_normal)
dct_diff        = map(x -> hdist(x[1],x[2]), dct_cmbo)
@test sum(dct_diff) <= 2

resdict = resolve_images("images", 5)

#16 mappings
@test length(resdict) == 16

#Each unique
for (k,v) in resdict
  @test length(v) == 1
end
