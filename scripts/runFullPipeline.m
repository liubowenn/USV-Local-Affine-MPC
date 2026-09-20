% runFullPipeline  Run the configured model-learning workflow.

clc; clear; close all;
setupProject();

cfg = defaultExperimentConfig();
runModelExperiment(cfg);
fprintf('\n=== Pipeline Complete ===\n');
