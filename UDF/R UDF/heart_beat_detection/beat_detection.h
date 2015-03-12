double* slope_sum_function(double* amplitude,int n);
int decision_rule(double *slope_sum, int n, double *onset_point);
int beat_detection( double *amplitude, int n, double *onset_point);
void pipeline_beat_detection(double* amplitude, int *len, double *onset_point);
