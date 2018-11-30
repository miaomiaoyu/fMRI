% 1.Maybe test at 2 8 16 32 64 128 Hz = 6*3=18 conditions
% 2s*50trials=1800s... which is 30 minutes roughly.
%
% 2. testing: Kirstie, Alex, Magda, Fed, myself and maybe two Nat Sci.
% 3. make sure it's saving out all the data you need.
% 4. is dpy.questInfo.thresholdStdev a measurement of noise int he signal?
% double check this for signal: this is how you can code error bars.
% 5. do about 50 trials per condition...
% 6. code it to step through 2 to 128 like you did previously.
%
%

%% You want to probe this a little more:
% the range where there's a dramatic increase in slope gradient - you
% should probe more: do the experimetn again with the frequencies in that region
% more carefully. this is so you can more carefully plot the curve.

% make the maximum 100...

clear; close all;

dataDir=('/Users/miaomiaoyu/Documents/Github/fMRI/pilotDataQuest271118/');

allColours={'scone', 'lms', 'lm'};

linesCol=lines(3); % to colour code the figures later..
linesCol=[0 0 1; 0 0 0; 1 0 0];

for colour=1:length(allColours) % just scone for right now..
    
    cd([dataDir, allColours{colour}]);% change directory to folder with data of that colour
    
    d=dir('SubID*.mat'); % this sifts out the . and .. files
    
    % This next bit is because the folder mixes up the frequencies:
    % it goes: 2, 128, 4..etc. Just to sort the data in the right order for
    % plotting...
    
    for thisFreq=1:length(d) % d = 6 (no. of freqs)
        
        [filepath, name, ext]=fileparts(d(thisFreq).name); % export file name
        
        dat=load(d(thisFreq).name);
        
        ExptID=dat.dpy.ExptID; % define the colour cond
        freq=dat.dpy.Freq; % define the frequency
        percentCorrect=dat.dpy.Response;
        contrastLevelTested=dat.dpy.contrastLevelTested;
        
        %'thresholdEstContrast' is the contrast at which you're at threshold...
        %'thresholdEst' is the (1/thresholdEstContrast)* 100% (sensitivity?)
        
        thresholdEstContrastFreq(thisFreq,:,colour)=[freq, dat.dpy.questInfo.thresholdEstContrast];

        thresholdEstSensitivityFreq(thisFreq,:,colour)=[freq, 10^-(dat.dpy.questInfo.thresholdEst)];
        
        thresholdSD(thisFreq,:,colour)=[freq, dat.dpy.questInfo.thresholdStdev];
        % these are 6 (freq) x 2 (threshold est and freq) x 3 (color)
        % matrices
        
    end
end

%% Make the contrasts that are larger than 100 to 100..

for freq=1:6
    for data=1:2
        for color=1:3
            if thresholdEstContrastFreq(freq,2,color)>100
                thresholdEstContrastFreq(freq,2,color)=100;
            end
            if thresholdEstSensitivityFreq(freq,2,color)>100
                thresholdEstSensitivityFreq(freq,2,color)=100;
            end
        end
    end
end

%%

thresholdEstContrastFreq=sort(thresholdEstContrastFreq,1);
thresholdEstSensitivityFreq=sort(thresholdEstSensitivityFreq,1);

FIG=0; % just percentage correct (sigmoid function) ..

if FIG
    
    figure
    scatter(contrastLevelTested, percentCorrect, 'filled');
    %plot(percentCorrect,contrastLevelTested,'-x', 'Color', linesCol(colour,:));
    xlabel('Contrast Level Tested');
    ylabel('Hit/Miss');
    
end




figure(100)

title('contrastLevel vs. tempFreq') % jagged line graph: for contrast level vs temporal freq
for colour=1:3
    %scatter(thresholdEstContrastFreq(:,1,colour), thresholdEstContrastFreq(:,2,colour), 'filled', linesCol(colour,:));
    plot(thresholdEstContrastFreq(:,1,colour), thresholdEstContrastFreq(:,2,colour), '-x', 'Color', linesCol(colour,:));
   
    set(gca, 'XScale', 'log');
    xlabel('Frequency');
    ylabel('contrastLevel');
    hold on;
    grid on;
    
    
end

hold off


figure(101)  % jagged line graph: for sensitivity vs temporal freq

title('sensitivity vs. tempFreq');
for colour=1:3
    %scatter(thresholdEstSensitivityFreq(:,1,colour), thresholdEstSensitivityFreq(:,2,colour), 'filled', linesCol(colour,:));
    plot(thresholdEstSensitivityFreq(:,1,colour), thresholdEstSensitivityFreq(:,2,colour), '-x', 'Color', linesCol(colour,:));
     hold on;
     
    errorbar(thresholdEstSensitivityFreq(:,1,colour), thresholdEstSensitivityFreq(:,2,colour), thresholdSD(:,2,colour));
    % I'm gonna have to check what the standard dev actually are in B116:
    % they look too small. I'm not entirely sure the threshold Contrast is
    % the right variable either..
    
    set(gca, 'XScale', 'log');
    xlabel('Frequency');
    ylabel('sensitivityLevel');
    set(gca, 'XScale', 'log');
    hold on;
    grid on;
    
end

hold off
%%

figure(200)

for colour=1:3
    
    [x, y]=prepareCurveData(thresholdEstContrastFreq(:,1,colour), thresholdEstContrastFreq(:,2,colour));
    %ft=fittype('poly3'); % pchip works better.. poly3 overfits it..?
    [fitresult,gof]=fit(x, y, 'pchip');
    h=plot(fitresult, x, y);
    set(h, 'color', linesCol(colour,:));
    legend('Contrast vs. Frequency (S Cone)', 'Fitted Model (S Cone)', ...
        'Contrast vs. Frequency (LMS)', 'Fitted Model (LMS)',...
        'Contrast vs. Frequency (LM)', 'Fitted Model (LM)',...
        'Location', 'NorthWest')
        set(gca, 'XScale', 'log');
    xlabel('Frequency - Hz')
    ylabel('Contrast?');
    hold on
    grid on
end


figure(201)

for colour=1:3
    
    [x, y]=prepareCurveData(thresholdEstSensitivityFreq(:,1,colour), thresholdEstSensitivityFreq(:,2,colour));
    ft=fittype('poly3');
    [fitresult,gof]=fit(x, y, 'pchip');
    h2=plot(fitresult, x, y);
    set(h2, 'color', linesCol(colour,:));
    
      legend('Sensitivity vs. Frequency (S Cone)', 'Fitted Model (S Cone)', ...
        'Sensitivity vs. Frequency (LMS)', 'Fitted Model (LMS)',...
        'Sensitivity vs. Frequency (LM)', 'Fitted Model (LM)',...
        'Location', 'NorthWest')
    
    xlabel('Frequency - Hz')
    ylabel('Sensitivity?')
    hold on
    grid on
    
end
hold off


