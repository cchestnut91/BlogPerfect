//
//  NSDateFormatter+Common.swift
//  SwiftBlogManager
//
//  Created by Calvin Chestnut on 1/14/17.
//  Copyright © 2017 Calvin Chestnut. All rights reserved.
//

import Foundation

// DateFormatters are expensive to create, maintain these references for reuse
var standard:DateFormatter?
var title:DateFormatter?
var rfc3:DateFormatter?

// DateFormatter extension with common formats
public extension DateFormatter {
    
    /// Standard formatter for file names
    ///
    /// - Parameter timeZone: The time zone for the formatter
    /// - Returns: The standard date formatter
    public static func standardFormatter(timeZone: TimeZone? = TimeZone(identifier: "America/New_York")!) -> DateFormatter! {
        if standard == nil || timeZone != standard?.timeZone {
            let formatter = DateFormatter.init()
            formatter.dateFormat = "yyyy-M-d-k-mm-ss"
            formatter.timeZone = timeZone
            standard = formatter
        }
        
        return standard!
    }
    
    /// Formatter for displayed dates
    ///
    /// - Parameter timeZone: The time zone for the formatter
    /// - Returns: The title date formatter
    public static func titleFormatter(timeZone: TimeZone? = TimeZone(identifier: "America/New_York")!) -> DateFormatter! {
        if title == nil || title?.timeZone != timeZone {
            let formatter = DateFormatter.init()
            formatter.dateStyle = DateFormatter.Style.short
            formatter.timeStyle = DateFormatter.Style.short
            formatter.timeZone = timeZone
            title = formatter
        }
        
        return title!
    }
    
    /// Formatter for JSONFeed to create RFC-339 date strings
    ///
    /// - Parameter timeZone: The time zone for the formatter
    /// - Returns: The RFFC-3339 formatter
    public static func rfc3339Formatter(timeZone: TimeZone? = TimeZone(identifier: "America/New_York")!) -> DateFormatter! {
        if rfc3 == nil || timeZone != rfc3?.timeZone {
            let formatter = DateFormatter.init()
            formatter.timeZone = timeZone
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            rfc3 = formatter
        }
        
        return rfc3!
    }
}
