function rays = indices2rays( allpnts, rayindices )
n = numel( rayindices );
rays = cell(n,1);
for i = 1 : n
    rays{i} = allpnts( rayindices{i}, : );
end

end

