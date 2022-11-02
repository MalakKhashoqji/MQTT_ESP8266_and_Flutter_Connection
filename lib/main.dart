import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
final client = MqttServerClient('broker.mqttdashboard.com', 'clientId-QbfY9nzdQV');

Future<int> main() async {
  client.logging(on: true);
  client.setProtocolV311();
  client.keepAlivePeriod = 200;
  client.connectTimeoutPeriod = 2000; // milliseconds
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = false;
  client.onAutoReconnect = onAutoReconnect;
  client.onAutoReconnected = onAutoReconnected;
  client.onConnected = onConnected;
  client.onSubscribed = onSubscribed;
  client.pongCallback = pong;

  final connMess = MqttConnectMessage()
      .withClientIdentifier('clientId-QbfY9nzdQV')
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('client connecting....');
  client.connectionMessage = connMess;
  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE:client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print('EXAMPLE::ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  /// Ok, lets try a subscription

  // The App Subscribed to the topic from the esp8266
  const topic = 'datafromesp'; // Not a wildcard topic
  client.subscribe(topic, MqttQos.atMostOnce);

  client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt =
    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print(
        'topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });
  client.published!.listen((MqttPublishMessage message) {
    print(
        ': topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
  });

  /// Lets publish to our topic
  /// Use the payload builder rather than a raw buffer
  /// Our known topic to publish to
  //This is my topic that other will subscribe to
  // to Send massages from Flutter To hiveMQ
  const pubTopic = 'Dart/Mqtt_client/testtopic';
  final builder = MqttClientPayloadBuilder();
  // after other are subscribed to my topic I published this massage
  builder.addString('Massage From Flutter');


  client.subscribe(pubTopic, MqttQos.exactlyOnce);
  client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

  /// Ok, we will now sleep a while, in this gap you will see ping request/response
  /// messages being exchanged by the keep alive mechanism.
  print(':Sleeping....');
  await MqttUtilities.asyncSleep(60);
  print('Unsubscribing');
  client.unsubscribe(topic);
  await MqttUtilities.asyncSleep(2);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

void onSubscribed(String topic) {
  print('Subscription confirmed for topic $topic');
}

/// The pre auto re connect callback
void onAutoReconnect() {
  print(
      'EXAMPLE::onAutoReconnect client callback - Client auto reconnection sequence will start');
}

/// The post auto re connect callback
void onAutoReconnected() {
  print(
      'EXAMPLE::onAutoReconnected client callback - Client auto reconnection sequence has completed');
}

/// The successful connect callback
void onConnected() {
  print(
      'EXAMPLE::OnConnected client callback - Client connection was successful');
}

/// Pong callback
void pong() {
  print(
      'EXAMPLE::Ping response client callback invoked - you may want to disconnect your broker here');
}