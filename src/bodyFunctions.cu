/*
    This file contains the following functions:
    float4 getColor(const char* colorName);
    void screenToWorld(int x, int y, float* worldX, float* worldY);
    void addBody(Body newBody);
    void addBodyAtPosition(float x, float y);
    void removeBodyAtPosition(float x, float y);
    void freeBodies();


*/

#include "./header.h"

// Helper functions
float4 getColor(const char* colorName) {
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
    if (strcmp(colorName, "bright_orange") == 0) return colors.bright_orange;
    return (float4){0.0, 0.0, 0.0, 1.0}; // Default value
}

void screenToWorld(int x, int y, float* worldX, float* worldY) {
    *worldX = (5.76 * x / XWindowSize) - 1.84f; // Map x to (-1.84, 1.84)
    *worldY = -(2.9f * y / YWindowSize) + 1.0f;   // Map y to (-1, 1)
    //printf("Converted screen (%d, %d) to world (%f, %f)\n", x, y, *worldX, *worldY); // Debugging statement
}

// Body Management functions
void addBody(Body newBody) {
    // Reallocate memory to accommodate the new body
    if (numBodies >= capacity) {
        capacity *= 2; //double the capacity
        Body* temp = (Body*)realloc(bodies, capacity * sizeof(Body));
        if (temp == NULL) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(1);
        }
        bodies = temp; //assign the new memory to the bodies array
    }

    // Set movement-specific properties
    if(newBody.movement == 0) { //random movement
        newBody.vel.x = ((float)rand()/(float)RAND_MAX)*2.0f - 1.0f;
        newBody.vel.y = ((float)rand()/(float)RAND_MAX)*2.0f - 1.0f;
        newBody.vel.z = 0.0;
    }
    else if (newBody.movement == 1) { //still
        newBody.vel.x = 0.0f;
        newBody.vel.y = 0.0f;
        newBody.vel.z = 0.0f;
    }
    else if (newBody.movement == 2) { //sinusoidal
        newBody.vel.x = 0.2f;
        newBody.vel.y = 0.0f;
        newBody.vel.z = 0.0f;
        newBody.initialY = newBody.pos.y; // Store the initial y position
    }
    else if (newBody.movement == 3) { //circular
        newBody.circle.x = circleCenterX; // Store the center x position
        newBody.circle.y = circleCenterY; // Store the center y position
        newBody.circle.z = atan2(newBody.pos.y - circleCenterY, newBody.pos.x - circleCenterX); // Calculate the initial angle
        newBody.circle.w = sqrt(pow(newBody.pos.x - circleCenterX, 2) + pow(newBody.pos.y - circleCenterY, 2)); // Calculate the radius
    }
    else if (newBody.movement == 4) { //oscillating
        newBody.initialX = newBody.pos.x;
        newBody.initialY = newBody.pos.y;
        newBody.oscillationAmplitude = currentOscillationAmplitude; 
        newBody.oscillationAngle = currentOscillationAngle;
    }

    // Add the new body to the array
    bodies[numBodies] = newBody;
    
    // Increment the number of bodies
    numBodies++;
}

void addBodyAtPosition(float x, float y) {
    Body newBody;

    // Set the color based on the ColorToggle value
    switch (ColorToggle) {
        case 1: newBody.color = getColor("paris_m"); break;
        case 2: newBody.color = getColor("manz"); break;
        case 3: newBody.color = getColor("outer_space"); break;
        case 4: newBody.color = getColor("curious_blue"); break;
        case 5: newBody.color = getColor("tahuna_sands"); break;
        case 6: newBody.color = getColor("livid_brown"); break;
        case 7: newBody.color = getColor("neptune"); break;
        case 8: newBody.color = getColor("lochmara"); break;
        case 9: newBody.color = getColor("regal_blue"); break;
        case 10: newBody.color = getColor("vis_vis"); break;
        case 11: newBody.color = getColor("light_curious_blue"); break;
        case 12: newBody.color = getColor("ironside_grey"); break;
        case 13: newBody.color = getColor("yellow"); break;
        case 14: newBody.color = getColor("deco"); break;
        case 15: newBody.color = getColor("astronaut_blue"); break;
        default: newBody.color = getColor("default"); break;
    }

    //set remaining properties of the new body
    newBody.id = numBodies;
    newBody.pos = make_float4(x, y, 0.0 + DrawLayer / 100.0, 1.0f);
    newBody.vel = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    newBody.force = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    newBody.radius = newBodyRadius * DiameterOfBody / 2.0f;
    newBody.isSolid = NewBodySolid;
    newBody.movement = NewBodyMovement;

    if (NewBodyMovement == 4) { // Oscillation movement
        newBody.initialX = x;
        newBody.initialY = y;
        newBody.oscillationAmplitude = currentOscillationAmplitude;
        newBody.oscillationAngle = currentOscillationAngle;
    }

    addBody(newBody);
}

void removeBodyAtPosition(float x, float y) {
    for (int i = 0; i < numBodies; ++i) {
        float dx = bodies[i].pos.x - x;
        float dy = bodies[i].pos.y - y;
        float distance = sqrt(dx * dx + dy * dy);

        if (distance < bodies[i].radius) {
            // Remove the body by shifting the remaining bodies
            for (int j = i; j < numBodies - 1; ++j) {
                bodies[j] = bodies[j + 1];
            }
            --numBodies;
            return;
        }
    }
}

void freeBodies() {
    free(bodies);
    bodies = NULL;
}