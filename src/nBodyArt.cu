// nvcc nBodyArtB.cu -o nBodyArt -lglut -lm -lGLU -lGL																																							
//To stop hit "control c" in the window you launched it from.
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
using namespace std;

FILE* ffmpeg;


// defines for terminal stuff.
#define BOLD_ON  "\e[1m"
#define BOLD_OFF   "\e[m"
#define INITIAL_CAPACITY 100

FILE* MovieFile;

// Globals
int NumberOfInitBodies;
float TotalRunTime;
float Dt;
float G;
float H;
float Epsilon;
float MassOfBody;
float DiameterOfBody;
float VelocityMax;
float Drag;
int DrawRate;
int PrintRate;

// Other Globals
int Pause;
//float *BodyPositionX, *BodyPositionY, *BodyPositionZ;
//float *BodyVelocityX, *BodyVelocityY, *BodyVelocityZ;
//float *BodyForceX, *BodyForceY, *BodyForceZ;
//float *BodyColorX, *BodyColorY, *BodyColorZ;
int DrawTimer, PrintTimer;
float RunTime;
int* Buffer;
int MovieOn;
int MovieFlag;
int Trace;
float MouseX, MouseY, MouseZ;
float newBodyRadius = 1.0;

// Window globals
static int Window;
int XWindowSize;
int YWindowSize; 
double Near;
double Far;
double EyeX;
double EyeY;
double EyeZ;
double CenterX;
double CenterY;
double CenterZ;
double UpX;
double UpY;
double UpZ;



typedef struct
{
	int id;
	bool isSolid;
	float4 color;
	int movement; //preconfigured movement pattern
	float4 pos;
	float4 vel;
	float4 force;
	float radius;
} Body;

// Prototyping functions
void setSimulationParameters();
void allocateMemory();
void setInitialConditions();
void drawPicture();
void nBody();
void errorCheck(const char*);
void terminalPrint();
void setup();
void movieOn();
void movieOff();
void screenShot();
float4 centerOfMass();
float4 linearVelocity();
void zeroOutSystem();
void addBody(Body newBody);

//Toggles
int NewBodyToggle = 0; // 0 if not currently adding a new body, 1 if currently adding a new body.
bool isOrthogonal = true;
int PreviousRunToggle = 1; // do you want to run a previous simulation or start a new one?
string PreviousRunFile = "simulationparams"; // The file name of the previous simulation you want to run.
int ColorToggle = 0; //15 possible values
int HotkeyPrint = 0; // 0 if not currently printing hotkeys, 1 if currently printing hotkeys.
int NewBodyMovement = 0; // 0 if random movement, 1 if circular movement
bool NewBodySolid = true; // 0 if not solid, 1 if solid


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
} Colors;

Colors colors = { // assigns values corresponding to the colors in the struct
    {49.0/255.0, 39.0/255.0, 96.0/255.0, 1.0},
    {228.0/255.0, 219.0/255.0, 85.0/255.0, 1.0},
    {65.0/255.0, 74.0/255.0, 76.0/255.0, 1.0},
    {21.18/255.0, 44.31/255.0, 77.65/255.0, 1.0},
    {93.0/255.0, 94.0/255.0, 78.0/255.0, 1.0},
    {49.0/255.0, 42.0/255.0, 41.0/255.0, 1.0},
    {49.0/255.0, 72.0/255.0, 73.0/255.0, 1.0},
    {50.0/255.0, 100.0/255.0, 150.0/255.0, 1.0},
    {14.0/255.0, 54.0/255.0, 87.0/255.0, 1.0},
    {249.0/255.0, 228.0/255.0, 150.0/255.0, 1.0},
    {15.0/255.0, 59.0/255.0, 82.0/255.0, 1.0},
    {40.0/255.0, 40.0/255.0, 38.0/255.0, 1.0},
    {244.0/255.0, 179.0/255.0, 5.0/255.0, 1.0},
    {198.0/255.0, 202.0/255.0, 116.0/255.0, 1.0},
    {42.0/255.0, 75.0/255.0, 124.0/255.0, 1.0}
};

float4 getColor(const char* colorName) { //to assign colors to the new body, call this function with the color name
    if (strcmp(colorName, "paris_m") == 0) return colors.paris_m;
    if (strcmp(colorName, "manz") == 0) return colors.manz;
    if (strcmp(colorName, "outer_space") == 0) return colors.outer_space;
    if (strcmp(colorName, "curious_blue") == 0) return colors.curious_blue;
    if (strcmp(colorName, "tahuna_sands") == 0) return colors.tahuna_sands;
    if (strcmp(colorName, "livid_brown") == 0) return colors.livid_brown;
    if (strcmp(colorName, "neptune") == 0) return colors.neptune;
    if (strcmp(colorName, "lochmara") == 0) return colors.lochmara;
    if (strcmp(colorName, "regal_blue") == 0) return colors.regal_blue;
    if (strcmp(colorName, "vis_vis") == 0) return colors.vis_vis;
    if (strcmp(colorName, "light_curious_blue") == 0) return colors.light_curious_blue;
    if (strcmp(colorName, "ironside_grey") == 0) return colors.ironside_grey;
    if (strcmp(colorName, "yellow") == 0) return colors.yellow;
    if (strcmp(colorName, "deco") == 0) return colors.deco;
    if (strcmp(colorName, "astronaut_blue") == 0) return colors.astronaut_blue;
    return (float4){0.0, 0.0, 0.0, 1.0}; // Default value
}

Body* bodies = NULL;
int numBodies = NumberOfInitBodies;
int capacity = INITIAL_CAPACITY; // Initial capacity of the bodies array


