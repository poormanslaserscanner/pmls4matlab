function [trir,vr, DT] = filterrefvertices( tri, v )
%FILTERREFVERTICES Summary of this function goes here
%   Detailed explanation goes here
n = size(v,1);
bool = zeros( n,1);
bool( tri(:) ) = 1;
vr = v(logical(bool),:);
bool = cumsum( bool );
trir = bool( tri );
[trir,vr, DT] = uniqueverts(trir,vr);
end

