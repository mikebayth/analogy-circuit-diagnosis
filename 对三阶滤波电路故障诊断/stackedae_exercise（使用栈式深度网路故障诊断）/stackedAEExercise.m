%% CS294A/CS294W Stacked Autoencoder Exercise

%  Instructions
%  ------------
% 
%  This file contains code that helps you get started on the
%  sstacked autoencoder exercise. You will need to complete code in
%  stackedAECost.m
%  You will also need to have implemented sparseAutoencoderCost.m and 
%  softmaxCost.m from previous exercises. You will need the initializeParameters.m
%  loadMNISTImages.m, and loadMNISTLabels.m files from previous exercises.
%  
%  For the purpose of completing the assignment, you do not need to
%  change the code in this file. 
%
%%======================================================================
%% STEP 0: Here we provide the relevant parameters values that will
%  allow your sparse autoencoder to get goo d filters; you do not need to 
%  change the parameters below.
clc
clear
index=5; 
epoch = 1000;
%�ܵĸ���Ϊ(index+1)*3000
inputSize = 28 * 28; 
%�� numClasses = 10;
numClasses = (index+1); 
hiddenSizeL1 = 200;    % Layer 1 Hidden Size
hiddenSizeL2 = 200;    % Layer 2 Hidden Size
sparsityParam = 0.1;   % desired average activation of the hidden units.
                       % (This was denoted by the Greek alphabet rho, which looks like a lower-case "p",
		               %  in the lecture notes). 
lambda = 3e-3;         % weight decay parameter       
beta = 3;              % weight of sparsity penalty term       

%%======================================================================
%% STEP 1: Load data from the MNIST database
%
%  This loads our training data from the MNIST database files.
A =[];
B =[];
double b;
for i=0:index
      b = repmat(i,1,3000)';
      i =num2str(i);
      a=xlsread([i  '.xlsx']);
      A = [A a];
      B = [B;b];
end


%����һ���������������Ԫ�ؾ���a,b�Ľű�
c=randperm(3000*(index+1));    %��Ϊa,b������Ԫ�ظ�����4
for i=1:(3000*(index+1))
  mnistData(:,c(i))=A(:,i);
  mnistLabels(c(i))=B(i);
end
mnistLabels = mnistLabels';



% Load MNIST database files
%trainData = loadMNISTImages('mnist/train-images.idx3-ubyte');
%trainLabels = loadMNISTLabels('mnist/train-labels.idx1-ubyte');

% trainData = trainData(:,1:1000);
% trainLabels = trainLabels(1:1000,:);
trainData = mnistData(:,1:(3000*(index+1)*2/3));
trainLabels = mnistLabels(1:(3000*(index+1)*2/3),1);

%��trainLabels(trainLabels == 0) = 10; % Remap 0 to 10  since our labels need to start from 1
trainLabels(trainLabels == 0) = index+1;
%%======================================================================
%% STEP 2: Train the first sparse autoencoder
%  This trains the first sparse autoencoder on the unlabelled STL training
%  images.
%  If you've correctly implemented sparseAutoencoderCost.m, you don't need
%  to change anything here.


%  Randomly initialize the parameters
sae1Theta = initializeParameters(hiddenSizeL1, inputSize);

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the first layer sparse autoencoder, this layer has
%                an hidden size of "hiddenSizeL1"
%                You should store the optimal parameters in sae1OptTheta

addpath minFunc/
options.Method = 'lbfgs'; % Here, we use L-BFGS to optimize our cost
                          % function. Generally, for minFunc to work, you
                          % need a function pointer with two outputs: the
                          % function value and the gradient. In our problem,
                          % sparseAutoencoderCost.m satisfies this.
%�� options.maxIter = 400;	  % Maximum number of iterations of L-BFGS to run 
options.maxIter = epoch;
options.display = 'on';

tic
[sae1OptTheta, cost] = minFunc( @(p) sparseAutoencoderCost(p, ...
                                   inputSize, hiddenSizeL1, ...
                                   lambda, sparsityParam, ...
                                   beta, trainData), ...
                              sae1Theta, options);

