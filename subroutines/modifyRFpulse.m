function [upd] = modifyRFpulse(numCESTpulses,methodDirectory)


    try
        [tline] = readFileSimple([methodDirectory,'/parsDefinition.h']);
        indx=[]; 
        for n=1:size(tline,2)
            if contains(tline{n},'/*	E N D   O F   F I L E')
                indx=[indx,n];
            end
        end
        if isempty(indx)
            fprintf('\n\tcould not find the exact match for "end of file" \n\n');
            indx = size(tline,2);
        end
        % modify file:
        fprintf('defining CEST pulses in parsDefinition.h...\n');
        here=cd;
        cd(methodDirectory);
        if ~isdir('mod')
            mkdir mod
        end
        cd(here)
        fid = fopen([methodDirectory,'/parsDefinition.h'],'w');
        for kk=1:indx-2
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           fprintf(fid,[temp,'\n']);
        end
     
        fprintf('adding CEST pulses...\n');
        % include all parameters we need:
        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n');
        %fprintf(fid,'/*these pulses are defined for the CEST-pulseq-hybrid! \n');
        % introduce custom pulses as Bruker pulse objects:
        for nP=1:numCESTpulses
            fprintf(fid,'PVM_RF_PULSE parameter\n');
            fprintf(fid,'{\n');
            fprintf(fid,'\tdisplay_name "CEST_pulse%02.f";\n',nP-1);
            fprintf(fid,'\trelations    cestpulse%02.fRelation;\n',nP-1);
            fprintf(fid,'\teditable false;\n');
            fprintf(fid,'}CESTpulse%02.f;\n',nP-1);  
            fprintf(fid,'\n');
        end

        % introduce CEST parameters:
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST saturation power";\n\trelations cest_power_relation;\n\tunits "W";\n\tformat "%%.6f";\n}CEST_pwrLIST[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST interpulse delay";\n\trelations cest_delay_relation;\n\tunits "s";\n\tformat "%%.6f";\n}CEST_DelayList[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST RF duration";\n\trelations cest_RFduration_relation;\n\tunits "us";\n\tformat "%%.6f";\n}CEST_RFduration[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST phase list";\n\trelations cest_phase_relation;\n\tformat "%%.6f";\n}CEST_PhaseList[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST offset list";\n\trelations cest_freq_relation;\n\tunits "Hz";\n\tformat "%%.6f";\n}CEST_freqList[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST power equivalents";\n\trelations cest_pwrEquiv_relation;\n\tformat "%%.6f";\n}CEST_pwrEquiv[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST pulse IDs";\n\trelations cest_pulseID_relation;\n\tformat "%%.0f";\n}CEST_pulseID[];\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "total CEST time";\n\trelations cest_TotTime_relation;\n\tformat "%%.6f";\n\tunits "ms";\n}CEST_TotTime;\n');
        fprintf(fid,'double parameter\n{\n\tdisplay_name "CEST FA equivalents";\n\trelations cest_pwrIntRat_relation;\n\tformat "%%.6f";\n\teditable false;\n}CEST_pwrIntRat[];\n');
        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n');
        if indx ~= size(tline,2)
            for kk=indx-1:size(tline,2)
               temp = strrep(tline{kk},'%','%%');
               temp = strrep(temp,'\n','\\n');
               fprintf(fid,[temp,'\n']);
            end
        end
        fclose(fid);
        upd = 1;
    catch 
      upd=0;
      try
          fclose(fid);
      catch
          fprintf('could not close file parsDefinitions.d');
      end
    end 
end 