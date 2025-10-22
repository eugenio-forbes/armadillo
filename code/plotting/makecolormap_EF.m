function mapx = makecolormap_EF(type)

%Diverging color maps are meant to be used for highlighting contrasts or
%disributions around a mean. 6000 values for diverging colormaps. To use in
%colorbar for z-scores and t-statistics can set color bar axis to caxis
%([-3 3])
%Single gradient colorbars to highlight maxima. One color to another color (6000 values).

x = linspace(0,3,3000);

switch type
    %%% Diverging color maps: Two different colors at each end that transition from center color
    case 'sigmoid1' %(blue-white-red) Sigmoid transition from white meant to highlight significant standard deviations white-magenta-blue and white-yellow-red
        y1 = 1./(1+exp(-3*(x-1.1)));
        y2 = 1./(1+exp(-3*(x-1.9)));
        part1 = [y1' x'/3 ones(3000,1)];
        part2 = [ones(3000,1) 1-y2' flipud(x'/3)];
        mapx = [part1;part2];
    case 'sigmoid2' %Same as sigmoid one but transtions are white-cyan-blue and white-magenta-red
        y1 = 1./(1+exp(-3*(x-1.1)));
        y2 = 1./(1+exp(-3*(x-1.9)));
        part1 = [x'/3 y1' ones(3000,1)];
        part2 = [ones(3000,1) flipud(x'/3) 1-y2'];
        mapx = [part1;part2];
    case 'sigmoid3' %Chef's selection. Same as sigmoid 1 but transitions are white-cyan-blue and white-yellow-red
        y1 = 1./(1+exp(-3*(x-1.1)));
        y2 = 1./(1+exp(-3*(x-1.9)));
        part1 = [x'/3 y1' ones(3000,1)];
        part2 = [ones(3000,1) 1-y2' flipud(x'/3)];
        mapx = [part1;part2];
    case 'sigmoid_black' %(cyan-black-yellow) Sigmoid transition black-blue-cyan and black-green-yellow
        y1 = 1./(1+exp(-3*(x-1.1)));
        y2 = 1./(1+exp(-3*(x-1.9)));
        part1 = [zeros(3000,1) 1-y1' flipud(x'/3)];
        part2 = [y2' x'/3 zeros(3000,1)];
        mapx = [part1;part2];
    case 'uniform1' %(blue-white-red) Uniform transitions from blue to white and white to red
        part1 = [x'/3  x'/3 ones(3000,1)];
        part2 = [ones(3000,1) flipud(x'/3) flipud(x'/3)];
        mapx = [part1;part2];
    case 'uniform2' %(magenta-white-green)
        part1 = [ones(3000,1) x'/3 ones(3000,1)];
        part2 = [flipud(x'/3) ones(3000,1) flipud(x'/3)];
        mapx = [part1;part2];
    case 'uniform3' %(purple-white-orange)
        part1 = [0.5+(0.5*x'/3) x'/3 ones(3000,1)];
        part2 = [ones(3000,1) 1-(0.5*x'/3) flipud(x'/3)];
        mapx = [part1;part2];
    case 'uniform4' %(red-white-green)
        part1 = [ones(3000,1) x'/3 x'/3];
        part2 = [flipud(x'/3) ones(3000,1) flipud(x'/3)];
        mapx = [part1;part2];
    case 'heat' %(black-white-red) Uniform
        part1 = [x'/3 x'/3 x'/3];
        part2 = [ones(3000,1) flipud(x'/3) flipud(x'/3)];
        mapx = [part1;part2];
    case 'jagged' %(blue-white-red) Transitions from white to red (or blue) with low slope from 0 to 1.9, sharp slope from 1.9 to 2.1 and low slope from 2.1 to 3
        g = [linspace(0,0.25,900)';linspace(0.25,0.472,200)';linspace(0.472,1,1900)'];
        part1 = [x'/3  g ones(3000,1)];
        part2 = [ones(3000,1) flipud(g) flipud(x'/3)];
        mapx = [part1;part2];
    case 'jump' %(blue-white-red) with transitions from white to blue and white to red where the saturation changes abruptly at 1.9
        g = [zeros(1900,1);ones(1100,1)];
        part1 = [x'/3 g ones(3000,1)];
        part2 = [ones(3000,1) flipud(g) flipud(x'/3)];
        mapx = [part1;part2];
    % Single gradient colormaps
    case 'single_gradient1' %(black-red)
        x = linspace(0,1,6000);
        mapx = [x' zeros(6000,1) zeros(6000,1)];
    case 'single_gradient2' %(black-green)
        x = linspace(0,1,6000);
        mapx = [zeros(6000,1) x' zeros(6000,1)];
    case 'single_gradient3' %(black-cyan)
        x = linspace(0,1,6000);
        mapx = [zeros(6000,1) x' x'];
end

end