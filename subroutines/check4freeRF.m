function [freeParams] = check4freeRF(tline,VersInfo)

    cnt = 1;
    for nn=1:size(tline,2)
        if contains(tline{nn},'"ACQ_RfShapes[') 
            blockedParams{1,cnt}=tline{nn};
            cnt = cnt +1 ;
        end
    end
    for kk=1:size(blockedParams,2)
       strt = strfind(blockedParams{1,kk},'ACQ_RfShapes');
       stp  = strfind(blockedParams{1,kk},'[');
       strt = min(stp(stp>strt));
       stp  = strfind(blockedParams{1,kk},']');
       stp  = min(stp(stp>strt));
       blcked(kk) = str2num(blockedParams{1,kk}(strt+1:stp-1)); 
    end
    % remove read out pulses 
    if strcmp(VersInfo,'PV6')
        freeParams=0:63;
        freeParams(blcked+1)=[];
        fprintf('Found %02.f/%2.f RF shapes - assigned to baselevel params\n',numel(blcked),64);
    else
        freeParams=0:15;
        freeParams(blcked+1)=[];
        %warning(sprintf('\n\tno version detected'));
    end
end