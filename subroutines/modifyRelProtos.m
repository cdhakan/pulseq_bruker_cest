function [upd] = modifyRelProtos(numCESTpulses,methodDirectory)

% Adds the CEST relation-function prototypes to relProtos.h 

    try
        [tline] = readFileSimple([methodDirectory,'/relProtos.h']);

        indx = [];
        for nn=1:size(tline,2)
            if strcmp(strtrim(tline{nn}),'#endif')
                indx = [indx,nn];
            end
        end
        if isempty(indx)
            error('modifyRelProtos.m:\n could not find "#endif" in relProtos.h');
        end
        indx = indx(end);   % last #endif = the include-guard close

        fid = fopen([methodDirectory,'/relProtos.h'],'w');

        for kk = 1:indx-1
            temp = strrep(tline{kk},'%','%%');
            temp = strrep(temp,'\n','\\n');
            fprintf(fid,[temp,'\n']);
        end

        % insert the CEST relation prototypes
        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n');
        fprintf(fid,'void cest_delay_relation(void);\n');
        fprintf(fid,'void cest_phase_relation(void);\n');
        fprintf(fid,'void cest_freq_relation(void);\n');
        fprintf(fid,'void cest_power_relation(void);\n');
        fprintf(fid,'void cest_pulseID_relation(void);\n');
        fprintf(fid,'void cest_pwrEquiv_relation(void);\n');
        fprintf(fid,'void cest_pwrIntRat_relation(void);\n');
        fprintf(fid,'void cest_RFduration_relation(void);\n');
        fprintf(fid,'void cest_TotTime_relation(void);\n');
        for nP = 1:numCESTpulses
            fprintf(fid,'void cestpulse%02.fRelation(void);\n',nP-1);
        end
        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n\n');


        for kk = indx:size(tline,2)
            temp = strrep(tline{kk},'%','%%');
            temp = strrep(temp,'\n','\\n');
            fprintf(fid,[temp,'\n']);
        end

        fclose(fid);
        upd = 1;
        fprintf('added CEST relation types to relProtos.h ...\n');
    catch 
        upd = 0;
        try fclose(fid); catch; end
        warning(sprintf('\tmodifyRelProtos.m:\n\t>>>could not add CEST types to relProtos.h ...\n'));
    end

end
