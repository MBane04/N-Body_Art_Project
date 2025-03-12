#include "./header.h"

/*
    this file contains the following functions:

        void cursor_position_adapter(GLFWwindow* window, double xpos, double ypos);
        void mouse_button_adapter(GLFWwindow* window, int button, int action, int mods);
        void key_adapter(GLFWwindow* window, int key, int scancode, int action, int mods);
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
        
*/

//Adapts cursor from GLFW to GLUT so we don't have to change the code
void cursor_position_adapter(GLFWwindow* window, double xpos, double ypos)
{
    mousePassiveMotionCallback((int)xpos, (int)ypos);
}

//Adapts mouse button from GLFW to GLUT so we don't have to change the code
void mouse_button_adapter(GLFWwindow* window, int button, int action, int mods)
{
    int glutButton = (button == GLFW_MOUSE_BUTTON_LEFT) ? 0 : 
                    (button == GLFW_MOUSE_BUTTON_MIDDLE) ? 1 : 2;
    int glutState = (action == GLFW_PRESS) ? 0 : 1;
    
    double xpos, ypos;
    glfwGetCursorPos(window, &xpos, &ypos);
    
    myMouse(glutButton, glutState, (int)xpos, (int)ypos);
}

//Adapts key press from GLFW to GLUT so we don't have to change the code
//Adapts key press from GLFW to GLUT so we don't have to change the code
void key_adapter(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    printf("Key pressed: %d, action: %d, mods: %d\n", key, action, mods);
    if (action == GLFW_PRESS || action == GLFW_REPEAT) 
    {
        // Handle letter keys (A-Z)
        if (key >= GLFW_KEY_A && key <= GLFW_KEY_Z)
        {
            // Convert to the correct case based on shift modifier
            unsigned char charKey;
            if (mods & GLFW_MOD_SHIFT)
                charKey = (unsigned char)key; // Keep uppercase (65-90)
            else
                charKey = (unsigned char)(key + 32); // Convert to lowercase (97-122)
            
            printf("Converted key: %c (%d)\n", charKey, charKey);
            keyPressed(charKey, 0, 0);
        }
        // Handle other printable ASCII characters
        else if (key >= 32 && key <= 126)
        {
            printf("ASCII key: %c (%d)\n", (unsigned char)key, key);
            keyPressed((unsigned char)key, 0, 0);
        }
        else if (key == GLFW_KEY_ESCAPE)
        {
            glfwSetWindowShouldClose(window, GLFW_TRUE);
        }
        // Add special key handling here if needed
        // else if (key == GLFW_KEY_UP) { ... }
    }
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

// Update reshape to work with GLFW
void reshape(GLFWwindow* window, int w, int h)
{
    // Prevent division by zero
    if (h == 0) h = 1;

    // Update global window size variables
    XWindowSize = w;
    YWindowSize = h;

    // Calculate the aspect ratio of the window
    float aspectRatio = (float)w / (float)h; 

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

void keyPressed(unsigned char key, int x, int y)
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
        // Replace glutDestroyWindow(Window) with:
        glfwSetWindowShouldClose(window, GLFW_TRUE);
        printf("\nw Good Bye\n");
        return; //return, not exit so glfw can clean up
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
        printf("Enter the file name to save this run to: ");
        char filename[256];
        scanf("%s", filename);
        writeBodiesToFile(filename);
	}
    if(key == 'e')
    {
        if(EraseMode)
        {
            EraseMode = false;
            terminalPrint();
        }
        else
        {
            EraseMode = true;
            terminalPrint();
        }
    }
    if(key == 'g')
    {
        if(GridOn)
        {
            GridOn = false;
            drawPicture();
            terminalPrint();
        }
        else
        {
            GridOn = true;
            drawPicture();
            terminalPrint();
        }
    }

    if(key == 'b')
    {
        if(BackgroundToggle >= 0 && BackgroundToggle < 2)
        {
            BackgroundToggle++;
        }
        else
        {
            BackgroundToggle = 0;
        }
        if(BackgroundToggle == 1)
        {
            loadBackgroundImage("../starry-king-of-the-monsters-hdtv.jpg");
            drawPicture();
            terminalPrint();
        }
        else if (BackgroundToggle == 2)
        {
            loadBackgroundImage("../godzilla_background7.png");
            drawPicture();
            terminalPrint();
        }
        else
        {
            BackgroundToggle = 0;
            drawPicture();
            terminalPrint();
        }
    }

    if(NewBodyToggle == 1)
    {
        if (key == 'l') // cycle through colors, forward
        {
            if (ColorToggle < 16)
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
            printf("0 for random movement, 1 for still, 2 for sinusoidal, 3 for circular, 4 for oscillating\n");
            scanf("%d", &NewBodyMovement);
            if (NewBodyMovement < 0 || NewBodyMovement > 4)
            {
                printf("Invalid movement pattern.\n");
                NewBodyMovement = 0;
            }
            if(NewBodyMovement == 3)
            {
                //get the center of the circle from the user using the mouse
                selectCircleCenter = true;
                currentOscillationAmplitude = 0.0f;
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

        //add DrawLayer so you can decide what appears on top of what
        if(key == 'u')
        {
            DrawLayer++;
            drawPicture();
            terminalPrint();
        }
        if(key == 'y')
        {
            DrawLayer--;
            drawPicture();
            terminalPrint();
        }

       if(NewBodyMovement == 4)
       {
            if (key == 'r') // Rotate oscillation angle left
            {
                currentOscillationAngle -= 0.1f; // Adjust the angle increment as needed
                if (currentOscillationAngle < 0.0f)
                {
                    currentOscillationAngle += 2.0f * M_PI;
                }
                drawPicture();
                terminalPrint();
            }
            if (key == 'R') // Rotate oscillation angle right
            {
                currentOscillationAngle += 0.1f; // Adjust the angle increment as needed
                if (currentOscillationAngle >= 2.0f * M_PI)
                {
                    currentOscillationAngle -= 2.0f * M_PI;
                }
                drawPicture();
                terminalPrint();
            }

            if (key == '+') // Increase oscillation amplitude
            {
                currentOscillationAmplitude += 0.01f; // Adjust the amplitude increment as needed
                drawPicture();
                terminalPrint();
            }
            if (key == '-') // Decrease oscillation amplitude
            {
                currentOscillationAmplitude -= 0.01f; // Adjust the amplitude increment as needed
                if (currentOscillationAmplitude < 0.0f)
                {
                    currentOscillationAmplitude = 0.0f;
                }
                drawPicture();
                terminalPrint();
            }
       }
    }
}

void mousePassiveMotionCallback(int x, int y) 
{
    // Use proper conversion function instead of magic numbers
    float worldX, worldY;
    screenToWorld(x, y, &worldX, &worldY);
    
    MouseX = worldX;
    MouseY = worldY;
    MouseZ = 0.0f;
    
    if (IsDragging)
    {
        if(EraseMode)
            removeBodyAtPosition(MouseX, MouseY);
        else
            addBodyAtPosition(MouseX, MouseY);
    }
}

// This is called when you push a mouse button.
void myMouse(int button, int state, int x, int y)
{	
	if(state == GLUT_DOWN)
	{	
		if(button == GLUT_LEFT_BUTTON)
		{	
			if(NewBodyToggle == 1)
			{
                if(EraseMode)
                {
                    removeBodyAtPosition(MouseX, MouseY);
                }
                else if(selectCircleCenter)
                {
                    // Convert screen coordinates to world coordinates
                    screenToWorld(x, y, &circleCenterX, &circleCenterY);
                    printf("Circle center selected at (%f, %f)\n", circleCenterX, circleCenterY);
                    selectCircleCenter = false; // Reset the flag
                }
                else
                {
                    //generate random numbers for all the properties of the new body
                    
                    int index = numBodies; // Define and initialize index

                    // Convert window coordinates to OpenGL coordinates
                    screenToWorld(x, y, &MouseX, &MouseY);
                    MouseZ = 0.0f + DrawLayer/100.0f; // Keep the Z offset for drawing layers

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
                      else if(ColorToggle == 16)
                    {
                        newBody.color = getColor("bright_orange");
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
                    newBody.pos = {MouseX, MouseY, MouseZ + DrawLayer/100.0f, 1.0f}; // Directly assign values to float4
                    newBody.force = {0.0f, 0.0f, 0.0f, 0.0f}; // Directly assign values to float4
                    newBody.radius = newBodyRadius * DiameterOfBody/2.0f;

                    addBody(newBody);
                }   
            }
		}
		else if(button == GLUT_RIGHT_BUTTON) // Right Mouse button down
		{
            if (state == GLUT_DOWN)
            {
                //make it a toggle
                if(IsDragging == false)
                {
                    IsDragging = true;
                    screenToWorld(x, y, &MouseX, &MouseY);
                    MouseZ = 0.0f + DrawLayer/100.0f; // Keep the Z offset for drawing layers
                }
                else
                {
                    IsDragging = false;
                }
            }
            else if (state == GLUT_UP)
            {
                IsDragging = false;
                printf("Mouse up at (%f, %f)\n", MouseX, MouseY); // Debugging statement
            }
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
    if (MovieOn == 1) 
    {
        pclose(MovieFile);
    }
    free(Buffer);
    MovieOn = 0;
    printf("Movie recording stopped successfully\n");
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