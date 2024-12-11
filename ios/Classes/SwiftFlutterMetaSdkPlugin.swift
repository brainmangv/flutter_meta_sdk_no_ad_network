import Flutter
import UIKit
import FBSDKCoreKit

public class SwiftFlutterMetaSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
            let channel = FlutterMethodChannel(name: "flutter_meta_sdk_no_ad_network", binaryMessenger: registrar.messenger())
            let instance = SwiftFlutterMetaSdkPlugin()

            // Required for FB SDK 9.0, as it does not initialize the SDK automatically any more.
            // See: https://developers.facebook.com/blog/post/2021/01/19/introducing-facebook-platform-sdk-version-9/
            // "Removal of Auto Initialization of SDK" section
            ApplicationDelegate.shared.initializeSDK()

            registrar.addMethodCallDelegate(instance, channel: channel)
            registrar.addApplicationDelegate(instance)
        }
        
        public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
            Settings.shared.isAdvertiserTrackingEnabled = false
            let launchOptionsForFacebook = launchOptions as? [UIApplication.LaunchOptionsKey: Any]
            ApplicationDelegate.shared.application(
                application,
                didFinishLaunchingWithOptions:
                    launchOptionsForFacebook
            )
            return true
        }
        
        public func applicationDidBecomeActive(_ application: UIApplication) {
            self.activateApp()
        }
        
        public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            return ApplicationDelegate.shared.application(application, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        }

        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "activateApp":
                self.activateApp()
                break
            case "clearUserData":
                self.clearUserData(result: result)
                break
            case "setUserData":
                self.setUserData(call, result: result)
                break
            case "clearUserID":
                self.clearUserID(result: result)
                break
            case "flush":
                self.flush(result: result)
                break
            case "getApplicationId":
                self.getApplicationId(result: result)
                break
            case "logEvent":
                self.logEvent(call, result: result)
                break
            case "logPushNotificationOpen":
                self.pushNotificationOpen(call, result: result)
                break
            case "setUserID":
                self.setUserId(call, result: result)
                break
            case "setAutoLogAppEventsEnabled":
                self.setAutoLogAppEventsEnabled(call, result: result)
                break
            case "setDataProcessingOptions":
                self.setDataProcessingOptions(call, result: result)
                break
            case "logPurchase":
                self.purchased(call, result: result)
                break
            case "getAnonymousId":
                self.getAnonymousId(result: result)
                break
            case "setAdvertiserTracking":
                self.setAdvertiserTracking(call, result: result)
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        func clearUserData(result: @escaping FlutterResult) {
        AppEvents.shared.clearUserData()
        result(nil)
    }

    func setUserData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()

        AppEvents.shared.setUserData(arguments["email"] as? String, forType: FBSDKAppEventUserDataType.email)
        AppEvents.shared.setUserData(arguments["firstName"] as? String, forType: FBSDKAppEventUserDataType.firstName)
        AppEvents.shared.setUserData(arguments["lastName"] as? String, forType: FBSDKAppEventUserDataType.lastName)
        AppEvents.shared.setUserData(arguments["phone"] as? String, forType: FBSDKAppEventUserDataType.phone)
        AppEvents.shared.setUserData(arguments["dateOfBirth"] as? String, forType: FBSDKAppEventUserDataType.dateOfBirth)
        AppEvents.shared.setUserData(arguments["gender"] as? String, forType: FBSDKAppEventUserDataType.gender)
        AppEvents.shared.setUserData(arguments["city"] as? String, forType: FBSDKAppEventUserDataType.city)
        AppEvents.shared.setUserData(arguments["state"] as? String, forType: FBSDKAppEventUserDataType.state)
        AppEvents.shared.setUserData(arguments["zip"] as? String, forType: FBSDKAppEventUserDataType.zip)
        AppEvents.shared.setUserData(arguments["country"] as? String, forType: FBSDKAppEventUserDataType.country)

        result(nil)
    }

    func clearUserID(result: @escaping FlutterResult) {
        AppEvents.shared.userID = nil
        result(nil)
    }

    func flush(result: @escaping FlutterResult) {
        AppEvents.shared.flush()
        result(nil)
    }

    func getApplicationId(result: @escaping FlutterResult) {
        result(Settings.shared.appID)
    }

    func getAnonymousId(result: @escaping FlutterResult) {
        result(AppEvents.shared.anonymousID)
    }

    func logEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let eventName = arguments["name"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        if arguments["_valueToSum"] != nil && !(arguments["_valueToSum"] is NSNull) {
            let valueToDouble = arguments["_valueToSum"] as! Double
            AppEvents.shared.logEvent(AppEvents.Name(eventName), valueToSum: valueToDouble, parameters: parameters)
        } else {
            AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)
        }

        result(nil)
    }

    func pushNotificationOpen(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let payload = arguments["payload"] as? [String: Any]
        if let action = arguments["action"] {
            let actionString = action as! String
            AppEvents.shared.logPushNotificationOpen(payload: payload!, action: actionString)
        } else {
            AppEvents.shared.logPushNotificationOpen(payload: payload!)
        }

        result(nil)
    }

    func setUserId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        AppEvents.shared.userID = id
        result(nil)
    }

    func setAutoLogAppEventsEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let enabled = call.arguments as! Bool
        Settings.shared.isAutoLogAppEventsEnabled = enabled
        result(nil)
    }

    func setDataProcessingOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let modes = arguments["options"] as? [String] ?? []
        let state = arguments["state"] as? Int32 ?? 0
        let country = arguments["country"] as? Int32 ?? 0

        Settings.shared.setDataProcessingOptions(modes, country: country, state: state)

        result(nil)
    }

    func purchased(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let amount = arguments["amount"] as! Double
        let currency = arguments["currency"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)

        result(nil)
    }

    func setAdvertiserTracking(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let enabled = arguments["enabled"] as! Bool
        let collectId = arguments["collectId"] as! Bool
        Settings.shared.isAdvertiserTrackingEnabled = enabled
        Settings.shared.isAdvertiserIDCollectionEnabled = collectId
        result(nil)
    }
    
    func activateApp(){
        AppEvents.shared.activateApp()
    }
}
