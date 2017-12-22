function [base,rays,vid, nedges, zeroshots, erays] = truehedgehogs( base, rays, vid, edges, zeroshots, truemin, erays )
if nargin < 6
    truemin = 10;
end
n = numel( rays );
hedgeindices = true(n,1);
if truemin >= 0
    trisc = hedgehogs(base, rays, zeroshots);
    for i = 1 : n
        hedgeindices(i) = numel(trisc{i}) > 0;
    end
end
for i = 1 : n
    hedgeindices(i) = hedgeindices(i) && ( size( rays{i}, 1 ) >= truemin );  
end
base = base( hedgeindices, : );
rays = rays(hedgeindices);
if nargin > 2
    vid = vid( hedgeindices );
end
if nargin > 3
    nedges = edges( hedgeindices( edges(:,1) ) & hedgeindices( edges(:,2 ) ), : );
    bool = int32( hedgeindices );
    count = 0;
    for i = 1 : n
        count = count + bool(i);
        bool( i ) = count;
    end
    m = numel( nedges );
    for i = 1 : m
        nedges(i) = bool( nedges(i) );
        assert( nedges(i) > 0 );
    end
end
if nargin > 4
    zeroshots = zeroshots( hedgeindices );
end
if nargin > 6
    erays = erays(hedgeindices);
end