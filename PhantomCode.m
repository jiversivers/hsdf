%% Code to automatically synchrnoze DAQ for Phantoms %%
%% Connect all hardware
lctf = vsInit("COM3");
cmos = videoinput("hamamatsu", 1, "MONO16_2048x2048_FastMode");
src = getselectedsource(cmos);
probe = probeInit("COM8");

%% Prep for acquisition
% Define output folder
d1 = inputdlg('Name folder to save images');

if ~isfolder(d1{:})
    mkdir(d1{:})
end

% Array of filter wavelengths and respective integration times to iterate
% through (example input paremeters, actual may vary)
clear imgPar
imgPar(1,:) = [400, 450, 500, 550, 600, 650, 680, 700 720]  ;    % nm
imgPar(2,:) = 2.0;           % s

%% DAQ
% Initiate empty cell arrays for data & metadata
img = cell(1,length(imgPar));
imgInfo = cell(1,length(imgPar));
DO = zeros(2, ceil(sum(imgPar(2,:))/10));
next = 1;

data = {};

fig = figure; hold on;

% Clear leftovers and wait for first reading to begin imaging
leftovers = readProbe(probe);
while isempty(data)
    data = readProbe(probe);
end

for cycle = 1:20
    % Iterate through all wavelengths and image at each
    for ii = 1:length(imgPar)
        
        % Tune LCTF
        setWavelength(imgPar(1,ii), lctf);
        
        % Set integration time
        src.ExposureTime = imgPar(2,ii);
    
        % Collect metadata
        expTime = src.ExposureTime;
        filterWavelength = getWavelength(lctf);
        
        % Collect DO readings
        if ~isempty(data)
            DO(1, next) = cell2mat(cellfun(@str2num, data(:,9), 'UniformOutput', false));
            DO(2, next) = filterWavelength;
            next = next + 1;
        end
        
        % Capture frame and metadata
        [img{ii}, imgInfo{ii}] = getsnapshot(cmos);
        imgInfo{ii}.ExpTime = expTime;
        imgInfo{ii}.Filter = filterWavelength;
    
        data = readProbe(probe);
    
        % Plot Oxygenation
        scatter(1:10:10*length(DO), DO(1,:), '.k')
    end

    %%% Save data
    prefix = [d1{:}, '_', 'c', num2str(cycle), '_'];
    cycDir = [d1{:}, filesep, 'cycle', num2str(cycle)];
    mkdir(cycDir)
    
    % Save probe readings
    writematrix(DO, [cycDir, filesep, prefix, '_DO.xlsx'])
    
    % Save images and average intensity
    avgInt = zeros(length(imgPar));
    for ii = 1:length(imgPar)
        filename = [prefix, num2str(imgPar(1,ii)), '.tiff'];
        imwrite(img{ii}, [cycDir, '/', filename])
        avgInt(ii) = mean(img{ii}, 'all');
        save([cycDir, filesep, prefix, '_metadata.mat'], 'imgInfo')
    end
end

%% Clean up
delete(cmos)
clear cmos
