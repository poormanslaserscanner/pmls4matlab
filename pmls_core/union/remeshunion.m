function [ntris,nvt] = remeshunion( base, rays, zeroshots, bpar, bdist, cuda, marcube )
tic
[trisc, vtc ] = hedgehogs( base, rays, zeroshots );
[ntris,nvt] = remeshunionc( trisc,vtc, bpar, bdist, cuda, marcube );
toc
return;
