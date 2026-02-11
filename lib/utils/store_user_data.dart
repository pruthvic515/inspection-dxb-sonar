import 'package:patrol_system/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreUserData {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  bool setStringList(String key, List<String> value) {
    try {
      instance.setStringList(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<String> getStringList(String key) {
    if (instance.getStringList(key) != null) {
      return instance.getStringList(key)!;
    } else {
      return [];
    }
  }

  bool setString(String key, String value) {
    try {
      instance.setString(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool setBoolean(String key, bool value) {
    try {
      instance.setBool(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool setInt(String key, int value) {
    try {
      instance.setInt(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool setDouble(String key, double value) {
    try {
      instance.setDouble(key, value);
      return true;
    } catch (e) {
      return false;
    }
  }

  String getString(String key) {
    if (instance.getString(key) != null) {
      return instance.getString(key)!;
    } else {
      return "";
    }
  }

  bool getBoolean(String key) {
    if (instance.getBool(key) != null) {
      return instance.getBool(key)!;
    } else {
      return false;
    }
  }

  int getInt(String key) {
    if (instance.getInt(key) != null) {
      return instance.getInt(key)!;
    } else {
      return -1;
    }
  }

  double getDouble(String key) {
    if (instance.getInt(key) != null) {
      return instance.getDouble(key)!;
    } else {
      return -1;
    }
  }

  bool? clearData() {
    try {
      String fcm = getString(USER_FCM);

      bool isAgentLogin = getBoolean(IS_AGENT_LOGIN);
      String agentPassword = "";
      String agentEmail = "";
      String userPassword = "";
      String userId = "";

      if (isAgentLogin) {
        agentPassword = getString(USER_AGENT_PASSWORD);
        agentEmail = getString(USER_AGENT_EMAIl);
      } else {
        userPassword = getString(USER_EMPLOYEE_PASSWORD);
        userId = getString(USER_BADGE_NUMBER);
      }

      instance.clear();
      setString(USER_FCM, fcm);
      setString(USER_EMPLOYEE_PASSWORD, userPassword);
      setString(USER_BADGE_NUMBER, userId);
      setBoolean(IS_AGENT_LOGIN, isAgentLogin);
      setString(USER_AGENT_PASSWORD, agentPassword);
      setString(USER_AGENT_EMAIl, agentEmail);

      return true;
    } catch (e) {
      return false;
    }
  }
}
