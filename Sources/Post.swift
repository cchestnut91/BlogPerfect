//
//  Post.swift
//  CalvinChestnutHomePage
//
//  Created by Calvin Chestnut on 6/4/17.
//
//

import Foundation

/// JSONFeed Keys
let idKey = "id", urlKey = "url", titleKey = "title", authorKey = "author", publishedKey = "date_published", modifiedKey = "date_modified", htmlBodyKey = "content_html", textBodyKey = "content_text", externalUrlKey = "external_url", externalUrlTextKey = "_external_url_text", summaryKey = "summary", tagsKey = "tags", imageKey = "image", bannerImageKey = "banner_image"

/// Class represents a post to a blog
public class Post: NSObject {
    
    /// A unique ID for a post. If none is specified will generate a UUID string
    public var id: String
    
    /// The URL where this post can be found online. This will be set by the BlogManager class if not provided
    public var url: URL?
    /// The title of the post
    public var title: String?
    
    /// The author of the post, may be different than the Author specified in the BlogManager configuration
    public var author: Author?
    /// The date the post was originally published
    public var published: Date
    /// The date the post was last modified
    public var modified: Date?
    
    /// The body of the post, either an HTML string or a Markdown string. Which is determined by the htmlBody property
    public var body: String?
    /// Boolean property indicates if the content is Markdown or HTML
    public var htmlBody = false
    
    /// External URL referencd by this post, if applicable
    public var externalUrl: URL?
    /// Text description of the externalURL link
    public var externalUrlText: String?
    
    /// A short summary of the post
    public var summary: String?
    /// Array of tags to group the post by
    public var tags: [String]?
    
    /// The primary image of the post, if any
    public var image: URL?
    /// A banner image of the post, if any
    public var bannerImage: URL?
    
    /// Initializes a new Post instance with a few given properties
    ///
    /// - Parameters:
    ///   - id: The unique ID of the post. If none is provided a UUIDString will be generated
    ///   - title: The title of the post
    ///   - author: The author of the post
    ///   - published: The date the post was originally created. If none provided the current date will be used
    ///   - content: The content body of the post. Markdown assumed unless indicated otherwise after initialization
    public init(id: String?, title: String?, author: Author?, published: Date?, content: String?) {
        
        self.id = id ?? UUID().uuidString
        self.published = published ?? Date()
        self.title = title
        self.author = author
        self.body = content
        
        super.init()
    }
    
    /// Deserialize a Post instance form a given JSON object
    ///
    /// - Parameter json: The JSON object to deserialize
    public init(_ json : [String:Any]) {
        id = json[idKey] as? String ?? ""
        
        if let urlString = json[urlKey] as? String {
            url = URL(string: urlString)
        }
        title = json[titleKey] as? String
        author = Author(json[authorKey] as? [String:Any])
        
        if let publishedString = json[publishedKey] as? String {
            published = DateFormatter.rfc3339Formatter(timeZone: nil).date(from: publishedString) ?? Date()
        } else {
            published = Date()
        }
        if let modifiedString = json[modifiedKey] as? String {
            modified = DateFormatter.rfc3339Formatter(timeZone: nil).date(from: modifiedString)
        }
        
        if let htmlBodyString = json[htmlBodyKey] as? String {
            body = htmlBodyString
            htmlBody = true
        } else {
            body = json[textBodyKey] as? String
        }
        
        if let externalUrlString = json[externalUrlKey] as? String {
            externalUrl = URL(string: externalUrlString)
        }
        if let externalUrlTextString = json[externalUrlTextKey] as? String {
            externalUrlText = externalUrlTextString
        }
        
        summary = json[summaryKey] as? String
        tags = json[tagsKey] as? [String]
        
        if let imageString = json[imageKey] as? String {
            image = URL(string: imageString)
        }
        if let bannerImageString = json[bannerImageKey] as? String {
            bannerImage = URL(string: bannerImageString)
        }
        
        super.init()
    }
}

// MARK: - Determined strings
extension Post {
    
    /// Returns the preferred filename of the post for serialization
    ///
    /// - Returns: The determined filename
    public func filename() -> String! {
        
        /// First use the formatted string from the published date
        var file = DateFormatter.standardFormatter().string(from: published)+".json"
        
        /// If we have a title prepend that to the file name before returning
        if title != nil {
            file = title!+"-"+file
        }
        return file
    }
    
    /// The title of the post for display on the Blog
    ///
    /// - Returns: The title to displa
    public func displayTitle() -> String! {
        
        // Use the title if we have one
        if title != nil {
            return title
        }
        
        // Otherwise just return the formatted date string
        return DateFormatter.titleFormatter().string(from: published)
    }
    
}

// MARK: - JSON Serialization
extension Post {
    
    /// Serializes the post into a JSON object
    ///
    /// - Returns: The serialized JSON Post
    public func toJson() -> [String:Any] {
        var json = [String:Any]()
        
        json[idKey] = self.id
        if url != nil {
            json[urlKey] = url?.absoluteString
        }
        if title != nil {
            json[titleKey] = title
        }
        if author != nil {
            json[authorKey] = author?.toJson()
        }
        json[publishedKey] = DateFormatter.rfc3339Formatter().string(from: published)
        if modified != nil {
            json[modifiedKey] = DateFormatter.rfc3339Formatter().string(from: modified!)
        }
        
        if body != nil {
            if htmlBody {
                json[htmlBodyKey] = body
            } else {
                json[textBodyKey] = body
            }
        }
        
        if externalUrl != nil {
            json[externalUrlKey] = externalUrl?.absoluteString
        }
        if externalUrlText != nil {
            json[externalUrlTextKey] = externalUrlText
        }
        
        if summary != nil {
            json[summaryKey] = summary
        }
        if tags != nil {
            json[tagsKey] = tags
        }
        
        if image != nil {
            json[imageKey] = image?.absoluteString
        }
        if bannerImage != nil {
            json[bannerImageKey] = bannerImage?.absoluteString
        }
        
        return json
    }
}

// MARK: - HTML
extension Post {

    /// Inserts the post into HTML content given a template HTML string
    ///
    /// - Parameter templateString: The Template HTML string
    /// - Returns: The updated HTML string with the post content 
    public func HTMLString(from templateString: String?) -> String {
        var html = templateString ?? ""
        
        var bodyText = ""
        
        if let imageUrlString = image?.absoluteString {
            bodyText = postImageTag.replacingOccurrences(of: imageURLMarker, with: imageUrlString)
        }
        
        if let bodyContent = body?.markdownToHTML {
            bodyText += bodyContent
        }
        
        html = html.replacingOccurrences(of: "{POST_TITLE}", with: displayTitle())
        html = html.replacingOccurrences(of: "{POST_PUBLISHED}", with: DateFormatter.titleFormatter().string(from: published))
        html = html.replacingOccurrences(of: "{POST_SUMMARY}", with: summary ?? "")
        html = html.replacingOccurrences(of: "{POST_AUTHOR}", with: author?.name ?? "")
        html = html.replacingOccurrences(of: "{POST_URL}", with: url?.absoluteString ?? "")
        html = html.replacingOccurrences(of: "{POST_MODIFIED}", with: modified != nil ? DateFormatter.standardFormatter().string(from: modified!) : "")
        html = html.replacingOccurrences(of: "{POST_EXTERNAL_URL}", with: externalUrl?.absoluteString ?? "")
        html = html.replacingOccurrences(of: "{POST_EXTERNAL_URL_TEXT}", with: externalUrlText ?? "")
        html = html.replacingOccurrences(of: "{POST_CONTENT}", with: body?.markdownToHTML ?? "")
        return html
    }
    
}
