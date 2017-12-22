function nrays = shortenrays( base, rays, siz )
%SHORTENRAYS Summary of this function goes here
%   Detailed explanation goes here
siz = siz / 100;
n = numel( rays );
nrays = cell(n,1);
for i = 1 : n
    nrays{i} = shortenray( base(i,:), rays{i}, siz );
end

end

function nray = shortenray( orig, pnts, siz )
n = size(pnts,1);
orig = repmat(orig,n,1);
pnts = pnts - orig;
d = sqrt( dot(pnts,pnts,2) );
pnts = pnts ./ repmat( d,1,3 );
d( d >= (siz + 0.2) ) = d( d>= (siz + 0.2) ) - siz;
pnts = pnts .* repmat( d, 1, 3 );
nray = pnts + orig;
end

