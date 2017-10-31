function b = hedgehogisvalid( H )
%HEDGEHOGISVALID Summary of this function goes here
%   Detailed explanation goes here
if size(H.base,1) == 0
    b = false;
    return;
end
n = size(H.base,1);
c = 0;
for i = 1 : n
    r = max(size(H.rays{i}), size(H.erays{i}));
    if r > 0
        c = c + r + 1;
    end
end
if c < 7
    b = false;
    return;
end
b = true;
end

