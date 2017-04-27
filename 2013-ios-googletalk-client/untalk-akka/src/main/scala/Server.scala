import akka.actor.Actor
import akka.actor.ActorLogging
import akka.actor.ActorSystem
import akka.actor.Props
import scala.util.Properties
import java.util.UUID
import java.util.Date

class Server extends Actor with ActorLogging {
  val uuid = UUID.randomUUID
  
  var ns = context.system.deadLetters
  override def preStart {
    
    log.info("Server started, uuid: " + uuid)
    
    val port = Properties.envOrElse("PORT", "8080").toInt
    
    val status = context.actorOf(Props(new ServerStatus(uuid, self)),"status")
    
    
    val db = context.actorOf(Props[Database], "db")
    
    val u = Database.User("b", "b", "c", "d", Some(uuid))
    db ! Database.Put(u)
    
    db ! Database.Put(Database.User("c", "b", "c", "d", None))
    db ! Database.Put(Database.User("d", "b", "c", "d", Some(UUID.fromString("298881aa-af0a-47d7-9d0f-a813c7595f95"))))
    
    //db ! Database.Delete(u)
    
    //db ! Database.PutIfCurrent(u.copy(refreshToken = "apa"), u.copy(refreshToken = "HAHA"))
    
    
    
    ns = context.actorOf(Props(new Notify(uuid, db)), "notify")
    val web = context.actorOf(Props(new WebService(port, db, ns)), "web")
  }
  
  def receive = {
    case ServerStatus.Updated(serversUp) => 
      log.info("Server status updated: " + serversUp)
      ns ! Notify.AttemptClaimUsers(serversUp)
      //val db = context.actorOf(Props[Database], "db2")
      //db ! Database.FindUnclaimed(serversUp, 100)
    case Database.Found(users) =>
  }
}