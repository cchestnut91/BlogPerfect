#  BlogPerfect

`BlogPerfect` is a Server-Side `Swift` Blogging Platform. Orignally built for my personal site, you can check out my blog built with `BlogPerfect` in action at [iCalvin.org](https://icalvin.org/archive) for an example. It was originally developed to work with [Perfect Swift](perfect.org), but it should be able to be used with any `Swift` server. Posts are stored as `HTML` files at a provided directory, and the `BlogManager` class returns `HTML` content as `String`s, so there shouldn't be anything specific to Perfect, but it has not been tested on any other platforms.

## Goals

The goal of the project is to build a blogging platform that could support a `JSON` REST API, act as a [Micro.blog](https://micro.blog) resource, and could export a [JSON Feed](https://jsonfeed.org).

## Installation

`BlogPerfect` can be installed using the [Swift Package Manager](https://github.com/apple/swift-package-manager/).

## Using BlogPerfect

The `BlogManager` class handles dealing with `Post` instances and creating the  `Post` `HTML` representations such as `Post` pages, an archive or a preview, for a home screen representation of recent posts for instance. These instances are stored in a directory represented by the `postDirectory` property of the `BlogConfiguration` object used to configure the `BlogManager` instance. New `Post` instances can be created and saved to the same directory and the `BlogManager` will pick it up the new `Post`.

All `Post` instances in the `postDirectory` location must be read accessibly by `BlogPerfect`, and be  all serialized `Post` files must be named by the title and the publish date with the following format: `"\(postTitle)-YYYY-mm-dd-hh-MM-ss.json"`. If the `Post` has no title it can just be saved it with the formatted date.

### Filtering Posts

### Archives

An `HTML` string containing links and titles to a series of `Post` instances can be created using the `BlogManager` `archiveHTML(for posts:)` method. Each `Post` will be represented by a `<li />` within an `<ul />`, where the item contains an `<a />` link tag with a URL link to the `Post` `html` page and the title of the `Post`. The link will use the `publishedPostUrlDirectory` provided with the `BlogConfiguration`, which should be the public URL for your Blog Posts, formatted as `\(publishedPostUrlDirectory)/year/month/day/\(title).html`.

Each `HTML` entity will be associated with a class, documented as follows:

- `<ul />` -> `"blogPostArchive"`
- `<li />` -> `"blogPostArchiveItem"`
- `<a />` -> `"blogPostArchiveItemLink"`

### Recent Posts

If you want to present multiple `Post` instances inline you can use the `BlogManager` `containerHTML(for posts:)` method. That will produce an `HTML` string that wraps the `Post` content as well as an `<a />` tag that links to the `Post` `.html` page, with the title wrapped in an `<h3 />` tag. All of this will be contained within a single `<div />` element. Just like with the Archives these `HTML` entites are represented with the following classes:

- `<div />` -> `"recentPostsContainer"`
- `<h3 />` -> `"postHeader"`
- `<a />` -> `"postLink"`

### New Posts

New `Post` instances can also be saved by passing them to the `BlogManager`  `writeJson(post:` method which will save them in the appropriate format at the directory given in the `BlogConfiguration` instance used to initialize the `BlogManager`, assuming a `postDirectory` was provided. If not `writeJson(post:)` will throw an error.

Using the `Blogmanager` `writeHTML(post:)`  method to save the post as a `.html` file within a directory passed as the `webrootDirectory` property in the `BlogConfiguration`. The `BlogManager` will create a new directory with the path format `/year/month/day/title.html`. If the `webrootDirectory` is the same as the webroot of your server the posts should be accessible to web traffic, otherwise you will need to route to the files yourself.

### Blog Post Template

If you pass a `blogPostTemplate` `HTML` string along with the `BlogConfiguration` the `.html` file saved will follow that be that string with the `Post` properties in replacing certain `String` occurences. Those `String` values are as follows:

- `"POST_TITLE}"`
- `"{POST_PUBLISHED}"`
- `"{POST_SUMMARY}"`
- `"{POST_AUTHOR}"`
- `"{POST_URL}"`
- `"{POST_MODIFIED}"`
- `"{POST_EXTERNAL_URL}"`
- `"{POST_EXTERNAL_URL_TEXT}"`
- `"{POST_CONTENT}"`

Those properties are pretty much 1-to-1 with the properties of the `Post` class.

### JSON Feed

The `BlogManager` `generateJsonFeed(jsonFeedPath:)` method can be used to generate a `.json` file conforming to the [JSON Feed](https://jsonfeed.org), which will be saved to a directory specified at the `jsonFeedPath` passed to the method.

## Status

`BlogPerfect` is working and stable in it's current form, but there are a few issues. Right now the handling of the blog content may not be entirely reliable, there is some logic improvements to be made between handling `HTML` vs `text` based blog content.

Also there are some problems with the JSON Feed, where the generated file doesn't seem to actually be readable by JSON Feed readers.

## Road Map

- [ ] Fix problems with JSON Feed files
- [ ] Fix logic around HTML post content

