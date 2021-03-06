function res = eval_voc(cls, boxes, image_ids, VOCopts)
%
% This file comes from the R-CNN code: 
% https://github.com/rbgirshick/rcnn
% 
% ---------------------------------------------------------
% Copyright (c) 2014, Ross Girshick
% 
% This file is part of the R-CNN code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

% Add a random string ("salt") to the end of the results file name
% to prevent concurrent evaluations from clobbering each other
use_res_salt = true;
% Delete results files after computing APs
rm_res = true;
% comp4 because we use outside data (ILSVRC2012)
comp_id = 'comp4';
% draw each class curve
draw_curve = true;

% save results
test_set  = VOCopts.testset;
year      = VOCopts.dataset(4:end);

addpath(fullfile(VOCopts.datadir, 'VOCcode')); 

if use_res_salt
  prev_rng = rng;
  rng shuffle;
  salt = sprintf('%d', randi(100000));
  res_id = [comp_id '-' salt];
  rng(prev_rng);
else
  res_id = comp_id;
end
res_fn = sprintf(VOCopts.detrespath, res_id, cls);

% write out detections in PASCAL format and score
fid = fopen(res_fn, 'w');
for i = 1:length(image_ids);
  bbox = boxes{i};
    for j = 1:size(bbox,1)
        fprintf(fid, '%s %f %.3f %.3f %.3f %.3f\n', image_ids{i}, bbox(j,end), bbox(j,1:4));
    end
end
fclose(fid);

recall = [];
prec = [];
ap = 0;
ap_auc = 0;

do_eval = (str2num(year) <= 2007) | ~strcmp(test_set, 'test');
if do_eval
  % Bug in VOCevaldet requires that tic has been called first
  tic;
  [recall, prec, ap] = VOCevaldet(VOCopts, res_id, cls, draw_curve);
  ap_auc = xVOCap(recall, prec);

  % force plot limits
  ylim([0 1]);
  xlim([0 1]);
end
fprintf('!!! %s : %.4f %.4f\n', cls, ap, ap_auc);

res.recall = recall;
res.prec = prec;
res.ap = ap;
res.ap_auc = ap_auc;
if rm_res
  delete(res_fn);
end

rmpath(fullfile(VOCopts.datadir, 'VOCcode')); 
end
