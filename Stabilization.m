clear all
close all
tic
ds = 0.1;
fn = 'unstable2.mp4';
frames = extractVideoEdges(fn, ds);
refFrame = frames(:,:,1);
xdisp = zeros(1,size(frames,3));
ydisp = zeros(1,size(frames,3));
for i = 2:size(frames,3)
    xc = xcorr2(refFrame,frames(:,:,i));
    OneD_XC = xc(:);
    [~, maxix] = max(OneD_XC);
    [MaxRow, MaxCol] = ind2sub(size(xc), maxix);
    xdisp(i) = MaxRow - 108;
    ydisp(i) = MaxCol - 192;
end
movie = makeRegisteredMovie(frames, -xdisp, -ydisp);

VidObj = VideoWriter('stable2', 'Uncompressed AVI'); %set your file name and video compression
VidObj.FrameRate = 60; %set your frame rate
open(VidObj);
for f = 1:size(movie, 3)  %T is your "100x150x75" matrix
    writeVideo(VidObj,mat2gray(movie(:,:,f)));
end
close(VidObj);
toc