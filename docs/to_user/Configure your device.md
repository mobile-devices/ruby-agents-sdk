
In this section we will configure your mobile device product (or Morpheus simulator) to be able to communicate with the vm.

**KEEP IN MIND THAT THIS DOCUMENTATION MIGHT NOT BE UP TO DATE, PLEASE REFER TO THE DEVICE SOFTWARE DOCUMENTATION**

Here are some configuration commands you have to run on the device's console :

s messageGate useBinaryGate 0
s dataEmitter useBinaryGate 0
s jbinaryGate active 1
s jbinaryGate url 192.168.10.4
s jbinaryGate port 5001
s jbinaryGate forceSerialUse 0
s jbinaryGate refreshPeriod 3

note : "192.168.10.4" is the ip of the vm's host side of the network built between the device and the vm's host.