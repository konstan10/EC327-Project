function writeRegisteredVideo(outfn, im)

vWriter = VideoWriter(outfn);
open(vWriter);

figure;
imax = imagesc(im(:, :, 1));

for i = 1:size(im, 3)

    set(imax, 'CData', im(:, :, i));
    colormap(gray);
    axis image off;
    title('Registered Image');
    xlabel('X position (pix)');
    ylabel('Y position (pix)');

    drawnow;
    
    movIm = getframe(gcf);
    writeVideo(vWriter,movIm);
end
close(vWriter);
