//
//  Author.swift
//  Perfect.Blog
//
//  Created by Calvin Chestnut on 6/7/17.
//
//

import Foundation

let nameKey = "name", contactUrlKey = "url", avatarKey = "avatar"

/// Struct to represent the Author of a blog or a post and handle serialization
public struct Author {
    
    /// The author's name
    public var name: String?
    
    /// The url of a site owned by the author, or a micro blog account where they can be reached. Can also be a mailto link
    public var contactUrl: String?
    
    /// URL for an image of the author
    public var avatarURL: String?
    
    public init() {
        // No default configuration
    }
    
    /// Initializes an Author instance given a dictionary, usually a serialized JSON object
    ///
    /// - Returns: The deserialized instance, or nil if no dictionary was passed
    public init?(_ json: [String:Any]?) {
        if json == nil {
            return nil
        }
        self.name = json!["name"] as? String
        self.contactUrl = json!["url"] as? String
        self.avatarURL = json!["avatar"] as? String
    }
    
    /// Converts the instance to a JSON friendly dictionary
    ///
    /// - Returns: The JSON Dictionary if at elast one value is present, otherwise nil
    public func toJson() -> [String:String]? {
        // According to the JSONFeed spec an author object is only valid if it has at least one of these properties
        if name == nil && contactUrl == nil && avatarURL == nil {
            return nil
        }
        var jsonDict = [String:String]()
        
        if name != nil {
            jsonDict[nameKey] = name
        }
        if contactUrl != nil {
            jsonDict[contactUrlKey] = contactUrl
        }
        if avatarURL != nil {
            jsonDict[avatarKey] = avatarURL
        }
        
        return jsonDict
    }
}
