#include "handler.h"
#include <stdio.h>

static const char *TAG = "AboutHandler";

#ifdef LAB_MODE
#define LAB_BANNER "<tr>\n                        <td colspan=\"2\" class=\"text-center\">\n                            <div class=\"alert alert-warning mt-2\">\n                                <strong>Lab build active.</strong>\n                                Active Wi-Fi commands require: (1) <code>lab_allow add &lt;mac&gt;</code>\n                                for each target you own, then (2) <code>authorize</code> at the serial prompt.\n                                See <a href=\"/wifi\">Wi‑Fi Test Suite</a> for details.\n                            </div>\n                        </td>\n                    </tr>"
#else
#define LAB_BANNER ""
#endif

esp_err_t about_get_handler(httpd_req_t *req)
{

    ESP_LOGI(TAG, "Requesting about page");
    if (isLocked())
    {
        return redirectToLock(req);
    }
    httpd_req_to_sockfd(req);

    extern const char about_start[] asm("_binary_about_html_start");
    extern const char about_end[] asm("_binary_about_html_end");
    const size_t about_html_size = (about_end - about_start);

    const char *project_version = get_project_version();
    const char *project_build_date = get_project_build_date();
    size_t banner_len = strlen(LAB_BANNER);
    char *about_page = malloc(about_html_size + strlen(project_version) + strlen(GLOBAL_HASH) + strlen(project_build_date) + banner_len + 64);
    if (!about_page) return ESP_ERR_NO_MEM;

    /* about.html uses three %s placeholders: version, hash, build date.
     * We insert LAB_BANNER before the closing </tbody> tag. */
    snprintf(about_page, about_html_size + strlen(project_version) + strlen(GLOBAL_HASH) + strlen(project_build_date) + banner_len + 64,
             about_start, project_version, GLOBAL_HASH, project_build_date);

    /* Append lab banner into the table body, before </tbody> */
    char *tbody_close = strstr(about_page, "</tbody>");
    if (tbody_close && banner_len > 0)
    {
        memmove(tbody_close + banner_len, tbody_close, strlen(tbody_close) + 1);
        memcpy(tbody_close, LAB_BANNER, banner_len);
    }

    closeHeader(req);

    esp_err_t out = httpd_resp_send(req, about_page, HTTPD_RESP_USE_STRLEN);
    free(about_page);
    return out;
}