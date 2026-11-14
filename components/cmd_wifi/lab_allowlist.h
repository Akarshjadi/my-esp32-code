/* Lab allow-list API header.
 * See lab_allowlist.c for implementation details.
 *
 * Public Domain (CC0).
 */
#pragma once

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/** Check whether `bssid` is in the NVS-stored lab_allowlist.
 * Returns false if the list is missing or empty (fail-closed). */
bool lab_allowlist_contains(const uint8_t bssid[6]);

/** Register the `lab_allow` console command. Call from register_wifi(). */
void register_lab_allowlist(void);

#ifdef __cplusplus
}
#endif
