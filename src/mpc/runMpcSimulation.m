% runMpcSimulation  Run one closed-loop MPC experiment and plot the result.

clc; close all;
setupProject();

runMpcExperimentCore(true);
