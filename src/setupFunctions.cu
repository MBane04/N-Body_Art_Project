#include "./header.h"

/*
  This file contains the following functions:
        void setSimulationParameters();
        void allocateMemory();
        void setInitialConditions();
        void setup();

*/

void setSimulationParameters()
{
    if(PreviousRunToggle == 0) numBodies = 0; //start with no bodies, a blank canvas

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
    //printf("Initial memory allocated with capacity: %d\n", capacity);
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

void setup()
{
	allocateMemory();
    if (PreviousRunToggle == 1)
    {
        // Read the previous simulation parameters from the specified file
        readBodiesFromFile(PreviousRunFile.c_str());
        setSimulationParameters();
        //zeroOutSystem();
    }
    else
    {
        // Set up a new simulation
        setSimulationParameters();
        allocateMemory();
        setInitialConditions();
        //zeroOutSystem();
    }

    DrawTimer = 0;
    PrintRate = 0;
    RunTime = 0.0;
    Trace = 0;
    Pause = 1;
    MovieOn = 0;
    terminalPrint();
}