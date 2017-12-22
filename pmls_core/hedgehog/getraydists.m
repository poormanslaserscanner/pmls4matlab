function distc = getraydists( rays, vt, tris )
%GETHEDGEPEAKS Summary of this function goes here
%   Detailed explanation goes here
n = numel(rays);
distc = cell(n,1);
offset = 0;
pnts = cell2mat(rays);
sd = signed_distance(pnts, vt, tris, 'SignedDistanceType', 'winding_number');
for i = 1 : n
    m = size(rays{i},1);
    distc{i} = sd((1 : m)' + offset);
    offset = offset + m;
end

end

