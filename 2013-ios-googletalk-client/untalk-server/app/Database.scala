





import java.util.Date
import scala.collection.concurrent.Map
import scala.collection.concurrent.TrieMap
import scala.collection.JavaConversions._




case class User (
    username: String,
    talkRefreshToken: String,
    talkAccessToken: String,
    expiresAt: Date,
    pnsDeviceToken: String,
    xmppConnected: Boolean
) 





object Database {
	private val users: Map[String, User] = TrieMap()
	
	def insert(u: User) {
	  users.put(u.username, u) match {
	    case None => println("inserted: " + u)
	    case Some(_) => println("replacedWith: " + u)
	  }
	}
	
	def getUnconnected = for ((_,u) <- users if !u.xmppConnected) yield u
	
	def clearExpired() =
	  for ((username, user) <- users if System.currentTimeMillis() > user.expiresAt.getTime) {
	    users.remove(username)
	    println("removed " + user)
	  }
	    
	  
	
	
}