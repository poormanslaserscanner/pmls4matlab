function data = filltripy( S )
%FILLTRIPY Summary of this function goes here
%   Detailed explanation goes here
m = numel(S);
data = cell(m,1);
for i = 1 : m
    loop = S{i};
    n = size(loop,1);
    mean = sum(loop) / n;
    loop = loop - repmat(mean,n,1);
    D = loop' * loop;
    [V,D] = eig(D);
    D = diag(D);
    [~,I] =sort(D);
    V = (V(:,I([3;2])));
    C1 = loop * V(:,1) / (V(:,1)'*V(:,1));
    C2 = loop * V(:,2) / (V(:,2)'*V(:,2));
    vt = [C1,C2];
    E = [(1:n)',[(2:n),1]'];
    H = zeros(0,2);
    [TV, TF] = triangle(vt,E,H,'NoEdgeSteiners', 'Quality', 25 );
    vt = TV(:,1) * (V(:,1))' + TV(:,2) * (V(:,2))';
    vt = vt + repmat(mean,size(vt,1),1);
    data{i} = matlab2py(struct('tris', TF, 'vt', vt, 'pmls_type', 'mesh', 'pmls_name', 'closure'));  
    
    
end

end

