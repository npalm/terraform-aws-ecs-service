#!/bin/bash

# exit on failures
set -e
set -o pipefail

terraform fmt -check -diff
