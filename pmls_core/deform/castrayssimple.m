function [allpnts, logind] = castrayssimple( orig, allpnts, tris, vt )
%CASTRAYS Summary of this function goes here
%   Detailed explanation goes here

TR = TriRep(tris,vt);
tree = opcodemesh( vt', tris' );
m = size( allpnts, 1 );
inner = false(m,1);
pc = (allpnts - orig);
[hit,d] = tree.intersect( orig', pc' );
nn = sqrt( dot(pc,pc,2));
d(hit) = d(hit) ./ nn(hit);
logind = hit;
logind(hit) = d(hit) < 1.0; 
allpnts(logind,:) = orig(logind,:) + pc(logind,:) .* [d(logind),d(logind),d(logind)];   
end

