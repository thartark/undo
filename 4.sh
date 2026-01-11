#!/bin/bash

echo "Testing /scan"
curl -s -X POST http://localhost:3000/scan \
  -H "Content-Type: application/json" \
  -d '{"text":"I can’t believe you did that!"}'

echo ""
echo "Testing /rewrite"
curl -s -X POST http://localhost:3000/rewrite \
  -H "Content-Type: application/json" \
  -d '{"text":"I can’t believe you did that!"}'
