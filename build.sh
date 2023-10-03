#!/bin/bash

VERSION=0.1.0

cd evolveum-jekyll-plugin
gem build evolveum-jekyll-plugin.gemspec
gem install evolveum-jekyll-plugin-0.1.0.gem
cd ..

cd evolveum-jekyll-theme
gem build evolveum-jekyll-theme.gemspec
gem install evolveum-jekyll-theme-$VERSION.gem
cd ..

#TODO not ideal place for this script
ruby testversioning.rb
