function H = pmlsrecon( H, vox, voxside )
%PMLSRECON Summary of this function goes here
%   Detailed explanation goes here
voxmul = 1.5;
if nargin > 1
    H = plclarifyinput(H, voxmul * vox);
    P.vox = vox;
    P.voxside = voxside;
    [H, mean, var] = plnormalize(H);
    P.var = var;
    P.mean = mean;
    P.dvar = eye(3);
    P.dmean = zeros(1,3);
    P.dvar = P.dvar * var;
    P.dmean = (P.dmean + mean) * var; 
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
    H = pmlsrecon( 'pltmp' );
else
    path = H;
    plload([path, '/tmp.mat']);
    P = load([path, '/tmppar.mat']);
    P = P.P;
    if strcmp( H.pmls_type, 'deform_mesh' )
        return
    end
    maxlen = 100 * (max(H.base(:,3)) - min(H.base(:,3))) / P.vox;
    if maxlen < P.voxside
%        H = plcgalunionhdgs(H,true,0.5,5.0,0.0);
        H = plvoxuniohdgs(H, voxmul * P.vox,0.0,true,true);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpu.mat'],Hd);
        H = plsurfacedeform(H,true, 2 * P.vox, P.vox);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpus.mat'],Hd);
        H = plvoxremesh(H,P.vox,1.0,true,true);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpusv.mat'],Hd);
        H = plrmsingularities(H,true, 4 * P.vox);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpusvf.mat'],Hd);
        H = plsurfacedeform(H,true, 4 * P.vox, P.vox);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpusvfs.mat'],Hd);
        H = plvolumedeform(H,P.vox,1.0,true,true,false,true);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpusvfsv.mat'],Hd);
        H = plsurfacedeform(H,true, 8 * P.vox, P.vox);
        Hd = pldebtrafo(H, P.dmean, P.dvar);
        plsave([path, '/tmpusvfsvs.mat'],Hd);
        H = plinvtrafo(H, P.mean, P.var);
        plsave( [path, '/tmp.m'], H );
        clear( 'H' );
        H = 0;
        return
    end
    dir1 = [path, 'tmp1'];
    dir2 = [path, 'tmp2'];
    if isdir(dir1) && isdir(dir2)
        H1 = pmlsrecon(dir1);
        H2 = pmlsrecon(dir2);
        if isstruct(H1) && isstruct(H2)
            H = plcgalunionmesh( {H1;H2}, false, false, 0.5, 2.0, 0.0 ); 
            H = plinvtrafo(H, P.mean, P.var);
            plsave( [path, '/tmp.m'], H );
            clear( 'H' );
        end
        H = 0;
        return
    end
    divx = (max(H.base(:,3)) + min(H.base(:,3))) / 2;
    lowx = divx + P.vox * voxside / 400;
    highx = divx - P.vox * voxside / 400;
    createtaskdir( [path,'/tmp1'], H, P, (@(x) x <= lowx) );
    createtaskdir( [path,'/tmp2'], H, P, (@(x) x >= highx) );
    clear( 'H' );
    H = pmlsrecon( path );
end
end

function createtaskdir( path, H, P, fl )
    n = numel(H.rays);
    for i = 1 : n
        logind = fl(H.rays{i}(:,3));
        H.rays{i} = H.rays{i}(logind,:);
        logind = fl(H.erays{i}(:,3));
        H.erays{i} = H.erays{i}(logind,:);
    end
    edg = zeros(0,2);
    [H.base, H.rays, H.vid, H.edges, H.zeroshots, H.erays] = truehedgehogs(H.base, H.rays, H.vid,edg, H.zeroshots, 6, H.erays);
    [H, P.mean, P.var] = plnormalize(H);
    P.dvar = P.dvar * P.var;
    P.dmean = (P.dmean + P.mean) * P.var; 
    
    if ~isdir(path)
        mkdir(path);
    end
    S = dir([path,'/tmp*']);
    n = numel(S);
    for i = 1 : n
        name = [S(i).folder, '/', S(i).name];
        if S(i).isdir
            rmdir( name, 's' );
        else
            delete(name);
        end
    end
    plsave( [path,'/tmp.m'], H );
    save([path,'/tmppar.m'], 'P');

