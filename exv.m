warning('off','all');
warning

clear all
close all
tic

fig = uifigure('Name','Video Stabilizer 1.0');
fig.Color = '#ADD8E6';
btn1 = uibutton(fig,'push','Position',[220, 375, 120, 22],'Text','Choose Video','ButtonPushedFcn', @(btn1,event) fin(btn1)); %fin
btn2 = uibutton(fig,'push','Position',[220, 275, 120, 22],'Text','Choose Output Path','ButtonPushedFcn', @(btn2,event) fileout(btn2)); %fout
btn3 = uibutton(fig,'push','Position',[220, 175, 120, 22],'Text','Stabilize','ButtonPushedFcn', @(btn3,event) convert(btn3)); %convert
sld = uislider(fig,'Position',[220, 100, 120, 22],'Limits',[0 1],'Value',0,'ValueChangingFcn',@(sld,event) sensitivity(event));
lbl1 = uilabel(fig,'Position',[250 100 150 32],'Text','Sensitivity');

global ogD;
global filein;
global pathin;
global pathout;
global sen;
ogD = pwd;

function sensitivity(event)
global sen;
sen = event.Value;
end

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
global sen;
if isempty(filein)
    f = msgbox('Select a video first','Error');
elseif isempty(pathout)
    f = msgbox('Select an output path first','Error'); 
else
f = waitbar(0,'Starting stabilization');
cd(pathin)
newFileName = "stable42";
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
grayFrame2 = grayFrame1;
grayFrame1 = rgb2gray(frame);
for i = 2:numFrames
	frame = readFrame(vid);
	grayFrame2 = rgb2gray(frame);
	transH = cvexEstStabilizationTform(grayFrame1, grayFrame2, sen);
	transHsrt = cvexTformToSRT(transH);
	hCum = transHsrt * hCum;
	newFrame = imwarp(frame, affine2d(hCum), 'OutputView', imref2d(size(grayFrame2)));
	writeVideo(nvid, newFrame);
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

%% Use MSAC algorithm to compute the affine transformation
tform = estimateGeometricTransform2D(pointsB, pointsA, 'affine', 'MaxDistance', 10);
H = tform.T;
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



