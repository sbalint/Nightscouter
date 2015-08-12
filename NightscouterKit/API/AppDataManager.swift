//
//  AppDataStore.swift
//  Nightscouter
//
//  Created by Peter Ina on 7/22/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//
import Foundation

public class AppDataManager: NSObject {
    
    internal struct SavedPropertyKey {
        static let sitesArrayObjectsKey = "userSites"
        static let currentSiteIndexKey = "currentSiteIndex"
        static let shouldDisableIdleTimerKey = "shouldDisableIdleTimer"
    }
    
    public var sites: [Site] = [Site]() {
        didSet{
            // write to defaults
            var arrayOfObjects = [Site]()
            var arrayOfObjectsData = NSKeyedArchiver.archivedDataWithRootObject(self.sites)
            defaults.setObject(arrayOfObjectsData, forKey: SavedPropertyKey.sitesArrayObjectsKey)
            saveAppData()
        }
    }
    
    public var currentSiteIndex: Int {
        set {
            defaults.setInteger(newValue, forKey: SavedPropertyKey.currentSiteIndexKey)
            saveAppData()
        }
        get {
            return defaults.integerForKey(SavedPropertyKey.currentSiteIndexKey)
        }
    }
    
    public var shouldDisableIdleTimer: Bool {
        set {
            #if DEBUG
                println("shouldDisableIdleTimer currently is: \(shouldDisableIdleTimer) and is changing to \(newValue)")
            #endif
            
            defaults.setBool(newValue, forKey: SavedPropertyKey.shouldDisableIdleTimerKey)
            saveAppData()
        }
        get {
            return defaults.boolForKey(SavedPropertyKey.shouldDisableIdleTimerKey)
        }
    }
    
    public let defaults: NSUserDefaults

    public class var sharedInstance: AppDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AppDataManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AppDataManager()
        }
        return Static.instance!
    }
    
    internal override init() {
        defaults  = NSUserDefaults(suiteName: "group.com.nothingonline.nightscouter")!
        
        super.init()
        
        if let arrayOfObjectsUnarchivedData = defaults.dataForKey(SavedPropertyKey.sitesArrayObjectsKey) {
            if let arrayOfObjectsUnarchived = NSKeyedUnarchiver.unarchiveObjectWithData(arrayOfObjectsUnarchivedData) as? [Site] {
                sites = arrayOfObjectsUnarchived
            }
        }
    }
    
    public func saveAppData() {
        let isSuccessfulSave = defaults.synchronize()
        #if DEBUG
            if !isSuccessfulSave {
            println("Failed to save sites...")
            }else{
            println("Successful save...")
            }
        #endif
    }
    
    public func addSite(site: Site, index: Int?) {
        if let indexOptional = index {
            if (sites.count >= indexOptional) {
                sites.insert(site, atIndex: indexOptional )
            }
        }else {
            sites.append(site)
        }
    }
    
    public func updateSite(site: Site)  ->  Bool {
        if let index = find(AppDataManager.sharedInstance.sites, site) {
            self.sites[index] = site
            return true
        }
        return false
    }
    
    public func deleteSiteAtIndex(index: Int) {
        let site = sites[index]
        sites.removeAtIndex(index)
    }
    
    public func loadSampleSites() -> Void {
        // Create a site URL.
        let demoSiteURL = NSURL(string: "https://nscgm.herokuapp.com")!
        // Create a site.
        let demoSite = Site(url: demoSiteURL, apiSecret: nil)!
        
        // Add it to the site Array
        sites = [demoSite]
    }
    
    // MARK: Extras
    
    public var infoDictionary: [String: AnyObject]? {
        return NSBundle.mainBundle().infoDictionary as? [String : AnyObject] // Grab the info.plist dictionary from the main bundle.
    }
    
    public var bundleIdentifier: String? {
        if let dictionary = infoDictionary {
            return dictionary["CFBundleIdentifier"] as? String
        }
        return nil
    }
    
    public var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, object) in enumerate(bundleURLTypes) {
                    if let urlTypeDictionary = bundleURLTypes[index] as? [String : AnyObject] {
                        if let urlScheme = urlTypeDictionary["CFBundleURLSchemes"] as? [String] {
                            schemes += urlScheme // We've found the supported schemes appending to the array.
                            return schemes
                        }
                    }
                }
            }
        }
        return nil
    }
    
}