.PHONY: help sagemaker-torch sagemaker-tf clean

help:
	@echo "Usage:"
	@echo "  make sagemaker-torch   # build torch SageMaker image (optionally push to ECR)"
	@echo "  make sagemaker-tf      # build tf SageMaker image"
	@echo "  make clean             # remove marker files"

NAME                ?= myapp
PROXY_ARGS          ?=
SRC_FILES           := $(shell find src/ -type f)
BUILDER_IMAGE       ?= builder:latest
TF_BUILDER_IMAGE    ?= builder-tf:latest
SAGEMAKER_IMAGE     ?= $(NAME):sagemaker-torch
TF_SAGEMAKER_IMAGE  ?= $(NAME):sagemaker-tf

AWS_ACCOUNT_ID      ?=
AWS_REGION          ?=
ECR_REPO_TORCH      ?=
ECR_REPO_TF         ?=
ECR_PUSH            ?= false

MARKER_TORCH        := .sagemaker-torch.done
MARKER_TF           := .sagemaker-tf.done

sagemaker-torch: $(MARKER_TORCH)
$(MARKER_TORCH): hack/docker/Dockerfile.sagemaker hack/docker/entrypoint.sh.builder $(SRC_FILES)
	@echo "Building SageMaker Torch image..."
	@NAME=$(NAME) BUILDER_IMAGE=$(BUILDER_IMAGE) IMAGE_TAG=$(SAGEMAKER_IMAGE) DOCKERFILE=hack/docker/Dockerfile.sagemaker CONTEXT=hack/docker AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) AWS_REGION=$(AWS_REGION) ECR_REPO=$(ECR_REPO_TORCH) ECR_PUSH=$(ECR_PUSH) PROXY_ARGS="$(PROXY_ARGS)" ./build-image.sh
	@touch $@

sagemaker-tf: $(MARKER_TF)
$(MARKER_TF): hack/docker/Dockerfile.sagemaker-tf hack/docker/entrypoint.sh.builder-tf $(SRC_FILES)
	@echo "Building SageMaker TF image..."
	@NAME=$(NAME) BUILDER_IMAGE=$(TF_BUILDER_IMAGE) IMAGE_TAG=$(TF_SAGEMAKER_IMAGE) DOCKERFILE=hack/docker/Dockerfile.sagemaker-tf CONTEXT=hack/docker AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) AWS_REGION=$(AWS_REGION) ECR_REPO=$(ECR_REPO_TF) ECR_PUSH=$(ECR_PUSH) PROXY_ARGS="$(PROXY_ARGS)" ./build-image.sh
	@touch $@

clean:
	@echo "Cleaning marker files..."
	@rm -f $(MARKER_TORCH) $(MARKER_TF)
