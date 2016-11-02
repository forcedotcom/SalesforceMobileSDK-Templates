#!/bin/bash
echo "Installing npm dependencies"
npm install

echo "Installing ios dependencies"
cd ios
pod update
cd ..
