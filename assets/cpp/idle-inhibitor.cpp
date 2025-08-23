#include <csignal>
#include <cstring>
#include <iostream>
#include <unistd.h>
#include <wayland-client-protocol.h>
#include <wayland-client.h>

// You'll need to generate these headers from the protocol XML files:
// wayland-scanner client-header < idle-inhibit-unstable-v1.xml >
// idle-inhibit-client-protocol.h wayland-scanner private-code <
// idle-inhibit-unstable-v1.xml > idle-inhibit-protocol.c
extern "C" {
#include "idle-inhibitor.h"
}

class WaylandIdleInhibitor {
private:
  struct wl_display *display;
  struct wl_registry *registry;
  struct wl_compositor *compositor;
  struct wl_surface *surface;
  struct zwp_idle_inhibit_manager_v1 *idle_inhibit_manager;
  struct zwp_idle_inhibitor_v1 *idle_inhibitor;

  static WaylandIdleInhibitor *instance;

  // Registry listener to get global objects
  static void registry_global(void *data, struct wl_registry *registry,
                              uint32_t id, const char *interface,
                              uint32_t version) {
    WaylandIdleInhibitor *inhibitor = static_cast<WaylandIdleInhibitor *>(data);

    if (strcmp(interface, wl_compositor_interface.name) == 0) {
      inhibitor->compositor = static_cast<struct wl_compositor *>(
          wl_registry_bind(registry, id, &wl_compositor_interface, 1));
    } else if (strcmp(interface, zwp_idle_inhibit_manager_v1_interface.name) ==
               0) {
      inhibitor->idle_inhibit_manager =
          static_cast<struct zwp_idle_inhibit_manager_v1 *>(wl_registry_bind(
              registry, id, &zwp_idle_inhibit_manager_v1_interface, 1));
    }
  }

  static void registry_global_remove(void *data, struct wl_registry *registry,
                                     uint32_t id) {}

  static const struct wl_registry_listener registry_listener;

public:
  WaylandIdleInhibitor()
      : display(nullptr), registry(nullptr), compositor(nullptr),
        surface(nullptr), idle_inhibit_manager(nullptr),
        idle_inhibitor(nullptr) {
    instance = this;
  }

  ~WaylandIdleInhibitor() { cleanup(); }

  bool initialize() {
    display = wl_display_connect(nullptr);
    if (!display) {
      return false;
    }

    registry = wl_display_get_registry(display);
    if (!registry) {
      return false;
    }

    wl_registry_add_listener(registry, &registry_listener, this);

    // Roundtrip to get all globals
    wl_display_roundtrip(display);

    if (!compositor || !idle_inhibit_manager) {
      return false;
    }

    return true;
  }

  bool createInvisibleSurface() {
    surface = wl_compositor_create_surface(compositor);
    if (!surface) {
      return false;
    }

    return true;
  }

  bool inhibitIdle() {
    if (!surface || !idle_inhibit_manager) {
      return false;
    }

    idle_inhibitor = zwp_idle_inhibit_manager_v1_create_inhibitor(
        idle_inhibit_manager, surface);

    if (!idle_inhibitor) {
      std::cerr << "Failed to create idle inhibitor\n";
      return false;
    }

    wl_display_roundtrip(display);

    std::cout << "Idle inhibition activated\n";
    return true;
  }

  void cleanup() {
    if (idle_inhibitor) {
      zwp_idle_inhibitor_v1_destroy(idle_inhibitor);
      idle_inhibitor = nullptr;
    }

    if (surface) {
      wl_surface_destroy(surface);
      surface = nullptr;
    }

    if (idle_inhibit_manager) {
      zwp_idle_inhibit_manager_v1_destroy(idle_inhibit_manager);
      idle_inhibit_manager = nullptr;
    }

    if (compositor) {
      wl_compositor_destroy(compositor);
      compositor = nullptr;
    }

    if (registry) {
      wl_registry_destroy(registry);
      registry = nullptr;
    }

    if (display) {
      wl_display_disconnect(display);
      display = nullptr;
    }
  }

  void run() {
    while (wl_display_dispatch(display) != -1)
      ;
  }

  static WaylandIdleInhibitor *getInstance() { return instance; }
};

WaylandIdleInhibitor *WaylandIdleInhibitor::instance = nullptr;

const struct wl_registry_listener WaylandIdleInhibitor::registry_listener = {
    WaylandIdleInhibitor::registry_global,
    WaylandIdleInhibitor::registry_global_remove};

void signalHandler(int signal) {

  WaylandIdleInhibitor *inhibitor = WaylandIdleInhibitor::getInstance();
  if (inhibitor) {
    inhibitor->cleanup();
  }

  exit(0);
}

int main() {
  signal(SIGINT, signalHandler);
  signal(SIGTERM, signalHandler);
  signal(SIGHUP, signalHandler);

  WaylandIdleInhibitor inhibitor;

  if (!(inhibitor.initialize() && inhibitor.createInvisibleSurface() &&
        inhibitor.inhibitIdle())) {
    std::cerr << "Cannot inhibit idle!" << std::endl;
    return 1;
  }

  inhibitor.run();

  return 0;
}
