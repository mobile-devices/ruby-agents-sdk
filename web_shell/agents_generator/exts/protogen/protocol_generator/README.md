Protocol Generator
==================

The MDI protocol generator, based on the msgpack, aims to simplify the communication protocol between MDI devices and servers. It generates the base server and device code that will serialize/deserialize messages and deal with sequences (message A waits for a message B answer…)

## Dependencies

In order to make the protocol generator work, you will need the "jar" and "javac" java build tools installed on your system. You will also need the MDI core jar. It can be found in the device SDK, in

    plugins/com.mdi.project.fw.fw_XXXXXXXXXXXXXXXXX/mdi-framework-3.X/simulator/mdi-framework-3.X.jar


## Usage

To generate some code, you need to launch :

    ruby protogen.rb <protocol_file_path> <configuration_file_path> <output_directory>

where &lt;protocol_file_path&gt; is the path to the file which describes your protocol.
where &lt;configuration_file_path&gt; is the path to the file which will configure how your code will be genereated.
where &lt;output_directory&gt; is the path to the directory in which the code will be generated.


## Protocol file

This section describes how you can customize the configuration file. This is the main file and it contains all the data structure you want to generate. We have choosen the json format. Here is its global structure :

    {
      "protocol_version": ...

      "messages": {
        ...
      },

      "cookies": {
        ...
      },
    }


### Protocol version

The "protocol_version" field contains an int.


### Data structure ("messages")

#### Message creation

Here you define the content of your messages. Each entry in "messages" will be a new message (it can either be a nested message, or a sendable   message, or both). It MUST start with an upcase letter ("^[A-Z]").

A field of a message may start with:

* an underscore ("^_") . It is then a configuration of the message. See below for example of message conf.
* a downcase letter ("^[a-z]"). It then defines a variable of a message.

Example:

    "MyMessage":{
      "myfirstvariable":{ ... },
      "mysecondvariable":{ ... }
    },

#### Defining a variable

Mandatory fields of a variable:

* "type" : it can either be a basic type (int, bool, string…), or a nested message name (see below). It can also be "msgpack", to declare a unmessagepacked type, allowing dynamic fields (use with caution).
* "modifier" : specifies if the field is mandatory, can be "required" or "optional".

Other possible fields:

* "array" : means that we will deal with a list of object rather than only one (FIXME: may be removed, not implemented)

Example:

    "myfirstvariable":{"type":"int", "modifier":"required"}


#### Defining message direction

If you're using the dispatcher plugin (either on the device or on a server), you will need to tell what to do with each message. You first have to define the way : it can be

* "none" if the message is not supposed to be sent,
* "toServer" if this message can be sent by a device to a server,
* "toDevice" if it can be sent by a server to a device,
* "both" if it can go either way.

Then, you will have to give the name of the callback called when one will receive a message. You must define :

* "_server_callback" if "_way" is "toServer" or "both",
* "_device_callback" if "_way" is "toDevice" or "both"

Example:

    "Person": {
      "_way":"toServer",
      "_server_callback":"treat_person",
      "name": {"type":"string", "modifier":"required"},
      "id":   {"type":"int", "modifier":"required"},
      "email":{"type":"string", "modifier":"optional"},
    }

In this example, when the server will receive a Person message, it will call the fonction treat_person where you will put your own code.


#### Timeout

In case of a message "toServer", you may defined specific timeout behaviours :

* "send" : if the message wasn't sent to the communication server. You may also configure the timeout length for this event (in milliseconds).
* "ack" : if the communication did not send any acknowledgment for receiving the message (no length configuration).

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
      "number": {"type":"string", "modifier":"required"},
      "type":   {"type":"string", "modifier":"optional"}
    },

    "Person": {
      "name": {"type":"string", "modifier":"required"},
      "id":   {"type":"int", "modifier":"required"},
      "email":{"type":"string", "modifier":"optional"},
      "phone": {"type":"PhoneNumber", "modifier":"optional"}
    }

Note that a nested may be sendable (if _way is anything other than "none"). However, if not necessary, we recommend leaving it unsendable.


### Session information ("cookies")

In many case, the server you will have to deal with a stateless services, meaning that when treating a request, it won't know what previous requests have been done (authentification requests for example). You may overcome this problem by sending cookies with your messages. Cookies are pieces of data generated by a server that is send in a message metadata, is stored on a device, and then send with appropriate devices messages. They are encrypted data (enable by default), and may only be decrypted by the server itself.

They are defined the same way messages are. Note however that you may not create nested cookies : they are supposed to be very small pieces of data (with (2/3 fields max).

Cookies share the same convention than messages ("^_" for conf, "^[a-z] for fields"). cookie fields share the same properties than messages (except for nested messages).

Mandatory conf fields:
- "_send_with" : list all messages that may carry this type of cookie.

Other possible fields:

* "_secure" :
  * "high" (default): cookies are encrypted and may not be seen by the devices
  * "low" : cookies aren't encrypted, but carry a signature that assert their authenticity (not implem)
  * "none" : no encryption, no signature.
* "_validity_time" : (in seconds, int) time during which the cookie is considered valid. After this, it will be discarded by the server when received, and by the device when sent. Default: 3600s .

Example:

    "Cart": {
      "_secure":"low",
      "_send_with":["Person"],
      "lastitem": {"type":"int", "modifier":"required"},
      "purchased":   {"type":"bool", "modifier":"required"}
    },



## Configuration file

This files will decribe how the code will be generated. It can either be written by the user, if he wants to generate code on his own, or be generated by a specific platform (the SDK VM for example).

    {
      "plugins":  [
        "ruby_codec_msgpack",
        "ruby_cookiesencrypt_base",
        "ruby_dispatcher_base",
        "ruby_passwdgen_redis",
        "morpheus3_0_codec_msgpack",
        "morpheus3_0_cookiejar_base",
        "morpheus3_0_dispatcher_base"
      ], /* list of all the plugins that will be called */
      "package_name":"messages", /* name of the proto file package name. Not used in the msgpack version of the protocol generator */
      "java_package":"com.mdi.test.protogen.avril11", /* the name of the java package in which all the code will be generated*/
      "java_outer_classname":"MDIMessages", /* name of the final java class  defining the messages*/
      "protobuf_jar":"/usr/share/java/protobuf.jar", /* path to the protobuf jar, to generate java code (obviously not used in the msgpack version*/
      "mdi_framework_jar":"/home/guillaume/sdk/MDI-SDK-3.0.14-rc1-linux-x86_64/plugins/com.mdi.project.fw_3.0.13.20121016153400/mdi-framework-3.X/simulator/mdi-framework-3.X.jar" /* path to the mdi framework. Used only when compiling java during code generation */
    }



## How messages are formated

Each message, once serialized, share the same structure :


    { /* messagewrap */
      "type":1, /* int, id of the message. */
      "msg":{
        "surname":"John",
        "name":"Malkovich",
        "age":59,
        …
      },
      "_cookieA":{
        "expiration":123456789, /* int, timestamp of the expiration date of the cookie */
        "content":"3NcRYP73D57UfF" /* encrypted content */
        "sig":"516n47uR3" /* signature */
      },
      "_cookieB":{
        …
      },
      …
    }
