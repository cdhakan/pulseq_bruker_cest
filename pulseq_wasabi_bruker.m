%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pulseq_wasabi_bruker

% AUTHOR - CHETAN B DHAKAN (cdhakan@mgh.harvard.edu)
% PV 360.3.6 (CEST - WASABI pulse sequence)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pulseq_wasabi_bruker()
%% Read the Pulseq file

    % select Bruker method source code
    uiwait(msgbox('Select the Bruker Source method folder', ...
                  'Select the Bruker Source PPG','help','modal'));
    [fname,floc] = locatePPGfile();
    % select *.seq file:
    seq = mr.Sequence();
    uiwait(msgbox('select the WASABI *.seq file', ...
                  'Select the WASABI .seq file','help','modal'));
    [fnPLSQ,pnPLSQ] = uigetfile({'*.seq','Pulseq sequence (*.seq)';'*.*','All files'}, ...
                                'Select the WASABI .seq file','MultiSelect','off');
    try
        if ~isdir([floc,'/mod'])
            mkdir([floc,'/mod']);
        end
        % log file to store process
        diary([floc,'/mod/MATLAB_logFile.txt']);
        seq.read([pnPLSQ,fnPLSQ]);
        fprintf('files were selected!\n');

        % reading & analyzing *.seq file 
        [eventTable_full,eventTable_ID,eventTable,~,unique_rf] = interpretPulseqFile(seq);

        % write information into arrays 
        [CEST_offArray,CEST_delays,CESTphasearray,CEST_rf,CEST_rfFA,CEST_pulseID] = CreateArraysForCEST(fname,floc,eventTable_ID,eventTable_full,unique_rf);

        % transfer pulses from *.seq files into Bruker's *.exc format
        [~,CEST_pwrEquiv,~,CEST_pwrIntRat] = writePulseShapeToFile(seq,unique_rf,floc);
        
        % copy the *.seq file so information is available for post procesing
        StatCopy = copyfile([pnPLSQ,fnPLSQ] ,[floc,'/mod/orig_',fnPLSQ]);
        if ~StatCopy
            warning('no *.seq file found');
        end
        % modify Bruker Method Code which includes Backbone, BaseLevelRelations,
        % parsRelations, RelProtos, ParsLayout, initMeth, XML
        upd =[0 0 0 0 0 0 0 0 0];
        methodDirectory     = floc;
        numCESTpulses       = numel(unique(eventTable(eventTable_ID>0)));
        [upd(1)]          = modifyRFpulse(numCESTpulses,methodDirectory);
        [upd(2)]          = modifyinitMeth(numCESTpulses,methodDirectory);
        [upd(3)]          = modifyBackBone(numCESTpulses,methodDirectory);
        [upd(6)]          = modifyBackBone_timing(methodDirectory); 
        [upd(4)]          = modifyparsRelations(numCESTpulses,methodDirectory,CEST_rf,CEST_rfFA,CESTphasearray,CEST_delays,CEST_offArray,CEST_pwrEquiv,CEST_pulseID,CEST_pwrIntRat);
        [upd(5),BaseParamIndex] = modifyBaseLevelRelations(numCESTpulses,methodDirectory,size(eventTable_full,2));
        [upd(7)]          = modifyXML(numCESTpulses,methodDirectory);
        [upd(8)]          = modifyParsLayout(methodDirectory);
        [upd(9)]          = modifyRelProtos(numCESTpulses,methodDirectory);

        if sum(find(upd==0))
            error(sprintf('error while modifying file number: %.0f!\n',find(upd==0)));
        else
            clear upd numCESTpulses methodDirectory CEST_rf CEST_rfFA CESTphasearray 
            clear CEST_delays CEST_offArray CEST_pwrEquiv CEST_pulseID 
        end
        % write Bruker *.ppg file containing the CEST presaturation 
        if ~WritingCESTpresatToPPG(floc,eventTable_ID,eventTable,eventTable_full,BaseParamIndex,seq,unique_rf)
            error('error writing CEST presaturation to *.ppg file!');
        else
            clear eventTable eventTable_ID BaseParamIndex seq 
        end
        diary off;

    catch ME
        warning('...');
        fprintf(2, '\n===== ERROR =====\n%s\n', getReport(ME, 'extended'));
        diary off;
    end
end 


