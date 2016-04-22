import Foundation
import CoreGraphics
import XCPlayground

/*:
 ## DSCOVR the Earth
 
 *[Jacob Bandes-Storch](https://bandes-stor.ch/), Earth Day 2016*
 
 On Feb. 11, 2015, a SpaceX rocket [launched](https://www.youtube.com/watch?v=OvHJSIKP0Hg#t=15m48s) the [Deep Space Climate Observatory](https://en.wikipedia.org/wiki/Deep_Space_Climate_Observatory) satellite (DSCOVR) into orbit.
 
 ![DSCOVR launch clip](dscovr-launch.gif)
 
 One of the instruments aboard DSCOVR is the [Earth Polychromatic Imaging Camera](http://epic.gsfc.nasa.gov/) (EPIC), which captures images of Earth several times per day in wavelengths surrounding the visible spectrum. Since DSCOVR sits at the L₁ [Lagrange point](https://en.wikipedia.org/wiki/Lagrangian_point), it always sees the sunlit face of Earth.
 
 The [@dscovr_epic](https://twitter.com/dscovr_epic) Twitter bot, by Russ Garrett, posts some of these images on Twitter after some [extra post-processing](https://russ.garrett.co.uk/bots/dscovr_epic.html). I thought it would be neat to animate these, and I figured this would be a good excuse to play with the Twitter API and JSON parsing from Swift.
 
 ### Contents of this playground
 - Note: Open this playground’s Assistant Editor (or press ⌥⌘↩) to view the slideshow.
 
 - Note: The playground is written to work with both iOS & OS X APIs. Open the File Inspector (⌥⌘1) to choose a platform.
 
 The following types are defined in the Swift files in this playground’s “Sources” directory. Press ⌘1 to open up the Project Navigator, and expand the Sources folder to see the additional source files.
 
 - `SlideshowView`: a view class which uses Core Animation to display photos and captions.
 - `JSON` and the `JSONCreatable` protocol: one of *many, many* possible ways of handling JSON in Swift. Compare it with others, love it, hate it... it’s up to you!
 - `TwitterAPI`: a class which handles the nasty details of authentication and response parsing.
 - `Tweet`: a convenience layer above plain JSON which lets us read tweets.
 - `AsyncOperation` and `FetchImageOperation`: two [NSOperation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/) subclasses which help with executing and chaining asynchronous tasks.
 
 First, let’s set up a slideshow view to flip through a series of images and captions.
*/
let slideshowView = SlideshowView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
slideshowView.speed = 3

XCPlaygroundPage.currentPage.liveView = slideshowView
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
 Now, we’ll authenticate with Twitter and make a request to the [`user_timeline` API](https://dev.twitter.com/rest/reference/get/statuses/user_timeline) to retrieve the most recent tweets from @dscovr_epic.
 
 - Important: Visit <https://apps.twitter.com/> and create a test app. You’ll be given a **consumer key** and **consumer secret**. Paste them below.
 */
let twitter = try TwitterAPI(
    consumerKey: "<#Your consumer key here#>",
    consumerSecret: "<#Your consumer secret here#>")

try twitter.makeAPICall(
    .GET, "1.1/statuses/user_timeline.json",
    params: ["screen_name": "dscovr_epic", "count": "20"])
{ (tweets: [Tweet]?) in

    guard let tweets = tweets else {
        print("failed to fetch tweets")
        return
    }
    
//: Then we can select the tweets which contiain photos, and create a `FetchImageOperation` instance to fetch the photo for each one:
    let tweetsWithPhotos = tweets.filter { $0.photoURL != nil }
    
    let fetchImageOps: [FetchImageOperation] = tweetsWithPhotos.map {
        let op = FetchImageOperation(url: $0.photoURL!)
        NSOperationQueue.mainQueue().addOperation(op)
        return op
    }
/*:
 Once the FetchImageOperations have finished, we take the images which were successfully fetched, and combine those with tweet captions to make Slides.
 
 We’ll do this from a simple NSBlockOperation, which depends on all of the FetchImageOperations (so it’ll wait for them to finish).
 */
    let showSlideshow = NSBlockOperation {
        slideshowView.slides = zip(tweetsWithPhotos, fetchImageOps).flatMap { tweet, op in
            guard let photo = op.image else { return nil }
            return SlideshowView.Slide(caption: tweet.caption, image: photo)
        }
    }
    
    fetchImageOps.forEach { showSlideshow.addDependency($0) }
    
    NSOperationQueue.mainQueue().addOperation(showSlideshow)
}

/*:
 ## Protect the Planet
 
 *Don’t just sit there, do something!*
 
 Many organizations are working hard to protect the Earth. Donate or volunteer:
 - <http://www.earthday.org/take-action/>
 - <http://www.worldwildlife.org/how-to-help>
 - <http://appstore.com/appsforearth>
 
 
 ## Further Exploration
 
 - Experiment: NASA provides its own [DSCOVR API](http://epic.gsfc.nasa.gov/about.html) which has more advanced features, like searching for images which show particular areas of the Earth. Try fetching images from this API instead of Twitter.
 
 You can explore some of the code powering the @dscovr_epic bot: <https://github.com/russss/dscovr-epic>
 
 
 The Japan Meteorological Agency has a weather satellite called [Himawari 8](https://en.wikipedia.org/wiki/Himawari_8) which captures images of the Eart at even higher resolution than EPIC does. Its orbit keeps it stationary above Japan.
 
 - How-to about generating animations from Himawari 8 imagery: <https://gist.github.com/celoyd/b92d0de6fae1f18791ef>
 - Some scripts to do so: <https://github.com/m-ad/himawari-8>
 - A beautiful “installation” of one such animation: <https://glittering.blue/>
 */
