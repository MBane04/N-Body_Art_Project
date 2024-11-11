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
using namespace std;

FILE* ffmpeg;

// defines for terminal stuff.
#define BOLD_ON  "\e[1m"
#define BOLD_OFF   "\e[m"

FILE* MovieFile;

// Globals
int NumberOfBodies;
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
double MouseX, MouseY, MouseZ;

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
void setInitailConditions();
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
} Body;

Body* bodies = NULL;
int numBodies = 0;

void addBody(int index, double x, double y, double z, double vx, double vy, double vz, double mass) 
{
    // Reallocate memory to accommodate the new body
    Body* temp = (Body*)realloc(bodies, (numBodies + 1) * sizeof(Body));
    if (temp == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    bodies = temp;

    // Initialize the new body
	bodies[numBodies].id = index;
	bodies[numBodies].isSolid = true;
	bodies[numBodies].color.x = 1.0;
	bodies[numBodies].color.y = 1.0;
	bodies[numBodies].color.z = 1.0;
	bodies[numBodies].color.w = 1.0;
	bodies[numBodies].movement = 0;
	bodies[numBodies].pos.x = x;
	bodies[numBodies].pos.y = y;
	bodies[numBodies].pos.z = z;
	bodies[numBodies].pos.w = 1.0;
	bodies[numBodies].vel.x = vx;
	bodies[numBodies].vel.y = vy;
	bodies[numBodies].vel.z = vz;
	bodies[numBodies].vel.w = 0.0;

    // Increment the number of bodies
    numBodies++;

	//for debugging
	printf("Body %d added at (%f, %f, %f) with velocity (%f, %f, %f)\n", index, x, y, z, vx, vy, vz);
}

void freeBodies() 
{
    free(bodies);
}

void Display()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glClear(GL_DEPTH_BUFFER_BIT);
	drawPicture();
}

void idle()
{
	nBody();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);
}

void KeyPressed(unsigned char key, int x, int y)
{	
	if(key == 'q')
	{
		pclose(ffmpeg);
		glutDestroyWindow(Window);
		printf("\nw Good Bye\n");
		exit(0);
	}
	if(key == 'o')
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-1.0, 1.0, -1.0, 1.0, Near, Far);
		glMatrixMode(GL_MODELVIEW);
		drawPicture();
	}
	if(key == 'f')
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
		glMatrixMode(GL_MODELVIEW);
		drawPicture();
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
		NewBodyToggle = 1;
	}
}

void mousePassiveMotionCallback(int x, int y) 
{
	// This function is called when the mouse moves without any button pressed
	// x and y are the current mouse coordinates
	
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
				//place new body where the mouse is.
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
	glutPostRedisplay();
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

void movieOn()
{
	string ts = getTimeStamp();
	ts.append(".mp4");

	// Setting up the movie buffer.
	/*const char* cmd = "ffmpeg -loglevel quiet -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
		      "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output.mp4";*/

	string baseCommand = "ffmpeg -loglevel quiet -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
				"-c:v libx264rgb -threads 0 -preset fast -y -pix_fmt yuv420p -crf 0 -vf vflip ";

	string z = baseCommand + ts;

	const char *ccx = z.c_str();
	MovieFile = popen(ccx, "w");
	//Buffer = new int[XWindowSize*YWindowSize];
	Buffer = (int*)malloc(XWindowSize*YWindowSize*sizeof(int));
	MovieOn = 1;
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

	const char* cmd = "ffmpeg -loglevel quiet -framerate 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
				"-c:v libx264rgb -threads 0 -preset fast -y -crf 0 -vf vflip output1.mp4";
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

	
	//system("ffmpeg -i output1.mp4 screenShot.jpeg");
	//system("rm output1.mp4");
	
	Pause = pauseFlag;
	//ffmpeg -i output1.mp4 output_%03d.jpeg
}

void setSimulationParameters()
{
	NumberOfBodies = 16;

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
	//allocate memory for the bodies, now stored in the bodies array of structs
	bodies = (Body*)malloc(NumberOfBodies * sizeof(Body));
}

void setInitailConditions()
{
    float dx, dy, dz, d, d2;
    int test;
	time_t t;
	
	srand((unsigned) time(&t));
	for(int i = 0; i < NumberOfBodies; i++)
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
	
	for(int i = 0; i < NumberOfBodies; i++)
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
	
	for(int i = 0; i < NumberOfBodies; i++)
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
		
	for(int i = 0; i < NumberOfBodies; i++)
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
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
		
	for(int i = 0; i < NumberOfBodies; i++)
	{
		glColor3d(bodies[i].color.x, bodies[i].color.y, bodies[i].color.z);
		glPushMatrix();
			glTranslatef(bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z);
			glutSolidSphere(DiameterOfBody/2.0, 20, 20);
		glPopMatrix();
	}
	glutSwapBuffers();
	
	if(MovieOn == 1)
	{
		glReadPixels(5, 5, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
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
		getForces(bodies, MassOfBody, G, H, Epsilon, Drag, Dt, NumberOfBodies);
        
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

	if (NewBodyToggle== 0) 
	{
		printf("\033[0;31m");
		printf(BOLD_ON "Mode: Position" BOLD_OFF); 
	}
	else 
	{
		printf("\033[0;32m");
		printf(BOLD_ON "Mode: Add Body" BOLD_OFF);
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
	setInitailConditions();
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
	
	XWindowSize = 1000;
	YWindowSize = 1000; 
	//Buffer = new int[XWindowSize*YWindowSize];

	// Clip plains
	Near = 0.2;
	Far = 30.0;

	//Direction here your eye is located location
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 2.0;

	//Where you are looking
	CenterX = 0.0;
	CenterY = 0.0;
	CenterZ = 0.0;

	//Up vector for viewing
	UpX = 0.0;
	UpY = 1.0;
	UpZ = 0.0;
	
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
	glutInitWindowSize(XWindowSize,YWindowSize);
	glutInitWindowPosition(5,5);
	Window = glutCreateWindow("N Body");
	
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
	glMatrixMode(GL_MODELVIEW);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	
	GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
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
	return 0;
}




