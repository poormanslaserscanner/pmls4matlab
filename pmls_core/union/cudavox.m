function [ vol, t ] = cudavox( vt, tris, bbox )
%CUDAVOX Summary of this function goes here
%   Detailed explanation goes here
c = (round(((bbox(:,1) + bbox(:,2) / 2))))';
bbox(:,1) = bbox(:,1) - c';  
bbox(:,2) = bbox(:,2) - c';  
vt = vt - repmat(c, size(vt,1),1);
tris = tris';
trpnts = (single(vt(tris(:),:)))';
if (nargin < 4)
    bbox = int32([floor(min(trpnts,[],2)), ceil(max(trpnts,[],2))]);
else
    bbox = int32([floor(bbox(:,1)), ceil(bbox(:,2))]);
end
assert( all(bbox(:,1) < min(trpnts,[],2)) );
assert( all(bbox(:,2) > max(trpnts,[],2)) );
[vol,t] = cudavoxmex(trpnts,bbox,1000.0);
t = t + c;
%t = t * grs;
end

