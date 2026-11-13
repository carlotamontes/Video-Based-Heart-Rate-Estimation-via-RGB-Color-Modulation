%%CODIGO COM VIDEO CARLOTA 
clc;
clear;
close all;
% --- Paths (added during reorganization; resolves data/models relative to this project) ---
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'third_party', 'dlib-matlab'));


% Caminho do vídeo
videoPath = fullfile(projectRoot, 'data', 'videos', 'subject_6.avi');

data = readmatrix(fullfile(projectRoot, 'data', 'ground_truth', 'ground_truth6.txt'));

hr_gt = data(1, :);
time_gt = data(2, :);

% Leitura do vídeo
video = VideoReader(videoPath);

firstFrame = readFrame(video);
video.CurrentTime = 0; 

debug=0;

% Inicializar o detector de face e landmarks
d = detector('new', fullfile(projectRoot, 'models', 'shape_predictor_68_face_landmarks.dat'));

% Inicializar arrays para armazenar valores RGB médios
r_vals = [];
g_vals = [];
b_vals = [];
timestamps = [];
HR = [];
HR_timestamps = [];
RR_all=[];
all_H = [];              
all_pulse_filtered = [];  
all_h = []; 
frame_count = 0;
fs = 30;
l = 1.6*fs;

figure;
subplot(2,1,1);
h1 = plot(nan, nan, 'b'); % pulse_filtered
title('Sinal de Pulso (Filtrado) em Tempo Real');
xlabel('Tempo [s]');
ylabel('Amplitude');
grid on;
hold on;

subplot(2,1,2);
h2 = plot(nan, nan, 'r');  % novo stairs
title('Frequência Cardíaca Estimada');
xlabel('Tempo [s]');
ylabel('HR [BPM]');
grid on;
hold on;

t=[];
even_all_HR=[];
HR_est_prev=0;

