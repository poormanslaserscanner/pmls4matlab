function data = separatesimplepy( SO, H1, H2 )
%SEPARATEPY Summary of this function goes here
%   Detailed explanation goes here
disp(mfilename());
disp('input:');
SO %#ok<NOPRT>
H1 %#ok<NOPRT>
H2 %#ok<NOPRT>
S = py2matlab(SO);
H1 = py2matlab(H1);
H2 = py2matlab(H2);
[H1.vt, H1.tris]=meshcheckrepair(H1.vt, H1.tris, 'meshfix');
[H1.tris, H1.vt] = filterrefvertices( H1.tris, H1.vt );
[H2.vt, H2.tris]=meshcheckrepair(H2.vt, H2.tris, 'meshfix');
[H2.tris, H2.vt] = filterrefvertices( H2.tris, H2.vt );

T1 = struct('tris', H1.tris, 'vt', H1.vt, 'pmls_type', 'deform_mesh', 'pmls_name', [S.pmls_name, '_1']);
T2 = struct('tris', H2.tris, 'vt', H2.vt, 'pmls_type', 'deform_mesh', 'pmls_name', [S.pmls_name, '_2']);
if isfield(SO, 'hedgehog')
    H1 = SO.hedgehog;
    H1.pmls_name = [SO.hedgehog.pmls_name, '_1'];
    ext = isfield(SO.hedgehog, 'erays_i');
    H2 = H1;
    H2.pmls_name = [SO.hedgehog.pmls_name, '_2'];
    allpnts = H1.verts;
    sd1 = signed_distance(allpnts, T1.vt, T1.tris, 'SignedDistanceType', 'winding_number');
    sd2 = signed_distance(allpnts, T2.vt, T2.tris, 'SignedDistanceType', 'winding_number');
    n = numel(H1.rays_i);
    logind = sd1 < sd2;
    for i = 1 : n
        ray = H1.rays_i{i};
        H1.rays_i{i} = ray(logind(ray));
        H2.rays_i{i} = ray(~logind(ray));
        if ext
            ray = H1.erays_i{i};
            H1.erays_i{i} = ray(logind(ray));
            H2.erays_i{i} = ray(~logind(ray));
        end
    end
    T1.hedgehog = py2matlab(H1);
    T2.hedgehog = py2matlab(H2);
end
if isfield(S, 'anchor')
    H1 = S.anchor;
    H1.pmls_name = [S.anchor.pmls_name, '_1'];
    H2 = H1;
    H2.pmls_name = [S.anchor.pmls_name, '_2'];
    allpnts = H1.vt;
    sd1 = signed_distance(allpnts, T1.vt, T1.tris, 'SignedDistanceType', 'winding_number');
    sd2 = signed_distance(allpnts, T2.vt, T2.tris, 'SignedDistanceType', 'winding_number');
    logind = sd1 < sd2;
    H1.vt = allpnts( logind,:);
    H2.vt = allpnts(~logind,:);
    H1.tris = zeros(0,3);
    H2.tris = zeros(0,3);
    T1.anchor = H1;
    T2.anchor = H2;
end
data{1} = matlab2py( T1 );
data{2} = matlab2py( T2 );   
disp('output:');
n = numel(data);
for i = 1 : n
    data{i} %#ok<NOPRT>
end


end

function logind = extendtomanifold( elem, nvt, logind )
GTR = triangulation(elem, nvt );
while true
    n = nnz(logind);
    nlogind = modifytomanifold(GTR, logind, true);
    nlogind = ~modifytomanifold(GTR, ~nlogind, false);
    nn = nnz(nlogind);
    logind = nlogind;
    if n == nn
        
        break;
    end
end
end

function logind = modifytomanifold( GTR, logind, toextend )
elem = GTR.ConnectivityList;
nvt = GTR.Points;
while true
    while true
        while true
            TR = triangulation(elem(logind,:), nvt );
            tris = freeBoundary(TR);
            TRB = triangulation(tris,nvt);
            E = edges(TRB);
            ti = edgeAttachments(TRB,E);
            nti = cellfun( @numel, ti );
            E = E(nti > 2, :);
            if numel( E ) == 0
                break;
            end
            ti = (edgeAttachments(GTR, E))';
            ti = cell2mat( ti );
            logind(ti) = toextend;
        end
        [tris,~,ic] = filterrefverticesic(tris,nvt);
         ti = (vertexAttachments(GTR, ic))';
         n = numel( ti );
         for i = 1 : n
             if ~any( logind(ti{i}) )
                 i %#ok<NOPRT>
             end
         end
        N = is_vertex_nonmanifold(tris);
        if nnz( N ) == 0
            break;
        end
        indices = ic( N );
        ti = (vertexAttachments(GTR, indices))';
        ti = cell2mat( ti );
        logind(ti) = toextend;
    end
    CC = connected_components(tris);
    C = unique(CC);
    if numel(C) == 1
        break
    end
    if numel(C) > 1
        n = numel(C);
        num = zeros(n,1);
        for i = 1 : n
            num(i) = nnz(CC==C(i));
        end
        [~,i] = min(num);
        N = (CC == C(i));
        indices = ic( N );
        ti = (vertexAttachments(GTR, indices))';
        ti = cell2mat( ti );
        logind(ti) = toextend;
        
    end
end

end

