files = dir('*.tiff');

wavelength = [400, 450, 500, 550, 600, 650, 680, 700 720];

lodImg = zeros([2048 2048 height(files)]);
avgInt= zeros(1,length(files));
satPerc = zeros(1,length(files));
drkPerc = zeros(1,length(files));

figure
for ii=1:length(files)
    lodImg(:,:,ii) = double(imread(files(ii).name));
    avgInt(ii) = mean(mean(lodImg(:,:,ii)));
    satPerc(ii) = sum(sum(lodImg(:,:,ii)==65535))/(2048*2048)*100;
    drkPerc(ii) = sum(sum(lodImg(:,:,ii)<0.01*(2^16)))/(2048*2048)*100;
    imshow(lodImg(:,:,ii)/2^16)
    drawnow
end

figure;
set(gcf, "Position", [360 360 560 420])
subplot(1,2,1)
plot(wavelength,avgInt)
title('Average Intensity of image')

subplot(1,2,2)
hold on
plot(wavelength,satPerc)
plot(wavelength,drkPerc)
legend('Percent of Saturated Pixels', 'Percent of Pixels less than 1% bright')
hold off