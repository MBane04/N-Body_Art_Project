#ifndef HEADER_H
#define HEADER_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <cuda.h>
#include <signal.h>
#include <cmath>
#include <SOIL/SOIL.h>

using namespace std;

// defines for terminal stuff.
#define BOLD_ON  "\e[1m"
#define BOLD_OFF   "\e[m"
#define INITIAL_CAPACITY 100

// Structure definitions
typedef struct //stores information for each body
{
    int id;
    bool isSolid;
    float4 color;
    int movement; //preconfigured movement pattern
    float4 pos;
    float4 vel;
    float4 force;
    float radius;
    float initialX; //store the initial x position for sinusoidal movement
    float initialY; //store the initial y position for sinusoidal movement
    float4 circle; //(x,y) of the center of the circle for circular movement, z is initial angle, w is orbital radius
    float oscillationAmplitude; //amplitude of the oscillation for sinusoidal movement  
    float oscillationAngle; // Angle of the oscillation in radians
} Body;

typedef struct //stores colors for Starry night
{
    float4 paris_m;
    float4 manz;
    float4 outer_space;
    float4 curious_blue;
    float4 tahuna_sands;
    float4 livid_brown;
    float4 neptune;
    float4 lochmara;
    float4 regal_blue;
    float4 vis_vis;
    float4 light_curious_blue;
    float4 ironside_grey;
    float4 yellow;
    float4 deco;
    float4 astronaut_blue;
    float4 bright_orange;
} Colors;

// File pointers
extern FILE* ffmpeg;
extern FILE* MovieFile;

// Simulation parameters
extern int NumberOfInitBodies;
extern float TotalRunTime;
extern float Dt;
extern float G;
extern float H;
extern float Epsilon;
extern float MassOfBody;
extern float DiameterOfBody;
extern float VelocityMax;
extern float Drag;
extern int DrawRate;
extern int PrintRate;

// Runtime variables
extern int Pause;
extern int DrawTimer;
extern int PrintTimer;
extern float RunTime;
extern int* Buffer;
extern int MovieOn;
extern int MovieFlag;
extern int Trace;
extern float MouseX, MouseY, MouseZ;
extern float newBodyRadius;
extern int DrawLayer;
extern GLuint backgroundTexture;
extern float circleCenterX;
extern float circleCenterY;
extern float currentOscillationAmplitude;
extern float currentOscillationAngle;
extern float initialMouseX, initialMouseY;

// Window settings
extern int Window;
extern int XWindowSize;
extern int YWindowSize;
extern double Near;
extern double Far;
extern double EyeX;
extern double EyeY;
extern double EyeZ;
extern double CenterX;
extern double CenterY;
extern double CenterZ;
extern double UpX;
extern double UpY;
extern double UpZ;

// Body management
extern Body* bodies;
extern int numBodies;
extern int capacity;

// Colors
extern Colors colors;

// UI state
extern int NewBodyToggle;
extern bool isOrthogonal;
extern int PreviousRunToggle;
extern string PreviousRunFile;
extern int ColorToggle;
extern int HotkeyPrint;
extern int NewBodyMovement;
extern bool NewBodySolid;
extern bool IsDragging;
extern bool GridOn;
extern bool EraseMode;
extern int BackgroundToggle;
extern bool selectCircleCenter;

// Function prototypes

float4 getColor(const char* colorName);
void screenToWorld(int x, int y, float* worldX, float* worldY);
void addBody(Body newBody);
void addBodyAtPosition(float x, float y);
void removeBodyAtPosition(float x, float y);
void freeBodies();

void idle();
void reshape(int w, int h);
void keyPressed(unsigned char key, int x, int y);
void mousePassiveMotionCallback(int x, int y);
void myMouse(int button, int state, int x, int y);
string getTimeStamp();
void handle_sigpipe(int sig);
void movieOn();
void movieOff();
void screenShot();

void readBodiesFromFile(const char* filename);
void writeBodiesToFile(const char* filename);
void loadBackgroundImage(const char* filename);

float4 centerOfMass();
float4 linearVelocity();
void zeroOutSystem();
void getForces(Body* bodies, float mass, float G, float H, float Epsilon, float drag, float dt, int n);
void nBody();

void drawPicture();
void drawGrid(float spacing, int numLines);
void display();
void renderBackground();
void terminalPrint();

void setSimulationParameters();
void allocateMemory();
void setInitialConditions();
void setup();











// void setSimulationParameters();
// void allocateMemory();
// void setInitialConditions();
// void drawPicture();
// void nBody();
// void errorCheck(const char*);
// void terminalPrint();
// void setup();
// void movieOn();
// void movieOff();
// void screenShot();
// float4 centerOfMass();
// float4 linearVelocity();
// void zeroOutSystem();
// void addBody(Body newBody);
// void loadBackgroundImage(const char* filename);
// void readBodiesFromFile(const char* filename);
// void writeBodiesToFile(const char* filename);
// void removeBodyAtPosition(float x, float y);
// void addBodyAtPosition(float x, float y);
// void screenToWorld(int x, int y, float* worldX, float* worldY);
// float4 getColor(const char* colorName);
// void freeBodies();

#endif // HEADER_H