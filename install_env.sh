#!/bin/bash

chmod +x ./init/*
chmod +x ./utils/*

scripts=`ls ./init`
for script in $scripts
do
    $script
done