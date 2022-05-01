clear all
close all
tic

fig = uifigure('Name','Video Stabilizer 1.0');
fig.Color = '#ADD8E6';
btn1 = uibutton(fig,'push','Position',[100, 100, 100, 22],'Text','Choose Video','ButtonPushedFcn', @(btn1,event) fin(btn1)); %fin
btn2 = uibutton(fig,'push','Position',[100, 200, 120, 22],'Text','Choose Output Path','ButtonPushedFcn', @(btn2,event) fileout(btn2)); %fout
btn3 = uibutton(fig,'push','Position',[100, 300, 100, 22],'Text','Stabilize','ButtonPushedFcn', @(btn3,event) convert(btn3)); %convert

global ogD;
global filein;
global pathin;
global pathout;

ogD = pwd;

%select input file
function fin(btn1)
global filein;
global pathin;
[filein,pathin] = uigetfile('*.mp4');
if isequal(filein,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(pathin,filein)]);
end
end

%select output folder
function [pathout] = fileout(btn2) 
global pathout;
pathout = uigetdir;
end


%convert
function convert(btn3) 
global filein;
global pathin;
global pathout;
global ogD;
if isempty(filein)
    f = msgbox('Select a video first','Error');
elseif isempty(pathout)
    f = msgbox('Select an output path first','Error'); 
else
cd(pathin)
ds = 0.15;
frames = getVideoData(filein, ds);
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
cd(pathout)
VidObj = VideoWriter(filein, 'Uncompressed AVI'); %set your file name and video compression
VidObj.FrameRate = 30; %set your frame rate
open(VidObj);
for f = 1:size(movie, 3)  %T is your "100x150x75" matrix
    writeVideo(VidObj,mat2gray(movie(:,:,f)));
end
close(VidObj);
end
cd(ogD);
toc
end

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
end

function regFrames = makeRegisteredMovie(frames, row, col)

xsz = size(frames, 2);
ysz = size(frames, 1);

padx2 = -min(col);
padx1 = max(col);

pady2 = -min(row);
pady1 = max(row);

regFrames = zeros(ysz+pady1+pady2, xsz+padx1+padx2, size(frames, 3));

for i = 1:size(frames, 3)
    xdev = -col(i);
    ydev = -row(i);
    
    regFrames(ydev+1+pady1:ydev+ysz+pady1, xdev+1+padx1:xdev+xsz+padx1, i) = frames(:, :, i);   
end

regFrames = regFrames(pady1+pady2:ysz, padx1+padx2:xsz, :);
end
