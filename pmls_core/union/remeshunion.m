function [ntris,nvt] = remeshunion( base, rays, zeroshots, bpar, bdist, cuda, marcube, shorten, Hc )
tic
if nargin < 8
    shorten = 0.7;
end
if nargin < 9
    Hc = {};
end
rays = shortenrays(base, rays, bpar*shorten);
[trisc, vtc ] = hedgehogs( base, rays, zeroshots );
%[trisc, vtc ] = hedgehogsbihar( base, rays, zeroshots );
[ntris,nvt] = remeshunionc( trisc,vtc, bpar, bdist, cuda, marcube, Hc );
toc
return;
