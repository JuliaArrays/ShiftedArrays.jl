using ShiftedArrays
using BenchmarkTools
sz = (1024,1024)

v = rand(sz...);
useCuda = true
if useCuda
    using CUDA
    CUDA.allowscalar(false);
    v = CuArray(v)

    macro mytime(expr)
        return :( @btime CUDA.@sync $expr)
    end    
else
    macro mytime(expr)
        return :( @btime $expr)
    end
end
sh = (335, 444)

sv = ShiftedArray(v, sh)
cv = CircShiftedArray(v, sh)


# timings stated for Dell Laptop XPS 15 (i7 11800) on Windows 10
@mytime q = $sv .+ 5.0; # bc version: 1.48 ms, CuArray bc: 0.099 ms, old version: 2.73 ms
res = sv .+ 5.0

@mytime res .= $sv .+ 5.0 # bc version: 0.18 ms, CuArray bc: 0.097 ms, old version: 0.37 ms

sv = ShiftedArray(v, sh, default=0.0)
resn = copy(v)
@mytime $resn .= $sv .+ 5.0; # bc version: 0.28 ms, CuArray bc: 0.118 ms, old version: 0.42 ms

@mytime $res .= $sv .+ 5.0 .* $v .*$sv; # bc version: 0.727 ms, CuArray bc: 0.264 ms, old version: 1.65 ms

svi = ShiftedArrays.ifftshift(v)
@mytime $resn .= $svi .+ 5.0 .* $v .*$svi; # bc version: 0.53 ms, CuArray bc: 0.324 ms, old version: 3.98 ms
@mytime $resn .= ShiftedArrays.fftshift($svi .+ 5.0 .* $v .*$svi); # bc version: 2.41 ms,  CuArray bc: 0.443 ms, old version: 3.98 ms
