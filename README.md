<h1>EnalogSwift</h1>
Enalog for Swift is the Unofficial Swift Package made by <a href="https://twitter.com/mistermeenr">Joe Barbour</a> in collaboration with <a href="https://enalog.app/">Enalog & Enteka Software</a>.

<h3>Getting Started</h3>
<p>You can add this package to your project using Swift Package Manager. Enter the following url when adding it to your project package dependencies:</p>

<pre>https://github.com/thebarbican19/EnalogSwift</pre>
<br/><br/>
<h3>Introduction</h3>
<p>EnalogSwift requires an Enalog Account and an <strong>API Key</strong> which can all be created for free <a href="https://dash.enalog.app/organisation">here</a>.</p>
<p>Once you have obtained an <strong>API Key</strong> and created a project in the Enalog Dashboard, you then you specify these in the <code>info.plist</code> in your Swift application.</p>
<p>To paste this directly in to the <code>info.plist</code> right click on the <code>info.plist</code> file in Xcode and choose <strong>Open As > Source Code</strong></p>

```
<key>EN_PROJECT_NAME</key>
<string>SprintDock</string>
<key>EN_API_KEY</key>
<string>$(SD_ENALOG_KEY)</string>
```
	
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
<li><strong>Event ID</strong> (String)</li>
<li><strong>Description</strong> (String)</li>
<li><strong>Metadata</strong> (AnyObject)</li>
<li><strong>Tags</strong> (Array<String>)</li>

  <br/><br/>
<h3>Logging & Debugging</h3>
Logging & Debugging are available in EnalogSwift. This can be toggled on and off at any point by calling <code>EnalogManager.main.debug(true)</code><p></p>By default, this will output all logs in the Xcode console.</p>
<p></p>For additional granularity, you can pass <strong>.fatal</strong> <code>EnalogManager.main.debug(true, logType:.fatal)</code>. This will call a <strong>FatalError</strong> exception whenever an error occurs.</p><p></p><strong>This should not be used in Production</strong></p>
<br/><br/>