end

function H = pltrafo(H, mean, var)
if strcmp( H.pmls_type, 'deform_mesh' )
    H = meshtrafo(H, mean, var);
else
    H = hedgtrafo(H, mean, var);
end
end

function H = plinvtrafo(H, mean, var)
if strcmp( H.pmls_type, 'deform_mesh' )
    H = meshinvtrafo(H, mean, var);
else
    H = hedginvtrafo(H, mean, var);
end
end

function H = pldebtrafo(H, mean, var)
if strcmp( H.pmls_type, 'deform_mesh' )
    H = meshdebtrafo(H, mean, var);
else
    H = hedgdebtrafo(H, mean, var);
end
end

function H = hedgtrafo(H,mean,var)
n = numel(H.rays);
H.base = (H.base - repmat(mean,n,1)) * var;
for i = 1 : n
    m = size(H.rays{i},1);
    H.rays{i} = (H.rays{i} - repmat(mean,m,1)) * var;
end
if isfield(H, 'erays')
    for i = 1 : n
        m = size(H.erays{i},1);
        H.erays{i} = (H.erays{i} - repmat(mean,m,1)) * var;
    end
end
end

function H = hedgdebtrafo(H,mean,var)
n = numel(H.rays);
H.base = (H.base + repmat(mean,n,1)) * var';
for i = 1 : n
    m = size(H.rays{i},1);
    H.rays{i} = (H.rays{i} + repmat(mean,m,1)) * var';
end
if isfield(H, 'erays')
    for i = 1 : n
        m = size(H.erays{i},1);
        H.erays{i} = (H.erays{i} + repmat(mean,m,1)) * var';
    end
end
end

function H = hedginvtrafo(H,mean,var)
n = numel(H.rays);
H.base = H.base * var' + repmat(mean,n,1);
for i = 1 : n
    m = size(H.rays{i},1);
    H.rays{i} = H.rays{i} * var' + repmat(mean,m,1);
end
if isfield(H, 'erays')
    m = size(H.erays{i},1);
    H.erays{i} = H.erays{i} * var' + repmat(mean,m,1);
end
end

function H = meshtrafo(H,mean,var)
H.vt = (H.vt - repmat(mean,size(H.vt,1),1)) * var;
if isfield(H,'hedgehog')
    H.hedgehog = hedgtrafo(H.hedgehog, mean, var);
end
if isfield(H,'anchor')
    H.anchor = meshtrafo(H.anchor, mean, var);
end
end

function H = meshdebtrafo(H,mean,var)
H.vt = (H.vt + repmat(mean,size(H.vt,1),1)) * var';
if isfield(H,'hedgehog')
    H.hedgehog = hedgdebtrafo(H.hedgehog, mean, var);
end
if isfield(H,'anchor')
    H.anchor = meshdebtrafo(H.anchor, mean, var);
end
end

function H = meshinvtrafo(H,mean,var)
H.vt = H.vt * var' + repmat(mean,size(H.vt,1),1);
if isfield(H,'hedgehog')
    H.hedgehog = hedginvtrafo(H.hedgehog, mean, var);
end
if isfield(H,'anchor')
    H.anchor = meshinvtrafo(H.anchor, mean, var);
end
end

function [H, mean_, var_] = plnormalize(H)
pnts = cell2mat(H.erays);
mean_ = mean(pnts);
var_ = cov(pnts);
[var_,D] = eig(var_);
D = diag(D);
[~,p] = sort(D);
var_=var_(:,p);
if det(var_) < 0
    var_ = var_(:,[2, 1, 3]);
end
H = pltrafo(H,mean_,var_);
end