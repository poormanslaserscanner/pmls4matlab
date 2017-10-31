function [ntris,nvt] = remeshunion( base, rays, zeroshots, bpar, bdist )
tic
[trisc, vtc ] = hedgehogs( base, rays, zeroshots );
[ntris,nvt] = remeshunionc( trisc,vtc, bpar, bdist );
toc
return;
