/*
 * Copyright (C) 2008 The Android Open Source Project
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Lights HAL for the LG D486 (vfp): LCD and keypad backlight plus the
 * LP5521 RGB indicator LED on the back cover.
 */

#define LOG_TAG "lights.vfp"

#include <cutils/log.h>

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <hardware/lights.h>

#define LCD_FILE        "/sys/class/leds/lcd-backlight/brightness"
#define BUTTONS_FILE    "/sys/class/leds/button-backlight/brightness"

#define LP5521_DIR      "/sys/devices/f9925000.i2c/i2c-2/2-0032"
#define LED_BLINK_FILE  LP5521_DIR "/led_blink"
#define RED_FILE        "/sys/class/leds/R/brightness"
#define GREEN_FILE      "/sys/class/leds/G/brightness"
#define BLUE_FILE       "/sys/class/leds/B/brightness"

/* led_blink takes on/off times in ms; the LP5521 program caps them */
#define MAX_BLINK_MS    10000

static pthread_once_t g_init = PTHREAD_ONCE_INIT;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

static struct light_state_t g_battery;
static struct light_state_t g_notification;
static struct light_state_t g_attention;

static void init_globals(void)
{
    memset(&g_battery, 0, sizeof(g_battery));
    memset(&g_notification, 0, sizeof(g_notification));
    memset(&g_attention, 0, sizeof(g_attention));
}

static int write_string(const char *path, const char *buffer)
{
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        ALOGE("failed to open %s: %s", path, strerror(errno));
        return -errno;
    }
    int amt = write(fd, buffer, strlen(buffer));
    close(fd);
    return amt < 0 ? -errno : 0;
}

static int write_int(const char *path, int value)
{
    char buffer[16];
    snprintf(buffer, sizeof(buffer), "%d\n", value);
    return write_string(path, buffer);
}

static int is_lit(const struct light_state_t *state)
{
    return state->color & 0x00ffffff;
}

static int rgb_to_brightness(const struct light_state_t *state)
{
    int color = state->color & 0x00ffffff;
    return ((77 * ((color >> 16) & 0xff)) +
            (150 * ((color >> 8) & 0xff)) +
            (29 * (color & 0xff))) >> 8;
}

static int set_light_backlight(struct light_device_t *dev __unused,
                               const struct light_state_t *state)
{
    pthread_mutex_lock(&g_lock);
    int err = write_int(LCD_FILE, rgb_to_brightness(state));
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int set_light_buttons(struct light_device_t *dev __unused,
                             const struct light_state_t *state)
{
    pthread_mutex_lock(&g_lock);
    int err = write_int(BUTTONS_FILE, is_lit(state) ? 255 : 0);
    pthread_mutex_unlock(&g_lock);
    return err;
}

/* Must be called with g_lock held */
static int set_indicator_locked(const struct light_state_t *state)
{
    char buffer[32];
    unsigned int rgb = state ? (state->color & 0x00ffffff) : 0;
    int on = 0, off = 0;

    /* Stop any running blink program and clear the solid colour */
    write_string(LED_BLINK_FILE, "0x000000 0 0\n");
    write_int(RED_FILE, 0);
    write_int(GREEN_FILE, 0);
    write_int(BLUE_FILE, 0);

    if (!rgb)
        return 0;

    if (state->flashMode == LIGHT_FLASH_TIMED ||
        state->flashMode == LIGHT_FLASH_HARDWARE) {
        on = state->flashOnMS;
        off = state->flashOffMS;
    }

    if (on > 0 && off > 0) {
        if (on > MAX_BLINK_MS) on = MAX_BLINK_MS;
        if (off > MAX_BLINK_MS) off = MAX_BLINK_MS;
        snprintf(buffer, sizeof(buffer), "0x%06x %d %d\n", rgb, on, off);
        return write_string(LED_BLINK_FILE, buffer);
    }

    write_int(RED_FILE, (rgb >> 16) & 0xff);
    write_int(GREEN_FILE, (rgb >> 8) & 0xff);
    return write_int(BLUE_FILE, rgb & 0xff);
}

/* Priority: attention > notification > battery. Must hold g_lock. */
static int update_indicator_locked(void)
{
    if (is_lit(&g_attention))
        return set_indicator_locked(&g_attention);
    if (is_lit(&g_notification))
        return set_indicator_locked(&g_notification);
    return set_indicator_locked(&g_battery);
}

static int set_light_battery(struct light_device_t *dev __unused,
                             const struct light_state_t *state)
{
    pthread_mutex_lock(&g_lock);
    g_battery = *state;
    int err = update_indicator_locked();
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int set_light_notifications(struct light_device_t *dev __unused,
                                   const struct light_state_t *state)
{
    pthread_mutex_lock(&g_lock);
    g_notification = *state;
    int err = update_indicator_locked();
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int set_light_attention(struct light_device_t *dev __unused,
                               const struct light_state_t *state)
{
    pthread_mutex_lock(&g_lock);
    g_attention = *state;
    if (state->flashMode == LIGHT_FLASH_NONE)
        g_attention.color = 0;
    int err = update_indicator_locked();
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int close_lights(struct light_device_t *dev)
{
    free(dev);
    return 0;
}

static int open_lights(const struct hw_module_t *module, const char *name,
                       struct hw_device_t **device)
{
    int (*set_light)(struct light_device_t *dev,
                     const struct light_state_t *state);

    if (!strcmp(LIGHT_ID_BACKLIGHT, name))
        set_light = set_light_backlight;
    else if (!strcmp(LIGHT_ID_BUTTONS, name) || !strcmp(LIGHT_ID_KEYBOARD, name))
        set_light = set_light_buttons;
    else if (!strcmp(LIGHT_ID_BATTERY, name))
        set_light = set_light_battery;
    else if (!strcmp(LIGHT_ID_NOTIFICATIONS, name))
        set_light = set_light_notifications;
    else if (!strcmp(LIGHT_ID_ATTENTION, name))
        set_light = set_light_attention;
    else
        return -EINVAL;

    pthread_once(&g_init, init_globals);

    struct light_device_t *dev = calloc(1, sizeof(struct light_device_t));
    if (!dev)
        return -ENOMEM;

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = 0;
    dev->common.module = (struct hw_module_t *)module;
    dev->common.close = (int (*)(struct hw_device_t *))close_lights;
    dev->set_light = set_light;

    *device = (struct hw_device_t *)dev;
    return 0;
}

static struct hw_module_methods_t lights_module_methods = {
    .open = open_lights,
};

struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "LG D486 (vfp) lights module",
    .author = "The LineageOS Project",
    .methods = &lights_module_methods,
};
