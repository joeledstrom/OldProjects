import akka.actor.Actor
import java.net.NetworkInterface
import scala.collection.JavaConversions._
import java.net.Inet4Address
import spray.io.IOExtension
import akka.actor.ActorLogging
import spray.io.IOBridge.Connect
import java.net.InetSocketAddress
import spray.io.IOBridge.Connected
import spray.io.IOBridge.Register
import spray.io.IOBridge.Send
import java.nio.ByteBuffer
import java.nio.charset.Charset
import spray.io.ConnectionActors
import spray.io.EmptyPipelineStage
import akka.actor.ActorRef
import akka.actor.Props
import spray.io.PipelineStage
import spray.io.PipelineContext
import spray.io.Pipelines
import spray.io.Command
import spray.io.Event
import spray.io.Connection
import spray.io.SslTlsSupport
import java.util.UUID







/*
class TestStage extends PipelineStage {
  override def build(context: PipelineContext, tailCommands: CPL, tailEvents: EPL) = {
    
    Pipelines(
       commandPL = { cmd: Command => 
         
         println("cmd pipe: kaka")
         
         
         tailCommands(cmd)
       },
       eventPL = { ev: Event =>
         println("evt pipe: " + ev.toString + ":::"+context.connection.tag)
         tailEvents(ev)
       } 
    )
    
    
  }
} 
*/

class ConnectionTag(
    val jid: String, 
    val authToken: String, 
    var ssl: Boolean = false, 
    var state: Int = 0) 
    extends SslTlsSupport.Enabling {
  
  override def encrypt(context: PipelineContext) = ssl
  
  override def toString = "kaka"

}


case class XMPPConnect(jid: String, authToken: String)
/*
class XMPPActors(val ioBridge: ActorRef) extends IOClient(ioBridge) with ConnectionActors {
  
  override def pipeline = new TestStage //>> SslTlsSupport()
 
  override def connectionTag(connection: Connection, tag: Any) = {
    val XMPPConnect(jid, token) = tag.asInstanceOf[XMPPConnect]
    new ConnectionTag(jid, token)
  }
}

class XMPPClient extends Actor with ActorLogging {
  val ioBridge = IOExtension(context.system).ioBridge()
  val xa = context.actorOf(Props(new XMPPActors(ioBridge)))
  
  
  
  def receive = {
    case c @ XMPPConnect(jid, authToken) =>
      xa ! Connect("talk.google.com", 5222, c)
      
    case IOClient.Connected(connection) => 
      
      connection.handler ! Start
      
      //connection.handler ! IOClient.Send(ByteBuffer.wrap("GET /\r\n".getBytes(Charset.forName("UTF-8"))))
      
      log.info(connection.tag.asInstanceOf[ConnectionTag].jid)  
  }
}

*/


case object Start
object Notify {
  case class AttemptClaimUsers(serversUp: Set[UUID])
}
class Notify(uuid: UUID, db: ActorRef) extends Actor with ActorLogging {

  import Notify._
  

  
  
  def receive = {

    case AttemptClaimUsers(serversUp) => 
    
    case Start => 
      log.info("Started")
      val ifs = getInterfaces() map (_.getHostAddress)
      log.info("Interfaces up: (" + ifs.mkString(", ") +")")
      
      val localAddr = new InetSocketAddress(getInterfaces().next(), 0)
  
      //xa ! Connect(new InetSocketAddress("192.168.0.2", 80), Some(localAddr))
      
    /*  
    case IOClient.Connected(connection) => 
      
      connection.handler ! IOClient.Send(ByteBuffer.wrap("GET /\r\n".getBytes(Charset.forName("UTF-8"))))
      
      log.info(connection.tag.asInstanceOf[ConnectionTag].toString)*/
    
  }
  
  
  
  
  def getInterfaces() =
    for {
      i <- NetworkInterface.getNetworkInterfaces() if i.isUp()
      a @ (ipv4: Inet4Address) <- i.getInetAddresses()
      if !a.isLoopbackAddress()
    } yield a
}