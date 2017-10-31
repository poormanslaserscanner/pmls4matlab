function [trir,vr,ic] = filterrefverticesic( tri, v )
%FILTERREFVERTICES Summary of this function goes here
%   Detailed explanation goes here
n = size(v,1);
bool = zeros( n,1);
bool( tri(:) ) = 1;
vr = v(logical(bool),:);
ic = find( bool );
bool = cumsum( bool );
trir = bool( tri );
end
