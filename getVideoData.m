function frames = getVideoData(fn, ds)
% fn: the filename of the video to load
% ds: downsample factor.  e.g. ds=0.1 to downsample the movie by 10 in each
% direction

vReader = VideoReader(fn);
firstFrame = readFrame(vReader);

frames = imresize(mean(firstFrame, 3), ds, 'bilinear');
frames = frames - mean(frames(:));
frames(:,:, vReader.NumFrames) = 0;

for i = 2:vReader.NumFrames
    
    vidFrame = readFrame(vReader);
    frames(:, :, i) = imresize(mean(vidFrame, 3), ds, 'bilinear');
    frames(:, :, i) = frames(:, :, i) - mean(mean(frames(:, :, i)));
    
end