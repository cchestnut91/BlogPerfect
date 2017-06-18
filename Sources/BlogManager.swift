//
//  BlogManager.swift
//  Perfect.Blog
//
//  Created by Calvin Chestnut on 6/4/17.
//
//

import Foundation
import PerfectMarkdown

/// Main manager class handles reading and writing blog posts, and generating HTML and a JSON Feed
public class BlogManager: NSObject {
    
    static private var sharedInst: BlogManager?
    
    public class func configureSharedInstance(_ configuration: BlogConfiguration) {
        sharedInst = BlogManager(configuration)
    }
    
    public class var shared: BlogManager? {
        return BlogManager.sharedInst
    }
    
    /// Stored configuration values
    public private(set) var configuration: BlogConfiguration
    
    /// Default initializer requires a configuration value and builds the blog
    /// at the paths defined in the configuration
    ///
    /// - Parameter configuration: The configuration values to use
    internal init(_ configuration: BlogConfiguration) {
        self.configuration = configuration
        super.init()
    }
}

/// Local file URL scheme
let fileUrlScheme = "file://"

// MARK: - File IO
extension BlogManager {

    /// Serialized and writes a given post to a file within a directory stored
    /// either in the directory provided in the configuration object
    /// or at the default directory within the webroot directory
    /// If neither the posts or webroon directory are provided posts will not be saved
    ///
    /// - Parameter post: The post to serialize and store
    /// - Throws: Error forwarded from the JSONSerialization attempt or the FileIO attempt
    public func writeJSON(post: Post!) throws {
        
        // Make sure we have a directory to save these on
        if let postDirectory = configuration.serializedPostStorageDirectory() {
            
            // Retrieve the preferred file name for the post
            let fileName = postDirectory+post.filename()
            
            // If we haven't set the post URL property yet do that now
            if post.url == nil, let postPath = publishedLink(to: post) {
                post.url = URL(string: postPath)
            }
            
            // Construct the URL to be used to save the serialized post
            let urlString = "\(fileUrlScheme)\(fileName)".replacingOccurrences(of: " ", with: "%20")
            if let url = URL(string: urlString) {
                do {
                    print(urlString)
                    // Attempt to write the Post JSON to the file url
                    let data = try JSONSerialization.data(withJSONObject: post.toJson(), options: .prettyPrinted)
                    print("attempting write")
                    try data.write(to: url)
                    print("Write succeeded")
                } catch {
                    throw error
                }
            } else {
                throw BlogErrors.URLGenerationError
            }
        } else {
            throw BlogErrors.MissingDirectoryError
        }
    }
    
    /// Write a given Post instance to an HTML file
    ///
    /// - Parameter post: The post to write to HTML
    /// - Throws: Error forwarded from File IO attempts
    public func writeHTML(_ post: Post) throws {
        
        // If we don't have a directory to store posts in then we can't read them, and we do nothing here
        if let _ = configuration.serializedPostStorageDirectory(), var generatedPostFile = configuration.publishedPostStorageDirectory(), let postPath = publishedLink(to: post) {
            let fileManager = FileManager.default
            
            /// Retrieve the year, month and day of the post publish date to create subdirectories
            let dateComponents = DateFormatter.standardFormatter(timeZone: configuration.timeZone).string(from: post.published).components(separatedBy: "-").prefix(3)
            for component in dateComponents {
                
                // Append the date component as a path component
                generatedPostFile.append(component+"/")
            }
            
            // Check to see if the date component directory exists, and create it if not
            var directory: ObjCBool = ObjCBool(true)
            if !(fileManager.fileExists(atPath: generatedPostFile, isDirectory: &directory)) {
                do {
                    try fileManager.createDirectory(atPath: generatedPostFile, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    throw error
                }
            }
            
            /// Construct the full file path
            let filePath = generatedPostFile + post.displayTitle().replacingOccurrences(of: " ", with: "%20") + ".html"
            
            // Generate the HTML string for the post page with the template from the configuration object
            let htmlString = post.HTMLString(from: configuration.blogPostTemplate)
            
            // Try to write the HTML string to the filePath
            do {
                try htmlString.write(toFile: filePath, atomically: true, encoding: .utf8)
            } catch {
                throw error
            }
        } else {
            throw BlogErrors.MissingDirectoryError
        }
    }
}


// MARK: - Blog Construction
extension BlogManager {
    
