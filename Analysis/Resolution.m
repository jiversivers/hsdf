% Resolution Test

close all; clearvars

% Import image, double, and normalize
imfile = 'Image193';
img = imread([imfile, '.tif']);
img = double(img);
img = img/max(img,[], 'all');
%%
% Correct "haze"
imgB = hist_stretch(img, 90, 1, 8);
L = graythresh(imgB);
imgB = imgB.*(imgB>L);

% Display for line selection
f1 = figure;
imagesc(imgB)
axis([0, size(img,1), 0, size(img,2)])
colormap gray

% Zoom to draw
[zoomX, zoomY] = ginput(1);
zoomX = round(zoomX);
zoomY = round(zoomY);
disp('Click to zoom for resolution line draw')

% Choose resolution test line
good = 'No';
while strcmp(good,'No')
    
    hold off
    imagesc(imgB(zoomY-250:zoomY+250, zoomX-250:zoomX+250));
    hold on
    
    [X, Y] = ginput(1);
    realX = round(X)-250+zoomX;
    realY = round(Y)-250+zoomY;
    %m = diff(Y)/diff(X);
    %b = Y(1) - m*X(1);

    x = round([1:2048]);
    y = ones(1,length(x))*round(Y);

    plot(x,y, 'r')

    good = questdlg('Does the line fall on the element you would like to test?', ...
              'Yes', 'No');
end

%% Plotting Results to test if resolved

if strcmp(good, 'Cancel')
  warning('Resolution test cancelled')
else
%% Get Data from Images
    intensityValuesA = img(round(Y-250+zoomY),:);
    intensityValuesB = imgB(round(Y-250+zoomY),:);
    xZoomed = realX-250:250+realX;
    intensityValuesC = intensityValuesA(realX-250:realX+250);
    intensityValuesD = intensityValuesB(realX-250:realX+250);
    
    
%% Make nice figures    
    hold off
    f1.Position = [320,1024,1024,1024];
    subplot(2,2,1); hold on; colormap gray;
    set(gca,'Visible', 'off');
    sgtitle('Resolution Test Results', 'FontSize', 24)
    
    imagesc(img); 
    plot(x,y-250+zoomY, 'r');
    title('Original image and Test Line (Red)', 'FontSize', 18)
    axis square
    
    subplot(2,2,2);hold on; colormap gray;
    set(gca,'Visible', 'off');
    imagesc(imgB);
    plot(x,y-250+zoomY, 'r');
    title('Contrast enhanced image', 'FontSize', 18)
    axis square
    
    subplot(2,2,3); 
    plot(x,intensityValuesA)
    xlim([0, size(img,2)])
    title('Intensity along test line (red)', 'FontSize', 18)
    set(gca, 'FontSize', 16)
    axis square
    
    subplot(2,2,4); 
    plot(x,intensityValuesB/255)
    xlim([0, size(img,2)])
    title('Intensity along test line (red)', 'FontSize', 18)
    set(gca, 'FontSize', 16)
    axis square
    
    filename = [imfile, '_subplots.tif'];
    saveas(f1,filename, 'tif')

    % Zoomed Version

    f2 = figure(2);
    f2.Position = [1599        1082        1081         1004];
    subplot(2,2,1); hold on; colormap gray;
    set(gca,'Visible', 'off'); axis([0, 500, 0, 500]);
    sgtitle('Resolution Test Results', 'FontSize', 24)

    imagesc(img(zoomY-250:zoomY+250, xZoomed)); 
    plot(x,y, 'r', 'LineWidth', 2);
    title('Original image and Test Line (Red)', 18)

    subplot(2,2,2);hold on; colormap gray;
    set(gca,'Visible', 'off'); axis([0, 500, 0, 500]);
    imagesc(imgB(zoomY-250:zoomY+250, xZoomed));
    plot(x,y, 'r', 'LineWidth',2);
    title('Contrast enhanced image')

    subplot(2,2,3); 
    plot(1:length(intensityValuesC),intensityValuesC)
    xlim([0, 500]); ylim([0, 1])
    set(gca, 'FontSize', 14)
    title('Intensity along test line (red)', 'FontSize', 18)

    intensityValuesD = imgB(round(Y-250+zoomY),zoomX-250:zoomX+250); 
    subplot(2,2,4); 
    plot(1:length(intensityValuesD),intensityValuesD/255)
    xlim([0, 500]); ylim([0, 1])
    set(gca, 'FontSize', 14)
    title('Intensity along test line (red)',  'FontSize', 18)

    filename = [imfile, '_zoomedSubplots.tif'];
    saveas(f2,filename, 'tif')
    
end