toc
                  
                          
% -------------------------------------------------------------------------



%%======================================================================
%% STEP 2: Train the second sparse autoencoder
%  This trains the second sparse autoencoder on the first autoencoder
%  featurse.
%  If you've correctly implemented sparseAutoencoderCost.m, you don't need
%  to change anything here.

[sae1Features] = feedForwardAutoencoder(sae1OptTheta, hiddenSizeL1, ...
                                        inputSize, trainData);

%  Randomly initialize the parameters
sae2Theta = initializeParameters(hiddenSizeL2, hiddenSizeL1);

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the second layer sparse autoencoder, this layer has
%                an hidden size of "hiddenSizeL2" and an inputsize of
%                "hiddenSizeL1"
%
%                You should store the optimal parameters in sae2OptTheta

tic
[sae2OptTheta, cost] = minFunc( @(p) sparseAutoencoderCost(p, ...
                                   hiddenSizeL1, hiddenSizeL2, ...
                                   lambda, sparsityParam, ...
                                   beta, sae1Features), ...
                              sae2Theta, options);

toc

% -------------------------------------------------------------------------


%%======================================================================
%% STEP 3: Train the softmax classifier
%  This trains the sparse autoencoder on the second autoencoder features.
%  If you've correctly implemented softmaxCost.m, you don't need
%  to change anything here.

[sae2Features] = feedForwardAutoencoder(sae2OptTheta, hiddenSizeL2, ...
                                        hiddenSizeL1, sae1Features);

%  Randomly initialize the parameters
saeSoftmaxTheta = 0.005 * randn(hiddenSizeL2 * numClasses, 1);


%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the softmax classifier, the classifier takes in
%                input of dimension "hiddenSizeL2" corresponding to the
%                hidden layer size of the 2nd layer.
%
%                You should store the optimal parameters in saeSoftmaxOptTheta 
%
%  NOTE: If you used softmaxTrain to complete this part of the exercise,
%        set saeSoftmaxOptTheta = softmaxModel.optTheta(:);

softlambda = 1e-4
%�� softoptions.maxIter = 100;
softoptions.maxIter = epoch;
tic
softmaxModel = softmaxTrain(hiddenSizeL2, numClasses, softlambda, ...
                            sae2Features, trainLabels, softoptions);
toc
saeSoftmaxOptTheta = softmaxModel.optTheta(:);


% -------------------------------------------------------------------------



%%======================================================================
%% STEP 5: Finetune softmax model

% Implement the stackedAECost to give the combined cost of the whole model
% then run this cell.

% Initialize the stack using the parameters learned
stack = cell(2,1);
stack{1}.w = reshape(sae1OptTheta(1:hiddenSizeL1*inputSize), ...
                     hiddenSizeL1, inputSize);
stack{1}.b = sae1OptTheta(2*hiddenSizeL1*inputSize+1:2*hiddenSizeL1*inputSize+hiddenSizeL1);
stack{2}.w = reshape(sae2OptTheta(1:hiddenSizeL2*hiddenSizeL1), ...
                     hiddenSizeL2, hiddenSizeL1);
stack{2}.b = sae2OptTheta(2*hiddenSizeL2*hiddenSizeL1+1:2*hiddenSizeL2*hiddenSizeL1+hiddenSizeL2);

% Initialize the parameters for the deep model
[stackparams, netconfig] = stack2params(stack);
stackedAETheta = [ saeSoftmaxOptTheta ; stackparams ];

%% ---------------------- YOUR CODE HERE  ---------------------------------
%  Instructions: Train the deep network, hidden size here refers to the '
%                dimension of the input to the classifier, which corresponds 
%                to "hiddenSizeL2".
%
%

tic
[stackedAEOptTheta, cost] =  minFunc(@(p)stackedAECost(p,inputSize,hiddenSizeL2,...
                         numClasses, netconfig,lambda, trainData, trainLabels),...
                        stackedAETheta,options);
