p = genpath('gptoolbox');
addpath(p);
addpath('dxflib/dxflib');
addpath('go-sqlite/inst');
addpath('opcodemesh/matlab');
addpath('iso2mesh');
addpath([getenv('PMLS_INSTALL_DIR'), '/bin']);
p = genpath('pmls_core');
addpath(p);
addpath('.');
savepath
disp('Wellcome! Pmls is on the matlab path.');
