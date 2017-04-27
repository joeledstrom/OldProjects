import org.jboss.netty.channel.socket.nio.NioClientSocketChannelFactory
import java.util.concurrent.Executors
import org.jboss.netty.channel.ChannelPipelineFactory
import org.jboss.netty.channel.Channels
import org.jboss.netty.channel.ChannelHandler
import org.jboss.netty.channel.SimpleChannelHandler
import org.jboss.netty.handler.codec.string.StringDecoder
import org.jboss.netty.handler.codec.string.StringEncoder
import org.jboss.netty.handler.codec.frame.DelimiterBasedFrameDecoder
import org.jboss.netty.channel.ChannelHandlerContext
import org.jboss.netty.channel.ChannelEvent
import org.jboss.netty.handler.codec.frame.Delimiters
import org.jboss.netty.bootstrap.ClientBootstrap
import org.jboss.netty.channel.MessageEvent
import java.net.InetSocketAddress
import org.jboss.netty.channel.ChannelStateEvent
import play.Logger
import org.jboss.netty.channel.ChannelState
import java.util.concurrent.atomic.AtomicInteger

class NotificationService {
	
  implicit def funcToRunnable(f: () => Unit) = new Runnable() {
    override def run() { f() }
  }
  
  
	val channelFactory = new NioClientSocketChannelFactory(Executors.newCachedThreadPool, Executors.newCachedThreadPool)
	
	def start() {
	  // pull users from database
	  // setup XMPP connections
	  // occasionally poll IMAP ???
	  // notify over aPNS
	  
	  var x = new AtomicInteger
	  
	  x.set(0)
	  
	  var msgs = new AtomicInteger
	  
	  msgs.set(0)
	  
	  val pipelineFactory = new ChannelPipelineFactory {
	    override def getPipeline() = {
	      Channels.pipeline(
	      new DelimiterBasedFrameDecoder(65000, Delimiters.lineDelimiter(): _*),
	      new StringDecoder(),
	      new StringEncoder,
	      new SimpleChannelHandler {
	        override def handleUpstream(ctx: ChannelHandlerContext, event: ChannelEvent) {
	          //println("Upstream: event: " + event)
	          event match {
	            case e: ChannelStateEvent =>  {
	              //println("Upstream: Channel state changed: " + e)
	              
	              if (e.getState == ChannelState.CONNECTED && e.getValue() != null) {
	                
	                 if (x.incrementAndGet % 1000 == 0) ctx.getChannel().write("hej " + x.get() + ": " + msgs.get() + "\n")
	                 //println("KAKA")
	                
	              }
	            }
	            case e: MessageEvent => {
	              //println("KAKA2")
	              val msg =  e.getMessage().asInstanceOf[String];
	              //println(msg)
	              //ctx.getChannel().write("Did you say '" + msg + "'?\n");
	              msgs.incrementAndGet()
	            }
	            case _ =>
	              
	          }
	          super.handleUpstream(ctx, event)
	        }
	        
	        override def handleDownstream(ctx: ChannelHandlerContext, e: ChannelEvent) {
	          //println("Downstream: event: " + e)
	        	e match {
	        	  case ev: ChannelStateEvent =>  {
	        	    //println("Downstream: Channel state changed: " + e)
	        	    ev.getState match {
	        	      case ChannelState.CONNECTED => //kaak
	        	      case _ =>
	        	    }
	        	    
	        	  }
	        	  case _ =>
	        	}

	        	super.handleDownstream(ctx, e)
	        }
	      })
	    }
	  }
	  
	  def createBootstrap() {
	    val bootstrap = new ClientBootstrap(channelFactory)
	    bootstrap.setPipelineFactory(pipelineFactory)
	    bootstrap.connect(new InetSocketAddress("81.235.209.136", 8888))
	  }
	  
	  /*
	  def f {
	     for (i <- Range(0,1000)) {
	    	   createBootstrap()
	       }
	       Thread sleep 20000
	       exec.submit(f _)
	  }
	  
	  exec.submit(f _)
	   */ 
	      
	       
	       
	       
	    	
	   
	 
	 
	  
	}
	val exec = Executors.newSingleThreadExecutor()
	
}