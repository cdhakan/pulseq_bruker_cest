function [fname,floc] = locatePPGfile()

    [floc] = uigetdir('select the Bruker readout source code');
    allFiles = dir(floc);
    indx=[];
    for n=1:size(allFiles,1)
        if contains(allFiles(n,1).name,'.ppg')
            indx=[indx,n];
        end
    end
    if numel(indx)>1
        for kk=1:numel(indx)
            list{kk}=allFiles(indx(kk),1).name;
        end
        [ID,~] = listdlg('ListString',list,'SelectionMode','single','PromptString','select readout...');
        fileName = allFiles(indx(ID),1).name;
    elseif numel(indx)==1
        fileName = allFiles(indx,1).name;
    elseif numel(indx)==0
        fprintf('something went wrong ... \n');
        error(['no *.ppg file could be found in the specified directory... ',floc])
    end
    fname = [floc,'/',fileName];
end