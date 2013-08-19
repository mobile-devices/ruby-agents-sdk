
The MDI protocol generator, based on *msgpack*, aims to simplify the communication protocol between MDI devices and servers. It generates the server and device code that will serialize/deserialize messages and deal with calling appropriate methods when receiving a message.

## Example

The following example implements most of the available features of the protogen within your *config/protogen.json* file:

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

      "cookies":{}
    }


## Minimal template file

This is the minimal template of a protocol file:

    {
      "protocol_version": 1,

      "messages": {

      },

      "cookies": {

      }
    }


### Protocol version

The "protocol\_version" field contains an *int*. Each time you change the protocol of an agent that has already been released, you should increment this value.


### Data structure ("messages")

Each entry in "messages" will be a new message. It MUST start with an upcase letter ("\^[A-Z]").

A field of a message may start with:

* an underscore ("\^_") . It is then a configuration of the message. See below for examples of message configuration.
* a downcase letter ("\^[a-z]"). It then defines an attribute of a message.

Example:

    "MyMessage":{
      "_my_conf1":"stuff",
      "_my_conf2":2,
      "myfirstvariable":{ ... },
      "mysecondvariable":{ ... }
    },


#### Message configuration

* "\_description" (optional string): Describes in the protocol documentation the purpose of this message
* "\_way" (required string): Tells who will send the message. Possible : "none", "toServer", "toDevice", "both",
* "\_server\_callback" (required string if message received by the server ("toServer" or "both")): Name of the callback to implement when a server receive a new message
* "\_device\_callback" (required string if message received by the device ("toDevice" or "both")): Name of the callback to implement when a device receive a new message
* "\_timeout\_calls" and "\_timeout" (optional): see Timeout section.


#### Attributes

Example:

    "myfirstvariable":{"type":"int", "modifier":"required", "docstring":"This variable is an example."}


* "type" (required): It can either be a basic type (int, bool, string…), or a nested message name (see below). It can also be "msgpack", to declare a unmessagepacked type, allowing dynamic fields (use with caution).
* "modifier" (required): specifies if the field is mandatory, can be "required" or "optional".
* "array" (optional boolean): If true, means that we will deal with a list of objects rather than only one.
* "docstring" (optional string): This field will describe the attribute in the generated documentation of the protocol.


#### Timeout

When a problem occurs while a message is being sent by a device ("toServer" or "both"), you may define specific timeout behaviours:

* "send": if the message wasn't sent to the communication server. You may also configure the timeout length for this event (in milliseconds).
* "ack": if the communication did not send any acknowledgment for receiving the message (no length configuration).

The callback thus created in the IMessageController will be called &lt;sequencename&gt;\_&lt;timeout&gt;\_timeout .

Example:

    "Request": {
      "_way":"toServer",
      "_server_callback":"treatPoiRequest",
      "_timeout_calls":["send", "ack"],
      "_timeouts":{"send":10000},
      "question": {"type":"string", "modifier":"required"}
    }


#### Nested messages

Example:

    "PhoneNumber": {
      "_way": "none",
      "number": {"type":"string", "modifier":"required"},
      "type":   {"type":"string", "modifier":"optional"}
    },

    "Person": {
      "_way":"toDevice",
      "_server_callback":"treatPerson",
      "name": {"type":"string", "modifier":"required"},
      "id":   {"type":"int", "modifier":"required"},
      "email":{"type":"string", "modifier":"optional"},
      "phone": {"type":"PhoneNumber", "modifier":"optional"}
    }

Note that a nested message may be sendable (if \_way is anything other than "none"). However, if not necessary, we recommend leaving it unsendable.


### Session information ("cookies")

In many cases, the server you will have to deal with runs stateless services, meaning that when treating a request, it won't know what previous requests have been received (authentification requests for example). You may overcome this by sending cookies with your messages. Cookies are pieces of data generated by a server that are sent in a message metadata, are stored on a device, and then sent with appropriate devices messages. They are encrypted data (enabled by default), and may only be decrypted by the server itself.

They are defined the same way messages are. Note however that you may not create nested cookies: they are supposed to be very small pieces of data (with (2/3 fields max).

Cookies share the same convention as messages ("\^\_" for conf, "\^[a-z] for fields"). Cookie fields share the same properties as messages (except for nested messages).

Mandatory conf fields:
* "\_send\_with" : list all messages that may carry this type of cookie.

Other possible fields:

* "_secure" :
  * "high" (default): cookies are encrypted and may not be seen by the devices
  * "low" : cookies aren't encrypted, but carry a signature that asserts their authenticity (not implemented)
  * "none" : no encryption, no signature.
* "\_validity\_time" : (in seconds, int) duration of the validity period of the cookie. At the end of this duration, it will be discarded by the server when received, and by the device when sent. Default: 3600s .

Example:

    "Cart": {
      "_secure":"low",
      "_send_with":["Person"],
      "lastitem": {"type":"int", "modifier":"required"},
      "purchased":   {"type":"bool", "modifier":"required"}
    }