    /// Function rewrites all of the HTML files as well as the JSONFeed file
    ///
    /// - Throws: Error forwarded from other methods
    public func rebuildBlog() throws {
        do {
            
            // Fetch posts sorted sequentially
            let allPosts = try sortedPosts()
            
            // Attempt to write each to an HTML file
            for post in allPosts {
                try writeHTML(post)
            }
        } catch {
            throw error
        }
        
        // If we have a path to save a JSONFeed to generate and save that feed
        if let feedLocation = configuration.jsonFeedFilePath {
            do {
                try generateJsonFeed(feedLocation)
            } catch {
                throw error
            }
        }
    }
}

// MARK: - Post Filters
extension BlogManager {
    
    /// Retrieves all posts from serialized storage and sorts them by date
    ///
    /// - Returns: Array of sorted Post instances
    /// - Throws: Forwarded JSONSerialization error
    public func sortedPosts() throws -> [Post] {
        let fileManager = FileManager.default
        
        // Make sure we have a directory where posts are saved
        if let postLocation = configuration.serializedPostStorageDirectory() {
            
            // Enumerate through each file in the directory
            if let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: postLocation) {
                
                // Create the array to return
                var posts: [Post] = []
                
                /// While we have another object in the enumerator
                while let element = enumerator.nextObject() as? String {
                    
                    // We only care about JSON files
                    if element.hasSuffix("json") {
                        
                        // Construct the full path of the element
                        let fullPath = postLocation + element
                        
                        // Try to fetch the contents of the file as Data
                        if let data = fileManager.contents(atPath: fullPath) {
                            do {
                                
                                // Construct the JSONObject from the data
                                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
                                    
                                    // Generate the Post from the JSON and append it to the array
                                    let post = Post(json)
                                    posts.append(post)
                                }
                            } catch {
                                throw error
                            }
                        }
                    }
                }
                
                // Sort all of the posts according to their Published date before returning
                return posts.sorted(by: { (a, b) -> Bool in
                    return a.published.compare(b.published) == .orderedDescending
                })
            } else {
                throw BlogErrors.FileReadError
            }
        } else {
            throw BlogErrors.MissingDirectoryError
        }
    }
    
    /// Filters the sortedPosts given a set of rules
    ///
    /// - Parameters:
    ///   - from: The start index of the filter
    ///   - max: The maximum number of results
    ///   - maxBodyLength: The maximum character length of the post body to allow in the filtered results
    ///   - titleOnly: Boolean flag to allow only posts with a non-nil title
    ///   - bodyOnly: Boolean flag to allow only posts with a non-nil body
    /// - Returns: The array of filtered Post instances
    /// - Throws: Forwarded error from the sortedPosts() method
    public func filteredPosts(from: Int?,
                              max: Int?,
                              maxBodyLength: Int?,
                              titleOnly: Bool = false,
                              bodyOnly: Bool = false) throws -> [Post] {
        
        // Attempt to load the sorted posts
        do {
            
            // Filter the posts with the given rules
            var filteredPosts = try self.sortedPosts().filter({ (post) -> Bool in
                
                // Allow the post IF it obeys the given rules for title, body, and bodyLength
                var allows = true
                if titleOnly && post.title == nil {
                    allows = false
                }
                if bodyOnly && post.body == nil {
                    allows = false
                }
                if maxBodyLength != nil {
                    if let bodyLength = post.body?.characters.count {
                        if bodyLength > maxBodyLength! {
                            allows = false
                        }
                    } else {
                        allows = false
                    }
                }
                return allows
            })
            
            // If we have a start index split the array from that index
            if from != nil && from! > 0 && filteredPosts.count > from! {
                filteredPosts = Array(filteredPosts.suffix(from!))
            }
            
            // If we have a max count split the array at that index
            if max != nil {
                filteredPosts = Array(filteredPosts.prefix(max!))
            }
            
            // Return the filtered array
            return filteredPosts
        } catch {
            throw error
        }
    }
    
}

// JSONFeed keys
let versionKey = "version", blogTitleKey = "title", blogAuthorKey = "author", blogURLKey = "home_page_url", feedURLKey = "feed_url", blogDescriptionKey = "description", blogIconKey = "icon", blogFaviconKey = "favicon", blogItemsKey = "items"

// Hard coded JSON version string
let jsonVersionString = "https://jsonfeed.org/version/1"

// MARK: - JSONFeed
extension BlogManager {
    
