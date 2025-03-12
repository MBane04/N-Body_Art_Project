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

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
    glutInitWindowSize(XWindowSize, YWindowSize);
    glutInitWindowPosition(5, 5);
    Window = glutCreateWindow("New Canvas");

    gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
    glMatrixMode(GL_MODELVIEW);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    loadBackgroundImage("../starry-king-of-the-monsters-hdtv.jpg");

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
    glDisable(GL_LIGHTING); //for lighting replace this and the next 2 lines with glEnable();
    glDisable(GL_LIGHT0);
    glDisable(GL_COLOR_MATERIAL);
    glEnable(GL_DEPTH_TEST);

    glutPassiveMotionFunc(mousePassiveMotionCallback);
    glutMouseFunc(myMouse);
    glutDisplayFunc(display);
    glutReshapeFunc(reshape);
    glutKeyboardFunc(keyPressed);
    glutIdleFunc(idle);
    terminalPrint();
    glutMainLoop();
    atexit(freeBodies);

    // Cleanup resources
    movieOff();
    freeBodies();

    return 0;
}





