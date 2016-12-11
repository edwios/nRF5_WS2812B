#ifndef COMMON_H_
#define COMMON_H_

static void power_manage(void);
static void change_color(void);
static void do_rainbow(void);

static void on_adv_evt(ble_adv_evt_t ble_adv_evt);
static void on_conn_params_evt(ble_conn_params_evt_t * p_evt);
static void on_ble_evt(ble_evt_t * p_ble_evt);
static void on_write(ble_evt_t * p_ble_evt);
static void conn_params_error_handler(uint32_t nrf_error);
static void button_event_handler(uint8_t pin_no, uint8_t button_action);
static void fds_evt_handler(fds_evt_t const * p_evt);
static void pm_evt_handler(pm_evt_t const * p_evt);
static void app_timeout_handler(void * p_context);
static void led_handler();
static void buttons_init(void);
static void leds_init(void);
static void timers_init(void);
static void ble_stack_init(void);
static void advertising_init(void);
static void gap_params_init(void);
static void conn_params_init(void);
static void peer_manager_init(bool erase_bonds);
static void services_init(void);
static void application_timers_start(void);
static void  adv_led_timer_start(void);
static void application_timers_stop(void);
static void  adv_led_timer_stop(void);
static void advertising_start(void);


#endif		/* COMMON_H_ */

