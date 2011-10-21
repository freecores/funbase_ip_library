% SYNTHESIS FOR FPGA 
% used Mentor Graphics Precision RTL Synthesis 2003a.29
% Synthesized for Altera Excalibur ARM, frequency 20 MHz
%
% Uses double_fifo_muxed_read components 
% which include two FIFOs and a read multiplexer
% FIFOs are 3b wide

close all
clear all

% Vertailussa kaytetyt fifojen pituudet
length      = [3    30    80]


% Max clock frequency
% (library set up time 0.17 ns is left out of these results)
delay_casev3        = [113.3 62.4  46.3]
delay_casev4        = [113.3 59.0  40.7]
delay_im_case       = [ 88.0 81.1  71.0]
delay_im            = [ 84.4 71.2  59.7]

% Areas [IOs]
%io_casev3        = [   32     32      32]
%io_casev4        = [   32     32      32]
%io_im_case       = [   32     32      32]

% Areas [LCs]
area_casev3        = [   90    858    2370]
area_casev4        = [   90    864    2394]
area_im_case       = [   94   1098    2744]
area_im            = [  126   1090    2730]

% Areas total
%area_casev3        = io_casev3 +lc_casev3
%area_casev4        = io_casev4 +lc_casev4
%area_im_case       = io_im_case +lc_im_case



% Plot figures
% Delay figure
%figure
%plot ( length, delay_im, 'r-o')
%hold on
%plot ( length, delay_iom, '-<')
%hold on
%plot ( length, delay_shift, 'k-*')
%hold on
%plot ( length, delay_slotted_shift, 'bo-')
%hold on
plot ( length, delay_casev3, 'k-o')
hold on
plot ( length, delay_casev4, 'r-*')
hold on
plot ( length, delay_im_case, '-<')
hold on
plot ( length, delay_im, '-*')
hold on

legend ('casev3', 'casev4', 'in-mux-case', 'in-mux', 0)
title (['Max frequency (MHz) of 3-bit double-FIFO'])
xlabel ('Depth of FIFOs')
ylabel ('Max Frequency [MHz]')
axis ([0 82 0 120])

% Area figure
figure
%plot ( length, area_im, 'r-o')
%hold on
%plot ( length, area_iom, '-<')
%hold on
%plot ( length, area_shift, 'k-*')
%hold on
%plot ( length, area_slotted_shift, 'bs-')
%hold on
plot ( length, area_casev3, 'k-o')
hold on
plot ( length, area_casev4, 'r-*')
hold on
plot ( length, area_im_case, '-<')
hold on
plot ( length, area_im_case, '-*')
hold on
legend ('casev3', 'casev4', 'in-mux-case', 'in-mux', 0)

title (['Area (LC) of 3-bit double-FIFO'])
xlabel ('Depth of FIFOs')
ylabel ('Area [LC]')
axis ([0 82 0 3000])

