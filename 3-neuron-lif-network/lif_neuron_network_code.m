%% 3-Neuron Leaky Integrate-and-Fire (LIF) Network
% Simple time-stepped LIF simulation with recurrent synapses and Hebbian learning.

clear; clc; close all;

%% Parameters
N = 3;
T = 500;                  % ms
dt = 0.1;                 % ms
time = 0:dt:T;
nSteps = numel(time);

% Membrane parameters
tau_m = 20;               % ms
V_rest = -65;             % mV
V_reset = -70;            % mV
V_th = -50;               % mV

% Synapse/input parameters
tau_syn = 10;             % ms
I_ext = [10.5; 15.0; 17.5];
I_osc_amp = [0.20; 0.10; 0.15];
I_osc_freq = [8; 5; 7];   % Hz

% Connectivity: W(post, pre)
W = [0.00,  0.60, -1.00;
     0.50,  0.00, -0.90;
     0.40,  0.35,  0.00];

% Hebbian learning (always enabled)
eta = 0.015;
traceTau = 30;            % ms
weightDecay = 0.0003;
W_max_exc = 1.5;
W_min_inh = -1.5;

%% State Initialization
V = V_rest * ones(N,1);
s = zeros(N,1);
preTrace = zeros(N,1);

V_hist = zeros(N, nSteps);
spikes = zeros(N, nSteps);
W_hist = zeros(N, N, nSteps);

V_hist(:,1) = V;
W_hist(:,:,1) = W;

%% Simulation Loop (Euler method)
for k = 2:nSteps
    % External drive: baseline + small oscillation
    I_t = I_ext + I_osc_amp .* sin(2*pi*I_osc_freq*(time(k)/1000));

    % LIF membrane ODE:
    % dV/dt = (-(V - V_rest) + I_t + W*s)/tau_m
    V = V + dt * (-(V - V_rest) + I_t + W*s) / tau_m;
    V_for_plot = V;  % keep pre-reset value so threshold crossing is visible

    % Spike + reset
    fired = V >= V_th;
    spikes(:,k) = fired;
    V(fired) = V_reset;

    % Synaptic activity and presynaptic trace (both decay + spike jump)
    s = s + dt * (-s / tau_syn);
    s(fired) = s(fired) + 1;

    preTrace = preTrace + dt * (-preTrace / traceTau);
    preTrace(fired) = preTrace(fired) + 1;

    % Hebbian update: strengthen when post spikes and pre was recently active
    W = W + eta * (spikes(:,k) * preTrace') - weightDecay * W;

    % Keep excitatory/inhibitory sign constraints
    W(:, 1:2) = min(max(W(:, 1:2), 0), W_max_exc);  % presynaptic neurons 1,2 are excitatory
    W(:, 3) = max(min(W(:, 3), 0), W_min_inh);      % presynaptic neuron 3 is inhibitory

    % No self-connections
    W(1:N+1:end) = 0;

    V_hist(:,k) = V_for_plot;
    W_hist(:,:,k) = W;
end

%% Plot 1: Membrane Potentials
figure('Name','Membrane Potentials','Color','w');
plot(time, V_hist(1,:), 'LineWidth', 1.3); hold on;
plot(time, V_hist(2,:), 'LineWidth', 1.3);
plot(time, V_hist(3,:), 'LineWidth', 1.3);
yline(V_th, '--k', 'Threshold', 'LineWidth', 1.0);
xlabel('Time (ms)');
ylabel('Membrane Potential V (mV)');
title('3-Neuron LIF Network: Membrane Potentials');
legend({'Neuron 1','Neuron 2','Neuron 3','Threshold'}, 'Location','best');
ylim([V_reset -45]);
grid on;

%% Plot 2: Spike Raster
figure('Name','Spike Raster','Color','w');
hold on;
for i = 1:N
    spikeTimes = time(spikes(i,:) == 1);
    plot(spikeTimes, i*ones(size(spikeTimes)), 'k.', 'MarkerSize', 10);
end
xlabel('Time (ms)');
ylabel('Neuron Index');
title('Spike Raster Plot');
yticks(1:N);
ylim([0.5, N+0.5]);
grid on;

%% Plot 3: Weight Evolution
figure('Name','Synaptic Weights Over Time','Color','w');
hold on;
plot(time, squeeze(W_hist(1,2,:)), '-',  'LineWidth', 1.2);
plot(time, squeeze(W_hist(1,3,:)), '--', 'LineWidth', 1.2);
plot(time, squeeze(W_hist(2,1,:)), ':',  'LineWidth', 1.2);
plot(time, squeeze(W_hist(2,3,:)), '-.', 'LineWidth', 1.2);
plot(time, squeeze(W_hist(3,1,:)), '-',  'LineWidth', 1.2);
plot(time, squeeze(W_hist(3,2,:)), '--', 'LineWidth', 1.2);

xlabel('Time (ms)');
ylabel('Weight Value');
title('Synaptic Weight Evolution (Hebbian Learning Enabled)');
legend({'W(1 <- 2)','W(1 <- 3)','W(2 <- 1)','W(2 <- 3)','W(3 <- 1)','W(3 <- 2)'}, 'Location','eastoutside');
grid on;
