# First Project Group 3

## Project: Image Classification and Deployment with Fastai and Hugging Face Space

## Overview:
In this project, students will create an image classification model using artificial neural networks with the Fastai package. They will then deploy this model as a web service using Hugging Face Spaces or an alternative free deployment solution of their choice.

Reference: https://course.fast.ai/Lessons/lesson2.html

## 1. Data Preparation
Choose a dataset for image classification.
Preprocess and load the dataset using Fastai's data loading functions.
If you want, create a baseline classification model to try to identify images that need a clean-up.

<i><b>In our project:</b><br/>
We used guitar images classificated as Stratocaster, Les Paul and Flying V. We got 150 images from each type. Images were taken from Bing.<br/>
We searched for similar projects and we found one in Kaggle which identifies other types of Fender guitars. In this model some different keywords were used in search, like 'full body guitar' and 'full view guitar', adding to the type.<br/>
We tested these keywords in our model but, at least with the results from Bing, it didn't work well, so we kept using just guitar + type.<br/>
We started our searches with 4 types (Stratocaster, Les Paul, Telecaster and Flying V), but we decided to cut Telecaster because its pretty similar to Stratocaster and we wouldn't have time to work on it.</i>

## 2. Model Building
Create an artificial neural network for image classification using the Fastai library.
Train and fine-tune the model using the prepared dataset. Choose a pre-trained model for the fine-tune / transfer learning and then train it using your problem's dataset.

<i><b>In our project:</b><br/>
We trained our model using different values for fine tuning and also different resnet values to test and compare the different results.</i>

## 3. Model Evaluation
Evaluate the model's performance using appropriate metrics (e.g., accuracy, precision, recall).
Plot the confusion matrix for your trained model.

<i><b>In our project:</b><br/>
We tested with resnet18, resnet34 and resnet50, with a different combination of fine-tuning values from 2 to 8 and we compared the error rate values and the confusion matrix to get the best performance.</i>

## 4. Model Export
Export the trained model in a format compatible with Hugging Face Transformers (e.g., PKL, PyTorch, ONNX).

<i><b>In our project:</b><br/>
We exported a .pkl file from our Google Colab notebook.</i>


## 5. Hugging Face Spaces Setup
Sign in to Hugging Face and set up a new Space for your project.
## 6. Model Deployment on Hugging Face Space
Upload the trained model to your Hugging Face Space.
Create a web page or API endpoint to serve the model using the Hugging Face Space's built-in features.

<i><b>In our project:</b><br/>
Model deployment available at:<br/>
https://huggingface.co/spaces/sahviola/guitar-classifier<br/>
In the deployed model on HuggingFace, we can upload an image and check if the model can classify it properly according to the guitar type considering the three ones we have used (Stratocaster, Les Paul and Flying V).</i>

## 7. Testing and Documentation
Test the deployed model using sample images or data.
Document the project, including a brief description, model performance, and deployment instructions.

## 8. Share and Collaborate
Share the project with peers on our GitHub.
Encourage collaboration and feedback from others.