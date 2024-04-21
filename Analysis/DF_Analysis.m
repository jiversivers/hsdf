% Darkfield Image Analysis
img = imread('Target LCTF 550.tif');

bg = imread('BG LCTF 550.tif');

NewImg = img-bg;

imagesc(NewImg); colormap gray;

%% Import image
img = img/max(img,[], 'all');

% Correct "haze"
imgStretch = hist_stretch(img,90,1);
L = graythresh(imgStretch);
imgThresh = (imgStretch>L);

figure; imagesc(imgStretch); colormap gray;
figure; imagesc(imgThresh); colormap gray;
figure; imagesc(imgStretch.*(imgStretch>L)); colormap gray