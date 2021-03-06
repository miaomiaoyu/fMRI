% plots the modulation of the LEDs for the selected condition.
%
% Uses the first contrast value tested in the experiment, but edit this if
% you want, or within the experiment to start at specific contrast level
% (N.B. if you want it to do max available, set the tGuess value in
% experiment really high, and then it will replace with the actual max
% available).
%
% written by LEW 070616

cc
addGitHubFolder
addConeIsolationFolder

%select a data file to load
theData=uigetfile(pwd,'Select a file containing a single data condition');
data=importdata((theData));

%import the LED spectra
LEDspec=data.dpy.LEDspectra;

%import/enter the LED amps (given in vals +/- above or below half output of
%leds)
LEDamps=data.dpy.targetLEDoutput(1,:)'; %just the first contrast condition (row)

%import the cone spectra that was used to generate the amps
coneSpectra=data.dpy.coneSpectra;

%save condition parameters
contrastPercentLevel=data.dpy.contrastLevelTested(1,1)*100; %for first condition, x100 for %
condition=data.dpy.ExptID;
conePos=[1,2,3,4];
coneLabels={'L','LP','M','S'};

WLs=data.dpy.WLrange;

%get modulation for the conditions by multiplying LED spec by the amps. get
%the neg of the mod (-mod).
PosMod=LEDspec*LEDamps;
PosMod=(PosMod/2048)*100; %adjust so on % modulation scale instead of amps - 2048 is half bit depth
NegMod=-PosMod;

backgroundMod=sum((LEDspec*0.5),2);
%% Now produce the plot
%plot the positive and negative modulations
theFig=figure();
set(theFig,'Color','w')

%plot pos modulation
thePosPlot=plot(WLs,backgroundMod);
set(thePosPlot,'Color',[0.5,0.5,0.5],'LineWidth',3)
hold on

%set plot properties
set(gca,'LineWidth',3,'FontName','Arial','FontSize',22,'YTick',[],...
    'YTickLabel',{},'XLim',[400,720],...
    'Position',[0.18 0.1443 0.7750 0.7736],'YLim',[0,0.55])
theXlabel=xlabel('Wavelength (nm)');
set(theXlabel,'FontName','Arial','FontSize',24)
theYlabel=ylabel('Normalised Intensity');
set(theYlabel,'FontName','Arial','FontSize',24,'Position',[380 0.275])

%add line at zero
zeroLine=line([400,720],[0,0]);
set(zeroLine,'LineWidth',2,'LineStyle',':','Color',[0 0 0])
%add lines for LED peaks on the plot - do this first so they are behind mod
LEDpeaks=[414.7,463.80,503.80,531,638.3]; %LED peaks
lineColours=[0.4,0,0.5;0,0,0.9;0,0.5,0.2;0,0.9,0;0.9,0,0]; %Colours used in previous LED plots
for thisLED=1:length(LEDpeaks) %for each LED
    theLEDline=line([LEDpeaks(thisLED),LEDpeaks(thisLED)],[30,-30]); %create the line
    set(theLEDline,'LineWidth',1.5,'LineStyle','--','Color',lineColours(thisLED,:)) %set properties of line
end

%re-plotting here so in front of the LED lines... can't remember how to
%remove any background when plotting data

%plot pos modulation
thePosPlot=plot(WLs,backgroundMod);
set(thePosPlot,'Color',[1,0,0],'LineWidth',3)
hold on


theTitle=title(sprintf('Background'));
set(theTitle,'FontName','Arial','FontSize',24)
