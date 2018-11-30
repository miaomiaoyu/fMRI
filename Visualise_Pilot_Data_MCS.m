%Simple function that imports some files and create figures to help us
%visualise the pilot data for invisible flicker project...

% written by MmY 18Nov2018

clear; close all;

dataDir=('/Users/miaomiaoyu/Documents/GitHub/fMRI/pilotDataMCS161118/');
allColours={'scone', 'lms', 'lm'};
linesCol=lines(3);

for colour=1:2 %length(allColours)
    cd([dataDir, allColours{colour}]);
    
    d=dir('tempData_*.mat'); % this sifts out the . and .. files
    
    
    for thisMat = 1:length(d)
        [filepath, name, ext] = fileparts(d(thisMat).name); % export filename
        
        freqPos=regexp(name, '\d'); %find position of the number
        freq=str2num(name(freqPos)); %get the frequency from filename string
        dat=load(d(thisMat).name, 'percentCorrect');
        results(thisMat,:)=[dat.percentCorrect, freq];
    end
    
    results=sortrows(results,2);
    
    figure(1)
    for i = 1:size(results,1)
        scatter(results(:,2), results(:,1), 'filled');
        plot(results(:,2),results(:,1), '-x', 'Color', linesCol(colour,:));
        set(gca, 'XScale', 'log');
        legend(allColours{colour})
        xlabel('Percentage Correct');
        ylabel('Frequency');
        hold on;
        grid on;
    end
    
end
