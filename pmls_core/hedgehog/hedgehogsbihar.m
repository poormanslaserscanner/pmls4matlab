function [ trisc, vtc ] = hedgehogsbihar( base, xcell, zeroshots )
%HEDGEHOGS Summary of this function goes here
%   Detailed explanation goes here
n = size(base,1);
assert( n == numel( xcell ) );
trisc = cell(n,1);
vtc = cell(n,1);
%if nargin <= 2
%    for i = 1 : n
%        [trisc{i}, vtc{i}] = hedgehog( xcell{i}, base(i,:) );
%    end
%else
    for i = 1 : n
        angles = zeroshots{i};
        if numel( angles ) > 0
            [trisc{i}, vtc{i}] = hedgehogbihar( xcell{i}, base(i,:), angles(1,2), angles(1,3) );
        else
            [trisc{i}, vtc{i}] = hedgehogbihar( xcell{i}, base(i,:) );
        end
    end
%end
end

