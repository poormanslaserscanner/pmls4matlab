function nxcell = extendrays( base, edges, xcell )
%EXTENDRAYS Summary of this function goes here
%   Detailed explanation goes here
n = size(base,1);
assert( n == numel( xcell ) );
nxcell = cell(n,1);
for i = 1 : n
    indices1 = ( edges(:,1) == i );
    indices2 = ( edges(:,2) == i );
    nxcell{i} = [ base(edges(indices2,1),:); xcell{i}; base(edges(indices1,2),:)];
end
end

