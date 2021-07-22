IMAGENAME=siga-base
REPO=brunocasas

.PHONY: help build push all

help:
	    @echo "Makefile arguments:"
	    @echo ""
	    @echo "verssion - Image Version"
	    @echo ""
	    @echo "Makefile commands:"
	    @echo "build"
	    @echo "pull"
	    @echo "all"

.DEFAULT_GOAL := build



IMAGEFULLNAME=${REPO}/${IMAGENAME}:${verssion}

build:
	@docker build --rm -t ${IMAGEFULLNAME} .

push:
	@docker push ${IMAGEFULLNAME}