toc


% -------------------------------------------------------------------------
 


%%======================================================================
%% STEP 6: Test 
%  Instructions: You will need to complete the code in stackedAEPredict.m
%                before running this part of the code
%

% Get labelled test images
% Note that we apply the same kind of preprocessing as the training set
%�� testData = loadMNISTImages('mnist/t10k-images.idx3-ubyte');
%�� testLabels = loadMNISTLabels('mnist/t10k-labels.idx1-ubyte');
testData = mnistData(:,(3000*(index+1)*2/3+1):3000*(index+1));
testLabels = mnistLabels((3000*(index+1)*2/3+1):3000*(index+1),:);
%�� testLabels(testLabels == 0) = 10; % Remap 0 to 10
testLabels(testLabels == 0) = index+1;
[pred] = stackedAEPredict(stackedAETheta, inputSize, hiddenSizeL2, ...
                          numClasses, netconfig, testData);

%acc = mean(testLabels(:) == pred(:));
acc = mean(testLabels(:) == pred(:));
% acc0 = mean(testLabels(testLabels==0) == pred(testLabels==0));
% acc1 = mean(testLabels(testLabels==1) == pred(testLabels==1));
% acc2 = mean(testLabels(testLabels==2) == pred(testLabels==2));
% acc3 = mean(testLabels(testLabels==3) == pred(testLabels==3));
% acc4 = mean(testLabels(testLabels==4) == pred(testLabels==4));
fprintf('Before Finetuning Test Accuracy: %0.3f%%\n', acc * 100);
% fid = fopen('result.txt','w');
% fprintf(fid,'Before Finetuning Test Accuracy:\n');
% fprintf(fid,'acc = %f\n',acc);
% fprintf(fid,'acc0 = %f\n',acc0);
% fprintf(fid,'acc1 = %f\n',acc1);
% fprintf(fid,'acc2 = %f\n',acc2);
% fprintf(fid,'acc3 = %f\n',acc3);
% fprintf(fid,'acc4 = %f\n',acc4);
[pred] = stackedAEPredict(stackedAEOptTheta, inputSize, hiddenSizeL2, ...
                          numClasses, netconfig, testData);

%acc = mean(testLabels(:) == pred(:));
acc = mean(testLabels(:) == pred(:));
% acc0 = mean(testLabels(testLabels==0) == pred(testLabels==0));
% acc1 = mean(testLabels(testLabels==1) == pred(testLabels==1));
% acc2 = mean(testLabels(testLabels==2) == pred(testLabels==2));
% acc3 = mean(testLabels(testLabels==3) == pred(testLabels==3));
% acc4 = mean(testLabels(testLabels==4) == pred(testLabels==4));
fprintf('After Finetuning Test Accuracy: %0.3f%%\n', acc * 100);
% fprintf(fid,'After Finetuning Test Accuracy:\n');
% fprintf(fid,'acc = %f\n',acc);fprintf(fid,'acc0 = %f\n',acc0);
% fprintf(fid,'acc1 = %f\n',acc1);
% fprintf(fid,'acc2 = %f\n',acc2);
% fprintf(fid,'acc3 = %f\n',acc3);
% fprintf(fid,'acc4 = %f\n',acc4);
figure(1);
W1 = reshape(stackedAETheta(1:hiddenSizeL1 * inputSize), hiddenSizeL1, inputSize);
display_network(W1', 12);
figure(2);
W2 = reshape(stackedAEOptTheta(1:hiddenSizeL1 * inputSize), hiddenSizeL1, inputSize);
display_network(W2', 12);
load chirp ;
sound(y,Fs) 
% Accuracy is the proportion of correctly classified images
% The results for our implementation were:
%
% Before Finetuning Test Accuracy: 87.7%
% After Finetuning Test Accuracy:  97.6%
%
% If your values are too low (accuracy less than 95%), you should check 
% your code for errors, and make sure you are training on the 
% entire data set of 60000 28x28 training images 
% (unless you modified the loading code, this should be the case)
