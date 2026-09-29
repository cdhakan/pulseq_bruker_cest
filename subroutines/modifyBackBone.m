function [upd] = modifyBackBone(numCESTpulses,methodDirectory)

% this function will provide a handle in backbone.c that is necessary to
% update pulses
  try
    [tline] = readFileSimple([methodDirectory,'/backbone.c']);
    indx=[];
    for nn=1:size(tline,2)
        temp_line = strtrim(tline{nn});
        if contains(tline{nn},'void backbone(') && strcmp(temp_line(1:14),'void backbone(') 
            indx=[indx,nn];
        end
    end
    indx = indx(end);
    if isempty(indx)
        error('could not find line void backbone...');
    else
       if strcmp(strtrim(tline{indx(end)+1}),'{')
           indx = indx +1;
       end
    end
    if strcmp(strtrim(tline{indx+1}),'}') || strcmp(strtrim(tline{indx+1}),'{')
        indx=indx+1;
        warning('may have trouble setting "STB_UpdateRFPulse" --- check backbone.c line %.0d ',indx);
    end
    fid = fopen([methodDirectory,'/backbone.c'],'w');
    for kk=1:indx(end)
       temp = strrep(tline{kk},'%','%%');
       temp = strrep(temp,'\n','\\n');
       fprintf(fid,[temp,'\n']);
    end
    
    fprintf(fid,'\n/* -----------------------CEST WASABI---------------------------*/\n');
    fprintf(fid,'\tDB_MSG(("including CEST relations into backbone.c"));\n');
    for nP=1:numCESTpulses
       fprintf(fid,'\tSTB_UpdateRFPulse("CESTpulse%02.f", 1, PVM_DeriveGains, Conventional);\n',nP-1); 
    end
    
    fprintf(fid,'\tcest_RFduration_relation();\n');
    fprintf(fid,'\tcest_delay_relation();\n');
    fprintf(fid,'\tcest_phase_relation();\n');
    fprintf(fid,'\tcest_pwrEquiv_relation();\n');
    fprintf(fid,'\tcest_pulseID_relation();\n');
    fprintf(fid,'\tcest_freq_relation();\n');
    fprintf(fid,'\tcest_TotTime_relation();\n');
    fprintf(fid,'\tcest_pwrIntRat_relation();\n');
    fprintf(fid,'\tcest_power_relation();/*call this after the other relations were called!*/\n');
    fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n');
    
    for kk=indx(end)+1:size(tline,2)
       temp = strrep(tline{kk},'%','%%');
       temp = strrep(temp,'\n','\\n');
       fprintf(fid,[temp,'\n']);
    end
    
    fclose(fid);
    upd=1;
    
  catch
      upd = 0;
      try
          fclose(fid);
      catch
          fprintf('could not close file .../CEST/backbone.c');
      end
  end
end 