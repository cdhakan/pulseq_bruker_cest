function [upd]= modifyparsRelations(numCESTpulses,methodDirectory,CEST_rf,CEST_rfFA,CESTphasearray,CEST_delays,CEST_offArray,CEST_pwrEquiv,CEST_pulseID,CEST_pwrIntRat)

    try
        [tline] = readFileSimple([methodDirectory,'/parsRelations.c']);

        % find insertion point (end-of-file marker)
        indx=[];
        for n=1:size(tline,2)
            if contains(tline{n},'E N D   O F   F I L E')
                indx=[indx,n];
            end
        end
        if isempty(indx)
            fprintf('HINT:\n\tparsRelations.c --- no "end of file" marker found attaching at end...\n');
            indx = size(tline,2)+1;
        end
        if contains(tline{indx-1},'************************')
            indx = indx-2;
        else
            indx = indx-1;
        end

        writeHfile(methodDirectory,'cest_offset.h',  'CEST_freqList',   CEST_offArray);            % [Hz]
        writeHfile(methodDirectory,'cest_phase.h',   'CEST_PhaseList',  CESTphasearray*360/2/pi);  % rad -> deg
        writeHfile(methodDirectory,'cest_pwrequ.h',  'CEST_pwrEquiv',   CEST_pwrEquiv);
        writeHfile(methodDirectory,'cest_pulseid.h', 'CEST_pulseID',    CEST_pulseID);
        writeHfile(methodDirectory,'cest_delay.h',   'CEST_DelayList',  CEST_delays);              % [s]
        writeHfile(methodDirectory,'cest_peakB1.h',  'CEST_pwrLIST',    CEST_rfFA);                % B1 [uT] (scaled to W below)
        writeHfile(methodDirectory,'cest_puldur.h',  'CEST_RFduration', CEST_rf*10^6);             % s -> us
        writeHfile(methodDirectory,'cest_IntEqu.h',  'CEST_pwrIntRat',  CEST_pwrIntRat);

        % ---- add the CEST relations to parsRelations.c ----
        fid = fopen([methodDirectory,'/parsRelations.c'],'w');
        if fid<0
            error('could not access/open file .../CEST/parsRelations.c');
        end
        for kk=1:indx
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           fprintf(fid,[temp,'\n']);
        end
        fprintf(fid,'\n/* -----------------------CEST WASABI---------------------------*/\n');

        
        for nP=1:numCESTpulses
            fprintf(fid,'void cestpulse%02.fRelation(void)\n{\n',nP-1);
            fprintf(fid,'\tDB_MSG(("-->cestpulse%02.fRelation"));\n',nP-1);
            fprintf(fid,'\tUT_SetRequest("CESTpulse%02.f");\n',nP-1);
            fprintf(fid,'\tbackbone();\n');
            fprintf(fid,'\tDB_MSG(("<--cestpulse%02.fRelation "));\n}\n',nP-1);
        end

        
        fprintf('\n\t check the RF power (CEST_pwrLIST) before scanning\n');
        % answer = questdlg('check "CEST_pwrLIST" before scanning','GUI','accept','decline','decline');
        % if strcmp(answer,'decline')
        %     error('recheck RF power');
        % end


        fprintf(fid,'void cest_delay_relation(void)\n{\n\tParxRelsParChangeDims("CEST_DelayList", {%.0f});\n#include "cest_delay.h"\n}\n',numel(CEST_delays));
        fprintf(fid,'void cest_RFduration_relation(void)\n{\n\tParxRelsParChangeDims("CEST_RFduration", {%.0f});\n#include "cest_puldur.h"\n}\n',numel(CEST_rf));
        fprintf(fid,'void cest_phase_relation(void)\n{\n\tParxRelsParChangeDims("CEST_PhaseList", {%.0f});\n#include "cest_phase.h"\n}\n',numel(CESTphasearray));
        fprintf(fid,'void cest_freq_relation(void)\n{\n\tParxRelsParChangeDims("CEST_freqList", {%.0f});\n#include "cest_offset.h"\n}\n',numel(CEST_offArray));
        fprintf(fid,'void cest_pulseID_relation(void)\n{\n\tParxRelsParChangeDims("CEST_pulseID", {%.0f});\n#include "cest_pulseid.h"\n}\n',numel(CEST_pulseID));
        fprintf(fid,'void cest_pwrIntRat_relation(void)\n{\n\tParxRelsParChangeDims("CEST_pwrIntRat", {%.0f});\n#include "cest_IntEqu.h"\n}\n',numel(CEST_pwrIntRat));
        fprintf(fid,'void cest_pwrEquiv_relation(void)\n{\n\tParxRelsParChangeDims("CEST_pwrEquiv", {%.0f});\n#include "cest_pwrequ.h"\n}\n',numel(CEST_pwrEquiv));

        % power relation: #include the peak-B1 [uT] values into CEST_pwrLIST then scale to Watts
        fprintf(fid,'void cest_power_relation(void)\n{\n\tParxRelsParChangeDims("CEST_pwrLIST", {%.0f});\n',numel(CEST_rfFA));
        fprintf(fid,'\tdouble CEST_gamma = 42.5774785; //NIST in [MHz/T]\n');
        fprintf(fid,'\tYesNo CEST_RefPowAvailable = No;\n\tdouble CEST_RefPower = 0.0;\n\tCEST_RefPowAvailable = STB_GetRefPower(1, &CEST_RefPower);\n');
        fprintf(fid,'\tif (CEST_RefPowAvailable == No)\n\t{\n\t\tCEST_RefPower = 0; /*!! MUST be 0 for experiments at scanner !!*/\n\t}\n');
        fprintf(fid,'#include "cest_peakB1.h"\n');
        fprintf(fid,'\tfor (int nn = 0;nn < %.0f; ++nn)\n\t{\n\t\tCEST_pwrLIST[nn] = CEST_RefPower * pow(CEST_pwrLIST[nn],2) / pow((double)90/(double)0.001/(double)360/CEST_gamma,2);\n\t\tCEST_pwrLIST[nn] = MIN_OF(MAX_OF(CEST_pwrLIST[nn], 0), 10);\n\t}\n}\n',numel(CEST_rfFA));

        % total scan time
        fprintf(fid,'void cest_TotTime_relation(void)\n{\n\tCEST_TotTime = 0;\n\tfor (int nn=0; nn<%.0f; ++nn)\n\t{\n\t\tCEST_TotTime += CEST_DelayList[nn]*1000;\n\t}\n\tfor (int nn=0; nn < %.0f; ++nn)\n\t{\n\t\tCEST_TotTime += CEST_RFduration[nn]/1000;\n\t}\n\tDB_MSG(("CEST scan time calculated:"));\n\tprintf("%%.2f [ms]\\n",CEST_TotTime);\n}\n',numel(CEST_delays),numel(CEST_rf));

        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n\n');
        if indx ~= size(tline,2)
            for kk=indx+1:size(tline,2)
               temp = strrep(tline{kk},'%','%%');
               temp = strrep(temp,'\n','\\n');
               fprintf(fid,[temp,'\n']);
            end
        end

        fclose(fid);
        upd = 1;
    catch
        upd = 0;
        try fclose(fid); catch; end
        try fclose all; catch; end
        warning('modifyparsRelations.m : unable to modify CEST relations / *.h files.');
    end
end 


% ------------------------------------------------------------------------
function writeHfile(methodDirectory, hName, paramName, values)

    fid = fopen([methodDirectory,'/',hName],'w');
    if fid<0
        error(['modifyparsRelations/writeHfile: could not open ',hName,' for writing']);
    end
    for nn=1:numel(values)
        fprintf(fid,'%s[%d] = %.6f;\n', paramName, nn-1, values(nn));
    end
    fclose(fid);
end
