base class PairedDevice {
  // TODO: unique id instead of name
  String name;
  String os;
  String passKey;
  bool isConnected = false;

  PairedDevice(this.name, this.os, this.passKey);
}