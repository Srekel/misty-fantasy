@REM @echo off

cls
@REM cd src

mkdir data\gen

cls

@REM external\sokol-tools-bin\bin\win32\sokol-shdc -i shaders/heightmap.glsl -o shaders/heightmap.glsl.zig -l glsl330:metal_macos:hlsl4 -f sokol_zig
external\sokol-tools-bin\bin\win32\sokol-shdc -i shaders/heightmap.glsl -o shaders/heightmap.glsl.zig -l hlsl4 -f sokol_zig

@REM zig build -Drelease-fast=true run-main
zig build run-misty
