using ShiftedArrays
using BenchmarkTools
sz = (1024,1024)

v = rand(sz...);
useCuda = true
if useCuda
    using CUDA
    CUDA.allowscalar(false);
    v = CuArray(v)
end
sh = (335, 444)

sv = ShiftedArray(v, sh)
cv = CircShiftedArray(v, sh)

# timings stated for Dell Laptop XPS 15 (i7 11800)
@btime q = $sv .+ 5.0 # bc version: 1.48 ms, CuArray bc: 0.016 ms, old version: 2.73 ms
res = sv .+ 5.0

@btime res .= $sv .+ 5.0 # bc version: 0.18 ms, CuArray bc: 0.015 ms, old version: 0.37 ms

sv = ShiftedArray(v, sh, default=0.0)
resn = copy(v)
@btime $resn .= $sv .+ 5.0 # bc version: 0.28 ms, CuArray bc: 0.020 ms, old version: 0.42 ms

@btime $res .= $sv .+ 5.0 .* $v .*$sv # bc version: 0.445 ms, CuArray bc: 0.039 ms, old version: 1.65 ms

svi = ShiftedArrays.ifftshift(v)
@btime $resn .= $svi .+ 5.0 .* $v .*$svi # bc version: 2.41 ms, CuArray bc: 0.029 ms, old version: 3.98 ms
@btime $resn .= ShiftedArrays.fftshift($svi .+ 5.0 .* $v .*$svi) # bc version: 2.41 ms,  CuArray bc: 0.050 ms, old version: 3.98 ms
