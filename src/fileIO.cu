/*
    this file contains the following functions:
        void readBodiesFromFile(const char* filename);
        void writeBodiesToFile(const char* filename);
        void loadBackgroundImage(const char* filename);
*/

#include "./header.h"

void readBodiesFromFile(const char* filename)
{
    // Append the file directory to the file
    string fileDir = "../PreviousRuns/";
    fileDir.append(filename); // Now fileDir = "/PreviousRuns/filename"

    FILE* file = fopen(fileDir.c_str(), "r");
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
        float initialX = 0.0f, initialY = 0.0f, oscillationAmplitude = 0.0f, oscillationAngle = 0.0f;
        int result = fscanf(file, "%d, %d, (%f, %f, %f, %f), %d, (%f, %f, %f), (%f, %f, %f), (%f, %f, %f), %f, %f, %f, %f, %f\n",
                            &newBody.id,
                            &isSolid,
                            &color_x, &color_y, &color_z, &color_w,
                            &newBody.movement,
                            &pos_x, &pos_y, &pos_z,
                            &vel_x, &vel_y, &vel_z,
                            &force_x, &force_y, &force_z,
                            &newBody.radius,
                            &initialX, &initialY, &oscillationAmplitude, &oscillationAngle);

        if (result == 17 || result == 21) // Old format or new format
        {
            newBody.isSolid = (bool)isSolid;
            newBody.color = make_float4(color_x, color_y, color_z, color_w);
            newBody.pos = make_float4(pos_x, pos_y, pos_z, 1.0f);
            newBody.vel = make_float4(vel_x, vel_y, vel_z, 0.0f);
            newBody.force = make_float4(force_x, force_y, force_z, 0.0f);

            if (result == 21) // New format
            {
                newBody.initialX = initialX;
                newBody.initialY = initialY;
                newBody.oscillationAmplitude = oscillationAmplitude;
                newBody.oscillationAngle = oscillationAngle;
            }
            else // Old format
            {
                newBody.initialX = 0.0f;
                newBody.initialY = 0.0f;
                newBody.oscillationAmplitude = 0.0f;
                newBody.oscillationAngle = 0.0f;
            }

            addBody(newBody);
        }
        else
        {
            fprintf(stderr, "Error: fscanf read %d values instead of 17 or 21\n", result);
            break;
        }
    }

    fclose(file);
    numBodies = numBodiesFromFile;
}

void writeBodiesToFile(const char* filename)
{
    string fileDir = "../PreviousRuns/";
    fileDir.append(filename); // Now fileDir = "/PreviousRuns/filename"

    FILE* file = fopen(fileDir.c_str(), "w");
    if (file == NULL)
    {
        fprintf(stderr, "Error: Could not open file %s for writing\n", filename);
        return;
    }

    // Write the number of bodies at the top of the file
    fprintf(file, "Number of bodies: %d\n", numBodies);

    // Write the header line
    fprintf(file, "ID, IsSolid, Color (R, G, B, A), Movement, Position (X, Y, Z), Velocity (X, Y, Z), Force (X, Y, Z), Radius, InitialX, InitialY, OscillationAmplitude, OscillationAngle\n");

    for (int i = 0; i < numBodies; i++)
    {
        fprintf(file, "%d, %d, (%f, %f, %f, %f), %d, (%f, %f, %f), (%f, %f, %f), (%f, %f, %f), %f, %f, %f, %f, %f\n",
                bodies[i].id,
                bodies[i].isSolid,
                bodies[i].color.x, bodies[i].color.y, bodies[i].color.z, bodies[i].color.w,
                bodies[i].movement,
                bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z,
                bodies[i].vel.x, bodies[i].vel.y, bodies[i].vel.z,
                bodies[i].force.x, bodies[i].force.y, bodies[i].force.z,
                bodies[i].radius,
                bodies[i].initialX, bodies[i].initialY, bodies[i].oscillationAmplitude, bodies[i].oscillationAngle);
    }

    fclose(file);
    printf("Body information written to %s\n", filename);
}

void loadBackgroundImage(const char* filename)
{
    printf("Attempting to load image: %s\n", filename); // Debug print
    
    backgroundTexture = SOIL_load_OGL_texture(
        filename,
        SOIL_LOAD_AUTO,
        SOIL_CREATE_NEW_ID,
        SOIL_FLAG_INVERT_Y
    );

    if (backgroundTexture == 0)
    {
        fprintf(stderr, "Error: Failed to load background image %s\n", filename);
        fprintf(stderr, "SOIL error: %s\n", SOIL_last_result()); // Print SOIL error message
    }
    else
    {
        printf("Successfully loaded background texture with ID: %u\n", backgroundTexture);
    }
}
