function Data=MCS_Run_TetraExp_DUE_5LEDs(dpy,s)
% Data = MCS_Run_TetraExp_DUE_5LEDs(dpy,s)
%
% Runs the experiment using details from dpy. s is the serial connection.
%
% dpy should contain:
% dpy.SubID     = the SubjectID
% dpy.NumSpec   = the number of cone spectra to use, either 2 3 or 4
% dpy.ExptID    = the experiment ID
% dpy.Repeat    = which session number is it
% dpy.Freq      = the frequency (Hz) of the stimulus
% dpy.NumStimLevels      = the number of contrast levels to test at in MCS
% dpy.NumTrialsPerLevel  = the number of trials to run at each contrast level
%
% Outputs 'Data', containing final thresholds, etc.
%
% % ARW 021515
% edited by LEW 200815 as a function to output 'Data'
% edited by LEW 131115 to use method of constant stimuli

% This code presents two flicker intervals - randomising which interval
% contains the target
pause(2);
fprintf('\n****** Experiment Running ******\n \n');

% Initialize the display system
% Load LEDspectra calib contains 1 column with wavelengths, then the LED calibs
load('LEDspectra_151215.mat'); %load in calib for the prizmatix
LEDcalib=LEDspectra; %if update the file loaded, the name only has to be updated here for use in rest of code
LEDcalib(LEDcalib<0)=0; %set any negative values to 0
clear LEDspectra %we'll use this variable name later so clear it here

%normalise the spectra scale so 0 to 1
maxVal=max(max(LEDcalib(:,2:end)));
normLEDcalib(:,1)=LEDcalib(:,1);
for thisLED = 1:size(LEDcalib,2)-1
    normLEDcalib(:,1+thisLED)=LEDcalib(:,1+thisLED)./maxVal;
end

LEDcalib=normLEDcalib;   


dpy.WLrange=(400:1:720)'; %must use range from 400 to 720
BITDEPTH=12;

%************ IF CHANGING NUMBER OF LEDS USED, UPDATE THESE VARIABLES *****
baselevelsLEDS=[1,1,1,1,1];
LEDamps=uint16([0,0,0,0,0]);
LEDsToUse=[1,2,3,4,5]; % the LEDs you want to use, where 1 is the 410nm LED, and 5 is 630nm LED
%**************************************************************************
dpy.LEDsToUse = LEDsToUse;
nLEDsTotal=length(LEDamps);

if dpy.NumSpec==4 %if tetra stim
    LprimePos=dpy.LprimePosition; %position of peak between the L and M cones, 0.5 is half way
    coneSpectra=creatingLprime(dpy); %outputs the L L' M S spectra, with first column containing wavelengths
    fprintf('LprimePos is %.2f\n',LprimePos);
elseif dpy.NumSpec==3; %if LMS stim
    coneSpectra=creatingLMSspectra(dpy);
elseif dpy.NumSpec==2;
    [coneSpectra,dpy]=creating2coneSpectra(dpy); %where 'LMpeak' is lambdaMax of the cone in longwavelength region
end
dpy.coneSpectra = coneSpectra;
dpy.coneSpectra(isnan(dpy.coneSpectra))=0;

% use white spectra to get baselevels for each LED (so white light as
% background), and resample the LEDcalib spectra to the desired WL range
[baselevelsLEDS, LEDspectra] = LED2white(LEDcalib,dpy); % outputs scaled baselevels and resampled LEDspectra based on WL
%baselevelsLEDS=baselevels/2; %we want the baselevels at half their scaled levels
%LEDbaseLevel=uint16((baselevelsLEDS)*(2^BITDEPTH)); % convert for sending to arduino
baselevelsLEDS = baselevelsLEDS(:,LEDsToUse);
% keep the necessary spectra for each LED in use (as specified above)
dpy.LEDspectra=LEDspectra(:,LEDsToUse); %specify which LED spectra to keep
dpy.LEDsToUse=LEDsToUse; % save to dpy
dpy.nLEDsTotal=nLEDsTotal; % save number of LEDs
dpy.nLEDsToUse=length(dpy.LEDsToUse); %duplicate info from above... check which is used in later code

