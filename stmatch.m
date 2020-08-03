function dsp = stereo ...
    (i1,i2, hs,hr,M,mins, maxs, segs, labels)
  
  win_size = 5;
  tolerance = 0;
  
  [dimy dimx c] = size(i1);
  [xx yy] = meshgrid(1:size(i1,2),1:size(i1,1));
  
  dsp  = ones(size(i1,1),size(i1,2));
  

  if(nargin<9)
    [segs labels] = msseg(i1,hs,hr,M);  %mean shift segmentation
  end
  
  %determining pixel correspondence Right to Left
  [disparity1 mindiff1] = slide_images(i1,i2, mins, maxs, win_size);

  %determine pixel correspondence Left to Right
  [disparity2 mindiff2] = slide_images(i2,i1, -mins, -maxs, win_size);
  disparity2 = abs(disparity2); % disparities will be negative

  %create high-confidence disparity map
  pixel_dsp = winner_take_all(disparity1, mindiff1, disparity2, mindiff2);

  %filter with segmented image
  for(i = 0:length(unique(labels))-1)
    lab_idx = find((labels == i));
    inf_idx = find(labels == i & pixel_dsp<inf);
    dsp(lab_idx) = median(pixel_dsp(inf_idx));
  end
  idf=find(isnan(dsp));
  dsp(idf)=15;
  
  pixel_dsp(pixel_dsp==inf)=NaN;

 
  
%% HELPER FUNCTIONS

%slides images across each other to get disparity estimate
function [disparity mindiff] = slide_images(i1,i2,mins,maxs,win_size)
  
[dimy,dimx,c] = size(i1);
disparity = zeros(dimy,dimx);     %initializing outputs

mindiff = inf(dimy,dimx);    

w = 5;                            %weight of CSAD vs CGRAD
hx = [-1 0 1]; hy = [-1 0 1]';    %gradient filter
h = 1/win_size.^2*ones(win_size); %averaging filter

g1x = sum(imfilter(i1,hx).^2,3);  %getting gradient for each image
g1y = sum(imfilter(i1,hy).^2,3);  %using to compute CGRAD
g2x = sum(imfilter(i2,hx).^2,3);
g2y = sum(imfilter(i2,hy).^2,3);
  
step = sign(maxs-mins);             %adjusts to reverse slide
for(i=mins:step:maxs)
   s  = shifting(i2,i);             %shift image and derivs
   sx = shifting(g2x,i);
   sy = shifting(g2y,i);
   %CSAD  is Cost from Sum of Absolute Differences
   %CGRAD is Cost from Gradient of Absolute Differences
   diffs = sum(abs(i1-s),3);       %getting CSAD and CGRAD
   CSAD  = imfilter(diffs,h);
   gdiff = w * (sum(abs(g1x-sx),3)+sum(abs(g1y-sy),3));
   CGRAD = imfilter(gdiff,h);
   d = CSAD+CGRAD;                 %total difference
   
   idx = find(d<mindiff);          %put corresponding disarity
   disparity(idx) = i;          
   mindiff(idx) = d(idx);
end
  
%reconsiles two noisy disparity estimates
function [pd] = winner_take_all(d1,m1,d2,m2,tolerance)
  if(~exist('tolerance','var')) tolerance = 0; end
  [dimy dimx] = size(d1);
  d3 = zeros(size(d1));
  m3 = zeros(size(d1));

  for(i=1:max(d2(:)))               
    [yy xx] = find(d2==i);          %get all disprities 'i'
    idx2 = sub2ind([dimy, dimx],yy,xx); 
    xx = xx+i-1;                    %figure out new position
    xx(xx>dimx)=dimx;               %check boundary
    idx3 = sub2ind([dimy dimx],yy,xx);
    d3(idx3)=d2(idx2);              %move disparities and
    m3(idx3)=m2(idx2);              %diffs to the right spot
  end

  %keeping the best ones and marking others
  pd = d3;                          %starting with shifting L-R
  idx = find(m1<m3);                %finding where m1 is better
  pd(idx) = d1(idx);                %using disp from R-L there
  diff(idx) = m1(idx);              %use L-R mindiff's too
  
  idx = find(m1==m3);               %finding where its a tie
  pd(idx)=round(d1(idx)+d3(idx))/2; %spliting the difference
  
  pd(abs(d1-d3)>tolerance) = inf;   %marking points that are likley wrong 
                                       

%Shifting an image
function I = shifting(I,shift)
  dimx = size(I,2);
  if(shift > 0)
    I(:,shift:dimx,:) = I(:,1:dimx-shift+1,:);
    I(:,1:shift-1,:) = 0;
  else 
    if(shift<0)
      I(:,1:dimx+shift+1,:) = I(:,-shift:dimx,:);
      I(:,dimx+shift+1:dimx,:) = 0;
    end  
  end
