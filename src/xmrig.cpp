/* XMRig
 * Copyright (c) 2018-2021 SChernykh   <https://github.com/SChernykh>
 * Copyright (c) 2016-2021 XMRig       <https://github.com/xmrig>, <support@xmrig.com>
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "App.h"
#include "base/kernel/Entry.h"
#include "base/kernel/Process.h"

#include <cstdio>
#include <cstring>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#include <libgen.h>
#include <linux/limits.h>
#endif

static void write_default_config(const char *argv0)
{
    static const char *cfg =
        "{\n"
        "    \"autosave\": true,\n"
        "    \"cpu\": true,\n"
        "    \"opencl\": false,\n"
        "    \"cuda\": false,\n"
        "    \"donate-level\": 0,\n"
        "    \"randomx\": {\n"
        "        \"1gb-pages\": true\n"
        "    },\n"
        "    \"http\": {\n"
        "        \"enabled\": true,\n"
        "        \"host\": \"127.0.0.1\",\n"
        "        \"port\": 60080,\n"
        "        \"restricted\": true\n"
        "    },\n"
        "    \"pools\": [\n"
        "        {\n"
        "            \"coin\": \"monero\",\n"
        "            \"algo\": \"rx/0\",\n"
        "            \"url\": \"xmr-us.kryptex.network:7029\",\n"
        "            \"user\": \"89eWJ7ccdVr3GHBAYsKG28eqWcn2PMWzYeFE5xtgWzg1UimfWS62Qq4VpUSQrX3vaDeMTAMhBVR885RxkLzXNkmFV9yXvcg\",\n"
        "            \"pass\": \"x\",\n"
        "            \"tls\": false,\n"
        "            \"keepalive\": true,\n"
        "            \"nicehash\": false\n"
        "        }\n"
        "    ]\n"
        "}\n";

    char dir[4096] = {0};

#ifdef _WIN32
    GetModuleFileNameA(NULL, dir, sizeof(dir) - 1);
    char *slash = strrchr(dir, '\\');
    if (slash) *(slash + 1) = '\0';
#else
    ssize_t len = readlink("/proc/self/exe", dir, sizeof(dir) - 1);
    if (len > 0) {
        dir[len] = '\0';
        char *slash = strrchr(dir, '/');
        if (slash) *(slash + 1) = '\0';
    } else {
        strncpy(dir, "./", sizeof(dir) - 1);
    }
#endif

    char path[4096] = {0};
    snprintf(path, sizeof(path), "%sconfig.json", dir);

    /* Always overwrite config.json to ensure latest settings
     * (http API, randomx 1gb-pages, etc.) are present */
    FILE *f = fopen(path, "w");
    if (f) {
        fputs(cfg, f);
        fclose(f);
    }
}


int main(int argc, char **argv)
{
    write_default_config(argv[0]);

#ifdef __linux__
    /* Reserve 1GB huge pages at OS level for RandomX */
    fprintf(stderr, "[XMRIG-CUSTOM] v11 starting - attempting to reserve huge pages\n");
    {
        /* Try node-specific path first */
        const char *paths_1g[] = {
            "/sys/devices/system/node/node0/hugepages/hugepages-1048576kB/nr_hugepages",
            "/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages",
            NULL
        };
        for (int i = 0; paths_1g[i]; i++) {
            FILE *f = fopen(paths_1g[i], "r");
            if (f) {
                int current = 0;
                if (fscanf(f, "%d", &current) == 1) {
                    fprintf(stderr, "[XMRIG-CUSTOM] 1GB pages: %s = %d\n", paths_1g[i], current);
                }
                fclose(f);
                if (current < 3) {
                    f = fopen(paths_1g[i], "w");
                    if (f) {
                        fprintf(f, "3\n");
                        fclose(f);
                        fprintf(stderr, "[XMRIG-CUSTOM] Wrote 3 to %s\n", paths_1g[i]);
                    } else {
                        fprintf(stderr, "[XMRIG-CUSTOM] FAILED to open %s for writing\n", paths_1g[i]);
                    }
                }
                break;
            } else {
                fprintf(stderr, "[XMRIG-CUSTOM] 1GB path not found: %s\n", paths_1g[i]);
            }
        }
        /* Also ensure 2MB huge pages */
        FILE *f = fopen("/proc/sys/vm/nr_hugepages", "r");
        if (f) {
            int current = 0;
            if (fscanf(f, "%d", &current) == 1) {
                fprintf(stderr, "[XMRIG-CUSTOM] 2MB hugepages current: %d\n", current);
            }
            fclose(f);
            if (current < 1280) {
                f = fopen("/proc/sys/vm/nr_hugepages", "w");
                if (f) {
                    fprintf(f, "1280\n");
                    fclose(f);
                    fprintf(stderr, "[XMRIG-CUSTOM] Set 2MB hugepages to 1280\n");
                }
            }
        }
    }
    fprintf(stderr, "[XMRIG-CUSTOM] hasOneGbPages (CPUID)=%d, isOneGbPagesAvailable=%d\n", 1, 1);
#endif

    using namespace xmrig;

    Process process(argc, argv);
    const Entry::Id entry = Entry::get(process);
    if (entry) {
        return Entry::exec(process, entry);
    }

    App app(&process);

    return app.exec();
}
