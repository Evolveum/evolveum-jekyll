#!/bin/bash

DOCSPATH="../"
DOCSDIR="docs"
MPPATH="../"
MPPREFIX="mp-"
SAMPLESPATH="../"
SAMPLESDIR="mp-samples"

for arg in "$@"; do
  shift
  case "$arg" in
    '--docs-path')   set -- "$@" '-a'   ;;
    '--docs-dir') set -- "$@" '-b'   ;;
    '--mp-path')   set -- "$@" '-c'   ;;
    '--mp-prefix')     set -- "$@" '-d'   ;;
    '--samples-path')     set -- "$@" '-e'   ;;
    '--samples-dir')     set -- "$@" '-f'   ;;
    *)          set -- "$@" "$arg" ;;
  esac
done

while getopts a:b:c:d:e:f:n:h flag
do
    case "${flag}" in
        a) DOCSPATH=${OPTARG}; CHANGED=true ;;
        b) DOCSDIR=${OPTARG}; CHANGED=true ;;
        c) MPPATH=${OPTARG}; CHANGED=true ;;
        d) MPPREFIX=${OPTARG}; CHANGED=true ;;
        e) SAMPLESPATH=${OPTARG}; CHANGED=true ;;
        f) SAMPLESDIR=${OPTARG}; CHANGED=true ;;
        h | *)
          HELP=true
          echo "script usage:"
          echo "$0 [-s value] [-n value]"
          echo "--docs-path     custom path to a docs directory. Default is ../"
          echo "--docs-dir      custom name of a docs directory. Default is \"docs\""	 
          echo "--mp-path       custom path to a midpoint directories (for documentation versioning). Default is ../"
          echo "--mp-prefix     custom prefix of midpoint directories. Name of a given midpoint directory consist from prefix + name of the midpoint branch without \"docs/\". Default is \"mp-\""
          echo "--samples-path	custom path to a midpoint samples directory. Default is ../"
          echo "--samples-dir	custom name of a midpoint samples directory. Default is mp-samples"
          ;; 
    esac
done

if [ -z $HELP ]
then

	if [ $CHANGED ]
	then
		sed -i "s#.*docsPath:.*#  docsPath: $DOCSPATH#" evolveum-jekyll-theme/_config.yml
		sed -i "s#.*docsDirName:.*#  docsDirName: $DOCSDIR#" evolveum-jekyll-theme/_config.yml
		sed -i "s#.*midpointVersionsPath:.*#  midpointVersionsPath: $MPPATH#" evolveum-jekyll-theme/_config.yml
		sed -i "s#.*midpointVersionsPrefix:.*#  midpointVersionsPrefix: $MPPREFIX#" evolveum-jekyll-theme/_config.yml
		sed -i "s#.*midpointSamplesPath:.*#  midpointSamplesPath: $SAMPLESPATH#" evolveum-jekyll-theme/_config.yml
		sed -i "s#.*midpointSamplesDir:.*#  midpointSamplesDir: $SAMPLESDIR#" evolveum-jekyll-theme/_config.yml
	fi

	VERSION=0.1.0

	cd evolveum-jekyll-plugin
	gem build evolveum-jekyll-plugin.gemspec
	gem install evolveum-jekyll-plugin-0.1.0.gem
	cd ..

	cd evolveum-jekyll-theme
	gem build evolveum-jekyll-theme.gemspec
	gem install evolveum-jekyll-theme-$VERSION.gem
	cd ..
fi