void readBodiesFromFile(const char* filename)
{
    FILE* file = fopen(filename, "r");
    if (file == NULL)
    {
        fprintf(stderr, "Error: Could not open file %s for reading\n", filename);
        return;
    }

    // Read the number of bodies from the top of the file
    int numBodiesFromFile;
    if (fscanf(file, "Number of bodies: %d\n", &numBodiesFromFile) != 1)
    {
        fprintf(stderr, "Error: Could not read the number of bodies from the file\n");
        fclose(file);
        return;
    }

    // Allocate memory based on the number of bodies
    capacity = numBodiesFromFile;
    bodies = (Body*)malloc(capacity * sizeof(Body));
    if (bodies == NULL)
    {
        fprintf(stderr, "Memory allocation failed\n");
        fclose(file);
        exit(1);
    }
    printf("Initial memory allocated with capacity: %d\n", capacity);

    // Skip the header line
    char header[256];
    fgets(header, sizeof(header), file);

    // Read body information
    for (int i = 0; i < numBodiesFromFile; i++)
    {
        Body newBody;
        int isSolid;
        float color_x, color_y, color_z, color_w;
        float pos_x, pos_y, pos_z;
        float vel_x, vel_y, vel_z;
        float force_x, force_y, force_z;
        int result = fscanf(file, "%d, %d, (%f, %f, %f, %f), %d, (%f, %f, %f), (%f, %f, %f), (%f, %f, %f), %f\n",
                            &newBody.id,
                            &isSolid,
                            &color_x, &color_y, &color_z, &color_w,
                            &newBody.movement,
                            &pos_x, &pos_y, &pos_z,
                            &vel_x, &vel_y, &vel_z,
                            &force_x, &force_y, &force_z,
                            &newBody.radius);
        newBody.isSolid = (bool)isSolid;
        newBody.color = make_float4(color_x, color_y, color_z, color_w);
        newBody.pos = make_float4(pos_x, pos_y, pos_z, 1.0f);
        newBody.vel = make_float4(vel_x, vel_y, vel_z, 0.0f);
        newBody.force = make_float4(force_x, force_y, force_z, 0.0f);

        if (result == 17)
        {
            addBody(newBody);
            printf("Read body %d: id=%d, isSolid=%d, color=(%f, %f, %f, %f), movement=%d, pos=(%f, %f, %f), vel=(%f, %f, %f), force=(%f, %f, %f), radius=%f\n",
                   i, newBody.id, newBody.isSolid, newBody.color.x, newBody.color.y, newBody.color.z, newBody.color.w,
                   newBody.movement, newBody.pos.x, newBody.pos.y, newBody.pos.z,
                   newBody.vel.x, newBody.vel.y, newBody.vel.z,
                   newBody.force.x, newBody.force.y, newBody.force.z,
                   newBody.radius);
        }
        else
        {
            fprintf(stderr, "Error: fscanf read %d values instead of 17\n", result);
            break;
        }
    }

    fclose(file);
    printf("Body information read from %s\n", filename);

    // Update numBodies
    numBodies = numBodiesFromFile;
}

void writeBodiesToFile(const char* filename)
{
    FILE* file = fopen(filename, "w");
    if (file == NULL)
    {
        fprintf(stderr, "Error: Could not open file %s for writing\n", filename);
        return;
    }

	// Write the number of bodies at the end of the file
    fprintf(file, "Number of bodies: %d\n", numBodies);


    fprintf(file, "ID, IsSolid, Color (R, G, B, A), Movement, Position (X, Y, Z), Velocity (X, Y, Z), Force (X, Y, Z), Radius\n");
    for (int i = 0; i < numBodies; i++)
    {
        fprintf(file, "%d, %d, (%f, %f, %f, %f), %d, (%f, %f, %f), (%f, %f, %f), (%f, %f, %f), %f\n",
                bodies[i].id,
                bodies[i].isSolid,
                bodies[i].color.x, bodies[i].color.y, bodies[i].color.z, bodies[i].color.w,
                bodies[i].movement,
                bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z,
                bodies[i].vel.x, bodies[i].vel.y, bodies[i].vel.z,
                bodies[i].force.x, bodies[i].force.y, bodies[i].force.z,
                bodies[i].radius);
    }



    fclose(file);
    printf("Body information written to %s\n", filename);
}

void addBody(Body newBody) 
{
    // Reallocate memory to accommodate the new body
	
    if (numBodies >= capacity) //if the new body will exceed the current capacity
	{
        capacity *= 2; //double the capacity
        Body* temp = (Body*)realloc(bodies, capacity * sizeof(Body)); //reallocate memory to accommodate the new body
        if (temp == NULL)  //if memory allocation fails
		{
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
        bodies = temp;//assign the new memory to the bodies array, so long as memory allocation was successful
		//printf("Reallocated memory to capacity: %d\n", capacity);
    }


	//
	if(newBody.movement == 0) //random movement
	{
		newBody.vel.x = ((float)rand()/(float)RAND_MAX)*2.0f - 1.0f;
		newBody.vel.y = ((float)rand()/(float)RAND_MAX)*2.0f - 1.0f;
		newBody.vel.z = 0.0;
	}
	if (newBody.movement == 1) //still
	{
        newBody.vel.x = 0.0f;
        newBody.vel.y = 0.0f;
        newBody.vel.z = 0.0f;
	}


    /// Add the new body to the array
	bodies[numBodies] = newBody;

    // Increment the number of bodies
    numBodies++;

	//for debugging
	//printf("Body %d added at (%f, %f, %f) with velocity (%f, %f, %f)\n", newBody.id, newBody.pos.x, newBody.pos.y, newBody.pos.z, newBody.vel.x, newBody.vel.y, newBody.vel.z);
}

void freeBodies() 
{
    free(bodies);
}

void setup()
{
	allocateMemory();
    if (PreviousRunToggle == 1)
    {
        // Read the previous simulation parameters from the specified file
        readBodiesFromFile(PreviousRunFile.c_str());
        setSimulationParameters();
        zeroOutSystem();
    }
    else
    {
        // Set up a new simulation
        setSimulationParameters();
        allocateMemory();
        setInitialConditions();
        zeroOutSystem();
    }

    DrawTimer = 0;
    PrintRate = 0;
    RunTime = 0.0;
    Trace = 0;
    Pause = 1;
    MovieOn = 0;
    terminalPrint();
}

void Display()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	drawPicture();
	glutSwapBuffers();
}

