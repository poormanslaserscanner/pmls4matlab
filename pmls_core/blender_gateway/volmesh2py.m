function [ vt, elem, edges ] = volmesh2py( vt, elem, edges )
%VOLMESH2PY Summary of this function goes here
%   Detailed explanation goes here
elem = int32(elem) - 1;
edges = int32(edges) - 1;
end

