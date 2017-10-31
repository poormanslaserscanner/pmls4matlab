function [tris, vt] = getsurface( tetr, v )
%GETSURFACE Summary of this function goes here
%   Detailed explanation goes here
tris = surftri(v,tetr);
[tris, vt] = filterrefvertices(tris,v);
end

