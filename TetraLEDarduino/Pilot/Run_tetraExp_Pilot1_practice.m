% Script to specify experiment conditions and then run the experiment.
% (make sure arduino script is already running).
% 
% Edit the 'LprimePositions' array to list the levels that should be tested for a
% cone peaking in the Long to middle wavelength region, i.e. enter a list
% of values between 0 and 1, where 0=M cone peak, and 1=L cone peak
% e.g.
% peakLevels = [0.1,0.25,0.5,0.75,0.9];
%
% Specify dpy structure to send to the Run_TetraExp_DUE_5LEDs script.
% dpy should contain:
% dpy.SubID          = the SubjectID 
% dpy.NumSpec        = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID         = the experiment ID
% dpy.Repeat         = which session number is it
% dpy.Freq           = the frequency (Hz) of the stimulus  
% dpy.LprimePosition = the position (0-1) between L and M cone peaks for
%                      Lprime
%
% written by LEW 20/08/15

clear all; close all;
addpath(genpath('/Users/wadelab/Github_MultiSpectral/TetraLEDarduino'))

%connect to arduino
s=ConnectToArduino;

% set number of trials in staircase
dpy.NumTrials=5;
% % Ask the user to enter a Subject ID number
% SubID=-1; 
% while(SubID<1)
%     SubID=input ('Enter Subject ID, e.g. 001: ','s'); %prompts to enter a subject ID
%     if(isempty(SubID))
%         SubID=-1;
%     end
% end
dpy.SubID='999';

dpy.NumSpec=4;
dpy.ExptID='LP';
dpy.ExptLabel='DriftCone';
dpy.Freq=2;

LprimePositions=[0.3]; %the levels of Lprime to test

% Ask the user to enter a session number
% Repeat=-1; 
% while(Repeat<1)
%     RepeatString=input ('Enter the session number for this condition: ','s'); 
%     Repeat=str2double(RepeatString);
%     if(isempty(Repeat))
%         Repeat=-1;
%     end
% end
dpy.Repeat=1;


tic;

%shuffle the order of the peaklevels so conditions are run in random order
LpLevels=Shuffle(LprimePositions);
for thisPeak=1:length(LpLevels)
    dpy.LprimePosition=LpLevels(thisPeak);
 
    

% Now send experiment details out and start experiment trials.

Data=Run_TetraExp_DUE_5LEDs(dpy,s);

%save out a file containing the contrastThresh, SubID, experimentType, freq and
%Session num

system ('say End of demo');
peakname=sprintf('peak%d',LpLevels(thisPeak)*100);
allPeaks{thisPeak}=peakname;
TempData.Thresh.(peakname)=Data.contrastThresh;
TempData.stDevPos.(peakname)=Data.contrastStDevPos;
TempData.stDevNeg.(peakname)=Data.contrastStDevNeg;



AllData.(peakname)=Data;

clear Data
close all
end
%turn off LEDs and close connection to ardunio
CloseArduino(s);



timeElapsed=toc/60;
fprintf('Experiment complete in %.3f minutes\n',timeElapsed);