% Save baselevels and bitDepth to dpy
dpy.baselevelsLEDS=baselevelsLEDS;
dpy.bitDepth=BITDEPTH;
dpy.backLED.dir=baselevelsLEDS;

dpy.backLED.scale=.5; % LEDs on at 50%

%CHECK THIS *******************************
dpy.LEDbaseLevel=round(dpy.backLED.dir*dpy.backLED.scale*(2.^dpy.bitDepth-1)); % Set just the LEDs we're using to be on a 50%
%*******************

% Set the modulation rate
dpy.modulationRateHz=dpy.Freq;

% Check whether or not an Lprime position has been set, if not set it to a
% default in case it is need to run the experiment (e.g. in Lprime
% isolating condition)
try
    dpy.LprimePosition = dpy.LprimePosition;
    % Using the specified Lprime LambdaMax
catch
    dpy.LprimePosition=0.5; %default position of the Lprime peak in relation to L and M cone peaks: 0.5 is half way between, 0 is M cone and 1 is L cone
    % Using default Lprime LambdaMax
end

% Set up the parameters for the possible stimuli - the thresholds
% for different opponent channels will be different - we estimate that they
% are .01 .02 and .05 for (L-M), L+M+S and s-(L+M)respectively (r/g, lum, s-cone)

% For each possible condition we need to record the max contrast value that
% we are able to produce, and set the min and max values we would want to
% use in a method of constant stimuli (based on educated guesses
% surrounding likely thresholds).  We  later use the information from
% dpy to build the list of contrast levels and the number of trials for
% each, so we can randomise the presentation of the stimuli.

