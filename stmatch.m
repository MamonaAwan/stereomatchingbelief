%Adding path to the dependencies
addpath 'msseg';
%setting minimum and maximum values for segmentation
mins = 1; 
maxs = 32;
%assigning spacial bandwidth, range 
hs = 10;
hr = 7;
%assigning minimum segment size 
M = 25;    
%reading input images
i1 = imread('imgR.png');  
i2 = imread('imgL.png');  
%converting images to gray then to double
gray1=im2double(rgb2gray(i1));
gray2=im2double(rgb2gray(i2));
%saving size of the image
[row,col]=size(gray1);
%calling the function from function file
d=stereo(i1,i2, hs,hr,M,mins,maxs);
%initializing array
z1=zeros(row,col);
%checking for occluded pixels
for y=16:1:col
    for x=1:1:row
        %taking in the value
        dL=round(d(x,y));
        %storing pixels to compare
        x1=gray1(x,y);
        x2=gray2(x,y-dL);
        %comparing with a certain threshold
        if(abs(x1-x2)<0.09)
            %marking pixels which satisfy
            z1(x,y)=0; 
        else
            %assinging value to unsatisfactory pixels
            z1(x,y)=255;
        end
    end
end
%displaying original image
imshow(i1,[]);
%displaying original disparity map
figure;
imshow(d,[]);
%storing index of occluded pixels
[idx idy]=find(z1==255);
%assigning occluded pixels a penality
for i=1:1:length(idx)
i1(idx(i),idy(i),:)=0.3*i1(idx(i),idy(i),:);
end
%calling function from finction file
d2=stereo(i1,i2, hs,hr,M,mins,maxs);
%displaying Improved Output
figure;
imshow(d2,[]);

gr=imread('groundtruth.png');
g=im2double(gr);
diff=sum(sum(abs(g-d)));
diff2=sum(sum(abs(g-d2)));
