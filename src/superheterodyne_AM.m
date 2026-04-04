% =========================================================================
% Super-heterodyne Receiver & DSB-SC AM Communication System Simulation
% =========================================================================
clear; clc; close all;

%% 1. Signal Preprocessing
disp('--- Stage 1: Preprocessing ---');
fileNames = {'audio1.wav', 'audio2.wav', 'audio3.wav', 'audio4.wav', 'audio5.wav'};
numSig = length(fileNames); audioSignals = cell(1, numSig);
fs_orig = zeros(1, numSig); maxLength = 0;

for i = 1:numSig
    [raw, fs] = audioread(fileNames{i});
    fs_orig(i) = fs; mono = sum(raw, 2); 
    mono = mono / max(abs(mono)); audioSignals{i} = mono;
    maxLength = max(maxLength, length(mono));
end

paddedSignals = zeros(maxLength, numSig);
for i = 1:numSig, paddedSignals(1:length(audioSignals{i}), i) = audioSignals{i}; end

%% 2. Interpolation & BW Estimation
disp('--- Stage 2: Resampling & BW ---');
baseFs = fs_orig(1); interpFactor = ceil(600000 / baseFs);
newFs = baseFs * interpFactor; interpLen = maxLength * interpFactor;
processedSignals = zeros(interpLen, numSig); estBW = zeros(1, numSig);

for i = 1:numSig
    estBW(i) = min(estimateBandwidth(paddedSignals(:,i), baseFs), 12000);
    fprintf('Signal %d: BW = %.2f Hz\n', i, estBW(i));
    processedSignals(:,i) = interp(paddedSignals(:,i), interpFactor);
end

%% 3. AM Modulation & Comparative Spectra
disp('--- Stage 3: AM Modulation ---');
t = (0:interpLen-1)' / newFs; modulatedSignals = zeros(interpLen, numSig);
fc = 100000 + (0:numSig-1)*30000; 
figure('Name','Stage 3: Comparative Spectra'); colors = lines(numSig);

for i = 1:numSig
    modulatedSignals(:,i) = processedSignals(:,i) .* cos(2*pi*fc(i)*t);
    subplot(2,1,1); hold on; plotSpectrum(processedSignals(:,i), newFs, '', colors(i,:));
    subplot(2,1,2); hold on; plotSpectrum(modulatedSignals(:,i), newFs, '', colors(i,:));
end
subplot(2,1,1); title('All Baseband Spectra'); grid on; legend show; xlim([-max(estBW)*1.2, max(estBW)*1.2]);
subplot(2,1,2); title('All Modulated Spectra'); grid on; legend show; xlim([-(max(fc)+max(estBW)), max(fc)+max(estBW)]);

%% 4. Frequency Division Multiplexing (FDM)
disp('--- Stage 4: FDM ---');
fdmSignal = sum(modulatedSignals, 2);
figure('Name','Stage 4: FDM'); plotSpectrum(fdmSignal, newFs, 'FDM Spectrum', 'b');
xlim([-(max(fc)+max(estBW)), max(fc)+max(estBW)]);

%% 5. Receiver - RF Stage
disp('--- Stage 5: RF Stage ---');
targetIdx = 3; targetFc = fc(targetIdx); bw = estBW(targetIdx);
rfFilt = designfilt('bandpassiir','FilterOrder',4,'HalfPowerFrequency1',targetFc-bw,...
    'HalfPowerFrequency2',targetFc+bw,'SampleRate',newFs);
rfOut = filtfilt(rfFilt, fdmSignal);
figure('Name','Stage 5: RF Output'); plotSpectrum(rfOut, newFs, 'RF Output', 'b');
xlim([-(targetFc + 2*bw), targetFc + 2*bw]);

%% 6. Mixer & Local Oscillator
disp('--- Stage 6: Mixer ---');
fIF = 15000; fLO = targetFc + fIF;
mixedSignal = rfOut .* cos(2*pi*fLO*t);
figure('Name','Stage 6: Mixer'); plotSpectrum(mixedSignal, newFs, 'Mixer Output', 'b');
xlim([-(fLO + targetFc + bw), (fLO + targetFc + bw)]);

