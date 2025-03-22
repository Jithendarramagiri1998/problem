#!/bin/bash

# Run OWASP ZAP DAST
echo "Running OWASP ZAP DAST..."
zap-baseline.py -c zap/zap-config.yaml
echo "OWASP ZAP DAST completed!"
