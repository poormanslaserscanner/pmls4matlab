function [H1, H2] = closeloops( H1, H2, L )
%CLOSELOOPS Summary of this function goes here
%   Detailed explanation goes here
m = numel(L);
[H1.tris, H1.vt, DT1] = filterrefvertices( H1.tris, H1.vt );

%[H2.tris, H2.vt, DT2] = filterrefvertices( H2.tris, H2.vt );
allvt = zeros(0,3);
for i = 1 : m
    inloop = H1.vt(L{i},:);
    n = size(inloop,1);
    mean = sum(inloop) / n;
    mloop = inloop - repmat(mean,n,1);
    D = mloop' * mloop;
    [VO,D] = eig(D);
    D = diag(D);
    [~,I] =sort(D);
    V = (VO(:,I([3;2])));
    C1 = mloop * V(:,1) / (V(:,1)'*V(:,1));
    C2 = mloop * V(:,2) / (V(:,2)'*V(:,2));
    vt = [C1,C2];
    E = [(1:n)',[(2:n),1]'];
    H = zeros(0,2);
    [TV, TF] = triangle(vt,E,H,'NoEdgeSteiners', 'Quality');
    vt = TV(:,1) * (V(:,1))' + TV(:,2) * (V(:,2))';
    vt = vt + repmat(mean,size(vt,1),1);
    n = size(H1.vt,1);
    V = (VO(:,I(1)));
    
    TR = triangulation(TF, vt);
    
    FBtri = freeBoundary(TR);
    FBtri = unique(FBtri(:));
    PI = nearestNeighbor(DT1,vt(FBtri,:));
    vt(FBtri,:) = DT1.X(PI,:);
    neighbourhood = getnextloop(H1, L{i});
    FN = faceNormal(TR);
%    if toorient(H1.vt - repmat(mean,n,1), FN, V(:,1)); 
    neighbourhood = neighbourhood - repmat(mean,size(neighbourhood,1),1);
    if toorient(neighbourhood, FN, V(:,1)); 
        TF = TF(:,[2,1,3]);
    end
%    ran = (rand(size(vt,1),1) - 0.5) * 0.05;
%    vt = vt + ran * V'; 
    TFn = TF + n;
    allvt = [allvt;vt];
    H1.vt = [H1.vt;vt];
    H1.tris = [H1.tris;TFn];
    n = size(H2.vt,1);
    TF = TF(:,[2,1,3]);

    TFn = TF + n;
    H2.vt = [H2.vt;vt];
    H2.tris = [H2.tris;TFn];
end
[H1.tris, H1.vt] = filterrefvertices( H1.tris, H1.vt );
[H1.vt, H1.tris]=meshcheckrepair(H1.vt, H1.tris, 'meshfix');
[H1.tris, H1.vt, DT] = filterrefvertices( H1.tris, H1.vt );
H1.selvt = unique(nearestNeighbor(DT, allvt));

[H1.tris, H1.vt] = filterrefvertices( H1.tris, H1.vt );
[H2.vt, H2.tris]=meshcheckrepair(H2.vt, H2.tris, 'meshfix');
[H2.tris, H2.vt, DT] = filterrefvertices( H2.tris, H2.vt );
H2.selvt = unique(nearestNeighbor(DT, allvt));

end

function b = toorient(p1, p2, v)
n = size(p1,1);
C1 = p1 * v / (v'*v);
C1 = nnz(C1 > 0) > (n / 2);
C2 = p2 * v / (v'*v);
C2 = nnz(C2 > 0) > (size(p2,1) / 2);
b = C1 == C2;
end

function vt = getnextloop(H, L)
L = L';
n = numel(L);
E = [L(1:n), [L(2:n);L(1)]];
TR = triangulation(H.tris, H.vt);
ti = edgeAttachments(TR, double(E));
ti = [ti{:,1}];
ti = H.tris(ti,:);
ti = setdiff(ti(:),L(:));
vt = H.vt(ti,:);
end
