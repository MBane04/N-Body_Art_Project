#!/bin/bash
# Installs all dependencies for N-Body Art project

# Install system packages
echo "Installing system dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install libglfw3-dev libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev libxfixes-dev libgl1-mesa-dev libglu1-mesa-dev libsoil-dev
sudo apt install git wget python3 python3-pip -y
sudo apt install mesa-utils -y
sudo apt install freeglut3-dev -y
sudo apt install libglfw3-dev -y
sudo apt install nvidia-cuda-toolkit -y
sudo apt install build-essential -y
sudo apt install ffmpeg -y

# Create directories if they don't exist
mkdir -p src/imgui
mkdir -p include/glad

# Download ImGui
echo "Setting up ImGui..."
cd src/imgui
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui_demo.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui_draw.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui_tables.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui_widgets.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imgui_internal.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imstb_rectpack.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imstb_textedit.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/imstb_truetype.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/backends/imgui_impl_glfw.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/backends/imgui_impl_glfw.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/backends/imgui_impl_opengl3.cpp
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/backends/imgui_impl_opengl3.h
wget -nc https://raw.githubusercontent.com/ocornut/imgui/master/backends/imgui_impl_opengl3_loader.h

# Return to project root
cd ../..

# Download and set up GLAD (OpenGL loader) No idea how to automate this but at least only needs to be done once by us for the user
# https://glad.dav1d.de/ to generate glad.zip file
#extract include folder from glad.zip and place it in include/glad
#extract src folder from glad.zip and place it in src/glad
echo "GLAD setup required. Please download glad.zip from https://glad.dav1d.de/ and extract the include and src folders to the project directory."
echo "Dependencies installation completed!"
echo "You may need to add #include paths to your project:"
echo "- For ImGui: #include \"imgui/imgui.h\""
echo "- For GLAD: #include \"glad/glad.h\""