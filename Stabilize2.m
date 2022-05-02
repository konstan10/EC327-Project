clear all
filename = "unstable42.mp4";
newFileName = "stable42.avi";
vid = VideoReader(filename);
numFrames = vid.numFrames;
frameRate = vid.FrameRate;

nvid = VideoWriter(newFileName, 'Uncompressed AVI');
nvid.FrameRate = frameRate;
open(nvid);

hCum = eye(3);
frame = readFrame(vid);
[frameDim(1), frameDim(2), ~, ~] = size(frame);
grayFrame1 = zeros(frameDim(1), frameDim(2));
grayFrame2 = grayFrame1;
grayFrame1 = rgb2gray(frame);
for i = 2:numFrames
	frame = readFrame(vid);
	grayFrame2 = rgb2gray(frame);
	transH = cvexEstStabilizationTform(grayFrame1, grayFrame2, 0.05);
	transHsrt = cvexTformToSRT(transH);
	hCum = transHsrt * hCum;
	newFrame = imwarp(frame, affine2d(hCum), 'OutputView', imref2d(size(grayFrame2)));
	writeVideo(nvid, newFrame);
	grayFrame1 = grayFrame2;
end
close(nvid);