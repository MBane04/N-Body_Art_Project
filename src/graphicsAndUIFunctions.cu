/*
    This file contains the following functions:
        void drawPicture();
        void drawGrid(float spacing, int numLines);
        void display();
        void renderBackground();
        void terminalPrint();
*/

#include "./header.h"


#include "./header.h"
#include <vector>

// Render a sphere with given radius, latitude segments, and longitude segments
void renderSphere(float radius, int slices, int stacks) //replaces glutSolidSphere
{
    // Generate sphere vertices
    std::vector<float> vertices;
    std::vector<float> normals;
    std::vector<unsigned int> indices;
    
    for (int lat = 0; lat <= slices; lat++) {
        float theta = lat * M_PI / slices;
        float sinTheta = sin(theta);
        float cosTheta = cos(theta);
        
        for (int lon = 0; lon <= stacks; lon++) {
            float phi = lon * 2 * M_PI / stacks;
            float sinPhi = sin(phi);
            float cosPhi = cos(phi);
            
            float x = cosPhi * sinTheta;
            float y = cosTheta;
            float z = sinPhi * sinTheta;
            
            normals.push_back(x);
            normals.push_back(y);
            normals.push_back(z);
            
            vertices.push_back(radius * x);
            vertices.push_back(radius * y);
            vertices.push_back(radius * z);
        }
    }
    
    // Generate indices
    for (int lat = 0; lat < slices; lat++) 
    {
        for (int lon = 0; lon < stacks; lon++) 
        {
            int first = (lat * (stacks + 1)) + lon;
            int second = first + stacks + 1;
            
            // Draw a quad for each segment
            glBegin(GL_QUADS);
            
            glNormal3f(normals[first * 3], normals[first * 3 + 1], normals[first * 3 + 2]);
            glVertex3f(vertices[first * 3], vertices[first * 3 + 1], vertices[first * 3 + 2]);
            
            glNormal3f(normals[first * 3 + 3], normals[first * 3 + 4], normals[first * 3 + 5]);
            glVertex3f(vertices[first * 3 + 3], vertices[first * 3 + 4], vertices[first * 3 + 5]);
            
            glNormal3f(normals[second * 3 + 3], normals[second * 3 + 4], normals[second * 3 + 5]);
            glVertex3f(vertices[second * 3 + 3], vertices[second * 3 + 4], vertices[second * 3 + 5]);
            
            glNormal3f(normals[second * 3], normals[second * 3 + 1], normals[second * 3 + 2]);
            glVertex3f(vertices[second * 3], vertices[second * 3 + 1], vertices[second * 3 + 2]);
            
            glEnd();
        }
    }
}

void drawPicture()
{
    if (Trace == 0)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    // Render the background image
    if (BackgroundToggle && backgroundTexture != 0)
    {
        renderBackground();
    }

    if (GridOn) drawGrid(0.5f, 50);  // Wider grid spacing, more grid lines

    if (NewBodyToggle == 1)
    {
        float4 mouseColor;

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
        else if (ColorToggle == 16)
        {
            //color astronaut blue
            mouseColor = getColor("bright_orange");
            glColor3d(mouseColor.x, mouseColor.y, mouseColor.z);
        }
        else
        {
            //color white
            glColor3d(1.0, 1.0, 1.0);
        }
        glPushMatrix();
        glTranslatef(MouseX, MouseY, MouseZ + DrawLayer / 100.0f);
        renderSphere(newBodyRadius * DiameterOfBody / 2.0, 20, 20);
        glPopMatrix();

        // Draw the oscillation path line
        if (NewBodyMovement == 4)
        {
            float dx = currentOscillationAmplitude * cos(currentOscillationAngle);
            float dy = currentOscillationAmplitude * sin(currentOscillationAngle);
            glColor3f(1.0f, 0.0f, 0.0f); // Red color for the line
            glBegin(GL_LINES);
            // Draw line in front of the body
            glVertex3f(MouseX, MouseY, MouseZ);
            glVertex3f(MouseX + dx, MouseY + dy, MouseZ);
            // Draw line behind the body
            glVertex3f(MouseX, MouseY, MouseZ);
            glVertex3f(MouseX - dx, MouseY - dy, MouseZ);
            glEnd();
        }
    }

    for (int i = 0; i < numBodies; i++)
    {
        glColor3d(bodies[i].color.x, bodies[i].color.y, bodies[i].color.z);
        glPushMatrix();
        glTranslatef(bodies[i].pos.x, bodies[i].pos.y, bodies[i].pos.z);
        //glutSolidSphere(bodies[i].radius, 20, 20);, args are radius, slices (vertical) , stacks (horizontal)
        renderSphere(bodies[i].radius, 20, 20);
        glPopMatrix();
    }

    glfwSwapBuffers(window); //changed from glutSwapBuffers();

    if (MovieOn == 1)
    {
        glReadPixels(0, 0, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
        fwrite(Buffer, sizeof(int) * XWindowSize * YWindowSize, 1, MovieFile);
    }

 
}

void drawGrid(float spacing, int numLines)
{
    glColor3f(0.8f, 0.8f, 0.8f); // Set grid color (light gray)
    glBegin(GL_LINES);

    // Draw vertical lines
    for (int i = -numLines; i <= numLines; ++i)
    {
        float x = i * spacing;
        glVertex3f(x, -numLines * spacing, 0.0f);
        glVertex3f(x, numLines * spacing, 0.0f);
    }

    // Draw horizontal lines
    for (int i = -numLines; i <= numLines; ++i)
    {
        float y = i * spacing;
        glVertex3f(-numLines * spacing, y, 0.0f);
        glVertex3f(numLines * spacing, y, 0.0f);
    }

    glEnd();
}


void display()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    renderBackground();
	drawPicture();
}

