
function [statusID,CEST_pwrEquiv,EvntTableToExcFile,CEST_pwrIntRat] = writePulseShapeToFile(seq,unique_rf,floc)
% Write RF pulse files
    fprintf('Writing pulse file...\n');
    
    EvntTableToExcFile = ones(size(unique_rf,1),1);
    statusID = 0;

    fprintf('writing pulse shape file...\n');

    keys                = seq.rfLibrary.keys;
    
    for nn=1:size(unique_rf,1)
        for kk=1:numel(keys)
            temp =seq.rfLibrary.data(keys(kk)).array(2:3);
            if sum(temp-unique_rf(nn,:))==0
                indx(nn) = keys(kk); 
            end
        end
    end
    
    keys = keys(indx);
    

    CEST_pwrEquiv = zeros(1,size(unique_rf,1));
    
    for iPulse=1:size(unique_rf,1)       
        
        data        = seq.rfLibrary.data(keys(iPulse)).array;
%         amp         = data(1);
        magShape    = data(2);
        phaseShape  = data(3);

        shapeData               = seq.shapeLibrary.data(magShape).array;
        compressed.num_samples  = shapeData(1);
        compressed.data         = shapeData(2:end);
        mag                     = mr.decompressShape(compressed)*100;   % pecentage of max


        shapeData               = seq.shapeLibrary.data(phaseShape).array;
        compressed.num_samples  = shapeData(1);
        compressed.data         = shapeData(2:end);
        phase                   = mr.decompressShape(compressed)*360; % 0-360 degrees

        if numel(mag)>256
            dwnsmplrt   = 256;
            origSize    = numel(mag);
            L1    = linspace(0,1,numel(mag));
            L2    = linspace(0,1,256);
            mag   = interp1(L1,mag,L2,'linear');
            phase = interp1(L1,phase,L2,'linear');
        end


        integralRatio           = sum(mag)/100/length(mag);

        CEST_pwrEquiv(iPulse)   = sum((mag/100).^2)/length(mag);
        CEST_pwrIntRat(iPulse)  = integralRatio;
        
        filename                = sprintf('cest_pulse%02.f.exc',iPulse-1);
        fid                     = fopen([floc,'/mod/',filename],'w');
        % header of pulse shape file 
        % ---- header in Bruker JCAMP-DX format ----
        shapeName = filename(1:end-4);   
        fprintf(fid,'##TITLE= %s\n',shapeName);   
        fprintf(fid,'##JCAMP-DX= 5.00 BRUKER JCAMP library\n');  % version 5.00
        fprintf(fid,'##DATA TYPE= Shape Data\n');
        fprintf(fid,'##ORIGIN= MATLAB\n');
        fprintf(fid,'##OWNER= <CBD>\n');
        dv = datevec(now);   % Bruker JCAMP: DATE as YY/MM/DD , TIME as HH:MM:SS
        fprintf(fid,'##DATE= %02d/%02d/%02d\n', mod(dv(1),100), dv(2), dv(3));
        fprintf(fid,'##TIME= %02d:%02d:%02d\n', dv(4), dv(5), round(dv(6)));
        fprintf(fid,'##MINX= %.6e\n',min(mag));
        fprintf(fid,'##MAXX= %.6e\n',max(mag));
        fprintf(fid,'##MINY= %.6e\n',min(phase));
        fprintf(fid,'##MAXY= %.6e\n',max(phase));
        fprintf(fid,'##$SHAPE_EXMODE= Excitation\n');
        fprintf(fid,'##$SHAPE_TOTROT= 9.000000e+01\n');
        fprintf(fid,'##$SHAPE_BWFAC= 2.025000e+01\n');
        fprintf(fid,'##$SHAPE_INTEGFAC= %.6e\n',integralRatio);
        fprintf(fid,'##$SHAPE_REPHFAC= 50\n');
        fprintf(fid,'##$SHAPE_TYPE= conventional\n');
        fprintf(fid,'##$SHAPE_MODE= 0\n');
        fprintf(fid,'##NPOINTS= %d\n',length(mag));
        fprintf(fid,'##XYPOINTS= (XY..XY)\n');
        % mag and phase (this defines the shape):
        if size(mag,1) < size(mag,2)
            mag     = mag';
            phase   = phase';
        end
        dataVec = cat(2,mag,phase)';
        fprintf(fid,'%.6e, %.6e\n',dataVec);
        fprintf(fid,'##END=\n\n');
        
        if ~ishandle(14)
            figure(14);
        end
        subplot(2,size(unique_rf,1),iPulse);                    plot(dataVec(1,:));title({'magnitude of pulse: ',strrep(filename,'_','\_')});
        subplot(2,size(unique_rf,1),iPulse+size(unique_rf,1));  plot(dataVec(2,:));title({'phase of pulse: ',strrep(filename,'_','\_')});

        fclose(fid);
        statusID = 1;
    end

end 