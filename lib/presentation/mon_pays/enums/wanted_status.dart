enum WantedStatus {
  dangereuse,
  disparue;

  static WantedStatus fromString(String value) {
    return value.toLowerCase() == 'dangereuse' 
        ? WantedStatus.dangereuse 
        : WantedStatus.disparue;
  }
}
