clear all
close all
tic
vid = VideoReader("unstable2.mp4");
vidFrames = read(vid);
dim = size(vidFrames);
nvid = VideoWriter("New Video.avi", 'Uncompressed AVI');
nvid.FrameRate = 60;
open(nvid);
for i = 1:dim(4)
	frame = rgb2gray(vidFrames(:, :, :, i));
	frame = single(edge(frame, 'sobel'));
	writeVideo(nvid, frame);
end
close(nvid);
toc