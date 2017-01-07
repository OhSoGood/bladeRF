#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>

#include "libbladeRF.h"     /* Public API */
#include "bladerf_priv.h"   /* Implementation-specific items ("private") */
#include "capabilities.h"

#include "si5338.h"
#include "btle.h"
#include "lms.h"
#include "rel_assert.h"
#include "log.h"
#include "tuning.h"



int
btle_read_control(struct bladerf *dev,
                   			bladerf_module module,
                   			int * val)
{

	int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CONTROL_READ(dev, val);

	return status;
}


int
btle_write_control(struct bladerf *dev,
                   			bladerf_module module, 
                   			int val)
{

    int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CONTROL_WRITE(dev,0xffffffff,val);

	return status;
}


int
btle_read_connect(struct bladerf *dev,
                   			bladerf_module module,
                   			int * val)
{

	int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CONNECT_READ(dev, val);

	return status;
}


int
btle_write_connect(struct bladerf *dev,
                   			bladerf_module module, 
                   			int val)
{

    int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CONNECT_WRITE(dev,0xffffffff,val);

	return status;
}


int
btle_read_crc(struct bladerf *dev,
                   			bladerf_module module,
                   			int * val)
{

	int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CRC_READ(dev, val);

	return status;
}


int
btle_write_crc(struct bladerf *dev,
                   			bladerf_module module, 
                   			int val)
{

    int status;

	status = check_module(module);
	if (status != 0) {
		return status;
	}

	status = BTLE_CRC_WRITE(dev,0xffffffff,val);

	return status;
}



