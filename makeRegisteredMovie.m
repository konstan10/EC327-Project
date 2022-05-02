function regFrames = makeRegisteredMovie(frames, row, col)

plotting = 0;

xsz = size(frames, 2);
ysz = size(frames, 1);

padx2 = -min(col);
padx1 = max(col);

pady2 = -min(row);
pady1 = max(row);

regFrames = zeros(ysz+pady1+pady2, xsz+padx1+padx2, size(frames, 3));

if plotting
    fig = figure;
    imhand = imagesc(regFrames(:, :, 1));
    colormap(gray);
    axis image; axis off;
end

for i = 1:size(frames, 3)
    xdev = -col(i);
    ydev = -row(i);
    
    regFrames(ydev+1+pady1:ydev+ysz+pady1, xdev+1+padx1:xdev+xsz+padx1, i) = frames(:, :, i);
    
    if plotting
        set(imhand, 'CData', regFrames(:, :, i));
        pause(0.03);
        drawnow;
    end
end

if plotting
    close(fig);
end

regFrames = regFrames(pady1+pady2:ysz, padx1+padx2:xsz, :);






