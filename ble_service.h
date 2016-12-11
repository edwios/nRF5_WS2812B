
#ifndef OUR_SERVICE_H__
#define OUR_SERVICE_H__

#include <stdint.h>
#include "ble.h"
#include "ble_srv_common.h"
#include "ble_advdata.h"
#include "ble_advertising.h"
#include "ble_conn_params.h"
#include "ble_gap.h"
#include "ble_bas.h"
#include "ble_dis.h"
#include "softdevice_handler.h"
#include "device.h"

// Defining 16-bit service and 128-bit base UUIDs
// Base UUID 00000000-BB79-2CBE-7648-CFA9EBAAB65F
// Little endian form and 12 & 13th octet are ignored
#define BLE_UUID_OUR_BASE_UUID              	{{0x5F, 0xB6, 0xAA, 0xEB, 0xA9, 0xCF, 0x48, 0x76, 0xBE, 0x2C, 0x79, 0xBB, 0x00, 0x00, 0x00, 0x00}} // 128-bit base UUID
// Environmental sensing UUiD (short) is 0x181A
#define BLE_UUID_OUR_SERVICE_UUID               0x181a // Environmental Sensing

// Defining various 16-bit characteristic UUIDs
#define BLE_UUID_RGBLED_CHARACTERISTC_UUID			0xFF00 // RGB

// This structure contains various status information for our service. 
// The name is based on the naming convention used in Nordics SDKs. 
// 'ble’ indicates that it is a Bluetooth Low Energy relevant structure and 
// ‘os’ is short for Our Service). 
typedef struct
{
    uint16_t                    conn_handle;    /**< Handle of the current connection (as provided by the BLE stack, is BLE_CONN_HANDLE_INVALID if not in a connection).*/
    uint16_t                    service_handle; /**< Handle of Our Service (as provided by the BLE stack). */
    // Add handles for the characteristic attributes to our struct
    ble_gatts_char_handles_t    char_handles;
}ble_os_t;

/**@brief Function for handling BLE Stack events related to our service and characteristic.
 *
 * @details Handles all events from the BLE stack of interest to Our Service.
 *
 * @param[in]   p_our_service       Our Service structure.
 * @param[in]   p_ble_evt  Event received from the BLE stack.
 */
void ble_our_service_on_ble_evt(ble_os_t * p_our_service, ble_evt_t * p_ble_evt);

/**@brief Function for initializing our new service.
 *
 * @param[in]   p_our_service       Pointer to Our Service structure.
 */
void our_service_init(ble_os_t * p_our_service, ble_uuid_t * service_uuid);





#endif  /* _ OUR_SERVICE_H__ */
