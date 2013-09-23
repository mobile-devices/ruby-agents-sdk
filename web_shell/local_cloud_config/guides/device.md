# @markup markdown
# @title On the device side: configure your device and use the device API
# @author Xavier Demorpion

# Configure your device #

In this section we will configure your Mobile Devices product (or Morpheus simulator) to be able to communicate with the VM.

**KEEP IN MIND THAT THIS DOCUMENTATION MIGHT NOT BE UP TO DATE, PLEASE REFER TO THE DEVICE SOFTWARE DOCUMENTATION.**

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

note : "192.168.10.4" is the IP address of the VM host side of the network built between the device and the VM host.

# Device API (java)

Once you have written your protocol in the protogen.json file of your agent and rebooted the agents, a .jar will be containing all the device side generated code.

In order to use the protocol generator, you will need to require the MessageGate, BinaryGate and Debug components in the JCPN of your project.Here is an example of code using a POI example.

You will first have to initialize a MessageSender, the object that will automatically encode the message and give it to the message Gate for you. Its constructor needs:

* the name of the channel of the agent,
* an instance of an implementation of the IMessageController interface. (You can first put the name of the a new class and ask the Morpheus SDK to automatically create this class with the stub methods),
* the messageGate, the binaryGate, the Debug.

Initial.java (stub created by the Morpheus SDK)

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



CustomMessageController.java

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