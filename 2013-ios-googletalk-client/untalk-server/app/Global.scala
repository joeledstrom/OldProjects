import play.api._
import java.util.Date





object Global extends GlobalSettings {
  implicit def funcToRunnable(f: () => Unit) = new Runnable() {
    override def run() { f() }
  }
    
    
  def makeThread(f: => Unit) = { 
    val t = new Thread(f _)
    t.start
    t
  }
  
  /*
  username: String,
    talkRefreshToken: String,
    talkAccessToken: String,
    expiresAt: Date,
    pnsDeviceToken: String,
    xmppConnected: Boolean*/

  
  val notificationService = new NotificationService
  
  override def onStart(app: Application) {
    Logger.info("kaka started")
    
    
    for (i <- Range(0,100)) {
    	val user = User(
    	    username = "joe@gmail.com"+i,
    	    talkRefreshToken =  "refreshToken",
    	    talkAccessToken = "accessToken", 
    	    expiresAt = new Date(),
    	    pnsDeviceToken = "pnsToken", 
    	    xmppConnected = i % 2 == 0)
    	
    	val user2 = user.copy(xmppConnected = true)
    	
    	//Database.insert(user)
  	}
    
    notificationService.start()
    
    val payload = javapns.notification.PushNotificationPayload.alert("kaka")
    payload.addBadge(2)
    println(payload)
  }  
  
  override def onStop(app: Application) {
    Logger.info("kaka shutdown")
    
  }  
    
}