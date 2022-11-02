#include <PubSubClient.h>
#include <stdlib.h>
#include <ESP8266WiFi.h>
#include "DHT.h"
#define DHTPIN 0 // GPIO pin 0 which is pin D3
#define DHTTYPE DHT11 
DHT dht(DHTPIN, DHTTYPE);
const char* ssid = "Your Wi-Fi Name";
const char* password = "Your Wi-Fi Password";
const char* mqtt_server = "broker.mqttdashboard.com";

char pub_str[100];



float gettemp();


WiFiClient espClient;
PubSubClient client(espClient);
void setup_wifi()
{

delay(10);

Serial.print("connecting to");
 Serial.println(ssid);
 WiFi.begin(ssid, password);

while (WiFi.status() != WL_CONNECTED)
 {
 delay(500);
 Serial.print("-");
 }

Serial.println();
 Serial.println("WiFi Connected");
 Serial.println("WiFi got IP");
 Serial.println();
 Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length)
{

Serial.print("Message arrived : ");
 Serial.print(topic);
 Serial.print(" : ");
 for (int i = 0; i < length; i++)
 {
 Serial.println((char)payload[i]);
 }
 if ((char)payload[0] == 'o' && (char)payload[1] == 'n')
 {
 digitalWrite(2, LOW);
 }
 else if ((char)payload[0] == 'o' && (char)payload[1] == 'f' && (char)payload[2] == 'f' ) {
 digitalWrite(2, HIGH);
 }

}

void reconnect()
{

while(!client.connected()){
Serial.println("Attempting MQTT connection");
if(client.connect("clientId-QbfY9nzdQV"))
{
Serial.println("Connected");
client.publish("datafromesp","Connected!");
client.subscribe("datafromhive");
Serial.print("subscribed!");
}
else
{
Serial.print("Failed, rc = ");
Serial.print(client.state());
Serial.println("Waiting for 5 seconds to try again");
delay(5000);
 }
 }
}

void setup()
{
 
 pinMode(2, OUTPUT);
 Serial.begin(115200);
 setup_wifi();
 client.setServer(mqtt_server, 1883);
 client.setCallback(callback);
 reconnect();
 dht.begin();
}

void loop()
{

if(!client.connected())
{
reconnect();
Serial.print("disconnected");
}
// Read temperature as Celsius (the default)
float h = dht.readHumidity();
float t = dht.readTemperature();
//sprintf(pub_str,"%f", t);
 
dtostrf(t,2,2,pub_str);
Serial.println(pub_str);
Serial.println(t);
client.publish("datafromesp",pub_str);
delay(1000);

client.loop();
}
