function T = mappntspy( SO )
%MAPPNTSPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
SO %#ok<NOPRT>
S = py2matlab(SO);
allpnts = zeros(0,3);
feszpnts = allpnts;
if isfield(S, 'hedgehog')
    allpnts = cell2mat(S.hedgehog.rays);
end
if isfield(S, 'anchor')
    feszpnts = S.anchor.vt;
end
indices = revdistnn([allpnts;feszpnts], S.vt);
T = int32(indices(indices>0)) - 1;
end

