#!/bin/bash
set -e -x -u

cd source

./gradlew clean test
