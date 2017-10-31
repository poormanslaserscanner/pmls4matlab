function indices = selinputbyraysiz( rays, siz)
%SELINPUTBYNAME Summary of this function goes here
%   Detailed explanation goes here
n = numel( rays );
indices = false(n,1);
for i = 1 : n
    indices(i) = ( size(rays{i},1) >= siz );
end
indices = find(indices);
end

