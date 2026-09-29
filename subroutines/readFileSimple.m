% simple read text file


function [tline] = readFileSimple(fname)
    fid = fopen(fname,'r');
    n = 1;
    while ~feof(fid)
        tline{n} = fgetl(fid);
        n = n+1;
    end
    fclose(fid);
end