/*
 * gpu_voltage_control.h -- gpu voltage control interface for the sgs2/3
 *
 *  Copyright (C) 2011 Michael Wodkins
 *  twitter - @xdanetarchy
 *  XDA-developers - netarchy
 *
 *  Modified for SiyahKernel
 *  Modified for Perseus kernel
 *
 *  This program is free software; you can redistribute  it and/or modify it
 *  under  the terms of the GNU General Public License as published by the
 *  Free Software Foundation;
 *
 */

#define MIN_VOLTAGE_GPU 600000
#define MAX_VOLTAGE_GPU 1400000
#define MALI_DVFS_STEPS 5

void gpu_voltage_control_start(void);