% For the current condition, check the ExptID and set stimulus values
% specific for that condition and for the number of cone spectra being
% assumed (i.e. contrast has to be much lower when accounting for 4 cones)
switch dpy.ExptID
    case {'L'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[1 0 0 0]; % L cone isolating
            stim.stimLMS.maxCont = .008;
            stim.stimLMS.maxTestLevel = .006;
            stim.stimLMS.minTestLevel = .0001;
        elseif dpy.NumSpec==3
            if isfield(dpy,'ConeTypes')==1
                dpy.ConeTypes=dpy.ConeTypes;
            else %default to setting as LMS coneTypes
                dpy.ConeTypes='LMS';
            end
            stim.stimLMS.dir=[1 0 0]; % L cone isolating
            stim.stimLMS.maxCont= .035;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .005;
        end
        thisExp='L';
        
    case {'LP'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 1 0 0]; % L' cone isolating
            if dpy.LprimePosition<0.25 || 0.75<dpy.LprimePosition
                stim.stimLMS.maxCont= .0007;
                stim.stimLMS.maxTestLevel = .0007;
                stim.stimLMS.minTestLevel = .0001;
            else
                stim.stimLMS.maxCont= .005;
                stim.stimLMS.maxTestLevel = .002;
                stim.stimLMS.minTestLevel = .0001;
            end
        elseif dpy.NumSpec==3
            if isfield(dpy,'ConeTypes')==1
                disp('cone types specified')
            else %default to setting as LpMS coneTypes
                dpy.ConeTypes='LpMS';
            end
            stim.stimLMS.dir=[1 0 0]; % L cone isolating
            stim.stimLMS.maxCont= .035;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .002;
        else
            error('Check NumSpec for this condition')
        end
        thisExp='Lp';
        
    case {'M'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 0 1 0]; % M cone isolating
            stim.stimLMS.maxCont= .008;
            stim.stimLMS.maxTestLevel = .005;
            stim.stimLMS.minTestLevel = .0001;
        elseif dpy.NumSpec==3
            if isfield(dpy,'ConeTypes')==1
                disp('cone types specified') %leave it set as is
            else %default to setting as LMS coneTypes
                dpy.ConeTypes='LMS';
            end
            stim.stimLMS.dir=[0 1 0]; % M cone isolating
            stim.stimLMS.maxCont= .035;
            stim.stimLMS.maxTestLevel = .03;
            stim.stimLMS.minTestLevel = .002;
        end
        thisExp='M';
        
    case {'LM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0.5 0 -1 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .015;
            stim.stimLMS.minTestLevel = .001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .045;
            stim.stimLMS.minTestLevel = .001;
        end;
        thisExp='LM';
        
    case {'LLP'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0.5 -1 0 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .007;
            stim.stimLMS.minTestLevel = .00005;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LLpS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .005;
        end
        thisExp='LLp';
        
    case {'LPM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 0.5 -1 0]; %
            stim.stimLMS.maxCont= .005;
            stim.stimLMS.maxTestLevel = .007;
            stim.stimLMS.minTestLevel = .00005;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LpMS';
            stim.stimLMS.dir=[0.5 -1 0]; %
            stim.stimLMS.maxCont= .045;
            stim.stimLMS.maxTestLevel = .05;
            stim.stimLMS.minTestLevel = .005;
        end
        thisExp='LpM';
        
    case {'LMS'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[1 0 1 1]; %
            stim.stimLMS.maxCont= .02;
            stim.stimLMS.maxTestLevel = .02;
            stim.stimLMS.minTestLevel = .001;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[1 1 1]; %
            stim.stimLMS.maxCont= .1;
            stim.stimLMS.maxTestLevel = .07;
            stim.stimLMS.minTestLevel = .002;
        end
        thisExp='LMS';
        
    case {'LLpMS'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[1 1 1 1]; %
            stim.stimLMS.maxCont= .02;
            stim.stimLMS.maxTestLevel = .02;
            stim.stimLMS.minTestLevel = .001;
        else
            error('Num spec must be set to 4 to run LLpMS')
        end
        thisExp='LLpMS';
        
        
    case {'S'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 0 0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .5;
            stim.stimLMS.minTestLevel = .01;
        elseif dpy.NumSpec==3
            dpy.ConeTypes='LMS';
            stim.stimLMS.dir=[0 0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .08;
            stim.stimLMS.minTestLevel = .005;
        elseif dpy.NumSpec==2
            stim.stimLMS.dir=[0 1]; % S cone isolating
            stim.stimLMS.maxCont= .25;
            stim.stimLMS.maxTestLevel = .10;
            stim.stimLMS.minTestLevel = .005;
        end
        thisExp='S';
        
    case {'TESTLM'}
        if dpy.NumSpec==4
            stim.stimLMS.dir=[0 1 0 0]; % testLM cone isolating
            stim.stimLMS.maxCont= .008;
            stim.stimLMS.maxTestLevel = .008;
            stim.stimLMS.minTestLevel = .0005;
        elseif dpy.NumSpec==2
            stim.stimLMS.dir=[1 0]; % testLM cone isolating
            stim.stimLMS.maxCont= .2;
            stim.stimLMS.maxTestLevel = .1;
            stim.stimLMS.minTestLevel = .005;
        else
            error('Incorrect NumSpec for this condition')
        end
        thisExp='testLM';
        
    otherwise
        error ('Incorrect experiment type');
end

% Create the series of trials to present in the method of constant stimuli
% We are going to do this on a log scale so we don't have too many levels
% at the high 'easy-to-see' end

%in case just in testing mode using pre-defined contrasts check for
%indicator
try
    if dpy.testingMode == 1
        dpy.stimLevels = dpy.TestingStimLevel;
        dpy.allStimTrialLevels = repmat(dpy.stimLevels,dpy.NumTrialsPerLevel,1);
    end
catch %if doesn't exist, proceed as normal
dpy.stimLevels=logspace(log10(stim.stimLMS.minTestLevel),log10(stim.stimLMS.maxTestLevel),dpy.NumStimLevels)'; %create the stimulus levels
dpy.allStimTrialLevels=Shuffle(repmat(dpy.stimLevels,dpy.NumTrialsPerLevel,1)); %produce list of all the contrast levels (i.e. all trials) and shuffle them
end
% Run the trials.
% On each trial we run one of the pre-defined stimulus contrast levels that have
% been pre-shuffled in dpy.allStimTrialLevels
wrongRight={'wrong','right'};
timeZero=GetSecs; % We >force< you to have PTB in the path for this so we know that GetSecs is present

%prompt to press 1 to start
toStart=-1;
pause(1);
Speak('Press 1 to start','Daniel');
while(toStart<0)
    startString=GetChar; %awaiting 1 to start
    toStart=str2double(startString);
end
Speak('Experiment beginning','Daniel');
pause(1)

k=0; 
exit=0;

% Run the trials
for thisTrial = 1:length(dpy.allStimTrialLevels)
    dpy.theTrial=thisTrial; %save the current trial in dpy so that the target interval and wrong/right info can be saved within next function
    %set the tTest value (i.e. the contrast level for the current trial)
    tTest=dpy.allStimTrialLevels(thisTrial);
    
    timeSplit=GetSecs;
    stim.stimLMS.scale=tTest; %assign tTest to stim
    
    if exit==0
        [response,dpy]=MCS_tetra_led_doLEDTrial_5LEDs(dpy,stim,s); % This should return 0 for an incorrect answer and 1 for correct
        
        % Check if the response was given, and whether 'q' was pressed to quit
        % experiment
        if (response ~=-1)
            fprintf('Trial %3d at %.4f is %s\n',thisTrial,tTest,char(wrongRight(response+1)));
            timeZero=timeZero+GetSecs-timeSplit;
            k=k+1;
        else
            disp('Quitting...');
            Speak('Quitting before all trials complete','Daniel');
            exit=1;
        end
        
    elseif exit==1
        continue
    end
end

% plot the percent correct curves
% concatenate columns with contrast level and hit/miss code
try
    responseData=cat(2,dpy.allStimTrialLevels,dpy.Response);
catch %if experiment was exited before end the values have to be altered for the number of trials actually completed
    dpy.allStimTrialLevels=dpy.allStimTrialLevels(1:k,1);
    dpy.Response=dpy.Response(1:k,1);
    responseData=cat(2,dpy.allStimTrialLevels,dpy.Response);
end

for thisLevel = 1:length(dpy.stimLevels)
    plotResponseData(thisLevel,1)=dpy.stimLevels(thisLevel); %name of each level
    totalTrials=0;
    totalHits=0;
    for thisTrial=1:length(dpy.allStimTrialLevels)
        if responseData(thisTrial,1)==dpy.stimLevels(thisLevel); %if row matches current level, save the response info
            totalTrials=totalTrials+1;
            if responseData(thisTrial,2)==1; %if a hit
                totalHits=totalHits+1;
            end
        end
    end
    plotResponseData(thisLevel,2)=totalHits;
    plotResponseData(thisLevel,3)=totalTrials;
    Data.CombinedResponseData=plotResponseData;
    percentCorrect=(plotResponseData(:,2)./plotResponseData(:,3))*100;
    Data.PercentCorrect=cat(2,plotResponseData(:,1),percentCorrect);
end

scatter(Data.PercentCorrect(:,1),Data.PercentCorrect(:,2));
set(gca,'YLim',[0,100]);
try
    title(sprintf('LMpeak %d at %.1f Hz Trial %d',dpy.LMpeak,dpy.Freq,dpy.Repeat))
catch
    title(sprintf('%s cond at %.1f Hz Trial %d',dpy.ExptID,dpy.Freq,dpy.Repeat))
end

%fit psychometric function to data
searchGrid.alpha = 0:1:30;
searchGrid.beta = 0:0.5:10;
searchGrid.gamma = .5;
searchGrid.lambda = 0.02;

paramsFree = [1 1 0 0];
PF = @PAL_CumulativeNormal;

[Data.Fit.paramValues,Data.Fit.LL,Data.Fit.exitFlag,Data.Fit.output] = PAL_PFML_Fit(plotResponseData(:,1),plotResponseData(:,2),...
    plotResponseData(:,3),searchGrid,paramsFree,PF);
Data.contrastThresh=Data.Fit.paramValues(1)*100;

try
    fprintf('Experiment Condition: %s    Freq: %.1f testLMpeak: %d\n',dpy.ExptID,dpy.Freq,dpy.LMpeak);
catch
    fprintf('Experiment Condition: %s    Freq: %.1f \n',dpy.ExptID,dpy.Freq);
end
if Data.Fit.exitFlag == 1
    Data.fitExit='successful';
elseif Data.Fit.exitFlag == 0
    Data.fitExit='not successful';
end
fprintf('Final threshold estimate is %.2f%%     Fit %s\n\n',Data.contrastThresh,Data.fitExit); %first val is threshold
Speak('Condition complete','Daniel');
Data.Date=datestr(now,30); %current date with time

Data.dpy=dpy;


