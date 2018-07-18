#!/bin/bash -x

DIR=$PWD

ln -s $DIR/.vimrc ~/
ln -s $DIR/.tmux.conf ~/
ln -s $DIR/.gitignore ~/
cp $DIR/.gitconfig ~/
read -p "email: " EMAIL
read -p "name: " NAME
git config --global user.email "$EMAIL"
git config --global user.name "$NAME"
test -d ~/bin || mkdir ~/bin
for fn in $DIR/bin/git/*; do ln -s "$fn" ~/bin/; done
cat >> ~/.bashrc <<EOF

source $DIR/.bashrc

EOF
