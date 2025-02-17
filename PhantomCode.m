%% Code to automatically synchrnoze DAQ for Phantoms %%
%% Connect all hardware
lctf = vsInit("COM10");
cmos = videoinput("hamamatsu", 1, "MONO16_2048x2048_UltraQuiet");
src = getselectedsource(cmos);
probe = probeInit("COM11");

%% Prep for acquisition
% Define output folder
d1 = inputdlg('Name folder to save images');

if ~isfolder(d1{:})
    mkdir(d1{:})
end

%% Set up image parameters
% Array of filter wavelengths and respective integration times to iterate
% through (example input paremeters, actual may vary)
clear imgPar
imgPar(1,:) = 400:10:720;    % nm
imgPar(2,:) = [repmat(1, 1, length(400:10:720))];           % s

% Number of batches to image
cycles = 10;

%% Live view
% Create figure
fig = figure('Name', 'Current View'); 
uicontrol('String', 'Close', 'Callback', 'close(gcf)');  

vidRes = cmos.VideoResolution; 
nBands = cmos.NumberOfBands; 

% Create a layout with two subplots: one for the image, one for the histogram
hAx1 = subplot(1, 2, 1);
hImage = imshow(zeros(vidRes(2), vidRes(1), nBands)); 
axis image; title('Live Preview');

hAx2 = subplot(1, 2, 2);
hHist = bar(zeros(256,1)); % Initialize empty histogram
xlim([0, 255]); ylim([0, 1000]); % Adjust based on expected pixel range
title('Intensity Histogram');

preview(cmos, hImage);
setappdata(hImage, 'UpdatePreviewWindowFcn', @(obj, event, himg) updateDisplay(event, hImage, hHist));

% Add text label
uicontrol('Style', 'text', 'String', 'Exposure Time (s):', ...
    'Position', [20, 50, 120, 20]);

% Add editable text box for exposure time
hExposureBox = uicontrol('Style', 'edit', 'String', num2str(src.ExposureTime), ...
    'Position', [150, 50, 80, 25], ...
    'Callback', @(input, ~) updateExposureTime(input, src));

% Add text label
uicontrol('Style', 'text', 'String', 'Wavelength (nm):', ...
    'Position', [20, 75, 120, 20]);

% Add editable text box for exposure time
hWavelengtheBox = uicontrol('Style', 'edit', 'String', num2str(getWavelength(lctf)), ...
    'Position', [150, 75, 80, 25], ...
    'Callback', @(input, ~) updateWavelength(input, lctf));


% Set up a timer to update the display
updateTimer = timer(...
    'ExecutionMode', 'fixedSpacing', ...
    'Period', 0.5, ... % Update every 0.5 seconds
    'TimerFcn', @(~,~) updateDisplay(cmos, hImage, hHist), ...
    'StartDelay', 0);

start(updateTimer);

% Ensure figure cleanup when closed
fig.CloseRequestFcn = @(~,~) closeGUI(cmos);


%% Check view
figure;
r = floor(sqrt(length(imgPar)));
c = ceil(length(imgPar) / r);
for ii = 1:length(imgPar)
    % Tune LCTF
        setWavelength(imgPar(1,ii), lctf);
        
        % Set integration time
        src.ExposureTime = imgPar(2,ii);
        
        % Capture frame and metadata
        img = getsnapshot(cmos);

        % Plot histogram of img
        ax = subplot(r, c, ii);
        histogram(img, 256);
        title(['Avg: ' num2str(mean(img, 'all')) ' - ' num2str(imgPar(1, ii)) 'nm - ' num2str(imgPar(2, ii)) 's']);
        xlabel('Pixel Intensity');
        ylabel('Frequency');

end
%% Non-probe DAQ (for img refs or two-system setup)
% Initiate empty cell arrays for data & metadata
img = cell(1,length(imgPar));
imgInfo = struct('AbsTime', [], 'ExpTime', [], 'Filter', [], 'AvgInt', [], 'Wavelength', []);

