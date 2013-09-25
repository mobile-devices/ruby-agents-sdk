# @markup markdown
# @title Device quick reference
# @author Xavier Demorpion

# Device quick reference #

**This page is here to provide a quick reference on how to configure and use your device with the SDK VM. KEEP IN MIND THAT THIS DOCUMENTATION MIGHT NOT BE UP TO DATE, PLEASE REFER TO THE DEVICE SOFTWARE DOCUMENTATION FOR A COMPLETE AND UP-TO-DATE REFERENCE.**

## Configure your device ##

In this section we will configure your Mobile Devices product (or Morpheus simulator) so it will be able to communicate with the VM.

Here are some configuration commands you may have to run on the device console:

- s messageGate useBinaryGate 0
- s dataEmitter useBinaryGate 0
- s binaryGate active 0
- s jbinaryGate active 1
- s jbinaryGate url 192.168.10.4
- s jbinaryGate port 5001
- s jbinaryGate forceSerialUse 0
- s jbinaryGate refreshPeriod 3
- s jbinaryGate enablePing 1

Note : "192.168.10.4" is the IP address of the VM host side of the network built between the device and the VM host. The port used on the VM host is the 5001 port.

## Device API (java) with Protogen ##

The Morpheus SDK should have generated a `.jar` with the Java Protogen-generated code.

In order to use Protogen on the device, you will need to require the `MessageGate`, `BinaryGate` and `Debug` components in the JCPN of your project.

You will have to initialize a `MessageSender` (a class defined by Protogen), the object that will automatically encode the message and give it to the `MessageGate` for you. Its constructor needs:

* the name of the channel of the agent,
* an instance of an implementation of the `IMessageController` interface  (this interface is defined by Protogen, you can ask the Morpheus SDK to automatically create this class with the stub methods),
* the `MessageGate`, the `BinaryGate` and the `Debug` singleton instances.

Here is an example of code using a POI example.

**Initial.java** (using the stub created by the Morpheus SDK)

``` java
package com.mdi.services.example;
import com.mdi.services.example.protogen.Codec.UnknownMessage;
import com.mdi.services.example.protogen.Dispatcher;
import com.mdi.services.example.protogen.MDIMessages;

public class Initial implements com.mdi.tools.cpn.Initial {

  public void start() {
    Component.getInstance().getDebug().init(0);


    // MessageSender initialization
    Dispatcher.MessageSender _msgsender = new Dispatcher.MessageSender(
          "com.mdi.services.mychannel", // name of the channel
          new CustomMessageController(), // The implementation of a IMessageController interface
          Component.getInstance().getMessageGate(), // The MessageGate
          Component.getInstance().getBinaryGate(), // The BinaryGate
          Component.getInstance().getDebug()); // The Debug tool

    try {

       // Waiting for the dynamic channel to be configured.
      Component.getInstance().getDebug().warn("protogen demo 30s sleep");
      Thread.sleep(30000);

      // Creating and sending a PoiRequest to the server
      MDIMessages.PoiRequest poiRequest = new MDIMessages.PoiRequest();
      poiRequest.name = "Stade Nautique Youri Gargarine";
      _msgsender.send_PoiRequestToServer(poiRequest);

    } catch (InterruptedException e) {
      // Thread exception... To be removed if an other solution is found
      e.printStackTrace();
    } catch (UnknownMessage e) {
      // If the message given to the MessageSender is not valid
      e.printStackTrace();
    }
  }

  private static Initial _instance = new Initial();

  public void shutdown() {
  }

  private Initial() {
    // TODO Auto-generated method stub
  }

  static Initial getInstance() {
    return _instance;
  }

}
```

**CustomMessageController.java** (implementation of the `IMessageController` interface)

```java
package com.mdi.services.example;

import com.mdi.services.example.protogen.IMessageController;
import com.mdi.services.example.protogen.MDIMessages.PoiList;
import com.mdi.services.example.protogen.MDIMessages.Poi;
import com.mdi.tools.dbg.Debug;

public class CustomMessageController implements IMessageController {

  public void PoiList_to_device_ack_timeout() {
    // TODO Auto-generated method stub
  }

  public void PoiList_to_device_send_timeout() {
    // TODO Auto-generated method stub
  }

  public void treatPoi(PoiList poiList) {
    Debug dbg = Component.getInstance().getDebug();

    dbg.debug("Poilist received !");
    dbg.debug("There are " + poiList.pois.length + " pois found!");

    for(Poi poi : poiList.pois){
      dbg.debug("\nPoi: "  + poi.name);
      dbg.debug("lat,lng: " + poi.latitude + " " + poi.longitude);
    }
  }

}
```

Corresponding **protogen.json** file

```javascript
{
  "protocol_version": 1,

  "messages": {

    "PoiRequest": {
      "_description":"This is a message sent by the device that asks for a list of POIs.",
      "_way": "toServer",
      "_server_callback": "treat_poi_request",
      "name": {"type":"string", "modifier":"required", "docstring":"Name of the wanted poi"},
      "latlist": {"type":"int", "modifier":"required", "array":true, "docstring":"List of the possible latitudes"},
    },

    "Category": {
      "_description":"This is nested object that describe a category of POI (car park, gas station, etc)",
      "_way": "none",
      "id": {"type":"int", "modifier":"required", "docstring":"Category id, given by a guy."},
      "name": {"type":"string", "modifier":"required", "docstring":"Name, given by a provider (do NOT use as an index!)"},
      "popularity": {"type":"int", "modifier":"optional", "docstring":"Value computed with the Like button on the fanpage of the category"}
    },

    "Poi": {
      "_description":"A POI (Point of Interest)",
      "_way": "none",
      "name": {"type":"string", "modifier":"required", "docstring":"Name (example: 'Parking Villejuif')"},
      "latitude": {"type":"int", "modifier":"required", "docstring":"Latitude"},
      "longitude": {"type":"int", "modifier":"required", "docstring":"Longitude"},
      "category": {"type":"Category", "modifier":"optional", "docstring":"Category of the POI"}
    },

    "PoiList": {
      "_description": "A list of POI that answers a PoiRequest",
      "_way":"toDevice",
      "_device_callback":"treatPoi",
      "_timeout_calls": ["ack", "send"],
      "_timeouts" : { "send":10000},
      "pois": {"type":"Poi", "modifier":"required", "array":true, "docstring":"List of POIs"}
    }
  },

  "cookies": {
    "LastRequest": {
      "_secure":"low",
      "_send_with":["PoiList"],
      "name": {"type":"string", "modifier":"required"},
      "time":   {"type":"int", "modifier":"required"}
    }

  }
}
```