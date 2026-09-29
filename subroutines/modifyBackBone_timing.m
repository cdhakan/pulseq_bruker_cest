function [upd] = modifyBackBone_timing(methodDirectory)

% Function will add the duration of all CEST events to the total scan time


  try
    [tline] = readFileSimple([methodDirectory,'/backbone.c']);
    indx=[];

    for nn=1:size(tline,2)
        temp_line = strtrim(tline{nn});
        if contains(tline{nn},'SetRecoParam(') && strcmp(temp_line(1:13),'SetRecoParam(') 
            indx=[indx,nn];
        end
    end
    if numel(indx) ~= 1
        error('could not modify scan time duration in backbone.c...');
    end
    fid = fopen([methodDirectory,'/backbone.c'],'w');
    for nn=1:indx
        temp = strrep(tline{nn},'%','%%');
        temp = strrep(temp,'\n','\\n');
        fprintf(fid,[temp,'\n']);
    end
    fprintf(fid,'PVM_ScanTime += CEST_TotTime;\n');
    for nn=indx+1:size(tline,2)
        temp = strrep(tline{nn},'%','%%');
        temp = strrep(temp,'\n','\\n');
        fprintf(fid,[temp,'\n']);
    end
    fclose(fid);
    upd = 1;
    fprintf('including the duration of all presaturation pulses and delays to scan time calculations');
  catch
      upd = 0;
      try
        fclose(fid);
      catch
          fprintf('could not close file .../CEST/backbone.c\n');
      end
      warning(sprintf('\n\tcould not find identifier in backbone.c for modifying total scan time\n'));
  end
end 