start_idx = length(dir([d1{:} filesep 'cycle*'])) + 1;
end_idx = cycles + start_idx - 1;
for cycle = start_idx:end_idx
    % Iterate through all wavelengths and image at each
    prefix = [d1{:}, '_', 'c', num2str(cycle), '_'];
    cycDir = [d1{:}, filesep, 'cycle', num2str(cycle)];
    mkdir(cycDir)
    for ii = 1:length(imgPar)
        
        % Tune LCTF
        setWavelength(imgPar(1,ii), lctf);
        
        % Set integration time
        src.ExposureTime = imgPar(2,ii);
    
        % Collect metadata
        expTime = src.ExposureTime;
        filterWavelength = getWavelength(lctf);
        
        % Capture frame and metadata
        [img, metadata] = getsnapshot(cmos);

        % Save metadata into a structured format
        imgInfo(ii).AbsTime = metadata.AbsTime;
        imgInfo(ii).ExpTime = expTime;
        imgInfo(ii).Filter = filterWavelength;
        imgInfo(ii).Wavelength = imgPar(1, ii);
        imgInfo(ii).AvgInt = mean(img, 'all');

        filename = [prefix, num2str(imgPar(1,ii)), '.tiff'];
        imwrite(img, [cycDir, '/', filename])
    end


    % Save imgInfo to a JSON file
    jsonFile = fullfile(cycDir, [prefix, '_metadata.json']);
    jsonStr = jsonencode(imgInfo); % Convert the structure to a JSON string
    fid = fopen(jsonFile, 'w'); % Open file for writing
    fwrite(fid, jsonStr, 'char'); % Write JSON string to file
    fclose(fid); % Close the file
end
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

for cycle = start_idx:end_idx
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
            new = cell2mat(cellfun(@str2num, data(:,9), 'UniformOutput', false));
            DO(1, next:next+length(new) - 1) = new';
            DO(2, next:end) = filterWavelength;
            next = next + 1;
        end
        
        % Capture frame and metadata
        [img{ii}, imgInfo{ii}] = getsnapshot(cmos);
        imgInfo{ii}.ExpTime = expTime;
        imgInfo{ii}.Filter = filterWavelength;
    
        data = readProbe(probe);
    
%       Plot Oxygenation
        scatter(1:10:10*length(DO), DO(1,:), '.k')
    end

    % Save data
    prefix = [d1{:}, '_', 'c', num2str(cycle), '_'];
    cycDir = [d1{:}, filesep, 'cycle', num2str(cycle)];
    mkdir(cycDir)
    
    % Save probe readings
    writematrix(DO, [cycDir, filesep, prefix, '_DO.xlsx'])
    
    % Save images and average intensity
    for ii = 1:length(imgPar)
        filename = [prefix, num2str(imgPar(1,ii)), '.tiff'];
        imwrite(img{ii}, [cycDir, '/', filename])
        imgInfo{ii}.AvgInt = mean(img{ii}, 'all');
        save([cycDir, filesep, prefix, '_metadata.mat'], 'imgInfo')
    end
end

%% Clean up
delete(cmos)
clear cmos


% Update display function for continuous preview
function updateDisplay(event, hImage, hHist)
    % Extract frame directly from event's data
    frame = event.Data; % Get the frame directly from preview event
    
    if isempty(frame)
        return; % Avoid errors if no frame is available
    end
    
    if size(frame, 3) == 1 % Grayscale image
        minVal = double(min(frame(:)));  
        maxVal = double(max(frame(:)));  
        frame = mat2gray(double(frame), [minVal, maxVal]); % Normalize contrast
        set(hImage, 'CData', frame * 255); % Scale for display
        counts = imhist(uint8(frame * 255)); % Compute histogram
        set(hHist, 'YData', counts); % Update histogram
    else % Color image
        set(hImage, 'CData', frame); % Direct update for color images
    end
end


function closeGUI(cmos)
    stoppreview(cmos); % Stop the preview safely
    delete(gcf); % Close the figure
end

function updateExposureTime(src, cmos)
    newExposure = str2double(get(src, 'String')); % Get user input
    if isnan(newExposure) || newExposure <= 0
        warning('Invalid exposure time. Please enter a positive number.');
        set(src, 'String', num2str(cmos.ExposureTime)); % Reset to current value
    else
        cmos.ExposureTime = newExposure; % Update camera setting
    end
end

function updateWavelength(src, lctf)
    newWavelength = str2double(get(src, 'String')); % Get user input
    if isnan(newWavelength) || newWavelength < 400 || newWavelength > 720
        warning('Invalid wavelength. Please enter a number from 400 to 720.');
         setWavelength(getWavelength(lctf), lctf); % Reset to current value
    else
        setWavelength(newWavelength, lctf); % Update lctf setting
    end
end