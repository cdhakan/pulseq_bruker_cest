function [upd] = modifyXML(numCESTpulses,methodDirectory)

% functions creates a CEST card in Bruker's GUI for CEST related parameters
    try
        content = dir(methodDirectory);
        indx=[];

        for nn=1:size(content,1)
            if numel(content(nn).name) >= 4
                if strcmp(content(nn).name(end-3:end),'.xml')
                    indx = [indx,nn];
                end
            end
        end
        if numel(indx) == 1
            [tline] = readFileSimple([methodDirectory,'/',content(indx).name]);
        else
            error('could not find the *.xml file for defining CEST card into GUI');
        end
        indx2 = [];
        for nn=1:size(tline,2)
            temp = strtrim(tline{nn});

            if ~isempty(regexp(temp,'^</(cs:)?cardStack>','once'))
                indx2 = [indx2,nn];
            end
        end
        if numel(indx2) ~= 1
            error('identifier "</cs:cardStack>" not found');
        end

        fid = fopen([methodDirectory,'/',content(indx).name],'w');
        for nn=1:indx2-1
            temp = tline{nn};
            temp = strrep(temp,'%','%%');
            temp = strrep(temp,'\','\\');
            fprintf(fid,[temp,'\n']);
        end
    % insert CEST card:
        fprintf(fid,'\t<parameterCard  displayName="CEST" >\n\t\t<parameterCard displayName="parameters">\n\t\t<column>\n\t\t\t<textLine text="CEST WASABI"/>\n\t\t\t<parameter name="CEST_DelayList" />\n');
        fprintf(fid,'\t\t\t<parameter name="CEST_RFduration" />\n\t\t\t<parameter name="CEST_PhaseList" />\n\t\t\t<parameter name="CEST_TotTime"/>\n\t\t</column>\n\t\t<column>\n');
        fprintf(fid,'\t\t\t<parameter name="CEST_pwrLIST" />\n\t\t\t<parameter name="CEST_freqList"/>\n\t\t\t<parameter name="CEST_pulseID" />\n\t\t\t<parameter name="CEST_pwrEquiv" />\n\t\t</column>\n\t\t</parameterCard>\n\t\t<parameterCard displayName="pulses">\n');
        modNum = 0;
        if mod(numCESTpulses,2) ~= 0
            numCESTpulses = numCESTpulses + 1;
            modNum=1;
        end


        cnt = 1;
    % more tabs on card for CEST pulses:    
        for kk=1:numCESTpulses/2 
            if kk>1
               fprintf(fid,'\t\t<parameterCard displayName="pulses">\n'); 
            end
            fprintf(fid,'\t\t<column>\n\t\t\t<parameter name="CESTpulse%02.0f" />\n\t\t</column>\n',cnt-1);
            cnt = cnt+1;
            if cnt <= numCESTpulses-modNum
                fprintf(fid,'\t\t<column>\n\t\t\t<parameter name="CESTpulse%02.0f" />\n\t\t</column>\n',cnt-1);
                cnt = cnt+1;
            else
                fprintf(fid,'\t\t<column>\n\t\t\t<textLine text="Pulse"/>\n\t\t</column>\n\t\t</parameterCard>\n');
            end
            fprintf(fid,'\t</parameterCard>\n');
        end

        for nn=indx2:size(tline,2)
            temp = tline{nn};
            temp = strrep(temp,'%','%%');
            temp = strrep(temp,'\','\\');
            fprintf(fid,[temp,'\n']);
        end
        fclose(fid);
        upd = 1;
        fprintf('successfully modifed the *.xml file\n');
    catch 
        try
            fclose(fid);
        catch
            fprintf('could not close the *.XML file\n'); 
        end
        upd = 0;
    end
end 