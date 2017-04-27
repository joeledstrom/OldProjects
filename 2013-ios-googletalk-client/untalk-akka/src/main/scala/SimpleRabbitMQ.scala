import akka.actor.Actor
import com.rabbitmq.client.ConnectionFactory
import scala.concurrent.ops.spawn
import com.rabbitmq.client.QueueingConsumer
import com.rabbitmq.client.Channel
import com.rabbitmq.client.Connection
import akka.actor.ActorRef
import java.util.UUID
import java.nio.charset.Charset
import akka.actor.ActorLogging


object SimpleRabbitMQ {
  case class Message(msg: String)
}


class SimpleRabbitMQ(uri: String, 
    exchange: String, 
    subscriber: ActorRef) 
    extends Actor 
    with ActorLogging {
  
  import SimpleRabbitMQ._
 
  
  @volatile var abort = false 
  var conn: Connection = _
  var pubChannel: Channel = _
  var connected: Boolean = _
  
  def connect() {
    if (connected)
      return
      
    val factory = new ConnectionFactory()
    factory.setUri(uri)
    conn = factory.newConnection()
    pubChannel = conn.createChannel()
    pubChannel.exchangeDeclare(exchange, "fanout");    
        
    spawn {     
      var sc: Channel = null
      try {
        sc = conn.createChannel()
        sc.exchangeDeclare(exchange, "fanout");
        val queueName = sc.queueDeclare().getQueue();
        sc.queueBind(queueName, exchange, "");
        val consumer = new QueueingConsumer(sc)
        sc.basicConsume(queueName, true, consumer);
        while (!abort) { {
            val delivery = consumer.nextDelivery()
            val message = new String(delivery.getBody(), "UTF-8")
            self ! InternalMsg(message)
          }
        }
        
      } catch {
        case e: Exception => 
          self ! InternalError(e)
      } finally {
        log.debug("consumer thread died")
    	  	if (sc != null)
    	  	  sc.close()
    	  	
      }
    }
    log.info("Connected to: " + uri + " exchange: " + exchange)
    connected = true
  }
  
  override def postStop {
    abort = true
    if (pubChannel != null)
      pubChannel.close()
    if (conn != null)
      conn.close()
  }
  
  def receive = {
    case InternalError(e) => throw e
    case InternalMsg(m) => subscriber ! Message(m)
    case Message(m) => 
      connect()
      pubChannel.basicPublish(exchange, "", null, m.getBytes(Charset.forName("UTF-8")))
  }
  
  private case class InternalError(e: Exception)
  private case class InternalMsg(m: String)
}