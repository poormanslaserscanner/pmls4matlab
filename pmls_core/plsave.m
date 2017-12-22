function plsave( path, varargin )
%PLSAVE Summary of this function goes here
%   Detailed explanation goes here
file_type = 'bpy_data'; %#ok<NASGU>
file_version = 1; %#ok<NASGU>
file_description = 'Data for PMLS Cave Editor'; %#ok<NASGU>
n = numel(varargin);
for i = 1 : n
    varargin{i}.pmls_name = inputname(i+1);
end
names = savehelper(varargin);
names = [{'file_type'; 'file_version'; 'file_description'};names];
save(path, names{:});
end

function names = savehelper(data)
n = numel(data);
names = cell(n,1);
for i = 1 : n
    D = data{i};
    names{i} = D.pmls_name;
    assignin('caller', names{i}, D);
end
end
