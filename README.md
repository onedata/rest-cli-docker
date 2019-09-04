# rest-cli-docker

Docker with Onedata REST CLI Zsh environment

## Usage

```shell
docker run -it onedata/rest-cli
```

## Release Process

In order to release new version of rest-cli please use script `release.sh`. Example"

```shell
release.sh 19.02.1
```

To make an image public please use script `make-public.sh`:

```shell
make-public.sh # if the version tag is attached to the HEAD commit
# or
make-public.sh 19.02.1 # it not
```

To inspect all images in private and public docker repositories please run:

```shell
check-releases.sh
```
