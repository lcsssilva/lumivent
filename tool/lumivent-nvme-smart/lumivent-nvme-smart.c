// lumivent-nvme-smart: reads the SMART/Health log (Get Log Page 02h) from NVMe
// controllers. Read-only: the only command sent is Get Log Page 02h.
//
// The kernel allows this command only with CAP_SYS_ADMIN, and /dev/nvmeN is root 600.
// Therefore the binary is installed with:
//   setcap cap_sys_admin,cap_dac_read_search+ep lumivent-nvme-smart
// (the PKGBUILD does this in package()). Model, serial, and temperature do not
// pass through here: the app reads them from sysfs without privileges.
//
// Uso:   lumivent-nvme-smart nvme0 [nvme1 ...]
// Output: one JSON line per controller, in argument order:
//   {"ctrl":"nvme0","log":"<512 bytes em hex>"}
//   {"ctrl":"nvme0","error":"open: Permission denied"}
#include <errno.h>
#include <fcntl.h>
#include <linux/nvme_ioctl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define LOG_LEN 512
#define MAX_CTRLS 16

// Only "nvme" followed by 1 to 3 digits: no paths or namespaces.
static int valid_name(const char *s) {
  if (strncmp(s, "nvme", 4) != 0) return 0;
  size_t n = strlen(s + 4);
  if (n < 1 || n > 3) return 0;
  for (size_t i = 0; i < n; i++)
    if (s[4 + i] < '0' || s[4 + i] > '9') return 0;
  return 1;
}

static int get_smart_log(int fd, uint32_t nsid, uint8_t *buf) {
  struct nvme_admin_cmd cmd;
  memset(&cmd, 0, sizeof cmd);
  cmd.opcode = 0x02;  // Get Log Page
  cmd.nsid = nsid;
  cmd.addr = (uint64_t)(uintptr_t)buf;
  cmd.data_len = LOG_LEN;
  cmd.cdw10 = 0x02 | ((LOG_LEN / 4 - 1) << 16);  // LID 02h, NUMDL
  return ioctl(fd, NVME_IOCTL_ADMIN_CMD, &cmd);
}

static void print_error(const char *ctrl, const char *what, int err) {
  printf("{\"ctrl\":\"%s\",\"error\":\"%s: %s\"}\n", ctrl, what, strerror(err));
}

static void read_ctrl(const char *ctrl) {
  char path[32];
  snprintf(path, sizeof path, "/dev/%s", ctrl);
  int fd = open(path, O_RDONLY | O_CLOEXEC);
  if (fd < 0) {
    print_error(ctrl, "open", errno);
    return;
  }
  uint8_t buf[LOG_LEN];
  memset(buf, 0, sizeof buf);
  // All namespaces (like nvme-cli); some controllers accept only 0.
  int r = get_smart_log(fd, 0xFFFFFFFFu, buf);
  if (r != 0) r = get_smart_log(fd, 0, buf);
  int err = errno;
  close(fd);
  if (r < 0) {
    print_error(ctrl, "ioctl", err);
    return;
  }
  if (r > 0) {
    printf("{\"ctrl\":\"%s\",\"error\":\"status NVMe 0x%x\"}\n", ctrl, r);
    return;
  }
  printf("{\"ctrl\":\"%s\",\"log\":\"", ctrl);
  for (int i = 0; i < LOG_LEN; i++) printf("%02x", buf[i]);
  printf("\"}\n");
}

int main(int argc, char **argv) {
  if (argc < 2 || argc - 1 > MAX_CTRLS) {
    fprintf(stderr, "uso: %s nvme0 [nvme1 ...]\n", argv[0]);
    return 2;
  }
  for (int i = 1; i < argc; i++) {
    if (!valid_name(argv[i])) {
      fprintf(stderr, "invalid name: %s\n", argv[i]);
      return 2;
    }
  }
  for (int i = 1; i < argc; i++) read_ctrl(argv[i]);
  return 0;
}