while hasFrame(video)
    frame = readFrame(video);
    frame_count = frame_count + 1;  % Incrementa o contador de frames
    grayFrame = rgb2gray(frame);
    t_prev=t;
    t=[t;video.CurrentTime];
    % Detectar rostos no frame
    faces = detector('detect', d, frame);
    if isempty(faces)
        continue; 
    end

    % Obter landmarks faciais
    landmarks = detector('fit', d, frame, faces(1, :));
    
    % Criar máscara da ROI (Testa, Nariz, Bochechas)
    rows = size(frame, 1);
    cols = size(frame, 2);    
    
    % Criar máscara da testa (com retângulo para expandir)
    forehead_offset = 20; % Ajustar altura do retângulo da testa
    forehead_width = landmarks(22,1) - landmarks(8,1) + 70; % Largura baseada nos landmarks da testa
    forehead_rect_x = landmarks(8,1) - 25; % Início do retângulo na lateral esquerda
    forehead_rect_y = landmarks(26,2) - forehead_offset - 25; % Início do retângulo (mais acima)

    mask_forehead = poly2mask([forehead_rect_x, forehead_rect_x + forehead_width, ...
                               forehead_rect_x + forehead_width, forehead_rect_x], ...
                              [forehead_rect_y, forehead_rect_y, ...
                               landmarks(20,2), landmarks(20,2)], ...
                              rows, cols);

    % Máscara do nariz
    nose_offset_up = 35;  % Ajuste para subir mais a máscara
    nose_offset_sides = 5; % Ajuste para expandir ligeiramente a largura
    nose_offset_down = 10;  % Ajustar a parte inferior para manter formato retangular

    % Expandir a máscara do nariz para cima, englobando mais área
    nose_points  = [landmarks(29, 1) - nose_offset_sides, landmarks(29, 2) - nose_offset_up;  % Canto superior esquerdo
                 landmarks(29, 1) + nose_offset_sides, landmarks(29, 2) - nose_offset_up;  % Canto superior direito
                 landmarks(33, 1) + nose_offset_sides, landmarks(33, 2) + nose_offset_down; % Canto inferior direito
                 landmarks(33, 1) - nose_offset_sides, landmarks(33, 2) + nose_offset_down]; % Canto inferior esquerdo
    
    mask_nose = poly2mask(nose_points(:,1), nose_points(:,2), rows, cols);

    % Máscara das bochechas
    cheek_offset = -10;  % Ajustar conforme necessário
    cheek_down = 10;  
    center_down = 10; % Baixar mais o ponto do meio para suavizar o "bico"


        % Definir pontos da bochecha esquerda
    cheek_left = [landmarks(2, 1) - cheek_offset, landmarks(2, 2) + cheek_down;
                  landmarks(3, 1) + 7 , landmarks(3, 2) + cheek_down - 2;
                  landmarks(5, 1) + 7 , landmarks(5, 2) + cheek_down - 2;
                  landmarks(31, 1) , landmarks(31, 2) + center_down];
    
    % Definir pontos da bochecha direita
    cheek_right = [landmarks(16, 1) + cheek_offset, landmarks(16, 2) + cheek_down;
                   landmarks(15, 1) - 7, landmarks(15, 2) + cheek_down - 2 ;
                   landmarks(13, 1) - 7, landmarks(13, 2) + cheek_down - 2 ;
                   landmarks(35, 1), landmarks(35, 2) + center_down];

    mask_cheeks = poly2mask([cheek_left(:, 1); flipud(cheek_right(:, 1))], ...
                            [cheek_left(:, 2); flipud(cheek_right(:, 2))], ...
                            rows, cols);

    % Criar máscara completa do rosto
    mask_face = mask_forehead | mask_cheeks | mask_nose;

   
    % Extrair valores RGB médios da ROI
    roi_masked = bsxfun(@times, frame, cast(mask_face, 'like', frame));
    r_vals = [r_vals; mean(roi_masked(:,:,1), 'all', 'omitnan')];
    g_vals = [g_vals; mean(roi_masked(:,:,2), 'all', 'omitnan')];
    b_vals = [b_vals; mean(roi_masked(:,:,3), 'all', 'omitnan')];
    
      
     % Aplicar Método POS com nova normalização
    if length(r_vals) > 47
      
            C = [r_vals, g_vals, b_vals]';
    
            if length(r_vals)==48
                mu=mean(C,2);
                mu_prev=mu;
            else
                mu = ((l-1)/l)*mu_prev + (1/l)*mean(C(:,end-47:end), 2);
                mu_prev = mu;
            end
    
            % *3) Normalização Temporal corrigida
            Cn = diag(1 ./ mu) * C(:, end-47:end);
    
            % *4) Projeção Ortogonal à Pele
            P = [0 1 -1; -2 1 1];
            S = P * Cn;
    
            if length(r_vals)==48
                mu_s=mean(S,2);
                mu_s_prev=mu_s;
                delta_s = S - mu_s;
                sigma_sq = (1/l) * (delta_s.^2);
                sigma_sq_prev = sigma_sq;
            else
                mu_s = ((l-1)/l) * mu_s_prev + (1/l) * mean(S, 2);
                mu_s_prev = mu_s;
                delta_s = S - mu_s;
                sigma_sq = ((l-1)/l) * sigma_sq_prev + (1/l) * (delta_s.^2);
                sigma_sq_prev = sigma_sq;
            end
            
            alpha = sqrt(sigma_sq(1) / sigma_sq(2));
            %h = S(1, :)/std(S(1, :)) + S(2, :)/std(S(2, :));
            h = S(1, :) + alpha*S(2, :);
    
            if exist('h', 'var') && isempty(all_h)
                all_h = [all_h, h];
            else
                all_h = [all_h, h(end)];
            end
     
            % 6b) Normalização de h
            H = (h - mean(h)) / std(h);
    
           if exist('H', 'var') && isempty(all_H)
                all_H = [all_H, H];
           else
                all_H = [all_H,H(end)];
           end
    
             
           [b, a] = butter(2, [0.8 2.5] / (fs / 2), 'bandpass');
           pulse_filtered = filtfilt(b, a, H);
    
           if exist('all_pulse_filtered', 'var') && isempty(all_pulse_filtered)
                all_pulse_filtered = [all_pulse_filtered, pulse_filtered];
           else
                all_pulse_filtered = [all_pulse_filtered,pulse_filtered(end)];
           end
           
           tempo_grafico = (0:length(all_H)-1)/fs;
           set(h1, 'XData', tempo_grafico, 'YData', all_pulse_filtered);

           [pks, locs] = findpeaks(all_pulse_filtered, 'MinPeakHeight', 0, 'MinPeakDistance', fs*0.4);
           
           debug_prev=debug;
           debug=length(locs);

           if length(locs) > 1 && debug>debug_prev 
           ultimo_pico = locs(end);
           tempo_ultimo_pico = tempo_grafico(ultimo_pico);
    
           if isempty(HR_timestamps) || length(t)>length(t_prev)
                if length(locs) >= 16
                    picos_recentes = locs(end-14:end);
                else
                    picos_recentes = locs;
                end
        
                
                tempos_recentes = tempo_grafico(picos_recentes);
        
                
                RR = diff(tempos_recentes);
                RR_all=[RR_all,RR(end)];
               
                HR_est = mean(60 ./ RR);
                HR_est_prev = HR_est;
                
            
                HR = [HR; HR_est];
                HR_timestamps = [HR_timestamps; tempos_recentes(end)];
                
                even_all_HR=[even_all_HR;HR_est];
           end
           else
               if length(locs) > 1
                   even_all_HR=[even_all_HR;HR_est_prev]; 
               end
        end

