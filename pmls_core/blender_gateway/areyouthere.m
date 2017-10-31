function t = areyouthere()
%AREYOUTHERE Summary of this function goes here
%   Detailed explanation goes here
if isdeployed
    t = true;
    disp( ctfroot );
else
    t = false;
end
end

