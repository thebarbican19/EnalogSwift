<h1>EnalogSwift</h1>

[![Swift Version](https://img.shields.io/badge/Swift-5.x-orange.svg)]()
[![MacOS Support](https://img.shields.io/badge/MacOS-10.14+-green)]()
[![iOS Support](https://img.shields.io/badge/iOS-11.0+-green)]()
[![tvOS Support](https://img.shields.io/badge/tvOS-11.0+-green)]()
[![watchOS Support](https://img.shields.io/badge/watchOS-4.0+-green)]()
[![visionOS Support](https://img.shields.io/badge/visionOS-1.0+-green)]()


Enalog for Swift is the Unofficial Swift Package made by <a href="https://twitter.com/mistermeenr">Joe Barbour</a> in collaboration with <a href="https://enalog.app/">Enalog & Enteka Software</a>.

<br/><br/>
<h3>Getting Started</h3>
<p>You can add this package to your project using Swift Package Manager. Enter the following url when adding it to your project package dependencies:</p>

<pre>https://github.com/thebarbican19/EnalogSwift</pre>
<br/><br/>
<h3>Introduction</h3>
<p>EnalogSwift requires an Enalog Account and an <strong>API Key</strong> which can all be created for free <a href="https://dash.enalog.app/organisation">here</a>.</p>
<p>Once you have obtained an <strong>API Key</strong> and created a project in the Enalog Dashboard, you must specify these in the <code>info.plist</code> in your Swift application.</p>
<p>To paste this directly into the <code>info.plist</code> right-click on the <code>info.plist</code> file in Xcode and choose <strong>Open As > Source Code</strong></p>

```
<key>EN_PROJECT_NAME</key>
<string>SprintDock</string>
<key>EN_API_KEY</key>
<string>$(SD_ENALOG_KEY)</string>
```

<br/>
Declare the Library <code>import EnalogClient</code>
	
<br/><br/>
<h3>User Metadata</h3>
<p><p>
<p>For tracking each event in Enalog by user attributes it's important to call the user function. Here you can pass an <strong>UserID</strong> (required), <strong>Email Address</strong> & <strong>Name</strong> Additionally, you can also pass Any object that conforms to the <code>Codable</code> protocol. </p>

```
struct UserObject:Codable {
    let id = "@MisterMeenr"
    let name = "Mojito Joe"
    let email = "joe@sprintdock.app"
    var plan:String
                                
}
                            
let user:UserObject = .init(plan: "PREMIUM")

EnalogManager.main.user(user.id, name: user.name, email: user.email, metadata: user)
```
  <br/><br/>
<h3>Tracking Events</h3>
Creating & Tracking events can be achieved by calling the <code>EnalogManager.main.ingest()</code> function. This function takes the following parameters...
<br/><br/>
<li><strong>Event ID</strong> (Enum)</li>
<li><strong>Description</strong> (String)</li>
<li><strong>Tags</strong> (Array<String>)</li>
<li><strong>Metadata</strong> (AnyObject)</li>
<li><strong>Channel</strong> (EnalogChannelObject)</li>

<br/><br/>
First, you must create an <strong>Enum</strong> with all your Event ID's. This can be named anything. 

```
enum EnalogEvents:String {
    case myNewEvent = "new.event"
    case fatalErrors = "fatal.error"
    case purchaseEvent = "purchase.event"

}
```

<p>Once you have added this, you can call...</p> <code>EnalogManager.main.ingest(EnalogEvents.myNewEvent, description:"This is a description")</code>
  <br/><br/>
<p>Additionally, you can add <strong>Tags</strong> by calling...</p> <code>EnalogManager.main.ingest(EnalogEvents.myNewEvent, description:"This is a description", tags:["My Tag 1", "My Tag 2"])</code>
 <br/><br/>
<p>And like when specifying <strong>User Metadata</strong>, you can specify additional Metadata with <strong>AnyObject</strong> the conforms to the codable protocol.</p>
<pre>
struct PurchaseEvent:Codable {
    let product:String
    let cost:Double
	
}

let product:PurchaseEvent = .init(product:"SprintDock License", cost:95.00)

EnalogManager.main.ingest(EnalogEvents.purchaseEvent, description:"A product was purchased", metadata:product)</pre>

<br/><br/>
<h3>Crash Logging</h3>
<strong>EnalogSwift can also notify you of crashes in your App.</strong> When enabled, additional metadata is sent which includes the reason.
<br><br>
To enable crash logging, you call the <code>crash</code>. This takes an <code>enum</code> just like the <code>ingest</code> function. <br><br>
<pre>
EnalogManager.main.crash(EnalogEvents.fatalError)
EnalogManager.main.crash(EnalogEvents.fatalError, channel: .init(.slack, id:"MY CHANNEL"))
</pre>

<br/><br/>
<h3>Throttling</h3>
<p>Throttling stops duplicate ingests and unnecessary requests to the server. By default, this is set to **10 requests per minute**.</p>
<p>This limit can be changed by passing an <code>Int</code> the <code>throttle</code> function</p> 
<code>EnalogManager.main.throttle(perMinute: 0)</code>
<br/><br/>
<strong>This limit is capped at 20 ingest requests per second.</strong>

<br/><br/>
<h3>Disabling</h3>
<p>You can **turn off all event tracking** if you are running in a debug environment or running tests manually.</p>
<code>EnalogManager.main.disable(true)</code>

<br/><br/>
<h3>Logging & Debugging</h3>
<p>Logging & Debugging are available in EnalogSwift. This can be toggled on and off at any point by calling</p> 
<code>EnalogManager.main.debug(true)</code><p></p>By default, this will output all logs in the Xcode console.</p>
<p></p>For additional granularity, you can pass <strong>.fatal</strong> <code>EnalogManager.main.debug(true, logType:.fatal)</code>. This will call a <strong>FatalError</strong> exception whenever an error occurs.</p><p></p><strong>This should not be used in Production.</strong></p>
<p>Debug is automatically enabled when running in Xcode.</p>
<br/><br/>

<h3>Version Support</h3>

EnalogSwift runs on **all** Apple device architectures, including  VisionOS! <br/>
 - MacOS **10.15+** (Silicon & Intel)<br/>
 - iOS **13.0+**<br/>
 - watchOS **6.0+**<br/>
 - tvOS **13.0+**<br/>
 - visionOS **1.0+**<br/>

<br/><br/>

<strong>Enalog</strong> also has official Libraries in <a href="https://enalog.app/docs/sdks/python/">Python</a> <a href="https://enalog.app/docs/sdks/node-js/">Node.js</a> & <a href="https://enalog.app/docs/sdks/go/">Go</a>. For more information, visit the <a href="https://enalog.app/docs/">official documentation</a>.