%% 7. IF Stage
disp('--- Stage 7: IF Stage ---');
ifFilt = designfilt('bandpassiir','FilterOrder',4,'HalfPowerFrequency1',fIF-bw,...
    'HalfPowerFrequency2',fIF+bw,'SampleRate',newFs);
ifOut = filtfilt(ifFilt, mixedSignal);
figure('Name','Stage 7: IF Output'); plotSpectrum(ifOut, newFs, 'IF Output', 'b');
xlim([-(fIF + 2*bw), fIF + 2*bw]);

%% 8. Baseband Detection & Playback
disp('--- Stage 8: Demodulation ---');
detMixed = ifOut .* cos(2*pi*fIF*t);
lpFilt = designfilt('lowpassiir','FilterOrder',6,'HalfPowerFrequency',bw,'SampleRate',newFs);
recovered = filtfilt(lpFilt, detMixed); recovered = recovered / max(abs(recovered));

figure('Name','Stage 8: Recovered'); plotSpectrum(recovered, newFs, 'Recovered Spectrum', 'b');
xlim([-bw*1.2, bw*1.2]);
disp('Playing recovered audio...'); sound(downsample(recovered, interpFactor), baseFs);
pause(maxLength/baseFs + 1);

%% 9. Experiments
disp('--- Stage 9: Experiments ---');
% Exp A
disp('Exp A: No RF Filter');
ifOutNoRF = filtfilt(ifFilt, fdmSignal .* cos(2*pi*fLO*t));
recNoRF = filtfilt(lpFilt, ifOutNoRF .* cos(2*pi*fIF*t));
figure('Name','Experiment A'); plotSpectrum(ifOutNoRF, newFs, 'No RF Filter IF Output', 'b');
xlim([-(fIF + 2*bw), fIF + 2*bw]);
sound(downsample(recNoRF/max(abs(recNoRF)), interpFactor), baseFs); pause(maxLength/baseFs + 1);

% Exp B
off1 = 100; off2 = 1000;
recOff1 = filtfilt(lpFilt, filtfilt(ifFilt, rfOut .* cos(2*pi*(fLO+off1)*t)) .* cos(2*pi*fIF*t));
recOff2 = filtfilt(lpFilt, filtfilt(ifFilt, rfOut .* cos(2*pi*(fLO+off2)*t)) .* cos(2*pi*fIF*t));

disp('Exp B: LO Offset 0.1 kHz'); sound(downsample(recOff1/max(abs(recOff1)), interpFactor), baseFs);
pause(maxLength/baseFs + 1);
disp('Exp B: LO Offset 1.0 kHz'); sound(downsample(recOff2/max(abs(recOff2)), interpFactor), baseFs);

figure('Name','Experiment B: LO Offset');
subplot(2,1,1); plotSpectrum(recOff1, newFs, 'Offset 0.1 kHz', 'b'); xlim([-bw*1.2, bw*1.2]);
subplot(2,1,2); plotSpectrum(recOff2, newFs, 'Offset 1.0 kHz', 'b'); xlim([-bw*1.2, bw*1.2]);

%% Helper Functions
function plotSpectrum(sig, fs, txt, clr)
    N = length(sig); f = (-N/2:N/2-1)*(fs/N);
    plot(f, abs(fftshift(fft(sig)))/N, 'Color', clr);
    grid on; title(txt); xlabel('Hz'); ylabel('Mag');
end

function bw = estimateBandwidth(sig, fs)
    N = length(sig); f = (-N/2:N/2-1)*(fs/N);
    mag = abs(fftshift(fft(sig))); mag = mag / max(mag);
    idx = find(mag > 0.01);
    if isempty(idx), bw = 5000; else, bw = max(abs(f(idx))); end
end