    /// Generates a JSONFeed and save the JSON to a given file path
    ///
    /// - Parameter saveLocation: The
    /// - Throws: Forwarded error from FileIO attempt
    public func generateJsonFeed(_ jsonFeedPath: String!) throws {
        
        // Generate the file URL from the given saveLocation
        if let url = URL(string: "file://"+jsonFeedPath.replacingOccurrences(of: " ", with: "%20")) {
            
            /// Create the JSONFeed dictionary and set values from the configuration
            var jsonFeed = [String:Any]()
            jsonFeed[versionKey] = jsonVersionString
            jsonFeed[blogTitleKey] = configuration.title
            jsonFeed[blogAuthorKey] = configuration.author?.toJson()
            jsonFeed[blogURLKey] = configuration.homeUrl
            jsonFeed[feedURLKey] = configuration.feedUrl
            jsonFeed[blogDescriptionKey] = configuration.description
            jsonFeed[blogIconKey] = configuration.iconUrl
            jsonFeed[blogFaviconKey] = configuration.faviconUrl
            
            do {
                
                // Get all of the posts
                let posts = try sortedPosts()
                
                // Map each to a JSON value and set the resulting array to the JSONFeed dictionary
                jsonFeed[blogItemsKey] = posts.map { (post) -> [String:Any] in
                    return post.toJson()
                }
                
                // Serialize the JSON Object into Data
                let jsonData = try JSONSerialization.data(withJSONObject: jsonFeed, options: .prettyPrinted)
                
                // and write the JSONData to the given file path
                try jsonData.write(to: url)
            } catch {
                throw error
            }
        } else {
            throw BlogErrors.InvalidURLError
        }
    }
}

// Template markers to replace with content
let recentPostsMarker = "{RECENT_POSTS}"
let headerContentMarker = "{POST_HEADER}"
let linkUrlMarker = "{POST_LINK_URL}"
let linkTextMarker = "{POST_LINK_TEXT}"
let archiveListContentMarker = "{POSTS_ARCHIVE}"
let archiveListItemContentMarker = "{ARCHIVE_ITEM}"
let archiveListItemLinkMarker = "{ARCHIVE_ITEM_LINK}"
let archiveListItemTextMarker = "{ARCHIVE_ITEM_TEXT}"

// Classes for HTML content, use these for CSS styling
let recentPostsClass = "recentPostsContainer"
let headerClass = "postHeader"
let postLinkClass = "postLink"
let archiveListClass = "blogPostArchive"
let archiveListItemClass = "blogPostArchiveItem"
let archiveListItemLinkClass = "blogPostArchiveItemLink"

// HTML tags for various content
let recentPostsTag =  "<div class='\(recentPostsClass)'>\(recentPostsMarker)</div>"
let headerTag = "<h3 class='\(headerClass)'>\(headerContentMarker)</h3>"
let postLinkTag = "<a class='\(postLinkClass)' href='\(linkUrlMarker)'>\(linkTextMarker)</a>"
let archiveListTag = "<ul class='\(archiveListClass)'>\n\(archiveListContentMarker)\n</ul>"
let archiveListItemTag = "<li class='\(archiveListItemClass)'>\(archiveListItemContentMarker)</li>\n"
let archiveListItemLinkTag = "<a class='\(archiveListItemLinkClass)' href='\(archiveListItemLinkMarker)'>\(archiveListItemTextMarker)</a>"

// MARK: - HTML
extension BlogManager {
    
    /// Generate the path where formatted HTML for the individual blog post will be saved
    ///
    /// - Parameter post: The post to be saved
    /// - Returns: The String file path where the post should be saved, or nil if we couldn't construct one
    public func publishedLink(to post: Post) -> String? {
        
        // If we have no directory to publish in we can't really do anything
        if let postDirectory = configuration.publishedPostStorageDirectory() {
            
            // Create the date string representing the Published date
            let formattedDate = DateFormatter.standardFormatter(timeZone: configuration.timeZone).string(from: post.published)
            
            // Split the dzte into components
            let components = formattedDate.components(separatedBy: "-")
            
            // Only the first three components (year, month, day) are part of the file path
            let dateString = components.prefix(3).joined(separator: "/")
            
            // Construct the link
            return postDirectory + dateString + "/" + post.displayTitle().replacingOccurrences(of: " ", with: "%20") + ".html"
        } else {
            print("No directory found")
            return nil
        }
    }
    
