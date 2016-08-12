using PerceptualHashes
using Base.Test

# write your own tests here
@test 1 == 1

arc1n = perceptual_hash("images/architecture1.bmp")
arc1c = perceptual_hash("images/architecture1-compressed.jpg")
arc2n = perceptual_hash("images/architecture_2.bmp")
arc2c = perceptual_hash("images/architecture_2-compressed.jpg")

@test UInt32(arc1n) == 0x7001fffc
@test UInt32(arc1c) == 0x7001fffc
@test hdist(arc1n, arc1c) == 2
@test hdist(arc2n, arc2c) == 0
@test hdist(arc1n, arc2n) == 130

dlist = readdir("images")
@test length(dlist) == 16

compressed = map(y -> perceptual_hash(string("images/",y)), filter(x -> contains(x, "compressed.jpg"), dlist))
normal = map(y -> perceptual_hash(string("images/",y)), filter(x -> contains(x, ".bmp"), dlist))
cmbo = zip(compressed, normal)
cdiff = map(x -> hdist(x[1],x[2]), cmbo)
@test cdiff == [2,0,0,2,0,0,2,0]
