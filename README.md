## Amazon Elastic Inference with Amazon EKS

This repository contains resources demonstrating how to use Amazon Elastic Inference (EI) and Amazon EKS together to deliver a cost optimized, scalable solution for performing inference on video frames. More specifically, the solution herein runs containers in Amazon EKS that read a video from Amazon S3, preprocess its frames, then send the frames for object detection to a TensorFlow Serving container modified to work with Amazon EI. This computationally intensive use case showcases the advantages of using Amazon EI and Amazon EKS together to achieve accelerated inference at low cost within a scalable, containerized architecture. 


## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
