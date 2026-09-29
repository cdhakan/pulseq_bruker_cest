function [statusID] = WritingCESTpresatToPPG(floc,eventTable_ID,eventTable,eventTable_full,BaseParamIndex,seq,unique_rf)

% Writes the CEST/WASABI presaturation as a Bruker ppg MODULE: cest_wasabi.mod

%     #include <cest_wasabi.mod>   ; in the ppg head
%     subr cest_wasabiInit()       ; once, before the NR loop 
%     subr cest_wasabi()           ; inside the NR loop - presaturation
%     subr cest_wasabiInc()        ; inside the NR loop - advance to next offset

    try
        fid = fopen([floc,'/mod/cest_wasabi.mod'],'w');
        if fid<0
            error('could not open .../CEST/cest_wasabi.mod for modifying');
        end
        ID = strrep(strrep(datestr(now),':','-'),' ','_');

        % ---- module header ----
        fprintf(fid,';****************************************************************\n');
        fprintf(fid, '; AUTHOR - CHETAN B DHAKAN ; Email - cdhakan@mgh.harvard.edu \n');
        fprintf(fid,'; cest_wasabi.mod : WASABI/CEST presaturation module\n');
        fprintf(fid,';   subr cest_wasabiInit()       ; once - before the NR loop\n');
        fprintf(fid,';   subr cest_wasabi()           ; in the NR loop - presat)\n');
        fprintf(fid,';   subr cest_wasabiInc()        ; in the NR loop - advance to next offset\n');
        fprintf(fid,';****************************************************************\n\n');

        % ---- definitions  ----
        fprintf(fid,'define list<frequency> fCEST     = {$CEST_freqList}\n');
        fprintf(fid,'define list<phase>     pCEST     = {$CEST_PhaseList}\n');
        fprintf(fid,'define list<delay>     dCEST     = {$CEST_DelayList}\n');
        fprintf(fid,'define list<pulse>     rfCEST    = {$CEST_RFduration}\n');
        fprintf(fid,'define list<power>     FArfCEST  = {$CEST_pwrLIST}\n\n');

        % ---- reset all list pointers ----
        fprintf(fid,'subroutine cest_wasabiInit()\n{\n');
        fprintf(fid,'\t0u fCEST.res\n\t0u pCEST.res\n\t0u dCEST.res\n\t0u rfCEST.res\n\t0u FArfCEST.res\n');
        fprintf(fid,'}\n\n');

        % ---- the presaturation itself ----
        fprintf(fid,'subroutine cest_wasabi()\n{\n');
        for nEvt = 1:size(eventTable_ID,1)
            if eventTable_ID(nEvt,1) == 0            % recovery delay
                fprintf(fid,'\tdCEST\n');
            elseif eventTable_ID(nEvt,1) > 0         % RF saturation pulse
                internalID = eventTable_full{nEvt,1}.ID;
                internalID = find(ismember(unique_rf,internalID,'rows'));
                if numel(internalID) ~= 1
                    error('could not assign baselevel pulse shape to this pulse ID!');
                end
                externalID = BaseParamIndex(internalID); 
                fprintf(fid,'\t10u FArfCEST:f1\n\t(10u fCEST):f1\n');
                fprintf(fid,'\t(rfCEST:sp%i(currentpower) pCEST):f1\n',externalID); % no gatepulse: amp blanking is automatic (BLKTR/SCON)
            elseif eventTable_ID(nEvt,1) < 0         % spoiler gradient (x=y=z)
                tRampUp   = seq.gradLibrary.data(eventTable(nEvt,1)).array(2)*1e6;
                tFlat     = seq.gradLibrary.data(eventTable(nEvt,1)).array(3)*1e6;
                tRampDown = seq.gradLibrary.data(eventTable(nEvt,1)).array(4)*1e6;
                amp       = seq.gradLibrary.data(eventTable(nEvt,1)).array(1);
                if ~exist('SysProp','var'); SysProp.gradient.maxAmp = amp; end
                amp = amp/SysProp.gradient.maxAmp*100;       % of max
                if abs(amp)>=100; amp = sign(amp)*25; end   
                fprintf(fid,'\t%.0fu grad_ramp{%.3f, %.3f, %.3f}\n',max(tRampUp),amp,amp,amp);
                fprintf(fid,'\t%du\n',round(tFlat));
                if tRampDown > 0
                    fprintf(fid,'\t%du grad_off\n',round(tRampDown));
                else
                    fprintf(fid,'\td2 grad_off\n');
                end
            end
        end
        % restore RX/TX frequency + power for the image readout
        fprintf(fid,'\t10u fq8(receive):f1\n\t10u pl1:f1\n');
        fprintf(fid,'}\n\n');

        % ---- advance all list pointers to the next offset ----
        fprintf(fid,'subroutine cest_wasabiInc()\n{\n');
        fprintf(fid,'\t0u fCEST.inc\n\t0u pCEST.inc\n\t0u dCEST.inc\n\t0u rfCEST.inc\n\t0u FArfCEST.inc\n');
        fprintf(fid,'}\n');

        fclose(fid);
        fprintf('CEST/WASABI presaturation written as : cest_wasabi.mod\n');
        statusID = 1;
    catch 
        statusID = 0;
        try fclose(fid); catch; end
    end
end
