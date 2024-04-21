%% Initial Setup

clear all; close all

% Connect to LCTF
lctf = vsInit("COM3");

% Connect to CMOS
cmos = videoinput("hamamatsu", 1, "MONO16_2048x2048_FastMode");
src = getselectedsource(cmos);

%% Prep for acquisition
% Define output folder
d1 = inputdlg('Name folder to save images');

if ~isfolder(d1{:})
    mkdir(d1{:})
end

% Array of filter wavelengths and respective integration times to iterate
% through (example input paremeters, actual may vary)
imgPar(1,:) = [400:10:720];    % nm
imgPar(2,:) = 2.0;             % s


%% Preview and setting selection

%% GUI
% Initial Figure




% Delete for actual operation (these are test lines when unconnected)
% vidRes = [2048 2048];
% nBands = 2^16;

% Commented out for testing without cmos connection. Delete above line and
% uncomment for actual operation
vidRes = cmos.VideoResolution;
nBands = cmos.NumberOfBands;

hImage = image( zeros(vidRes(2), vidRes(1), nBands));

% Start preview
start(cmos)
preview(cmos, hImage)
uiwait(gcf)
disp('Capturing images...')

%% Image acquistion
%  Initiate empty cell arrays for data & metadata
img = cell(1,length(imgPar));
imgInfo = cell(1,length(imgPar));

% Iterate through all wavelengths and image at each
for i = 1:length(imgPar)
    
    % Tune LCTF
    setWavelength(imgPar(1,i), lctf);
    
    % Set integration time
    src.ExposureTime = imgPar(2,i);

    % Collect metadata
    expTime = src.ExposureTime;
    filterWavelength = getWavelength(lctf);
    
    % Capture frame and metadata
    [img{i}, imgInfo{i}] = getsnapshot(cmos);
    imgInfo{i}.ExpTime = expTime;
    imgInfo{i}.Filter = filterWavelength;
end

%% Save data
% Save images
for i = 1:length(imgPar)
    filename = [d1{:}, '_', num2str(imgPar(1,i)), '.tif'];
    imwrite(img{i}, [d1{:}, '/', filename])
    save([d1{:}, '/MetaData'],'imgInfo')
end

%% Clean up
delete(cmos)
clear cmos

