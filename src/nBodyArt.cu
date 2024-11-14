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

//Toggles
int NewBodyToggle = 0; // 0 if not currently adding a new body, 1 if currently adding a new body.
bool isOrthogonal = false;
//#include "./callBackFunctions.h"

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

Body* bodies = NULL;
int numBodies = NumberOfInitBodies;
int capacity = INITIAL_CAPACITY; // Initial capacity of the bodies array

// void readSimulationParameters()
// {
// 	ifstream data;
// 	string name;
	
// 	data.open("./simulationSetup");
	
// 	if(data.is_open() == 1)
// 	{
		
// 		getline(data,name,'=');
// 		data >> PreviousRunFileName;
		
// 		getline(data,name,'=');
// 		data >> Movement;
		
// 		getline(data,name,'=');
// 		data >> Velocity;
		
// 		getline(data,name,'=');
// 		data >> Radius;

//       	getline(data,name, '=');
//     	data >> Mass;
		
// 		// getline(data,name,'=');
// 		// data >> SparkleIntensity;
		
// 		getline(data,name,'=');
// 		data >> PrintRate;
		
// 		getline(data,name,'=');
// 		data >> DrawRate;
		
// 		getline(data,name,'=');
// 		data >> Dt;
		
// 		getline(data,name,'=');
// 		data >> Color.x;
		
// 		getline(data,name,'=');
// 		data >> Color.y;
		
// 		getline(data,name,'=');
// 		data >> Color.z;
		
// 		getline(data,name,'=');
// 		data >> BackGroundColor;
		
// 	}
// 	else
// 	{
// 		printf("\nTSU Error could not open simulationSetup file\n");
// 		exit(0);
// 	}
// }

// //this is how u open the setup file
// void readSimulationParameters()
// {
// 	if(PreviousRunsFile == 0)
// 	{
// 		allocateMemory();
// 		setBallAttributesAndMasses();

// 	}
// 	else if(PreviousRunsFile == 1)
// 	{
// 		FILE *inFile;
// 		char fileName[256];
		
// 		strcpy(fileName, "");
// 		strcat(fileName,"./PreviousRunsFile/");
// 		strcat(fileName,PreviousRunFileName);
// 		strcat(fileName,"/nBodyArt");
// 		//printf("\n fileName = %s\n", fileName);

// 		inFile = fopen(fileName,"rb");
// 		if(inFile == NULL)
// 		{
// 			printf(" Can't open %s file.\n", fileName);
// 			exit(0);
// 		}
//     }
// }

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
		newBody.vel.z = ((float)rand()/(float)RAND_MAX)*2.0f - 1.0f;
	}
	if (newBody.movement == 1) //circular movement
	{

	}
	



    /// Add the new body to the array
	bodies[numBodies] = newBody;

    // Increment the number of bodies
    numBodies++;

	//for debugging
	printf("Body %d added at (%f, %f, %f) with velocity (%f, %f, %f)\n", newBody.id, newBody.pos.x, newBody.pos.y, newBody.pos.z, newBody.vel.x, newBody.vel.y, newBody.vel.z);
}

void freeBodies() 
{
    free(bodies);
}

void Display()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	drawPicture();
	glutSwapBuffers();
}

void idle()
{
	nBody();
}

void reshape(int w, int h)
{
    // Prevent division by zero
    if (h == 0) h = 1;

    // Calculate the aspect ratio of the window
    float aspectRatio = (float)w / (float)h;

    // Set the viewport to cover the new window
    glViewport(0, 0, (GLsizei)w, (GLsizei)h);

    // Set the projection matrix
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Adjust the projection matrix to maintain the aspect ratio of the bodies
    if (isOrthogonal) {
        if (aspectRatio >= 1.0f) {
            // Window is wider than it is tall
            glOrtho(-1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0, Near, Far);
        } else {
            // Window is taller than it is wide
            glOrtho(-1.0, 1.0, -1.0 / aspectRatio, 1.0 / aspectRatio, Near, Far);
        }
    } else {
        if (aspectRatio >= 1.0f) {
            // Window is wider than it is tall
            glFrustum(-0.2 * aspectRatio, 0.2 * aspectRatio, -0.2, 0.2, Near, Far);
        } else {
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
	if(key == 'v') 
   	{
        // Toggle the view mode
        isOrthogonal = !isOrthogonal;

        // Call reshape to update the projection matrix
        reshape(glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT));

        // Redraw the scene
        glutPostRedisplay();
   	 }
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
		newBodyRadius += 0.005;
		terminalPrint();
		//printf("\n Your selection area = %f times the radius of atrium. \n", HitMultiplier);
	}
	if(key == '[')
	{
		newBodyRadius -= 0.005;
		if(newBodyRadius < 0.0) newBodyRadius = 0.0;
		terminalPrint();
		//printf("\n Your selection area = %f times the radius of atrium. \n", HitMultiplier);
	}
}

