import akka.actor.Actor
import akka.actor.ActorRef
import akka.actor.ActorLogging
import spray.can.server.HttpServer
import akka.actor.Props
import spray.io.SingletonHandler
import spray.io.IOBridge.Bind
import spray.http._
import spray.http.HttpMethods._
import scala.concurrent.duration._
import akka.pattern.ask
import akka.util.Timeout
import akka.dispatch.Futures
import spray.io.ServerSSLEngineProvider

class WebService(port: Int, db: ActorRef, ns: ActorRef) extends Actor with ActorLogging {

  /*
  implicit val myEngineProvider = ServerSSLEngineProvider { engine =>
  	engine.setEnabledCipherSuites(Array("TLS_RSA_WITH_AES_256_CBC_SHA"))
  	engine.setEnabledProtocols(Array("SSLv3", "TLSv1"))
  	
  	engine
  }
  */
  
  
  
  val httpServer = context.actorOf(
      Props(new HttpServer(SingletonHandler(self))), "spray-can-httpserver")
  
  
  override def preStart {
    log.info("Starting on port:" + port)
    httpServer ! Bind("localhost", port)
  }
  
  def receive = {
    case HttpRequest(POST, "/register", headers, _, _) =>
      
      val newUser = parseHeaders(headers)
      handleRequest(newUser)
      
    
  }
  
  def parseHeaders(headers: List[HttpHeader]) = {
    val hMap = headers map { case HttpHeader(k, v) => (k -> v)} toMap
            
      val uO = hMap.get("username".toLowerCase)
      val aO = hMap.get("accessToken".toLowerCase)
      val rO = hMap.get("refreshToken".toLowerCase)
      val dO = hMap.get("deviceToken".toLowerCase)
           
      for {
        u <- uO
        a <- aO
        r <- rO
        d <- dO
      } yield Database.User(u, a, r, d, None)
  }
  
  def handleRequest(u: Option[Database.User]) {
    val s = sender
      
      u match {
        case Some(user) =>
          log.debug("OK, received new user: " + user)
          
          implicit val timeout = Timeout(5.seconds)
          import context.dispatcher
          
          val putRequest = db ? Database.Put(user)
          
          // complete successfully even when failed, but with the exception as value
          val alwaysCompleting = putRequest recover {
            case e => e
          } 
        
          for (response <- alwaysCompleting) response match {
            case Database.PutSuccess =>
              s ! HttpResponse(200)
            case _ =>
              s ! HttpResponse(500)
          }
                     
        case _ =>
          log.debug("Bad Request")
          s ! HttpResponse(400)
      }
  }
  
  
}