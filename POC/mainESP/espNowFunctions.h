#include <esp_now.h>
#include <WiFi.h>



class espNow{
  bool m_isOngoingSession;
  uint8_t m_macAdress*;
  void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status);
  void OnDataRecv(const esp_now_recv_info *recv_info, const uint8_t *incomingData, int len);
public :
  espNow();
};

