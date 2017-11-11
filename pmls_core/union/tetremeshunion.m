function [ vt, tris ] = tetremeshunion( base, rays, zeroshots, premesh, apar, qpar, dpar )
%TETREMESHUNION Summary of this function goes here
%   Detailed explanation goes here
[trisc, vtc ] = hedgehogs( base, rays, zeroshots );
[ vt, tris ] = tetremeshunionc( trisc, vtc, premesh, apar, qpar, dpar );
end

