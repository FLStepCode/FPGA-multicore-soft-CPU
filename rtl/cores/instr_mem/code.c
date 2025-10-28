// Type your code here, or load an example.

int main () {
    long (*old_image)[50] = (long (*)[50])0;
    long (*new_image)[48] = (long (*)[48])20480;
    long *kernel = (long *)40960;

    for (int i = 1; i < 90; i++) {
        for (int j = 1; j < 49; j++) {
            new_image[i-1][j-1] = kernel[0] * old_image[i-1][j-1] + 
                                  kernel[1] * old_image[i-1][j] + 
                                  kernel[2] * old_image[i-1][j+1] +
                                  kernel[3] * old_image[i][j-1] + 
                                  kernel[4] * old_image[i][j] + 
                                  kernel[5] * old_image[i][j+1] + 
                                  kernel[6] * old_image[i+1][j-1] + 
                                  kernel[7] * old_image[i+1][j] + 
                                  kernel[8] * old_image[i+1][j+1];
        }
    }
}