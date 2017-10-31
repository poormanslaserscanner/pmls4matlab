function [nrays,edges] = extendvisible( base, rays, zeroshots, trisc, vtc )
%PRBMESH Summary of this function goes here
%   Detailed explanation goes here
%rays = extendrays( base, edges, rays );
[allpnts, rayindices] = rays2indices( rays );
nrayindices = rayindices;
n = numel( rays );
edges = zeros(0,2);
if nargin < 4
    for i = 1 : n
%        [nrayindices, ~,edges] = visiblepoints( allpnts, rayindices, base, nrayindices, zeroshots, edges, i );
        [nrayindices, ~,edges] = visiblepointsraycast( allpnts, rayindices, base, nrayindices, zeroshots, edges, i );
    end
else
    [nrayindices, ~,edges] = visiblepoints( allpnts, rayindices, base, nrayindices, zeroshots, edges, 1 : n, trisc, vtc );
end
nrays = indices2rays( allpnts, nrayindices );
end

