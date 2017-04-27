
import util.Properties
import spray.io
import akka.actor.ActorSystem
import spray.io.IOExtension
import java.net.NetworkInterface
import scala.collection.JavaConversions._
import java.net.Inet4Address
import akka.actor.Props


object Main {
  def main(args: Array[String]) {
    
    
    val system = ActorSystem()
    
    
    system.actorOf(Props[Server], name = "server")
    
    
    
    //system.actorOf(Props[XMPPClient], "xmppClient") ! 
    //XMPPConnect("joel.edstrom@gmail.com", "ya29.AHES6ZT40koo0eiVAEX7apbdSHwwTicFdJGI4jieunazy4TaBu72")
    
    //println("Starting on port:"+port)
    
    
    
    //println("Started.")
  }
  
  
    	

   
 
   

}

