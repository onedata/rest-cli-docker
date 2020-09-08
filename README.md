# rest-cli-docker

Docker with Onedata REST CLI

## Usage

```shell
docker run -it onedata/rest-cli
```

## Release Process

**Releases are done automatically using the onedata-release-assistant.**

If you wish to create a new release manually anyway, use the script `release.sh`:

```shell
./release.sh 19.02.1
```

## Publishing a release

To make an image public please use script `make-public.sh`:

```shell
./make-public.sh # if the version tag is attached to the HEAD commit
# or
./make-public.sh 19.02.1 # it not
```

To inspect all images in private and public docker repositories please run:

```shell
./check-releases.sh
```
