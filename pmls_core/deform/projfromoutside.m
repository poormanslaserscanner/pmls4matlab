function allpnts = projfromoutside( orig, allpnts, tris, vt )
%DEFORMTORAYS Summary of this function goes here
%   Detailed explanation goes here
ld = castrays( orig, allpnts, tris, vt );
pc = allpnts - orig;
ld(ld<0) = 1000000;
lvsrc = (pc .* repmat(ld,1,3) ) + orig;
ld = 1.0 - ld;
lpc = sqrt( dot(pc,pc,2));
sd = ld .* lpc;
logind = (sd > 0);
allpnts(logind,:) = lvsrc(logind,:);
end

