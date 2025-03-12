/* 
    this file contains the followinf functions:
        float4 centerOfMass();
        float4 linearVelocity();
        void zeroOutSystem();
        void getForces(Body* bodies, float mass, float G, float H, float Epsilon, float drag, float dt, int n);
        void nBody();
        
*/

#include "./header.h"

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
        if(bodies[i].movement != 1) //if the body is not still (movement 1 is still)
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
    }
	
}

void nBody()
{
    if (Pause != 1)
    {
        // Update positions and velocities
        for (int i = 0; i < numBodies; i++)
        {
            if (bodies[i].movement == 2) // sinusoidal
            {
                float frequency = 1.0f; // Adjust this value to change the period of the sine wave
                float amplitude = 0.2f; // Adjust this value to change the amplitude of the sine wave
    
                bodies[i].pos.x += bodies[i].vel.x * Dt;
                bodies[i].pos.y = bodies[i].initialY + amplitude * sin(frequency * bodies[i].pos.x);
            }
            else if (bodies[i].movement == 3) // circular
            {
                float angularVelocity = 2.0f; // Adjust this value to change the angular velocity of the circle

                float angle = bodies[i].circle.z + angularVelocity * RunTime;
                bodies[i].pos.x = bodies[i].circle.x + bodies[i].circle.w * cos(angle);
                bodies[i].pos.y = bodies[i].circle.y + bodies[i].circle.w * sin(angle);
            }
            else if (bodies[i].movement == 4) // Oscillation movement
            {
                float time = RunTime; // Use the elapsed time for smooth oscillation
                float frequency = 1.0f; // Adjust this value to change the frequency of the oscillation
                float amplitude = bodies[i].oscillationAmplitude; // Use the amplitude set for the body
                float angle = bodies[i].oscillationAngle; // Use the angle set for the body

                // Calculate the new position using a sine function
                bodies[i].pos.x = bodies[i].initialX + amplitude * cos(angle) * sin(frequency * time);
                bodies[i].pos.y = bodies[i].initialY + amplitude * sin(angle) * sin(frequency * time);
            }
            else
            {
                // Update position based on velocity for other movement types
                bodies[i].pos.x += bodies[i].vel.x * Dt;
                bodies[i].pos.y += bodies[i].vel.y * Dt;
                bodies[i].pos.z += bodies[i].vel.z * Dt;
            }
        }

        DrawTimer++;
        if (DrawTimer == DrawRate)
        {
            drawPicture();
            DrawTimer = 0;
        }

        PrintTimer++;
        if (PrintTimer == PrintRate)
        {
            // Print information if needed
            PrintTimer = 0;
        }

        RunTime += Dt;
        if (TotalRunTime < RunTime)
        {
            Pause = 1;
        }
    }
}