    /// Generate the path where formatted HTML for the individual blog post will be saved
    ///
    /// - Parameter post: The post to be saved
    /// - Returns: The String file path where the post should be saved, or nil if we couldn't construct one
    public func publishedUrl(to post: Post) -> String? {
        
        // If we have no directory to publish in we can't really do anything
        if let postDirectory = configuration.publishedPostUrlDirectory {
            
            // Create the date string representing the Published date
            let formattedDate = DateFormatter.standardFormatter(timeZone: configuration.timeZone).string(from: post.published)
            
            // Split the dzte into components
            let components = formattedDate.components(separatedBy: "-")
            
            // Only the first three components (year, month, day) are part of the file path
            let dateString = components.prefix(3).joined(separator: "/")
            
            // Construct the link
            return postDirectory + dateString + "/" + post.displayTitle().replacingOccurrences(of: " ", with: "%20") + ".html"
        } else {
            print("No directory found")
            return nil
        }
    }
    
    /// Generates an HTML string with the content of the given post, including title, date, and body
    /// This is similar to the content provided by post.HTMLString(from templateString)
    /// but without the wrapping HTML
    /// This content is intended to be shown in a list of recent posts, 
    /// where multiple posts live alongside eachother on a single page
    ///
    /// - Parameter post: The post to generate content for
    /// - Returns: The HTML string with the content of the post 
    public func postContent(_ post: Post) -> String {
        var header = ""
        
        // Make sure we have a link to reference otherwise leave the header empty
        if let postLink = publishedUrl(to: post) {
            
            // Set up variables
            var postLinkText = ""
            var postHeaderSuffix = ""
            
            // If we have a title use that as the linked text and the formatted published date as the suffix
            if post.title != nil {
                postLinkText = post.title!
                postHeaderSuffix = " \(DateFormatter.titleFormatter(timeZone: configuration.timeZone).string(from: post.published))"
            } else {
                
                // Otherwise just use the formatted published date as linked text
                postLinkText = DateFormatter.titleFormatter(timeZone: configuration.timeZone).string(from: post.published)
            }
            
            // Generate the content of the header
            let headerContent = postLinkTag.replacingOccurrences(of: linkUrlMarker, with: postLink).replacingOccurrences(of: linkTextMarker, with: postLinkText) + postHeaderSuffix
            
            // Generate the header content
            header = headerTag.replacingOccurrences(of: headerContentMarker, with: headerContent)
        }
        
        // Create an HTML String to return based on the header
        var html = header
        
        // If we have a body convert from Markdown to HTML and append to the HTML String
        if let body = post.body?.markdownToHTML {
            html += body
        }
        
        return html
    }
    
    /// Generates an HTML String containing the content of the given blog posts.
    /// Intended to be used as a 'recent posts' section
    ///
    /// - Parameter posts: The posts to display within the HTML
    /// - Returns: The generated HTML content string with the content of the given posts
    public func containerHTML(for posts: [Post]!) -> String {
        var blogPreviewContent = ""
        
        // For each of the given posts, append the postContent to the HTMLString
        for post in posts {
            blogPreviewContent.append(postContent(post))
        }
        let html = recentPostsTag.replacingOccurrences(of: recentPostsMarker, with: blogPreviewContent)
        
        return html
    }
    
    /// Given an array of Post instances generate HTML for an archive with links to each
    ///
    /// - Parameter posts: The posts to create links for
    /// - Returns: The HTML string for the archive
    public func archiveHTML(for posts: [Post]!) -> String {
        var listContent = ""
        
        // For each given post
        for post in posts {
            
            // If we have a link to the published page and a title
            if let postUrl = publishedUrl(to: post), let postTitle = post.displayTitle() {
                
                // Create the archive list item HTML string
                let archiveLink = archiveListItemLinkTag.replacingOccurrences(of: archiveListItemLinkMarker, with: postUrl).replacingOccurrences(of: archiveListItemTextMarker, with: postTitle)
                let itemHTML = archiveListItemTag.replacingOccurrences(of: archiveListItemContentMarker, with: archiveLink)
                listContent.append(itemHTML)
            }
        }
        
        // Add the items to the containing archive HTML string
        let archiveHTML = archiveListTag.replacingOccurrences(of: archiveListContentMarker, with: listContent)
        
        return archiveHTML
    }
}
