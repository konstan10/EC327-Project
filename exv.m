warning('off','all');
warning

clear all
close all force
tic
%%  GUI Code
fig = uifigure('Name','Video Stabilizer Final');
fig.Color = '#ADD8E6';
btn1 = uibutton(fig,'push','Position',[220, 375, 125, 22],'Text','Choose Video (.mp4)','ButtonPushedFcn', @(btn1,event) fin(btn1)); %fin
btn2 = uibutton(fig,'push','Position',[220, 275, 125, 22],'Text','Choose Output Path','ButtonPushedFcn', @(btn2,event) fileout(btn2)); %fout
btn3 = uibutton(fig,'push','Position',[220, 175, 125, 22],'Text','Stabilize','ButtonPushedFcn', @(btn3,event) convert(btn3)); %convert
sld = uislider(fig,'Position',[220, 100, 125, 22],'Limits',[0 1],'Value',0.5,'ValueChangingFcn',@(sld,event) sensitivity(event));
lbl1 = uilabel(fig,'Position',[250 100 150 32],'Text','Sensitivity');

f = msgbox('Welcome to Video Stabilizer Final. To stabilize a video, first click on the "Choose Video" button, and choose a video. Next, click on the "Choose Output Path" button and choose the path you want the new video to be saved in. Then, adjust the sensitivity slider. Lastly, click "Stabilize".','Instructions');

global ogD;
global filein;
global pathin;
global pathout;
global sen;
ogD = pwd;

function sensitivity(event)
global sen;
sen = 1-event.Value;
end

%select input file
function fin(btn1)
global filein;
global pathin;
[filein,pathin] = uigetfile('*.mp4');
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
global sen;
if isempty(filein)
    f = msgbox('Select a video first','Error');
elseif isempty(pathout)
    f = msgbox('Select an output path first','Error'); 
else
    a = inputdlg("Output File Name (without extension): ");
    newFileName = string(a);
    f = waitbar(0,'Starting stabilization');
    cd(pathin)
    %%  Video Stabilization
    vid = VideoReader(filein);
    numFrames = vid.numFrames;
    frameRate = vid.FrameRate;
    cd(pathout)
    nvid = VideoWriter(newFileName, 'MPEG-4');
    nvid.FrameRate = frameRate;
    open(nvid);
    hCum = eye(3);
    frame = readFrame(vid);
    [frameDim(1), frameDim(2), ~, ~] = size(frame);
    grayFrame1 = zeros(frameDim(1), frameDim(2));
    %   Compute Frame 1
    grayFrame2 = grayFrame1;
    grayFrame1 = rgb2gray(frame);
    %   Compute Subsequent Frames, sequentially
    for i = 2:numFrames
        %   Read new frame:
	    frame = readFrame(vid);
        %   Convert to Grayscale
	    grayFrame2 = rgb2gray(frame);
        %   Extract features and estimate affine transform:
	    transH = cvexEstStabilizationTform(grayFrame1, grayFrame2, sen);
	    transHsrt = cvexTformToSRT(transH);
	    hCum = transHsrt * hCum;
        %   Apply transform to the original color frame:
	    newFrame = imwarp(frame, affine2d(hCum), 'OutputView', imref2d(size(grayFrame2)));
	    %   Write framt to video
        writeVideo(nvid, newFrame);
        %   Set current frame to last frame
	    grayFrame1 = grayFrame2;
        waitbar(i/numFrames,f,'Stabilizing')
    end
    delete(f);
    f = msgbox("Stabilization Complete",'Success');
    close(nvid);
end
cd(ogD);
toc
end

function H = cvexEstStabilizationTform(leftI,rightI,ptThresh)
%Get inter-image transform and aligned point features.
%  H = cvexEstStabilizationTform(leftI,rightI) returns an affine transform
%  between leftI and rightI using the |estimateGeometricTransform|
%  function.
%
%  H = cvexEstStabilizationTform(leftI,rightI,ptThresh) also accepts
%  arguments for the threshold to use for the corner detector.

% Copyright 2010 The MathWorks, Inc.

% Set default parameters
if nargin < 3 || isempty(ptThresh)
    ptThresh = 0.1;
end

%% Generate prospective points
pointsA = detectFASTFeatures(leftI, 'MinContrast', ptThresh);
pointsB = detectFASTFeatures(rightI, 'MinContrast', ptThresh);



%% Select point correspondences
% Extract features for the corners
[featuresA, pointsA] = extractFeatures(leftI, pointsA);
[featuresB, pointsB] = extractFeatures(rightI, pointsB);

% Match features which were computed from the current and the previous
% images
indexPairs = matchFeatures(featuresA, featuresB, 'MaxRatio', 1);
pointsA = pointsA(indexPairs(:, 1), :);
pointsB = pointsB(indexPairs(:, 2), :);
if(pointsA.Count < 3)
    f = msgbox('Not enough points were extracted. Close the progress bar and increase the sensitivity.','Error');
elseif(pointsB.Count < 3)
    f = msgbox('Not enough points were extracted. Close the progress bar and increase the sensitivity.','Error');
else

%% Use MSAC algorithm to compute the affine transformation
tform = estimateGeometricTransform2D(pointsB, pointsA, 'affine', 'MaxDistance', 10);
H = tform.T;
end
end

function [H,s,ang,t,R] = cvexTformToSRT(H)
%Convert a 3-by-3 affine transform to a scale-rotation-translation
%transform.
%  [H,S,ANG,T,R] = cvexTformToSRT(H) returns the scale, rotation, and
%  translation parameters, and the reconstituted transform H.

% Extract rotation and translation submatrices
R = H(1:2,1:2);
t = H(3, 1:2);
% Compute theta from mean of stable arctangents
ang = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
% Compute scale from mean of two stable mean calculations
s = mean(R([1 4])/cos(ang));
% Reconstitute transform
R = [cos(ang) -sin(ang); sin(ang) cos(ang)];
H = [[s*R; t], [0 0 1]'];
end



