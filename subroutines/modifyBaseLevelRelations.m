function [upd,BaseParamIndex] =  modifyBaseLevelRelations(numCESTpulses,methodDirectory,nmbrCESToffsets)

% in this function BaseLevelRelations.c is modified to assign CEST
% pulses to base level parameters and set NR hard coded to the number
% of CEST presaturation offsets.


    try
        [tline]         = readFileSimple([methodDirectory,'/BaseLevelRelations.c']);
        [freeParams]    = check4freeRF(tline,'PV360.3.6');
        BaseParamIndex  = []; 
        
        indx            = [];
        for kk=1:size(tline,2)
            temp_line = strtrim(tline{kk});
            if contains(tline{kk},'void SetPpgParameters(') && strcmp(temp_line(1:22),'void SetPpgParameters(')
                indx=[indx,kk];
            end
        end
        if strcmp(tline{indx(end)+1},'{')
            indx=indx+1;
        end
        if isempty(indx)
            error('unable to modify "BaseLevelRelations.c...');
        end
        
        fid = fopen([methodDirectory,'/BaseLevelRelations.c'],'w');
        for kk=1:indx(end) 
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           temp = strrep(temp,'\0','\\0');
           fprintf(fid,[temp,'\n']);
        end    
       
        for nP=1:numCESTpulses
           fprintf(fid,'ATB_SetRFPulse("CESTpulse%02.f", "ACQ_RfShapes[%1.f]");\n',nP-1,freeParams(nP));
           BaseParamIndex=[BaseParamIndex,freeParams(nP)];
           %warning(['assigned base level parameter SP',num2str(freeParams(nP))]);        
        end
% hard coded: number of repetitions equals number of CEST offsets
        fprintf(fid,'NR = %02.f;',nmbrCESToffsets);
        fprintf(fid,'\n/*--------------------------------------------------------------*/\n');
        for kk=indx(end)+1:size(tline,2)
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           temp = strrep(temp,'\0','\\0');
           temp = regexprep(temp,'ATB_SetPulprog\("([^"]+)\.ppg"\)','ATB_SetPulprog("cbd_$1.ppg")');
           fprintf(fid,[temp,'\n']);
        end

        fclose(fid);
        upd = 1;
        
    catch
       upd = 0;
       try
           fclose(fid);
       catch
           fprintf('could not close file .../CEST/BaseLevelRelations.c\n');
       end
    end

end