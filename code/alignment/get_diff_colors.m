function diff_colors = get_diff_colors(differential) 

mapx = [hsv(675); zeros(325, 3); ones(2000, 3)];

mean_diff = mean(differential);
std_diff = std(differential);

differential = (differential - mean_diff) / std_diff;
differential = round(abs(differential) * 1000);
differential(differential <= 0) = ones(sum(differential <= 0), 1);
differential(differential > 3000) = ones(sum(differential > 3000), 1) * 3000;

diff_colors = mapx(differential, :);

end