function [ID] = modifyParsLayout(methodDirectory)
% Inserts a CEST parameter group into parsLayout.h using
% the modern "pargroup {} attributes {} CEST_Parameters"


    try
        [tline] = readFileSimple([methodDirectory,'/parsLayout.h']);

        idxMC = [];
        for n=1:size(tline,2)
            if contains(strrep(tline{n},' ',''),'}MethodClass;')
                idxMC = [idxMC,n];
            end
        end
        if isempty(idxMC)
            error(sprintf('modifyParsLayout.m (PV360):\n could not find "} MethodClass;" in parsLayout.h\n'));
        end
        idxMC = max(idxMC);

        idxOpen = [];
        for n = idxMC-1:-1:1
            t = strtrim(tline{n});
            if strcmp(t,'extend pargroup') || strcmp(t,'pargroup')
                idxOpen = n; break;
            end
        end
        if isempty(idxOpen)
            error(sprintf('modifyParsLayout.m (PV360):\n could not find the pargroup for MethodClass\n'));
        end

        % CEST parameter group as "CEST"
        TheCESTparams = ['pargroup\n{\n', ...
            '\tCEST_freqList;\n\tCEST_pwrLIST;\n\tCEST_RFduration;\n', ...
            '\tCEST_DelayList;\n\tCEST_PhaseList;\n\tCEST_pulseID;\n', ...
            '\tCEST_pwrEquiv;\n\tCEST_pwrIntRat;\n\tCEST_TotTime;\n', ...
            '}\nattributes\n{\n\tdisplay_name "CEST";\n} CEST_Parameters;\n\n'];

        fid = fopen([methodDirectory,'/parsLayout.h'],'w');


        for kk = 1:idxOpen-1
            temp = strrep(tline{kk},'%','%%');
            temp = strrep(temp,'\n','\\n');
            fprintf(fid,[temp,'\n']);
        end

        fprintf(fid,TheCESTparams);

        for kk = idxOpen:idxMC-1
            temp = strrep(tline{kk},'%','%%');
            temp = strrep(temp,'\n','\\n');
            fprintf(fid,[temp,'\n']);
        end

        fprintf(fid,'\tCEST_Parameters;\n');

        for kk = idxMC:size(tline,2)
            temp = strrep(tline{kk},'%','%%');
            temp = strrep(temp,'\n','\\n');
            fprintf(fid,[temp,'\n']);
        end

        fclose(fid);
        ID = 1;
        fprintf('CEST parameters written into parsLayout.h \n');
    catch
        ID = 0;
        try; fclose(fid); catch; end
        warning(sprintf('\tmodifyParsLayout.m :\n\t>>>could not insert CEST group into parsLayout.h...\n'));
    end

end
