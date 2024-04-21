% expTime Calculator

% Experimental good exp time
t1 = .0043;
index1 = 690;

% Lamp spectrtum data points
intensity1 = 13409.3;

index2 = 670;
intensity2 = 18115.9;

% Calculations
t2 = (index1/index2) * t1;
m = (t2-t1)/(index2-index1)
b = t1 - m*index1


