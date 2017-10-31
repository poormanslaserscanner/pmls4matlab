function [hit,d,trix,bary,Q] = raycast(tree, origs, pnts, dcn )
%RAYCAST Summary of this function goes here
%   Detailed explanation goes here
pc = dcn * ( pnts - origs );
[hit,d,trix,bary,Q] = tree.intersect(origs',pc');
bary = bary';
Q = Q';
bary = [ones(size(bary,1),1) - bary * ones(2,1),bary];
if any(hit)
    pnt = pc(hit,:);
d(hit) = d(hit) ./ sqrt( dot(pnt,pnt,2) );
end
end

