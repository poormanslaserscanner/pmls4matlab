function S = plremoveoutliers( S, internal, dihedral )
%PLREMOVEOUTLIERS Summary of this function goes here
%   Detailed explanation goes here
if strcmp( S.pmls_type, 'deform_mesh' )
    distc = getraydists( S.hedgehog.rays, S.vt, S.tris );
    n = numel(S.hedgehog.rays);
    k = 0;
    for i = 1 : n
        logind = distc{i} > internal;
        k = k + nnz(logind);
        S.hedgehogs.rays{i} = S.hedgehogs.rays{i}(~logind,:);
    end
    if k > 0
        S = S.hedgehog;
        S = rmfield(S, 'erays');
    end
end
ready = false;
n = numel(S.rays);
if isfield( S, 'erays' )
    while ~ready
        outrays = gethedgepeaks(S.base, S.rays, S.erays, S.zeroshots, internal, dihedral);
        ready = true;
        for i = 1 : n
            indices = outrays{i};
            if numel(indices) == 0
                continue
            end
            ready = false;
            logind = true(size(S.rays{i},1),1);
            logind(indices) = false;
            S.rays{i} = S.rays{i}(logind,:);
        end
        if ~ready
            S = plextendvisible(S);
        end
    end
else
    n = numel(S.rays);
    rrays = cell(n,1); 
    while ~ready
        outrays = gethedgepeaks(S.base, S.rays, S.rays, S.zeroshots, internal, dihedral);
        ready = true;
        for i = 1 : n
            indices = outrays{i};
            if numel(indices) == 0
                if numel(S.rays{i}) > 0
                    rrays{i} = S.rays{i};
                    S.rays{i} = zeros(0,3);
                end
                continue
            end
            ready = false;
            logind = true(size(S.rays{i},1),1);
            logind(indices) = false;
            S.rays{i} = S.rays{i}(logind,:);
        end
    end
    S.rays = rrays;
end

end

