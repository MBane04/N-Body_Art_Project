#include "./header.h"

// File pointers
FILE* ffmpeg = NULL;
FILE* MovieFile = NULL;

// Simulation parameters
int NumberOfInitBodies = 0;
float TotalRunTime = 10000.0;
float Dt = 0.002;
float G = 0.03;
float H = 0.00001;
float Epsilon = 0.01;
float MassOfBody = 1.0;
float DiameterOfBody = 0.2;
float VelocityMax = 10.0;
float Drag = 0.001;
int DrawRate = 8;
int PrintRate = 100;

// Runtime variables
int Pause = 0;
int DrawTimer = 0;
int PrintTimer = 0;
float RunTime = 0.0;
int* Buffer = NULL;
int MovieOn = 0;
int MovieFlag = 0;
int Trace = 0;
float MouseX = 0.0, MouseY = 0.0, MouseZ = 0.0;
float newBodyRadius = 0.1;
int DrawLayer = 0;
GLuint backgroundTexture = 0;
float circleCenterX = 0.0;
float circleCenterY = 0.0;
float currentOscillationAmplitude = 0.0;
float currentOscillationAngle = 0.0;
float initialMouseX = 0.0, initialMouseY = 0.0;

// Window settings
int Window = 0;
int XWindowSize = 3000;
int YWindowSize = 1500;
double Near = 0.2;
double Far = 30.0;
double EyeX = 0.0;
double EyeY = 0.0;
double EyeZ = 2.0;
double CenterX = 0.0;
double CenterY = 0.0;
double CenterZ = 0.0;
double UpX = 0.0;
double UpY = 1.0;
double UpZ = 0.0;

// Body management
Body* bodies = NULL;
int numBodies = 0;
int capacity = INITIAL_CAPACITY;

// UI state
int NewBodyToggle = 0;
bool isOrthogonal = true;
int PreviousRunToggle = 1;
string PreviousRunFile = "awesomepicture";
int ColorToggle = 0;
int HotkeyPrint = 0;
int NewBodyMovement = 0;
bool NewBodySolid = true;
bool IsDragging = false;
bool GridOn = true;
bool EraseMode = false;
int BackgroundToggle = 1;
bool selectCircleCenter = false;

// Color definitions
Colors colors = {
    {49.0/255.0, 39.0/255.0, 96.0/255.0, 1.0},    // paris_m
    {228.0/255.0, 219.0/255.0, 85.0/255.0, 1.0},  // manz
    {65.0/255.0, 74.0/255.0, 76.0/255.0, 1.0},    // outer_space
    {21.18/255.0, 44.31/255.0, 77.65/255.0, 1.0}, // curious_blue
    {93.0/255.0, 94.0/255.0, 78.0/255.0, 1.0},    // tahuna_sands
    {49.0/255.0, 42.0/255.0, 41.0/255.0, 1.0},    // livid_brown
    {49.0/255.0, 72.0/255.0, 73.0/255.0, 1.0},    // neptune
    {50.0/255.0, 100.0/255.0, 150.0/255.0, 1.0},  // lochmara
    {14.0/255.0, 54.0/255.0, 87.0/255.0, 1.0},    // regal_blue
    {249.0/255.0, 228.0/255.0, 150.0/255.0, 1.0}, // vis_vis
    {15.0/255.0, 59.0/255.0, 82.0/255.0, 1.0},    // light_curious_blue
    {40.0/255.0, 40.0/255.0, 38.0/255.0, 1.0},    // ironside_grey
    {244.0/255.0, 179.0/255.0, 5.0/255.0, 1.0},   // yellow
    {198.0/255.0, 202.0/255.0, 116.0/255.0, 1.0}, // deco
    {42.0/255.0, 75.0/255.0, 124.0/255.0, 1.0},   // astronaut_blue
    {240.0/255.0, 98.0/255.0, 16.0/255.0, 1.0},   // bright_orange
};