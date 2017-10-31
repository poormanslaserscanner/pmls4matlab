function [ utris, uvt, DT ] = uniqueverts( tris, vt )
%UNIQUEVERTS Summary of this function goes here
%   Detailed explanation goes here
DT = DelaunayTri( vt );
PI = nearestNeighbor(DT,vt);
uvt = DT.X;
utris = PI(tris);
end

