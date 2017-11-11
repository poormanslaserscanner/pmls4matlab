function sqlite2csv( sqfile, sid, csvfile )
%SELDAT Summary of this function goes here
%   Detailed explanation goes here
fp = which( 'sqlite3.exe' );
i = find(fp == '\');
if ~isempty(i)
    i = i(end) - 1;
    fp = fp(1:i);
    s = sqlite(sqfile, fp);
else
    s = sqlite(sqfile);
end
[~,out] = fprintf( s, sprintf('SELECT * FROM shots WHERE surveyID = %d', int32(sid)) );
fid = fopen(csvfile,'wt');
fprintf( fid, '%s', out'  );
fclose(fid);