void idle()
{
    if (NewBodyToggle == 1)
    {
        drawPicture();
    }
    else
    {
        nBody();
    }
}

void reshape(int w, int h)
{
    // Prevent division by zero
    if (h == 0) h = 1;

    // Calculate the aspect ratio of the window
    float aspectRatio = (float)w / (float)h; //currently 3000/1500 = 2

    // Set the viewport to cover the new window
    glViewport(0, 0, (GLsizei)w, (GLsizei)h);

    // Set the projection matrix
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Adjust the projection matrix to maintain the aspect ratio of the bodies
    if (isOrthogonal) 
	{
        if (aspectRatio >= 1.0f) 
		{
            // Window is wider than it is tall
            glOrtho(-1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0, Near, Far);
        } 
		else 
		{
            // Window is taller than it is wide
            glOrtho(-1.0, 1.0, -1.0 / aspectRatio, 1.0 / aspectRatio, Near, Far);
        }
    } 
	else 
	{
        if (aspectRatio >= 1.0f) 
		{
            // Window is wider than it is tall
            glFrustum(-0.2 * aspectRatio, 0.2 * aspectRatio, -0.2, 0.2, Near, Far);
        } else 
		{
            // Window is taller than it is wide
            glFrustum(-0.2, 0.2, -0.2 / aspectRatio, 0.2 / aspectRatio, Near, Far);
        }
    }

    // Switch back to the modelview matrix
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
}

void KeyPressed(unsigned char key, int x, int y)
{	
	if(key == 'q')
	{
		// Check if ffmpeg is not NULL before closing
        if (ffmpeg != NULL) 
		{
            pclose(ffmpeg);
            ffmpeg = NULL; // Optionally set to NULL after closing
        } 
		else 
		{
            fprintf(stderr, "Warning: Attempted to close a NULL file pointer\n");
        }
        glutDestroyWindow(Window);
        printf("\nw Good Bye\n");
        exit(0);
	}
	// if(key == 'v') //not much need for this anymore
   	// {
    //     // Toggle the view mode
    //     isOrthogonal = !isOrthogonal;

    //     // Call reshape to update the projection matrix
    //     reshape(glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT));

    //     // Redraw the scene
    //     glutPostRedisplay();
   	//  }
	if(key == 'p')
	{
		if(Pause == 1) Pause = 0;
		else Pause = 1;
		drawPicture();
		terminalPrint();
	}
	if(key == 't') // Turns tracers on and off
	{
		if(Trace == 1) Trace = 0;
		else Trace = 1;
		drawPicture();
		terminalPrint();
	}
	if(key == 'M')  // Movie on/off
	{
		if(MovieFlag == 0) 
		{
			MovieFlag = 1;
			movieOn();
		}
		else 
		{
			MovieFlag = 0;
			movieOff();
		}
		terminalPrint();
	}
	
	if(key == 'S')  // Screenshot
	{	
		screenShot();
		terminalPrint();
	}
	if (key == 'n') // Add a new body
	{
		if(NewBodyToggle == 0) NewBodyToggle = 1;
		else NewBodyToggle = 0;
		terminalPrint();
	}
	if(key == ']')  
	{
		newBodyRadius += 0.01;
		terminalPrint();
		//printf("\n Your selection area = %f times the radius of atrium. \n", HitMultiplier);
	}
	if(key == '[')
	{
		newBodyRadius -= 0.01;
		if(newBodyRadius < 0.0) newBodyRadius = 0.0;
		terminalPrint();
		//printf("\n Your selection area = %f times the radius of atrium. \n", HitMultiplier);
	}
	if(key == 's')
	{
		writeBodiesToFile("simulationparams");
	}

    if(NewBodyToggle == 1)
    {
        if (key == 'l') // cycle through colors, forward
        {
            if (ColorToggle < 15)
            {
                ColorToggle++;
            }
            else
            {
                ColorToggle = 1;
            }
            terminalPrint();
        }
        if (key == 'k') // cycle through colors, backward
        {
            if (ColorToggle > 1)
            {
                ColorToggle--;
            }
            else
            {
                ColorToggle = 15;
            }
            terminalPrint();
        }
        //set movement pattern
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!CHANGES NEED TO BE MADE LATER!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if (key == 'm')
        {
            printf("Enter the movement pattern for the new body: ");
            scanf("%d", &NewBodyMovement);
            if (NewBodyMovement != 0 && NewBodyMovement != 1) //change this when we actually make new bodies
            {
                printf("Invalid movement pattern.\n");
                NewBodyMovement = 0;
            }
            terminalPrint();
        }

        if(key == 'i')//is the new body solid?
        {
            if(NewBodySolid == true)
            {
                NewBodySolid = false;
            }
            else
            {
                NewBodySolid = true;
            }
            terminalPrint();
        }
       
    }
}

void mousePassiveMotionCallback(int x, int y) 
{

	// Convert window coordinates to OpenGL coordinates
		MouseX = ( 2.0*x/XWindowSize - 1.0) *2.8 + 1.0;
		MouseY = (-2.0*y/YWindowSize + 1.0)*1.5 - 0.5;

    // Print the converted coordinates for debugging
    //printf("MouseX: %f, MouseY: %f\n", MouseX, MouseY);


    // Redraw the scene
    //glutPostRedisplay();
}

