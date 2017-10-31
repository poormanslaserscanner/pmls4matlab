function [allpnts, rayindices] = rays2indices( rays )
n = numel( rays );
allpnts = cell2mat( rays );
rayindices = cell(n,1);
lastind = 0;
for i = 1 : n
    to = lastind + size( rays{i}, 1 );
    rayindices{i} = ( lastind + 1 ) : to;
    lastind = to;
end
end
