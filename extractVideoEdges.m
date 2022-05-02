function frames = extractVideoEdges(fileName, downScaleFactor)
vid = VideoReader(fileName);
vidFrames = read(vid);
dim = size(vidFrames);
frames = zeros(downScaleFactor * dim(1), downScaleFactor * dim(2), dim(4));
for i = 1:dim(4)
	frame = imresize(vidFrames(:, :, :, i), downScaleFactor, 'bicubic');
	frame = rgb2gray(frame);
	frame = edge(frame, 'sobel');
	frame = single(frame);
	frames(:, :, i) = gather(frame);
end
end