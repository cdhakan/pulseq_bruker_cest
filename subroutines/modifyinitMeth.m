function [upd] = modifyinitMeth(numCESTpulses,methodDirectory)

% this function will intialize the pulses in initMeth.c
    try
        [tline] = readFileSimple([methodDirectory,'/initMeth.c']);

        indx=[];
        for  nn=1:size(tline,2)
            if contains(tline{nn},'void initMeth()')
                indx=[indx,nn];
            end
        end

        for nn=indx:size(tline,2)
            if strcmp(tline{nn},'{');
                indx=[indx,nn];
            end
        end
        fprintf('creating new initMeth.c \n');
        fid = fopen([methodDirectory,'/initMeth.c'],'w');
        for kk=1:indx(2)
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           fprintf(fid,[temp,'\n']);
        end
        % custom pulses:
        fprintf(fid,'\n/* -----------------------CEST WASABI---------------------------*/\n');
        for nP=1:numCESTpulses
            fprintf(fid,'\tSTB_InitRFPulse("CESTpulse%02.f",    // name of pulse structure\n',nP-1);
            fprintf(fid,'\t\t\t0,\t\t\t// name of pulse list parameter\n');
            fprintf(fid,'\t\t\t0,\t\t\t// name of pulse amplitude parameter\n');
            fprintf(fid,'\t\t\t0,\t\t\t// name of pulse shape (for calc. pulses)\n');
            fprintf(fid,'\t\t\t0,\t\t\t// used for excitation\n');
            fprintf(fid,'\t\t\t"cest_pulse%02.f.exc",\t // default shape \n',nP-1);
            fprintf(fid,'\t\t\t3000.0,\t\t\t// default bandwidth\n');
            fprintf(fid,'\t\t\t30.0);\t\t\t// default pulse angle\n');
        end
        fprintf(fid,'/* -----------------------CEST WASABI---------------------------*/\n\n');
        for kk=indx(2)+1:size(tline,2)
           temp = strrep(tline{kk},'%','%%');
           temp = strrep(temp,'\n','\\n');
           fprintf(fid,[temp,'\n']);
        end
        fclose(fid);
        upd = 1;
    catch % on error:
            upd = 0;
            try
                fclose(fid);
            catch
               fprintf('could not close file .../CEST/initMeth.c\n') ;
            end
    end
    
end %main function