// This is called when you push a mouse button.
void mymouse(int button, int state, int x, int y)
{	
	if(state == GLUT_DOWN)
	{	
		if(button == GLUT_LEFT_BUTTON)
		{	
			if(NewBodyToggle == 1)
			{

                //generate random numbers for all the properties of the new body
				
                int index = numBodies; // Define and initialize index

				// Convert window coordinates to OpenGL coordinates
				MouseX = ( 2.0*x/XWindowSize - 1.0) *2.8 + 1.0;
				MouseY = (-2.0*y/YWindowSize + 1.0)*1.5 - 0.5;
                MouseZ = 0.0f;

                // Print the converted coordinates for debugging
                printf("MouseX: %f, MouseY: %f, MouseZ: %f\n", MouseX, MouseY, MouseZ);

                Body newBody; //create a new body with the body struct

                // Set the color of the new body based on the ColorToggle

                if(ColorToggle == 1)
                {
                    newBody.color = getColor("paris_m");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 2)
                {
                    newBody.color = getColor("manz");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 3)
                {
                    newBody.color = getColor("outer_space");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 4)
                {
                    newBody.color = getColor("curious_blue");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 5)
                {
                    newBody.color = getColor("tahuna_sands");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 6)
                {
                    newBody.color = getColor("livid_brown");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 7)
                {
                    newBody.color = getColor("neptune");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 8)
                {
                    newBody.color = getColor("lochmara");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 9)
                {
                    newBody.color = getColor("regal_blue");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 10)
                {
                    newBody.color = getColor("vis_vis");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 11)
                {
                    newBody.color = getColor("light_curious_blue");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 12)
                {
                    newBody.color = getColor("ironside_grey");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 13)
                {
                    newBody.color = getColor("yellow");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 14)
                {
                    newBody.color = getColor("deco");
                    HotkeyPrint = 0;
                }
                else if(ColorToggle == 15)
                {
                    newBody.color = getColor("astronaut_blue");
                    HotkeyPrint = 0;
                }
                else
                {
                    newBody.color =  {1.0f, 1.0f, 1.0f, 1.0f}; //default
                }

                //assign all the properties of the new body
                newBody.id = index;
                newBody.isSolid = true;
                newBody.movement = NewBodyMovement;
                newBody.pos = {MouseX, MouseY, MouseZ, 1.0f}; // Directly assign values to float4
                newBody.force = {0.0f, 0.0f, 0.0f, 0.0f}; // Directly assign values to float4
				newBody.radius = newBodyRadius*DiameterOfBody/2.0;

                addBody(newBody);
			}
		}
		else if(button == GLUT_RIGHT_BUTTON) // Right Mouse button down
		{
			// Do stuff in here if you choose to when the right mouse button is pressed.
		}
		else if(button == GLUT_MIDDLE_BUTTON)
		{
			// Do stuff in here if you choose to when the middle mouse button is pressed.
		}
	}
	
	// If no mouse button is down (state 0, they don't have a nice word like GLUT_NOT_DOWN) 
	// but you move the mouse wheel this is called.
	if(state == 0)
	{
		// When you turn the mouse whell forward this is called.
		if(button == 3)
		{
			EyeZ -=0.1;
			
		}
		
		// When you turn the mouse whell backward this is called.
		else if(button == 4)
		{
			EyeZ += 0.1;
			
		}
	}
	glLoadIdentity();
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	//glutPostRedisplay();
}


string getTimeStamp()
{
	// Want to get a time stamp string representing current date/time, so we have a
	// unique name for each video/screenshot taken.
	time_t t = time(0); 
	struct tm * now = localtime( & t );
	int month = now->tm_mon + 1, day = now->tm_mday, year = now->tm_year, 
				curTimeHour = now->tm_hour, curTimeMin = now->tm_min, curTimeSec = now->tm_sec;
	stringstream smonth, sday, syear, stimeHour, stimeMin, stimeSec;
	smonth << month;
	sday << day;
	syear << (year + 1900); // The computer starts counting from the year 1900, so 1900 is year 0. So we fix that.
	stimeHour << curTimeHour;
	stimeMin << curTimeMin;
	stimeSec << curTimeSec;
	string timeStamp;
	if (curTimeMin <= 9)	
		timeStamp = smonth.str() + "-" + sday.str() + "-" + syear.str() + '_' + stimeHour.str() + ".0" + stimeMin.str() + 
					"." + stimeSec.str();
	else			
		timeStamp = smonth.str() + "-" + sday.str() + '-' + syear.str() + "_" + stimeHour.str() + "." + stimeMin.str() +
					"." + stimeSec.str();
	return timeStamp;
}

// Signal handler for SIGPIPE
void handle_sigpipe(int sig)
{
    fprintf(stderr, "Caught SIGPIPE signal: %d\n", sig);
}

void movieOn()
{
    // Register the SIGPIPE signal handler
    signal(SIGPIPE, handle_sigpipe);

    string ts = getTimeStamp();
    ts.append(".mp4");

    // Convert the x and y window size to a string of format "XsizexYsize"
    stringstream ss;
    ss << XWindowSize << "x" << YWindowSize;
    string windowSize = ss.str();

    // Setting up the movie buffer with the dynamic window size
    string baseCommand = "ffmpeg -loglevel quiet -r 60 -f rawvideo -pix_fmt rgba -s " + windowSize + " -i - "
                         "-c:v libx264rgb -threads 0 -preset fast -y -pix_fmt yuv420p -crf 0 -vf vflip 2>ffmpeg_error.log ";

    string z = baseCommand + ts;

    const char *ccx = z.c_str();
    MovieFile = popen(ccx, "w");

    // Check if popen was successful
    if (MovieFile == NULL) {
        fprintf(stderr, "Error: Failed to open movie file with popen\n");
        return;
    }

    // Allocate buffer
    Buffer = (int*)malloc(XWindowSize * YWindowSize * sizeof(int));

    // Check if malloc was successful
    if (Buffer == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory for buffer\n");
        pclose(MovieFile);
        MovieFile = NULL;
        return;
    }

    MovieOn = 1;
    printf("Movie recording started successfully\n");
}

void movieOff()
{
	if(MovieOn == 1) 
	{
		pclose(MovieFile);
	}
	free(Buffer);
	MovieOn = 0;
}

