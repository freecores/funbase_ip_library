% Prints the synthesis results of FIFO comparison @ 0.18 um
% Uses double_fifo_muxed_read components 
% which include two FIFOs and a read multiplexer
% FIFOs are 3b wide
% _im   = in-mux (triagle in figures)
% _iom  = inout-mux (circle in figures)
% shift = shift register (star in figures)

close all
clear all

% Vertailussa kaytetyt fifojen pituudet
length      = [3    30    80]


% Delay [ns] = data arrival time 
% (library set up time 0.17 ns is left out of these results)
delay_im            = [1.99  3.06  3.82]
delay_iom           = [2.25  3.63  4.62]
delay_shift         = [1.33  2.15  2.81]
delay_slotted_shift = [1.56  1.99  1.81]
% delay_casev3        = [1.05  2.16  3.43]
delay_casev4        = [1.48  2.36  3.64]
delay_casev4a       = [1.69  2.52  3.34]
delay_casev5        = [1.72  2.52  3.75]
delay_casev6        = [1.86  2.66  3.55]
delay_im_case       = [1.57  2.54  3.92]


% Areas [um2]
area_im            = [11214  55672  161906]
area_iom           = [12955  62296  140750]
area_slotted_shift = [ 7688  43724  110645]
area_shift         = [ 7696  45350  114765]
% area_casev3      = [ 6602  50802  129232]
area_casev4        = [10014  54546  133443]
area_casev4a       = [11051  63721  159215]
area_casev5        = [10264  55255  132984]
area_casev6        = [10088  64253  158724]
area_im_case       = [ 8978  53493  160079]
 
% Plot figures
% Delay figure
figure
%plot ( length, delay_shift, 'k-*')
%hold on
%plot ( length, delay_slotted_shift, 'bo-')
%hold on
plot ( length, delay_im, 'k-o')
hold on
plot ( length, delay_iom, '-<')
hold on
plot ( length, delay_casev4, 'r-o')
hold on
plot ( length, delay_casev4a, 'r-*')
hold on
plot ( length, delay_casev5, 'r-+')
hold on
plot ( length, delay_casev6, 'c-+')
hold on
plot ( length, delay_im_case, 'k-<')
hold on

%title (['Delay of 3-bit double-FIFO (blue triangle=inout-mux, red' ...
%	' o= in-mux, black *=shift, black square= slotted shift, red * = 
%casev4, red triangle = im-case, black o= casev3)'])

title ('Delay of 3-bit double-FIFO')
legend('in-mux', 'inout-mux', 'casev4', 'casev4a','casev5','casev6', 'in-mux-case',0) 

xlabel ('Depth of FIFOs')
ylabel ('Delay [ns]')
axis ([0 82 0 5])

% Area figure
figure
%plot ( length, area_shift, 'k-*')
%hold on
%plot ( length, area_slotted_shift, 'bs-')
%hold on
plot ( length, area_im, 'k-o')
hold on
plot ( length, area_iom, '-<')
hold on
plot ( length, area_casev4, 'r-o')
hold on
plot ( length, area_casev4a, 'r-*')
hold on
plot ( length, area_casev5, 'r-+')
hold on
plot ( length, area_casev6, 'c-+')
hold on
plot ( length, area_im_case, 'k-<')
hold on


%title (['Area of 3-bit double-FIFO (blue triangle=inout-mux, red' ...
%	' o= in-mux, black *=shift, black square= slotted shift, red * = 
%casev4, red triangle = im-case, black o = casev3)'])

title ('Area of 3-bit double-FIFO')
legend('in-mux', 'inout-mux', 'casev4', 'casev4a', 'casev5','casev6','in-mux-case',0) 

xlabel ('Depth of FIFOs')
ylabel ('Area [um2]')
axis ([0 82 0 18e4])


