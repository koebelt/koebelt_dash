// ESP32-CAM (AI-Thinker) rover with live video in the app.
// Board: "AI Thinker ESP32-CAM", PSRAM enabled. The camera streams MJPEG on
// port 81; the app finds it through klink.video() and shows it in the Camera
// view, the drive screen background and the Camera tile.
#include <KoebeltLink.h>
#include <WiFi.h>

#include "esp_camera.h"
#include "esp_http_server.h"

KLink klink("Cam-Rover", KLink::ROVER);
float speed = 0, turn = 0;

// multipart/x-mixed-replace: one JPEG per part, with its length.
static esp_err_t stream(httpd_req_t* req) {
  httpd_resp_set_type(req, "multipart/x-mixed-replace;boundary=frame");
  char head[80];
  while (true) {
    camera_fb_t* fb = esp_camera_fb_get();
    if (!fb) return ESP_FAIL;
    int n = snprintf(head, sizeof(head), "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n", (unsigned)fb->len);
    esp_err_t r = httpd_resp_send_chunk(req, head, n);
    if (r == ESP_OK) r = httpd_resp_send_chunk(req, (const char*)fb->buf, fb->len);
    if (r == ESP_OK) r = httpd_resp_send_chunk(req, "\r\n", 2);
    esp_camera_fb_return(fb);
    if (r != ESP_OK) return r;  // the app went away
  }
}

static bool startCamera() {
  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0;
  c.ledc_timer = LEDC_TIMER_0;
  // AI-Thinker ESP32-CAM pin map
  c.pin_d0 = 5;
  c.pin_d1 = 18;
  c.pin_d2 = 19;
  c.pin_d3 = 21;
  c.pin_d4 = 36;
  c.pin_d5 = 39;
  c.pin_d6 = 34;
  c.pin_d7 = 35;
  c.pin_xclk = 0;
  c.pin_pclk = 22;
  c.pin_vsync = 25;
  c.pin_href = 23;
  c.pin_sccb_sda = 26;
  c.pin_sccb_scl = 27;
  c.pin_pwdn = 32;
  c.pin_reset = -1;
  c.xclk_freq_hz = 20000000;
  c.pixel_format = PIXFORMAT_JPEG;
  c.frame_size = FRAMESIZE_VGA;  // 640x480; QVGA if the link is weak
  c.jpeg_quality = 12;
  c.fb_count = 2;
  c.fb_location = CAMERA_FB_IN_PSRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;  // always the newest frame: low latency
  if (esp_camera_init(&c) != ESP_OK) return false;

  httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
  cfg.server_port = 81;
  cfg.ctrl_port = 32769;
  httpd_handle_t server = nullptr;
  if (httpd_start(&server, &cfg) != ESP_OK) return false;
  httpd_uri_t uri = {};
  uri.uri = "/stream";
  uri.method = HTTP_GET;
  uri.handler = stream;
  return httpd_register_uri_handler(server, &uri) == ESP_OK;
}

void setup() {
  Serial.begin(115200);
  klink.setSensors("CAMERA, IMU");
  klink.begin("my-ssid", "my-password");
  if (startCamera()) {
    klink.video(":81/stream", "cam", "mjpeg", "Front");  // port and path on this board's IP
  } else {
    klink.log("Camera failed to start", "error");
  }
  klink.onControl([](const KControl& c) { speed = c.ry; turn = c.lx; });
  klink.onStop([] { speed = turn = 0; });
  klink.failsafe(1000, KMode::HOLD);
}

void loop() {
  // Drive your motor driver from speed and turn here.
  klink.battery(7.6f, 80);
  klink.rssi(WiFi.RSSI());
  klink.update();
  delay(20);
}
