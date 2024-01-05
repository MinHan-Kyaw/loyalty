class TabService {
  static final TabService _instance = TabService._internal();

  // passes the instantiation to the _instance object
  factory TabService() => _instance;

  //initialize variables in here
  TabService._internal() {
    _currentIndex = 0;
  }

  int _currentIndex;

  int get currentIndex => _currentIndex;

  set currentIndex(int value) => currentIndex = value;

  void setCurrentIndex(int value) => _currentIndex = value;
}

class DefaultOrgService {
  static final DefaultOrgService _instance = DefaultOrgService._internal();

  // passes the instantiation to the _instance object
  factory DefaultOrgService() => _instance;

  //initialize variables in here
  DefaultOrgService._internal() {
    _selectMenuSetDefaultOrgid = "";
  }

  String _selectMenuSetDefaultOrgid;

  String get selectMenuSetDefaultOrgid => _selectMenuSetDefaultOrgid;

  set selectMenuSetDefaultOrgid(String value) =>
      selectMenuSetDefaultOrgid = value;

  void setOrgid(String value) => _selectMenuSetDefaultOrgid = value;
}
