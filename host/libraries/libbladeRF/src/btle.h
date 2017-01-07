

#ifndef BLTE_H
#define BLTE_H


#include <libbladeRF.h>
#include "bladerf_priv.h"

#define BTLE_CONTROL_READ(dev, val) \
    dev->fn->btle_control_read(dev, val)


#define BTLE_CONTROL_WRITE(dev, mask, val) \
    dev->fn->btle_control_write(dev, mask, val)


#define BTLE_CONNECT_READ(dev, val) \
    dev->fn->btle_connect_read(dev, val)


#define BTLE_CONNECT_WRITE(dev, mask, val) \
    dev->fn->btle_connect_write(dev, mask, val)


#define BTLE_CRC_READ(dev, val) \
    dev->fn->btle_crc_read(dev, val)


#define BTLE_CRC_WRITE(dev, mask, val) \
    dev->fn->btle_crc_write(dev, mask, val)


int btle_read_control(struct bladerf *dev,
                   bladerf_module module,
                   int * val);

int btle_write_control(struct bladerf *dev,
                   bladerf_module module, 
                   int val);


int btle_read_connect(struct bladerf *dev,
                   bladerf_module module,
                   int * val);

int btle_write_connect(struct bladerf *dev,
                   bladerf_module module, 
                   int val);


int btle_read_crc(struct bladerf *dev,
                   bladerf_module module,
                   int * val);

int btle_write_crc(struct bladerf *dev,
                   bladerf_module module, 
                   int val);

#endif