void mousePassiveMotionCallback(int x, int y) 
{
	// This function is called when the mouse moves without any button pressed
	// x and y are the current mouse coordinates
	MouseX = (2.0*x/XWindowSize - 1.0);
	MouseY = -(2.0*y/YWindowSize - 1.0);
	MouseZ = 0.0;
	//drawPicture();
	// x and y come in as 0 to XWindowSize and 0 to YWindowSize. 
	// Use this if you choose to.
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
				MouseX = (2.0*x/XWindowSize - 1.0);
				MouseY = -(2.0*y/YWindowSize - 1.0);
				MouseZ = 0.0;

                float mass = MassOfBody;

                float colorx = ((float)rand()/(float)RAND_MAX);
                float colory = ((float)rand()/(float)RAND_MAX);
                float colorz = ((float)rand()/(float)RAND_MAX);

                Body newBody; //create a new body with the body struct

                //assign all the properties of the new body
                newBody.id = index;
                newBody.isSolid = true;
                newBody.color = {colorx, colory, colorz, 1.0f}; // Directly assign values to float4
                newBody.movement = 0;
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
	numBodies = 16;

	TotalRunTime = 10000.0;

	Dt = 0.002;

	// This is a lennard-Jones type force G*m1*m2/(r^2) - H*m1*m2/(r^4).
	// If you want a gravity type force just set G to your gravity and set H equal 0.
	G = 0.03;

	H = 0.0;

	Epsilon = 0.01;

	MassOfBody = 1.0;

	DiameterOfBody = 0.2;

	VelocityMax = 0.0;

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

		bodies[i].radius =((float)rand()/(float)RAND_MAX)* DiameterOfBody/2.0;
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
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}
	
	if (NewBodyToggle == 1)
	{
		//set mouse to look look like a new body
		glColor3d(1.0,1.0,1.0);
		glPushMatrix();
			glTranslatef(MouseX, MouseY, MouseZ);
			glutSolidSphere(newBodyRadius*DiameterOfBody/2.0, 20, 20);
		glPopMatrix();
	}

	for(int i = 0; i < numBodies; i++)
	{
		glColor3d(bodies[i].color.x, bodies[i].color.y, bodies[i].color.z);
		glPushMatrix();
			glTranslatef(bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z);
			glutSolidSphere(bodies[i].radius, 20, 20);
		glPopMatrix();
	}
	glutSwapBuffers();
	
	if(MovieOn == 1)
	{
		glReadPixels(0, 0, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
		fwrite(Buffer, sizeof(int)*XWindowSize*YWindowSize, 1, MovieFile);
	}
}

void getForces(Body* bodies, float mass, float G, float H, float Epsilon, float drag, float dt, int n)
{
    float dx, dy, dz, d2, d;
    float forceMag;

    // Initialize forces to zero
    for(int i = 0; i < n; i++)
    {
        bodies[i].force.x = 0.0;
        bodies[i].force.y = 0.0;
        bodies[i].force.z = 0.0;
    }

    // Calculate forces
    for(int i = 0; i < n; i++)
    {
        for(int j = i + 1; j < n; j++)
        {
            dx = bodies[j].pos.x - bodies[i].pos.x;
            dy = bodies[j].pos.y - bodies[i].pos.y;
            dz = bodies[j].pos.z - bodies[i].pos.z;
            d2 = dx*dx + dy*dy + dz*dz + Epsilon;
            d = sqrt(d2);
            forceMag = (G*mass*mass)/(d2) - (H*mass*mass)/(d2*d2);
            bodies[i].force.x += forceMag * dx / d;
            bodies[i].force.y += forceMag * dy / d;
            bodies[i].force.z += forceMag * dz / d;
            bodies[j].force.x -= forceMag * dx / d;
            bodies[j].force.y -= forceMag * dy / d;
            bodies[j].force.z -= forceMag * dz / d;
        }
    }

    // Update positions and velocities
    for(int i = 0; i < n; i++)
    {
        bodies[i].vel.x += ((bodies[i].force.x - drag * bodies[i].vel.x) / mass) * dt;
        bodies[i].vel.y += ((bodies[i].force.y - drag * bodies[i].vel.y) / mass) * dt;
        bodies[i].vel.z += ((bodies[i].force.z - drag * bodies[i].vel.z) / mass) * dt;

        bodies[i].pos.x += bodies[i].vel.x * dt;
        bodies[i].pos.y += bodies[i].vel.y * dt;
        bodies[i].pos.z += bodies[i].vel.z * dt;
    }
}

void nBody()
{
	if(Pause != 1)
	{	
		getForces(bodies, MassOfBody, G, H, Epsilon, Drag, Dt, numBodies);
        
        DrawTimer++;
		if(DrawTimer == DrawRate) 
		{
			drawPicture();
			DrawTimer = 0;
		}
		
		PrintTimer++;
		if(PrintTimer == PrintRate) 
		{
			terminalPrint();
			PrintTimer = 0;
		}
		
		RunTime += Dt; 
		if(TotalRunTime < RunTime)
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
	printf("\n");
	printf("\033[0m");
	printf(" v: Toggle view (Perspective/Orthogonal) --> ");
	printf(" Current View: ");
	if (isOrthogonal) 
	{
		printf("\e[1m" " \033[0;32mOrthogonal\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;31mDefault\n" "\e[m");
	}
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
	
	printf("\n");
	printf("\n S: Screenshot");
	
	printf("\n");
	printf("\n q: Terminates the simulation");
	
	printf("\n");
}


void setup()
{	
	setSimulationParameters();
	allocateMemory();
	setInitialConditions();
	zeroOutSystem();
    	DrawTimer = 0;
    	PrintRate = 0;
	RunTime = 0.0;
	Trace = 0;
	Pause = 1;
	MovieOn = 0;
	terminalPrint();
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





