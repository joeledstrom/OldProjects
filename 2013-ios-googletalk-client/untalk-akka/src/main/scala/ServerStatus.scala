import akka.actor.Actor
import akka.actor.ActorLogging
import akka.actor.Props
import scala.util.Properties
import scala.concurrent.duration._
import akka.actor.ActorRef
import java.util.Date
import java.util.UUID


object ServerStatus {
  private case object Tick
  private val TickFrequency = 1.minute
  private val ServerTimeout = 2.minutes + 15.seconds
  private val Uri = Properties.envOrElse("CLOUDAMQP_URL", 
      "amqp://guest:guest@localhost")
  
  case class Updated(serversUp: Set[UUID])
  
  private implicit class RichDuration(d: Duration) {
    def passedSince(since: Long) = {
      val time = System.currentTimeMillis()
      time > since + d.toMillis
    }
  } 
}

class ServerStatus(selfUuid: UUID, subscriber: ActorRef) extends Actor with ActorLogging {
  import ServerStatus._
  
  var rabbit: ActorRef = _
  
  var serverCache: Map[UUID, Long] = Map.empty
  
  var serverStarted: Long = _
  
  override def preStart {
    rabbit = context.actorOf(Props(new SimpleRabbitMQ(Uri, "untalk66b945da8c5f", self)), "rabbitMQ")
    serverStarted = System.currentTimeMillis()
    
    import context.dispatcher
    context.system.scheduler.schedule(0.second, 1.minute, self, Tick)
    
  }
  
  
  //var firstTick: Boolean = _
  
  def receive = {
    case Tick =>
      log.debug("Tick")
      rabbit ! SimpleRabbitMQ.Message(selfUuid.toString)
    
      notifyChanges()
      
    /*case SimpleRabbitMQ.Message(msg) if msg == "PING" =>
      log.debug("Received PING, triggering Tick")
      self ! Tick*/
    case SimpleRabbitMQ.Message(uuid) =>
      serverCache += (UUID.fromString(uuid) -> System.currentTimeMillis())
      notifyChanges()
  }
  
 
  
  def removeOldServers() {
    serverCache = serverCache filter {
      case (_,t) => !(ServerTimeout passedSince t)
    }
  }
  
  
  var lastServers: Set[UUID] = Set.empty

  def notifyChanges() {
    removeOldServers()
    
    val servers = serverCache map {case (s,_) => s} toSet
    
    
    
    if (lastServers != servers && 
        (ServerTimeout passedSince serverStarted) ) {
      
      subscriber ! ServerStatus.Updated(servers)
      
      lastServers = servers
    }
    
  }
}