void screenShot()
{	
	int pauseFlag;
	FILE* ScreenShotFile;
	int* buffer;

	//convert the x and y windowsize to a string of format "XsizexYsize"
    stringstream ss;
    ss << XWindowSize << "x" << YWindowSize;
    string windowSize = ss.str();

    // Construct the ffmpeg command with the dynamic window size
    string baseCommand = "ffmpeg -loglevel quiet -framerate 60 -f rawvideo -pix_fmt rgba -s " + windowSize + " -i - "
                         "-c:v libx264rgb -threads 0 -preset fast -y -crf 0 -vf vflip output1.mp4";
    const char* cmd = baseCommand.c_str();
	//const char* cmd = "ffmpeg -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
	//              "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output1.mp4";
	ScreenShotFile = popen(cmd, "w");
	buffer = (int*)malloc(XWindowSize*YWindowSize*sizeof(int));
	
	if(Pause == 0) 
	{
		Pause = 1;
		pauseFlag = 0;
	}
	else
	{
		pauseFlag = 1;
	}
	
	for(int i =0; i < 1; i++)
	{
		drawPicture();
		glReadPixels(5, 5, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
		fwrite(buffer, sizeof(int)*XWindowSize*YWindowSize, 1, ScreenShotFile);
	}
	
	pclose(ScreenShotFile);
	free(buffer);

	string ts = getTimeStamp(); // Only storing in a separate variable for debugging purposes.
	string s = "ffmpeg -loglevel quiet -i output1.mp4 -qscale:v 1 -qmin 1 -qmax 1 " + ts + ".jpeg";
	// Convert back to a C-style string.
	const char *ccx = s.c_str();
	system(ccx);
	system("rm output1.mp4");
	printf("\nScreenshot Captured: \n");
	cout << "Saved as " << ts << ".jpeg" << endl;
	
	Pause = pauseFlag;
	//ffmpeg -i output1.mp4 output_%03d.jpeg
}

void setSimulationParameters()
{
	//numBodies = 16;

	TotalRunTime = 10000.0;

	Dt = 0.002;

	// This is a lennard-Jones type force G*m1*m2/(r^2) - H*m1*m2/(r^4).
	// If you want a gravity type force just set G to your gravity and set H equal 0.
	G = 0.03;

	H = 0.00001;

	Epsilon = 0.01;

	MassOfBody = 1.0;

	DiameterOfBody = 0.2;

	VelocityMax = 10.0;

	Drag = 0.001;

	DrawRate = 8;
	
	PrintRate = 100;
}

void allocateMemory()
{
// Allocate initial memory for the bodies array
    bodies = (Body*)malloc(capacity * sizeof(Body));
    if (bodies == NULL) 
    {
        fprintf(stderr, "Initial memory allocation failed\n");
        exit(1);
    }
    printf("Initial memory allocated with capacity: %d\n", capacity);
}

void setInitialConditions()
{
    float dx, dy, dz, d, d2;
    int test;
	time_t t;
	
	srand((unsigned) time(&t));
	for(int i = 0; i < numBodies; i++)
	{
		bodies[i].id = i;
		test = 0;
		while(test == 0)
		{
			// Get random number between -1 at 1.
			bodies[i].pos.x = ((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			bodies[i].pos.y= ((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			bodies[i].pos.z= 0.0;  //((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			test = 1;
			
			for(int j = 0; j < i; j++)
			{
				dx = bodies[i].pos.x - bodies[j].pos.x;
				dy = bodies[i].pos.y - bodies[j].pos.y;
				dz = bodies[i].pos.z - bodies[j].pos.z;
				d2  = dx*dx + dy*dy + dz*dz;
				d = sqrt(d2);
				if(d < DiameterOfBody)
				{
					test = 0;
					break;
				}
			}
			
			if(test == 1)
			{
				bodies[i].vel.x = 0.0; //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				bodies[i].vel.y = 0.0; //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				bodies[i].vel.z = 0.0;  //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				
				bodies[i].color.x = ((float)rand()/(float)RAND_MAX);
				bodies[i].color.y = ((float)rand()/(float)RAND_MAX);
				bodies[i].color.z = ((float)rand()/(float)RAND_MAX);
			}
		}
		//set the radius of the body
		bodies[i].radius =((float)rand()/(float)RAND_MAX)* DiameterOfBody/2.0;

		//initialize everything else to zero
		bodies[i].force.x = 0.0;
		bodies[i].force.y = 0.0;
		bodies[i].force.z = 0.0;
		bodies[i].movement = 0;
		bodies[i].isSolid = true;
		
	}
}

float4 centerOfMass()
{
	float totalMass;
	float4 centerOfMass;
	
	centerOfMass.x = 0.0;
	centerOfMass.y = 0.0;
	centerOfMass.z = 0.0;
	totalMass = 0.0;
	
	for(int i = 0; i < numBodies; i++)
	{
    	centerOfMass.x += bodies[i].pos.x*MassOfBody;
		centerOfMass.y += bodies[i].pos.y*MassOfBody;
		centerOfMass.z += bodies[i].pos.z*MassOfBody;
		totalMass += MassOfBody;
	}
	centerOfMass.x /= totalMass;
	centerOfMass.y /= totalMass;
	centerOfMass.z /= totalMass;
	
	return(centerOfMass);
}

float4 linearVelocity()
{
	float totalMass;
	float4 linearVelocity;
	
	linearVelocity.x = 0.0;
	linearVelocity.y = 0.0;
	linearVelocity.z = 0.0;
	totalMass = 0.0;
	
	for(int i = 0; i < numBodies; i++)
	{
    	linearVelocity.x += bodies[i].vel.x*MassOfBody;
		linearVelocity.y += bodies[i].vel.y*MassOfBody;
		linearVelocity.z += bodies[i].vel.z*MassOfBody;
		totalMass += MassOfBody;
	}
	linearVelocity.x /= totalMass;
	linearVelocity.y /= totalMass;
	linearVelocity.z /= totalMass;
	
	return(linearVelocity);
}

void zeroOutSystem()
{
	float4 pos, vel;
	pos = centerOfMass();
	vel = linearVelocity();
		
	for(int i = 0; i < numBodies; i++)
	{
		bodies[i].pos.x -= pos.x;
		bodies[i].pos.y -= pos.y;
		bodies[i].pos.z -= pos.z;
		
		bodies[i].vel.x -= vel.x;
		bodies[i].vel.y -= vel.y;
		bodies[i].vel.z -= vel.z;
	}
}

void drawPicture()
{


    if (Trace == 0)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    if (NewBodyToggle == 1)
    {
        float4 mouseColor;
        // Set mouse to look like a new body

        // float4 paris_m = (49.0/255.0, 39.0/255.0, 96.0/255.0);
        // float4 manz =(228.0/255.0, 219.0/255.0, 85.0/255.0);
        // float4 outer_space =(65.0/255.0, 74.0/255.0, 76.0/255.0);
        // float4 curious_blue = (21.18/255.0, 44.31/255.0, 77.65/255.0);
        // float4 tahuna_sands = (93.0/255.0, 94.0/255.0, 78.0/255.0);
        // float4 livid_brown = (49.0/255.0, 42.0/255.0, 41.0/255.0);
        // float4 neptune = (49.0/255.0, 72.0/255.0, 73.0/255.0);
        // float4 lochmara = (50.0/255.0, 100.0/255.0, 150.0/255.0);
        // float4 regal_blue = (14.0/255.0, 54.0/255.0, 87.0/255.0);
        // float4 vis_vis = (249.0/255.0, 228.0/255.0, 150.0/255.0);
        // float4 light_curious_blue = (15.0/255.0, 59.0/255.0, 82.0/255.0);
        // float4 ironside_grey = (40.0/255.0, 40.0/255.0, 38.0/255.0);
        // float4 yellow = (244.0/255.0, 179.0/255.0, 5.0/255.0);
        // float4 deco = (198.0/255.0, 202.0/255.0, 116.0/255.0);
        // float4 astronaut_blue = (42.0/255.0, 75.0/255.0, 124.0/255.0);

        if (ColorToggle == 1)
        {
            //color paris m
            mouseColor = getColor("paris_m");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 2)
        {
            //color manz
            mouseColor = getColor("manz");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 3)
        {
            //color outer space
            mouseColor = getColor("outer_space");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 4)
        {
            //color curious blue
            mouseColor = getColor("curious_blue");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 5)
        {
            //color tahuna sands
            mouseColor = getColor("tahuna_sands");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 6)
        {
            //color livid brown
            mouseColor = getColor("livid_brown");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 7)
        {
            //color neptune
            mouseColor = getColor("neptune");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 8)
        {
            //color lochmara
            mouseColor = getColor("lochmara");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 9)
        {
            //color regal blue
            mouseColor = getColor("regal_blue");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 10)
        {
            //color vis vis
            mouseColor = getColor("vis_vis");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 11)
        {
            //color light curious blue
            mouseColor = getColor("light_curious_blue");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 12)
        {
            //color ironside grey
            mouseColor = getColor("ironside_grey");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 13)
        {
            //color yellow
            mouseColor = getColor("yellow");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 14)
        {
            //color deco
            mouseColor = getColor("deco");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else if (ColorToggle == 15)
        {
            //color astronaut blue
            mouseColor = getColor("astronaut_blue");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else
        {
            //color white
            glColor3d(1.0, 1.0, 1.0);
        }
        glPushMatrix();
        glTranslatef(MouseX, MouseY, MouseZ);
        glutSolidSphere(newBodyRadius * DiameterOfBody / 2.0, 20, 20);
        glPopMatrix();
    }

    for (int i = 0; i < numBodies; i++)
    {
        glColor3d(bodies[i].color.x, bodies[i].color.y, bodies[i].color.z);
        glPushMatrix();
        glTranslatef(bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z);
        glutSolidSphere(bodies[i].radius, 20, 20);
        glPopMatrix();
    }

    glutSwapBuffers();

    if (MovieOn == 1)
    {
        glReadPixels(0, 0, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
        fwrite(Buffer, sizeof(int) * XWindowSize * YWindowSize, 1, MovieFile);
    }
}

void getForces(Body* bodies, float mass, float G, float H, float Epsilon, float drag, float dt, int n)
{
	float dx, dy, dz, d2, d;
    float forceMag;
    float inOut;
	float kSphereReduction = 0.5;
	float dvx, dvy, dvz;
	float kSphere = 10000;

    // Initialize forces to zero
    for (int i = 0; i < n; i++)
    {
        bodies[i].force = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    }

    // Calculate forces
    for (int i = 0; i < n; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            dx = bodies[j].pos.x - bodies[i].pos.x;
            dy = bodies[j].pos.y - bodies[i].pos.y;
            dz = bodies[j].pos.z - bodies[i].pos.z;
            d2 = dx * dx + dy * dy + dz * dz + Epsilon;
            d = sqrt(d2);
			if (d < 1e-6) 
			{
                fprintf(stderr, "Warning: Small distance in force calculation, skipping\n");
                continue;
            }
            //forceMag = (G * mass * mass) / d2 - (H * mass * mass) / (d2 * d2); // gravitational force
            forceMag = 0.0; //No force between bodies. Each body acts individually.

            float3 force = make_float3(forceMag * dx / d,
                                       forceMag * dy / d,
                                       forceMag * dz / d);

            if(bodies[i].isSolid ^ bodies[j].isSolid) //bitwise XOR. If one is solid and the other is not, and only then, do the following.
            {
                float combinedDiamter = bodies[i].radius + bodies[j].radius;
                if(d < combinedDiamter) //if the balls touch. i.e if the distance betweeen < both radii
			    {
                    
                    dvx = bodies[j].vel.x - bodies[i].vel.x;
                    dvy = bodies[j].vel.y - bodies[i].vel.y;
                    dvz = bodies[j].vel.z - bodies[i].vel.z;
                    inOut = dx*dvx + dy*dvy + dz*dvz;
                    if(inOut < 0.0) forceMag = kSphere*(combinedDiamter - d); // If inOut is negative the sphere are converging.
                    else forceMag = kSphereReduction*kSphere*(combinedDiamter - d); // If inOut is positive the sphere are diverging.
                    
                    // Doling out the force in the proper perfortions using unit vectors.
                    bodies[i].force.x -= forceMag*(dx/d);
                    bodies[i].force.y -= forceMag*(dy/d);
                    bodies[i].force.y -= forceMag*(dz/d);
                    // A force on me causes the opposite force on you. 
                    bodies[j].force.x += forceMag*(dx/d);
                    bodies[j].force.y += forceMag*(dy/d);
                    bodies[j].force.z += forceMag*(dz/d);
                }
            }

            bodies[i].force.x += force.x;
            bodies[i].force.y += force.y;
            bodies[i].force.z += force.z;

            bodies[j].force.x -= force.x;
            bodies[j].force.y -= force.y;
            bodies[j].force.z -= force.z;
        }
    }

	// Check for nan values
	for (int i = 0; i < n; i++) {
		if (isnan(bodies[i].color.x) || isnan(bodies[i].color.y) || isnan(bodies[i].color.z) || isnan(bodies[i].color.w) ||
			isnan(bodies[i].pos.x) || isnan(bodies[i].pos.y) || isnan(bodies[i].pos.z) ||
			isnan(bodies[i].vel.x) || isnan(bodies[i].vel.y) || isnan(bodies[i].vel.z) ||
			isnan(bodies[i].force.x) || isnan(bodies[i].force.y) || isnan(bodies[i].force.z) ||
			isnan(bodies[i].radius))
		{
			fprintf(stderr, "Error: Encountered nan value in body %d\n", bodies[i].id);
			exit(1);
		}
	}
	
}

void nBody()
{
    if (Pause != 1)
    {
        // Print initial positions and velocities
        // for (int i = 0; i < numBodies; i++)
        // {
        //     printf("Initial Body %d: pos=(%f, %f, %f), vel=(%f, %f, %f), force=(%f, %f, %f)\n",
        //            i, bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z,
        //            bodies[i].vel.x, bodies[i].vel.y, bodies[i].vel.z,
        //            bodies[i].force.x, bodies[i].force.y, bodies[i].force.z);
        // }

        // Calculate forces
        getForces(bodies, MassOfBody, G, H, Epsilon, Drag, Dt, numBodies);

        // Print positions, velocities, and forces after force calculation
        // for (int i = 0; i < numBodies; i++)
        // {
        //     printf("After Force Calculation Body %d: pos=(%f, %f, %f), vel=(%f, %f, %f), force=(%f, %f, %f)\n",
        //            i, bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z,
        //            bodies[i].vel.x, bodies[i].vel.y, bodies[i].vel.z,
        //            bodies[i].force.x, bodies[i].force.y, bodies[i].force.z);
        // }

        // Update positions and velocities
        for (int i = 0; i < numBodies; i++)
        {
            bodies[i].vel.x += ((bodies[i].force.x - Drag * bodies[i].vel.x) / MassOfBody) * Dt;
            bodies[i].vel.y += ((bodies[i].force.y - Drag * bodies[i].vel.y) / MassOfBody) * Dt;
            bodies[i].vel.z += ((bodies[i].force.z - Drag * bodies[i].vel.z) / MassOfBody) * Dt;

            bodies[i].pos.x += bodies[i].vel.x * Dt;
            bodies[i].pos.y += bodies[i].vel.y * Dt;
            bodies[i].pos.z += bodies[i].vel.z * Dt;

            // Check for nan values
            if (isnan(bodies[i].pos.x) || isnan(bodies[i].pos.y) || isnan(bodies[i].pos.z) ||
                isnan(bodies[i].vel.x) || isnan(bodies[i].vel.y) || isnan(bodies[i].vel.z) ||
                isnan(bodies[i].force.x) || isnan(bodies[i].force.y) || isnan(bodies[i].force.z))
            {
                fprintf(stderr, "Error: Encountered nan value in body %d during update\n", bodies[i].id);
                // exit(1);
            }
        }

        // Print positions and velocities after update
        // for (int i = 0; i < numBodies; i++)
        // {
        //     printf("After Update Body %d: pos=(%f, %f, %f), vel=(%f, %f, %f), force=(%f, %f, %f)\n",
        //            i, bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z,
        //            bodies[i].vel.x, bodies[i].vel.y, bodies[i].vel.z,
        //            bodies[i].force.x, bodies[i].force.y, bodies[i].force.z);
        // }

        DrawTimer++;
        if (DrawTimer == DrawRate)
        {
            drawPicture();
            DrawTimer = 0;
        }

        PrintTimer++;
        if (PrintTimer == PrintRate)
        {
            terminalPrint();
            PrintTimer = 0;
        }

        RunTime += Dt;
        if (TotalRunTime < RunTime)
        {
            printf("\n\n Done\n");
            exit(0);
        }
    }
}

void terminalPrint()
{
	/*
	default  \033[0m
	Black:   \033[0;30m
	Red:     \033[0;31m
	Green:   \033[0;32m
	Yellow:  \033[0;33m
	Blue:    \033[0;34m
	Magenta: \033[0;35m
	Cyan:    \033[0;36m
	White:   \033[0;37m
	printf("\033[0;30mThis text is black.\033[0m\n");
	
	BOLD_ON  "\e[1m"
	BOLD_OFF   "\e[m"
	*/
	
	system("clear");
	
    printf("\n");
	printf("\n S: Screenshot");
	
	printf("\n");
	printf("\n q: Terminates the simulation");

    printf("\n");
    printf("\n s: Save this run");

	printf("\n\n");
	printf("\033[0m");
	printf(" p: Pause on/off toggle --> ");
	printf(" The simulation is:");
	if (Pause == 1) 
	{
		printf("\e[1m" " \033[0;31mPaused\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mRunning\n" "\e[m");
	}
	
	printf("\n");
	printf("\033[0m");
	printf(" t: Trace on/off toggle --> ");
	printf(" Trace is:");
	if (Trace == 1) 
	{
		printf("\e[1m" " \033[0;31mOn\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mOff\n" "\e[m");
	}
	//printf("\n");
	//printf("\033[0m");
	//printf(" v: Toggle view (Perspective/Orthogonal) --> ");
	//printf(" Current View: ");
	// if (isOrthogonal) 
	// {
	// 	printf("\e[1m" " \033[0;32mOrthogonal\n" "\e[m");
	// }
	// else 
	// {
	// 	printf("\e[1m" " \033[0;31mDefault\n" "\e[m");
	// }
	printf("\n M: Video On/Off toggle --> ");
	if (MovieFlag == 0) 
	{
		printf("\033[0;31m");
		printf(BOLD_ON "Video Recording Off\n" BOLD_OFF); 
	}
	else 
	{
		printf("\033[0;32m");
		printf(BOLD_ON "Video Recording On\n" BOLD_OFF);
	}
	printf("\n n: Simulaton Mode Add View/Add Body Toggle --> Mode:");
	if (NewBodyToggle== 0) 
	{
		printf("\033[0;31m");
		printf(BOLD_ON "View" BOLD_OFF); 
	}
	else 
	{
		printf("\033[0;32m");
		printf(BOLD_ON "Add Body" BOLD_OFF);
	}
	//controls for body placement
    if(NewBodyToggle == 1)
    {
        printf("\n");
        printf("\033[0m");
        printf(" [/]: Change radius of new body backwards/forwards\n");

        printf("\n");
        printf("\033[0m");
        printf(" k/l: Change color of new body backwards/forwards\n");
        printf(" Current Color: ");
        if (ColorToggle == 1)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Paris M" BOLD_OFF);
        }
        else if (ColorToggle == 2)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Manz" BOLD_OFF);
        }
        else if (ColorToggle == 3)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Outer Space" BOLD_OFF);
        }
        else if (ColorToggle == 4)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Curious Blue" BOLD_OFF);
        }
        else if (ColorToggle == 5)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Tahuna Sands" BOLD_OFF);
        }
        else if (ColorToggle == 6)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Livid Brown" BOLD_OFF);
        }
        else if (ColorToggle == 7)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Neptune" BOLD_OFF);
        }
        else if (ColorToggle == 8)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Lochmara" BOLD_OFF);
        }
        else if (ColorToggle == 9)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Regal Blue" BOLD_OFF);
        }
        else if (ColorToggle == 10)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Vis Vis" BOLD_OFF);
        }
        else if (ColorToggle == 11)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Light Curious Blue" BOLD_OFF);
        }
        else if (ColorToggle == 12)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Ironside Grey" BOLD_OFF);
        }
        else if (ColorToggle == 13)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Yellow" BOLD_OFF);
        }
        else if (ColorToggle == 14)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Deco" BOLD_OFF);
        }
        else if (ColorToggle == 15)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Astronaut Blue" BOLD_OFF);
        }
        else
        {
            printf("\033[0;32m");
            printf(BOLD_ON "DEFAULT" BOLD_OFF);
        }

        printf("\n");
        printf("\033[0m");
        printf("m : set movement preset --> Current Preset:");
        if(NewBodyMovement == 0)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Random" BOLD_OFF);
        }
        else if(NewBodyMovement == 1)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Circle" BOLD_OFF);
        }
        else
        {
            printf("\033[0;32m");
            printf(BOLD_ON "DEFAULT" BOLD_OFF);
        }

        printf("\n");
        printf("\033[0m");
        printf(" i: Body Solidity On/Off Toggle --> ");
        if (!NewBodySolid)
        {
            printf("\033[0;31m");
            printf(BOLD_ON "Solid Off" BOLD_OFF);
        }
        else
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Solid On" BOLD_OFF);
        }


    }
    printf("\n");
}




