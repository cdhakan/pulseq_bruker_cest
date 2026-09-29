function [CEST_offArray,CEST_delays,CESTphasearray,CEST_rf,CEST_rfFA,CEST_pulseID] = CreateArraysForCEST(fname,floc,eventTable_ID,eventTable_full,unique_rf)
  
    fid = fopen(fname,'r');
    nn = 1;
    define_lines=[];
    while ~feof(fid)
        tline{nn}=fgetl(fid);
        if nn>1 && contains(tline{nn-1},'#include <MRI.include>') 
            define_lines = [define_lines,nn]; 
        end
        nn = nn+1;
    end
    fclose(fid);clear fid;

    CEST_offArray   = [];
    CEST_delays     = [];
    CESTphasearray  = [];
    CEST_rf         = []; 
    CEST_rfFA       = [];
    CEST_pulseID    = [];
    indx            = [];
    for nOffset=1:size(eventTable_full,2)
        for nPulse=1:size(eventTable_full,1)
            if eventTable_ID(nPulse,nOffset) > 0  %RF event 
                CEST_offArray   = [CEST_offArray,eventTable_full{nPulse,nOffset}.offset];
                CESTphasearray  = [CESTphasearray,eventTable_full{nPulse,nOffset}.phase];
                CEST_rf         = [CEST_rf,eventTable_full{nPulse,nOffset}.rfDuration];
                CEST_rfFA       = [CEST_rfFA,eventTable_full{nPulse,nOffset}.rfFAHz];

                for nn=1:size(unique_rf,1)
                    if sum(eventTable_full{nPulse,nOffset}.ID-unique_rf(nn,:)) == 0
                        indx = nn;
                    end
                end
                CEST_pulseID    = [CEST_pulseID,indx];
            elseif eventTable_ID(nPulse,nOffset) == 0 % delay
                CEST_delays     = [CEST_delays,eventTable_full{nPulse,nOffset}.delay];
            end
        end
    end

    % B1 in [uT]
    CEST_rfFA = CEST_rfFA / 42.5764; 
    

    lastLine=0;
    while lastLine < size(tline,2)
        if ~isempty(tline{1,end-lastLine}) && ~isnumeric(tline{1,end-lastLine})
            break;
        elseif isnumeric(tline{1,end-lastLine})
            warning(['could not read line ',num2str(size(tline,2)-lastLine),' check *.ppg ']);
        end
        lastLine = lastLine + 1;
    end

    
    fprintf('=======\n');
    fprintf('modified method files written into:\n\t%s\n\t(cest_wasabi.mod / cest_pulse00.exc / *.seq -> %s/mod)\n', floc, floc);
    fprintf('=======\n');
    if ~isdir([floc,'/mod']);mkdir([floc,'/mod']);end

    strt=strfind(fname,'/');
    fid = fopen([floc,'/cbd_',fname(strt(end)+1:end)],'w');clear strt;

    insertedCESTpulseq = 0;

    for nLine=1:size(tline,2)-lastLine
        skipThisLine=0;
        if nLine == define_lines(end)
            here = cd;cd(floc);
           if ~isdir('mod')
               mkdir mod;
           end; cd(here);
           % CEST/WASABI presaturation is in cest_wasabi.mod
           fprintf(fid,'#include <cest_wasabi.mod>\n\n');
        end

        % modify *.ppg of readout such that NR-loop includes CEST presaturation:
        if ~isempty(tline{1,nLine}) &&  ~isnumeric(tline{1,nLine}) 
           temp_line = strtrim(tline{1,nLine});
           if ischar(tline{1,nLine}) && contains(tline{1,nLine},'start,','IgnoreCase',true)...
                                        && ~insertedCESTpulseq && strcmp(temp_line(1:6),'start,')                             
                fprintf(fid,'subr cest_wasabiInit()\nstartCEST,\nsubr cest_wasabi()\n');
                insertedCESTpulseq = 1;
                %warning('no match found for "startNR", using label "start, 10u" ');
                %warning(sprintf(['\n\t\tmodified the NR loop ;\n\t\tin file:\n\t\t',strrep(fname,'\','\\'),'\n\t\tcheck line %03.f '],nLine));
           elseif ischar(tline{1,nLine}) && contains(tline{1,nLine},'lo to start times NR','IgnoreCase',true) && insertedCESTpulseq
                skipThisLine=1;
                fprintf(fid,'subr cest_wasabiInc()\nlo to startCEST times NR\n');
                %warning(sprintf(['\n\t\tmodified the NR loop;\n\t\tin file:\n\t\t',strrep(fname,'\','\\'),'\n\t\tcheck line %03.f '],nLine));
           end
        end
        if ~isnumeric(tline{1,nLine})
           if ~skipThisLine
                fprintf(fid,[tline{1,nLine} ,'\n']);
           end
        elseif isnumeric(tline{1,nLine})
           warning(['could not read line ',num2str(nLine),' check *.ppg carefully!']);
        end

        if ~isempty(tline{1,nLine}) &&  ~isnumeric(tline{1,nLine}) 
           if ischar(tline{1,nLine}) && contains(tline{1,nLine},'All Rights Reserved','IgnoreCase',true)
               fprintf(fid,'\n;-*-*-*-*-*-*-*-*-*-*-*-*-*-\n; !!! CEST WASABI !!!');
           end
        end
    end
    fclose(fid);
end 