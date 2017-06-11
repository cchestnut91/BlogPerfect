//
//  BlogConfiguration.swift
//  Perfect.Blog
//
//  Created by Calvin Chestnut on 6/7/17.
//
//

import Foundation

/// Default directory to store serialized posts
let publicPostsDirectory = "posts/"

/// Struct to represent the configuration options for a blog
public struct BlogConfiguration {
    
    /// Initializer which takes a title, the only required value for the configuration
    ///
    /// - Parameter title: Title of the blog being configured
    public init(title: String) {
        self.title = title
    }
    
    /// Title of the blog
    public var title: String
    
    /// The primary author of the blog
    public var author: Author?
    
    /// Short description of the blog
    public var description: String?
    
    /// URL of the image for the feed that should be used in a timeline
    public var iconUrl: String?
    /// URL of the image that would be used in a feed list
    public var faviconUrl: String?
    
    /// URL of the main page of the site hosting the blog, or a blog page
    public var homeUrl: String?
    /// If publishing JSONFeed, this url of the Feed resource
    public var feedUrl: String?
    
    /// Directory where individual posts will be stored. These will not be the publicy viewable post HTML files, but rather the serialized JSON files storing them (w/ trailing slashes)
    public var postDirectory: String?
    /// Directory of the webroot where published posts will be stored (w/ trailing slashes)
    public var webrootDirectory: String?
    public var publishedPostUrlDirectory: String?
    
    /// File Path where the JSONFeed file should be saved
    public var jsonFeedFilePath: String?
    
    /// Template of an individual blogpost page.
    public var blogPostTemplate: String?
    
    /// The time zone the blog should use for date formatters, will default to Eastern time
    public var timeZone: TimeZone?
    
    /// Helper method to access the directory where serialized posts are stored
    ///
    /// - Returns: String value of the directory, or nil if no valid configuration was provided
    public func serializedPostStorageDirectory() -> String? {
        if postDirectory != nil {
            return postDirectory
        }
        if webrootDirectory != nil {
            return webrootDirectory! + publicPostsDirectory
        }
        return nil
    }
    
    /// Helper method to access the directory where published posts are stored
    ///
    /// - Returns: The directory to use
    public func publishedPostStorageDirectory() -> String? {
        if webrootDirectory != nil {
            return webrootDirectory! + "/\(publicPostsDirectory)"
        }
        return nil
    }
}
