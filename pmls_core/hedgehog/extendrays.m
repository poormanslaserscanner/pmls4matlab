function nxcell = extendrays( base, edges, xcell,logind )
%EXTENDRAYS Summary of this function goes here
%   Detailed explanation goes here
n = size(base,1);
assert( n == numel( xcell ) );
if nargin < 4
    logind = true(n,1);    
end
nxcell = cell(n,1);
for i = 1 : n
    indices1 = edges(( edges(:,1) == i ), 2);
    indices2 = edges(( edges(:,2) == i ), 1);
    indices1 = indices1(logind(indices1));
    indices2 = indices2(logind(indices2));
    nxcell{i} = [ base(indices2,:); xcell{i}; base(indices1,:)];
end
end

