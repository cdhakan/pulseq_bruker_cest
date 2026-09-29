function [eventTable_full,eventTable_ID,eventTable,unique_events,unique_rf] = interpretPulseqFile(seq)

    % interpret the .seq file
    blocks      = seq.blockEvents;
    numBlocks   = numel(seq.blockEvents);

    fprintf('wait...\n');


    % unique rf id for mag and phase
    num_rf_events = numel(seq.rfLibrary.keys);
   
    
    % 1: mag; 2: phase; 3: id
    unique_rf     = zeros(2,num_rf_events);

    for k = 1:num_rf_events
        unique_rf(1,k) = seq.rfLibrary.data(k).array(2);
        unique_rf(2,k) = seq.rfLibrary.data(k).array(3);
    end
    unique_rf = unique(unique_rf', 'rows');
    fprintf('\n\t found %.0f pulses!\n',size(unique_rf,1));
    %%%%%%%%%%
    h = waitbar(0,'reading *.seq file...');
    grad_id = 1;
    for iB = 1:length(seq.blockEvents)
        block   = seq.getBlock(iB);
        isGrad  = cellfun(@(x)~isempty(x),{block.gx,block.gy,block.gz});
        if isGrad
            for nGrad = 1:3
                unique_grad(nGrad,grad_id) = seq.blockEvents{iB}(nGrad+2);
            end
            grad_id = grad_id+1;
        end
        waitbar(iB/length(seq.blockEvents));
    end
    close(h);
    unique_grad = unique(unique_grad', 'rows');

    startBlock = 1;
    if isKey(seq.definitions,'run_m0_scan') 
        if seq.definitions('run_m0_scan') == 0
            startBlock = 3;
        end
    end
    
    num_adc         = 0;
    ev_startBlock   = startBlock;
    h = waitbar(0,'processing information...');
    for iB=startBlock:length(seq.blockEvents)
        block = seq.getBlock(iB);
        if ~isempty(block.adc)
            num_adc                 = num_adc+1;
            numSatEvents(num_adc)   = iB-ev_startBlock;
            ev_startBlock           = iB+1;
        end
        waitbar(iB/(length(seq.blockEvents)-startBlock));
    end
    close(h);

    if numel(unique(numSatEvents)) > 1
        warning(sprintf('\n\t different number of pulses for each presaturation offset frequency!\n'));
    end
        
    
    numSatEvents    = max(unique(numSatEvents));
    eventTable      = zeros(numSatEvents,num_adc);
    eventTable_ID   = eventTable*NaN; 
    ev_idx = 0;
    adc_idx = 1;

    if ~exist('magicFactor','var')
        magicFactor = 10^-6;
        %warning(sprintf('\nmagicFactor was not defined! Will use f=10^-6'));
    end
    h = waitbar(0,'grouping information...');
    for iB=startBlock:numBlocks
        block = seq.getBlock(iB);
        ev_idx = ev_idx + 1;

        if isfield(block,'delay') && ~isempty(block.delay)
            eventTable(ev_idx,adc_idx)              = seq.blockEvents{iB}(1);
            eventTable_full{ev_idx,adc_idx}.delay   = block.delay.delay;
            eventTable_ID(ev_idx,adc_idx)           = 0;
        elseif ~isfield(block,'delay') && isempty(block.rf) && isempty(block.gx) ...
               && isempty(block.gy) && isempty(block.gz) && isempty(block.adc)
            eventTable(ev_idx,adc_idx)              = 1;
            if isprop(seq,'blockDurations') && numel(seq.blockDurations)>=iB
                eventTable_full{ev_idx,adc_idx}.delay = seq.blockDurations(iB);
            elseif isfield(block,'blockDuration')
                eventTable_full{ev_idx,adc_idx}.delay = block.blockDuration;
            else
                eventTable_full{ev_idx,adc_idx}.delay = 0;
            end
            eventTable_ID(ev_idx,adc_idx)           = 0;
        end
        if ~isempty(block.rf)
            rf          = block.rf;
            rf_lut      = blocks{iB}(2);
            magId       = seq.rfLibrary.data(rf_lut).array(2);
            phase_id    = seq.rfLibrary.data(rf_lut).array(3);
            rfId        = find(ismember(unique_rf, [magId phase_id], 'rows'));
            eventTable(ev_idx,adc_idx)      = rfId;
            eventTable_full{ev_idx,adc_idx}.offset      = rf.freqOffset;                        % []
            eventTable_full{ev_idx,adc_idx}.phase       = rf.phaseOffset;                       % []
            eventTable_full{ev_idx,adc_idx}.rfDuration  = numel(rf.t)*magicFactor;              % [sec]
            eventTable_full{ev_idx,adc_idx}.rfFAHz      = seq.rfLibrary.data(rfId).array(1);    % [Hz]
            eventTable_full{ev_idx,adc_idx}.ID          = [magId phase_id]; 
            eventTable_ID(ev_idx,adc_idx)   = 1;
        end
        isGrad = cellfun(@(x)~isempty(x),{block.gx,block.gy,block.gz});
        if isGrad
            gx = seq.blockEvents{iB}(3);
            gy = seq.blockEvents{iB}(4);
            gz = seq.blockEvents{iB}(5);
            gradId = find(ismember(unique_grad, [gx gy gz], 'rows'));
            eventTable(ev_idx,adc_idx) = gradId;
            eventTable_full{ev_idx,adc_idx}.gradient = gradId;
            eventTable_ID(ev_idx,adc_idx) = -1;
        end
        %%%%%%%%%
        % put gradients in event table 
        %%%%%%%%%
        if ~isempty(block.adc)
            adc_idx = adc_idx+1;
            ev_idx = 0;
        end
        waitbar(iB/(-startBlock+numBlocks));
    end
    close(h);
    fprintf('.seq file processing completed\n');
    
    unique_events = zeros(numSatEvents,1);
    for nEvt = 1:numSatEvents
        unique_events(nEvt,1) = numel(unique(eventTable(nEvt,:)));
    end
end 