void renderBackground()
{
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);

    // Save the current color state
    GLboolean colorMask[4];
    glGetBooleanv(GL_COLOR_WRITEMASK, colorMask);
    GLfloat currentColor[4];
    glGetFloatv(GL_CURRENT_COLOR, currentColor);

    // Reset color to white
    glColor3f(1.0f, 1.0f, 1.0f);

    // Calculate aspect ratio
    float windowAspect = (float)XWindowSize / (float)YWindowSize;

    glBegin(GL_QUADS);
    glTexCoord2f(0.0f, 0.0f); glVertex3f(-windowAspect, -1.0f, -1.0f);
    glTexCoord2f(1.0f, 0.0f); glVertex3f(windowAspect, -1.0f, -1.0f);
    glTexCoord2f(1.0f, 1.0f); glVertex3f(windowAspect, 1.0f, -1.0f);
    glTexCoord2f(0.0f, 1.0f); glVertex3f(-windowAspect, 1.0f, -1.0f);
    glEnd();

    glDisable(GL_TEXTURE_2D);

    // Restore the previous color state
    glColor4fv(currentColor);
    glColorMask(colorMask[0], colorMask[1], colorMask[2], colorMask[3]);
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
    printf("\n");
    printf("\033[0m");
    printf(" g: Grid On/Off Toggle --> ");
    if (GridOn)
    {
        printf("\033[0;32m");
        printf(BOLD_ON "Grid On" BOLD_OFF);
    }
    else
    {
        printf("\033[0;31m");
        printf(BOLD_ON "Grid Off" BOLD_OFF);
    }

    printf("\n");
    printf("\033[0m");
    printf(" b: Background On/Off Toggle --> ");
    if (BackgroundToggle)
    {
        printf("\033[0;32m");
        printf(BOLD_ON "Background On" BOLD_OFF);
    }
    else
    {
        printf("\033[0;31m");
        printf(BOLD_ON "Background Off" BOLD_OFF);
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
         else if (ColorToggle == 16)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Bright Orange" BOLD_OFF);
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
            printf(BOLD_ON "Still" BOLD_OFF);
        }
        else if(NewBodyMovement == 2)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Sinusoidal" BOLD_OFF);
        }
        else if (NewBodyMovement == 3)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Circular" BOLD_OFF);
            if(selectCircleCenter)
            {
                printf("\n");
                printf("\033[0m");
                printf("Click to select circle center:");
            }
        
        }
        else if (NewBodyMovement == 4)
        {
            printf("\033[0;32m");
            printf(BOLD_ON "Oscillation" BOLD_OFF);

            printf("\n");
            printf("r/R: rotate the oscillation angle forwards/backwards\n");
            printf("+/-: increase/decrease the oscillation amplitude\n");
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
        
        printf("\n");
        printf("\033[0m");
        printf("e: Erase bodies toggle --> ");

        if (!EraseMode)
        {
            printf("\033[0;31m");
            printf(BOLD_ON "Off" BOLD_OFF);
        }
        else
        {
            printf("\033[0;32m");
            printf(BOLD_ON "On" BOLD_OFF);
        }

        printf("\n");
        printf("\033[0m");
        printf("y/u: decrease/increase layer  --> Current Layer: %d", DrawLayer);

    }
    printf("\n");
}