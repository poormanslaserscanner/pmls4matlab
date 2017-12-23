function H = pmlsrecon( H, varargin )
%PMLSRECON Summary of this function goes here
%   Detailed explanation goes here
id = 'MATLAB:delaunayTriangulation:DupPtsWarnId';
warning('off', id);
if nargin > 1
    P.vox = varargin;
    H = plclarifyinput(H, P.vox{1});
    if ~isdir('pltmp')
        mkdir('pltmp');
    end
    S = dir('pltmp/tmp*');
    n = numel(S);
    for i = 1 : n
        name = [S(i).folder, '/', S(i).name];
        if S(i).isdir
            rmdir( name, 's' );
        else
            delete(name);
        end
    end
    plsave( 'pltmp/tmp.mat', H );
    save('pltmp/tmppar.mat', 'P');
    clear( 'H' );
    H = 0;
    while ~isstruct(H)
        H = pmlsrecon( 'pltmp' );
    end
else
    path = H;
    plload([path, '/tmp.mat']);
    P = load([path, '/tmppar.mat']);
    P = P.P;
    if strcmp( H.pmls_type, 'deform_mesh' )
        return
    end
    n = numel(P.vox);
    mul = 2;
    proc = 0;
    if n > 0
        vox = P.vox{1};
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plvoxuniohdgs(H, vox,0.0,true,true);
            saveprocres(H,path,proc);
        end
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plsurfacedeform(H,true, mul * vox, vox);
            saveprocres(H,path,proc);
        end
    end
    for i = 2 : n
        mul = mul * 2;
        vox = P.vox{i};
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plvoxremesh(H,vox,1.0,true,true);
            saveprocres(H,path,proc);
        end
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plrmsingularities(H,true, mul * vox);
            saveprocres(H,path,proc);
        end
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plsurfacedeform(H,true, mul * vox, vox);
            saveprocres(H,path,proc);
        end
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plvolumedeform(H,vox,1.0,true,true,false,true);
            saveprocres(H,path,proc);
        end
        proc = proc + 1;
        [H,fnd] = checkfile(path,proc,H);
        if ~fnd
            H = plsurfacedeform(H,true, 8 * vox, vox);
            saveprocres(H,path,proc);
        end
    end
    plsave( [path, '/tmp.mat'], H );
    clear( 'H' );
    H = 0;
    return
end
end

function [H,fnd] = checkfile(path,proc, H)
fname = sprintf('tmp%03d.mat', proc);
S = dir([path,'/', fname]);
n = numel(S);
fnd = false;
for i = 1 : n
    if strcmp(S(i).name, fname)
        plload([path,'/', fname]);
        fnd = true;
        return
    end
end
end

function saveprocres(H, path, proc)
fname = sprintf('tmp%03d.mat', proc);
plsave([path, '/', fname],H);
end