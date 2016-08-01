% Initialization
clear ; close all ; clc

% Param setup
input_layer_size  = 12;  % 12 X params
hidden_layer_size = 25;   % 25 hidden units
num_labels = 9;          % 9 possible values of y

load_data;

Theta1 = rand(hidden_layer_size, input_layer_size+1)-0.5;
Theta2 = rand(num_labels, hidden_layer_size+1)-0.5;

nn_params = [Theta1(:) ; Theta2(:)];

lambda = 0.01;

J = nnCostFunction(nn_params, input_layer_size, hidden_layer_size, ...
                   num_labels, X, y, lambda)
                   
initial_Theta1 = randInitializeWeights(input_layer_size, hidden_layer_size);
initial_Theta2 = randInitializeWeights(hidden_layer_size, num_labels);

initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];

options = optimset('MaxIter', 500);

lambda = 0.01;

costFunction = @(p) nnCostFunction(p, ...
                                   input_layer_size, ...
                                   hidden_layer_size, ...
                                   num_labels, X, y, lambda);

[nn_params, cost] = fmincg(costFunction, initial_nn_params, options);

Theta1 = reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                 hidden_layer_size, (input_layer_size + 1));
                 
Theta2 = reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                 num_labels, (hidden_layer_size + 1)); 
                 
pred = predict(Theta1, Theta2, X);

fprintf('\nTraining Set Accuracy: %f\n', mean(double(pred == y)) * 100);
                 
                               