% Atualiza o gráfico
set(h2, 'XData', HR_timestamps, 'YData', HR);
drawnow limitrate;

    end

end

even_all_hr_gt = interp1(time_gt,hr_gt, t, 'previous', 'extrap');
even_all_hr_gt(isnan(even_all_hr_gt)) = hr_gt(1);

figure;

% 1. Raw POS signal (h)
subplot(2, 1, 1);
plot(tempo_grafico,all_h, 'Color', [0.1 0.5 0.9]);
title('Raw Pulse Signal (POS Output) — h(n)');
ylabel('Amplitude');
legend('Raw Pulse Signal');
grid on;

% 3. Filtrado passa-banda
subplot(2, 1, 2);
plot(tempo_grafico,all_pulse_filtered, 'Color', [0.5 0 0.9]);
title('Bandpass Filtered Pulse Signal');
ylabel('Amplitude');
legend('Filtered Pulse Signal');
grid on;

% 4. Picos detetados na última janela
figure
plot(tempo_grafico, all_pulse_filtered, 'b');
hold on;
plot(tempo_grafico(locs), all_pulse_filtered(locs), 'ro', 'MarkerFaceColor', 'none');
hold on;
title('Final Pulse Signal with Detected Peaks');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Pulse Signal', 'Detected Peaks');
grid on;


figure
plot(t(length(t)-length(even_all_HR)+1:end), even_all_hr_gt((length(t)-length(even_all_HR)+1:end)), 'b');
hold on;
stairs(t(length(t)-length(even_all_HR)+1:end), even_all_HR, 'green');
hold on;
xlabel('Time (s)');
ylabel('HR (bpm)');
title('Estimated Cardiac Frequency (POS) compared to Ground Truth''s HR');
legend('HR Ground Truth', 'HR Detected');
grid on;

% Dados para avaliarmos

erro_absoluto_gt_n = abs(even_all_HR - even_all_hr_gt(length(t)-length(even_all_HR)+1:end));
media_erro = mean(erro_absoluto_gt_n);
std_erro = std(erro_absoluto_gt_n);

fprintf('Erro absoluto médio HR Ground Truth: %.2f BPM\n', media_erro);
fprintf('Desvio padrão HR Ground Truth: %.2f BPM\n', std_erro);


