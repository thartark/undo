#!/bin/bash
# setup_project.sh
echo "Setting up TextCraft Pro project structure..."

# Create main directories
mkdir -p TextCraftPro/{core,modules,scripts,assets,configs,docs}

# Create module directories
mkdir -p TextCraftPro/modules/{ai_tools,quick_actions,analytics,formatting,templates,developer,history,integrations,advanced,ui,system}

# Create manifest versions
mkdir -p TextCraftPro/configs/manifests

# Create build directories
mkdir -p TextCraftPro/builds/{v1,v2,v3,v4,complete}

# Create documentation
mkdir -p TextCraftPro/docs/{api,guides,examples}

echo "Project structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Run ./install_basic.sh to create the basic extension"
echo "2. Add modules incrementally using the numbered scripts"