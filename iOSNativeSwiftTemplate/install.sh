#!/bin/bash
echo "Installing npm dependencies"
npm install

echo "Installing ios pods"
pod update
