//main file for the nBodyArt project
#include "./header.h"

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

    if(!glfwInit()) // Initialize GLFW, check for failure
    {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return -1;
    }

    // Set compatibility mode to allow legacy OpenGL (this is just standard)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2); //these 2 lines are for compatibility with older versions of OpenGL (2.1+) ensures backwards compatibility
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_ANY_PROFILE); //this line is for compatibility with older versions of OpenGL

    //Experimenting with using monitor size in glfw
    // Get the primary monitor
    GLFWmonitor* primaryMonitor = glfwGetPrimaryMonitor();
    if (!primaryMonitor) {
        fprintf(stderr, "Failed to get primary monitor\n");
        return -1;
    }

    // Get the video mode of the primary monitor
    const GLFWvidmode* mode = glfwGetVideoMode(primaryMonitor);
    if (!mode) {
        fprintf(stderr, "Failed to get video mode\n");
        return -1;
    }

    // Set window size to 80% of monitor resolution
    XWindowSize = (int)(mode->width * 0.8);
    YWindowSize = (int)(mode->height * 0.8);

    // Create a windowed mode window and its OpenGL context
    window = glfwCreateWindow(XWindowSize, YWindowSize, "New Canvas", NULL, NULL); // args: width, height, title, monitor, share
    if (!window) // Check if window creation failed
    {
        glfwTerminate(); // Terminate GLFW
        fprintf(stderr, "Failed to create window\n");
        return -1;
    }

    

    // Make the window's context current
    glfwMakeContextCurrent(window); // Make the window's context current, meaning that all future OpenGL commands will apply to this window
    glfwSwapInterval(1); // Enable vsync (1 = on, 0 = off), vsync is a method used to prevent screen tearing which occurs when the GPU is rendering frames at a rate faster than the monitor can display them

    //these set up our callbacks, most have been changed to adapters until GUI is implemented
    glfwSetFramebufferSizeCallback(window, reshape);  //sets the callback for the window resizing
    glfwSetCursorPosCallback(window, cursor_position_adapter); //sets the callback for the cursor position
    glfwSetMouseButtonCallback(window, mouse_button_adapter); //sets the callback for the mouse clicks
    glfwSetKeyCallback(window, key_adapter); //sets the callback for the keyboard

    // Initialize GLAD (neccessary to load OpenGL functions including the GUI library)
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) // Load all OpenGL function pointers
    {
        fprintf(stderr, "Failed to initialize GLAD\n");
        return -1;
    }

    // Set the viewport size and aspect ratio
    glViewport(0, 0, XWindowSize, YWindowSize);
    float aspectRatio = (float)XWindowSize / (float)YWindowSize;

    // PROJECTION MATRIX - this controls how wide your viewing area is
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    // Use a much wider frustum to give more workspace (-3 to +3 instead of -0.2 to +0.2)
    if (isOrthogonal) 
    {
        glOrtho(-3.0 * aspectRatio, 3.0 * aspectRatio, -3.0, 3.0, Near, Far);
    } 
    else 
    {
        glFrustum(-3.0 * aspectRatio, 3.0 * aspectRatio, -3.0, 3.0, Near, Far);
    }

    // MODELVIEW MATRIX - this controls camera position
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
    

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f); // Set the clear color to white

    // Load the background image
    loadBackgroundImage("../media/starry-king-of-the-monsters-hdtv.jpg");

    // Set up the lighting
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

    //disable lighting by default for this project
    glDisable(GL_LIGHTING); //for lighting replace this and the next 2 lines with glEnable();
    glDisable(GL_LIGHT0);
    glDisable(GL_COLOR_MATERIAL);
    glEnable(GL_DEPTH_TEST);


    //*****************************************ImGUI stuff here********************************
    // Initialize ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;  // Enable keyboard controls

    // Setup ImGui style
    ImGui::StyleColorsDark();  // Choose a style (Light, Dark, or Classic)
    ImGuiStyle& style = ImGui::GetStyle(); // Get the current style
    style.Colors[ImGuiCol_WindowBg].w = 1.0f;  // Set window background color

    // Setup Platform/Renderer backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);  // Setup Platform bindings
    ImGui_ImplOpenGL3_Init("#version 130");      // Setup Renderer bindings

    // Load a font
    io.Fonts->AddFontDefault();

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    //********Back to different stuff here

    // Main loop
    while (!glfwWindowShouldClose(window))
    {
        // Poll events
        glfwPollEvents();
        
        // Start the ImGui frame
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
    
        // Update simulation state first
        idle();
        
        // Let display() handle the single clear
        display();
        
        // Create ImGui UI here - after scene rendering
        createGUI();
        
        // Render ImGui
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        
        // Swap buffers ONCE at the end
        glfwSwapBuffers(window);
    }
    
    
    // Cleanup resources
    movieOff();
    freeBodies();

    //shutdown ImGui
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    // Terminate GLFW
    glfwDestroyWindow(window);
    glfwTerminate();





    // glutInit(&argc, argv);
    // glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
    // glutInitWindowSize(XWindowSize, YWindowSize);
    // glutInitWindowPosition(5, 5);
    // Window = glutCreateWindow("New Canvas");

    // gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
    // glMatrixMode(GL_PROJECTION);
    // glLoadIdentity();
    // glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
    // glMatrixMode(GL_MODELVIEW);
    // glClearColor(1.0, 1.0, 1.0, 1.0);
    // loadBackgroundImage("../starry-king-of-the-monsters-hdtv.jpg");

    // GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
    // GLfloat light_ambient[] = {0.0, 0.0, 0.0, 1.0};
    // GLfloat light_diffuse[] = {1.0, 1.0, 1.0, 1.0};
    // GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
    // GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
    // GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
    // GLfloat mat_shininess[] = {10.0};
    // glShadeModel(GL_SMOOTH);
    // glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
    // glLightfv(GL_LIGHT0, GL_POSITION, light_position);
    // glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
    // glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
    // glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
    // glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
    // glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    // glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
    // glDisable(GL_LIGHTING); //for lighting replace this and the next 2 lines with glEnable();
    // glDisable(GL_LIGHT0);
    // glDisable(GL_COLOR_MATERIAL);
    // glEnable(GL_DEPTH_TEST);

    // glutPassiveMotionFunc(mousePassiveMotionCallback);
    // glutMouseFunc(myMouse);
    // glutDisplayFunc(display);
    // glutReshapeFunc(reshape);
    // glutKeyboardFunc(keyPressed);
    // glutIdleFunc(idle);
    // terminalPrint();
    // glutMainLoop();
    // atexit(freeBodies);

}