int main(int argc, char** argv)
{
    setup();

    XWindowSize = 3000;
    YWindowSize = 1500;

    // Clip planes
    Near = 0.2;
    Far = 30.0;

    // Direction here your eye is located location
    EyeX = 0.0;
    EyeY = 0.0;
    EyeZ = 2.0;

    // Where you are looking
    CenterX = 0.0;
    CenterY = 0.0;
    CenterZ = 0.0;

    // Up vector for viewing
    UpX = 0.0;
    UpY = 1.0;
    UpZ = 0.0;

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
    glutInitWindowSize(XWindowSize, YWindowSize);
    glutInitWindowPosition(5, 5);
    Window = glutCreateWindow("N Body");

    gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
    glMatrixMode(GL_MODELVIEW);
    glClearColor(0.0, 0.0, 0.0, 0.0);

    GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
    GLfloat light_ambient[] = {0.0, 0.0, 0.0, 1.0};
    GLfloat light_diffuse[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
    GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat mat_shininess[] = {10.0};
    glShadeModel(GL_SMOOTH);
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
    glLightfv(GL_LIGHT0, GL_POSITION, light_position);
    glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);
    glEnable(GL_DEPTH_TEST);

    glutPassiveMotionFunc(mousePassiveMotionCallback);
    glutMouseFunc(mymouse);
    glutDisplayFunc(Display);
    glutReshapeFunc(reshape);
    glutKeyboardFunc(KeyPressed);
    glutIdleFunc(idle);
    terminalPrint();
    glutMainLoop();

    // Cleanup resources
    movieOff();
    freeBodies();

    return 0;
}





