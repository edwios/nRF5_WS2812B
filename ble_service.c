
#include <stdint.h>
#include <string.h>
#include "nrf_gpio.h"
#include "app_error.h"
#include "SEGGER_RTT.h"
#include "ble_service.h"

static uint32_t srgb = 0;
//static uint16_t sbatt = 0;

// Housekeeping of ble connections related to our service and characteristic
void ble_our_service_on_ble_evt(ble_os_t * p_our_service, ble_evt_t * p_ble_evt)
{
    // case handling BLE events related to our service. 
    switch (p_ble_evt->header.evt_id)
    {
        case BLE_GAP_EVT_CONNECTED:
            p_our_service->conn_handle = p_ble_evt->evt.gap_evt.conn_handle;
            break;
        case BLE_GAP_EVT_DISCONNECTED:
            p_our_service->conn_handle = BLE_CONN_HANDLE_INVALID;
            break;
        default:
            // No implementation needed.
            break;
    }
}

/**@brief Function for adding our new characterstic to "Our service" that we initiated in the previous tutorial. 
 *
 * @param[in]   p_our_service        Our Service structure.
 *
 */
static uint32_t our_char_add(ble_os_t * p_our_service, ble_gatts_char_handles_t* p_chandle, uint16_t chuuid, bool notifyenabled, bool writeenabled, uint32_t* p_value)
{
    uint32_t            err_code;
    ble_uuid_t          char_uuid;
    ble_uuid128_t       base_uuid = BLE_UUID_OUR_BASE_UUID;

    char_uuid.uuid = chuuid;
    err_code = sd_ble_uuid_vs_add(&base_uuid, &char_uuid.type);
    APP_ERROR_CHECK(err_code);

    // Add read only properties to our characteristic
    ble_gatts_char_md_t char_md;
    memset(&char_md, 0, sizeof(char_md));
    char_md.char_props.read = 1;
    char_md.char_props.write = 0;
    
    if (notifyenabled) {
        // Configuring Client Characteristic Configuration Descriptor metadata
        // for notification and add to char_md structure
        // This should be read/write
        static ble_gatts_attr_md_t cccd_md;
        memset(&cccd_md, 0, sizeof(cccd_md));
        BLE_GAP_CONN_SEC_MODE_SET_OPEN(&cccd_md.read_perm);
        BLE_GAP_CONN_SEC_MODE_SET_OPEN(&cccd_md.write_perm);
        cccd_md.vloc                = BLE_GATTS_VLOC_STACK;    
        char_md.p_cccd_md           = &cccd_md;
        char_md.char_props.notify   = 1;   
    }
    
    // Configure the attribute metadata
    ble_gatts_attr_md_t attr_md;
    memset(&attr_md, 0, sizeof(attr_md));  
    attr_md.vloc        = BLE_GATTS_VLOC_USER; // user provided location
    
    // Set read/write security levels to our characteristic
    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.read_perm);
    if (writeenabled) {
        char_md.char_props.write = 1;
        BLE_GAP_CONN_SEC_MODE_SET_OPEN(&attr_md.write_perm);
    } else {
        BLE_GAP_CONN_SEC_MODE_SET_NO_ACCESS(&attr_md.write_perm);
    }
    
    // Configure the characteristic value attribute
    ble_gatts_attr_t    attr_char_value;
    memset(&attr_char_value, 0, sizeof(attr_char_value));
    attr_char_value.p_uuid      = &char_uuid;
    attr_char_value.p_attr_md   = &attr_md;
    
    // Define characteristic length (in number of bytes) and set
    // initial value to whatever passed to here
    attr_char_value.max_len     = 4;
    attr_char_value.init_len    = 4;
    attr_char_value.p_value     = (uint8_t *)p_value;

    // Add our new characteristic to the service
    err_code = sd_ble_gatts_characteristic_add(p_our_service->service_handle,
                                                &char_md,
                                                &attr_char_value,
                                                p_chandle);
    APP_ERROR_CHECK(err_code);

    return NRF_SUCCESS;
}


/**@brief Function for initiating our new service.
 *
 * @param[in]   p_our_service        Our Service structure.
 *
 */
void our_service_init(ble_os_t * p_our_service, ble_uuid_t * service_uuid)
{
//    ble_bas_init_t   bas_init;
    ble_dis_init_t   dis_init;
    ble_dis_sys_id_t sys_id;
    uint32_t   err_code; // Variable to hold return codes from library and softdevice functions

    // Initialize Device Information Service.
    memset(&dis_init, 0, sizeof(dis_init));

    ble_srv_ascii_to_utf8(&dis_init.manufact_name_str, MANUFACTURER_NAME);
    ble_srv_ascii_to_utf8(&dis_init.model_num_str, MODEL_NUM);

    sys_id.manufacturer_id            = MANUFACTURER_ID;
    sys_id.organizationally_unique_id = ORG_UNIQUE_ID;
    dis_init.p_sys_id                 = &sys_id;

    BLE_GAP_CONN_SEC_MODE_SET_OPEN(&dis_init.dis_attr_md.read_perm);
    BLE_GAP_CONN_SEC_MODE_SET_NO_ACCESS(&dis_init.dis_attr_md.write_perm);

    err_code = ble_dis_init(&dis_init);
    APP_ERROR_CHECK(err_code);

    // Set our service connection handle to default value. I.e. an invalid handle since we are not yet in a connection.
    p_our_service->conn_handle = BLE_CONN_HANDLE_INVALID;

    ble_uuid_t osuuid;
    osuuid.uuid = BLE_UUID_OUR_SERVICE_UUID;
    osuuid.type = BLE_UUID_TYPE_BLE;

    // Add our service
    err_code = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY,
                                        &osuuid,
                                        &p_our_service->service_handle);
    APP_ERROR_CHECK(err_code);

    // Add RGB LED with notification DISABLED and write ENABLED characteristic to the service. 
    our_char_add(p_our_service, &p_our_service->char_handles, BLE_UUID_RGBLED_CHARACTERISTC_UUID, false, true, &srgb);
}

