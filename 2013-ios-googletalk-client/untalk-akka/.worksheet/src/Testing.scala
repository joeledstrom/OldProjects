import spray.io.PipelineStage
import spray.io.PipelineContext
import spray.io.Pipelines
import spray.io._




object Testing {

	
	case class Become(stage: PipelineStage) extends Command;import org.scalaide.worksheet.runtime.library.WorksheetSupport._; def main(args: Array[String])=$execute{;$skip(849); 

	def dynamic(initial: PipelineStage) =
		new PipelineStage {
			def apply(context: PipelineContext, cpl: CPL, epl: EPL) = {
			
				var pipelines: Pipelines = null

				def attachBecomeHandler(stage: PipelineStage): Pipelines = stage(
					context,
      		commandPL = {
      			case Become(replaceStage) =>
      				pipelines = attachBecomeHandler(replaceStage)
			 			case c =>
			 				cpl(c)
			 		},
      		eventPL = epl
      	)
			
				pipelines = attachBecomeHandler(initial)
				
				// Note: really need to close on pipelines
	  		Pipelines(
	  			commandPL = pipelines.commandPipeline(_),
	  			eventPL = pipelines.eventPipeline(_)
	  		)
  		}
		}

  class Stage(val name: String) extends PipelineStage {
  	def apply(context: PipelineContext, tailCommands: CPL, tailEvents: EPL) =
  		Pipelines(
  			{
  				//case IOBridge.Connect(a,b,c) if (a.getPort() == 0 && name == "C") =>
  					//tailCommands(Become(new Stage("3") >> new Stage("4")))
  				case cmd =>
  				println(name + ": command passing")
  				tailCommands(cmd)
  			},
  			{ ev =>
  				println(name + ": event passing")
  				tailEvents(ev)
  			}
  		)
  };System.out.println("""dynamic: (initial: spray.io.PipelineStage)spray.io.PipelineStage{def apply(context: spray.io.PipelineContext,cpl: spray.io.Command => Unit,epl: spray.io.Event => Unit): spray.io.Pipelines{val commandPipeline: spray.io.Command => Unit; val eventPipeline: spray.io.Event => Unit}}""");$skip(643); 
  
  val pipeline =
  	new Stage("A") >>
  	new Stage("B") >>
  	dynamic {
  		new Stage("1") >>
  		new Stage("2")
  	} >>
  	new Stage("C") >>
  	new Stage("D");System.out.println("""pipeline  : spray.io.PipelineStage = """ + $show(pipeline ));$skip(156); 
  
  val pipelines = pipeline(
      context = null,
      commandPL = {cmd => println("base command")},
      eventPL = {cmd => println("base event")}
  );System.out.println("""pipelines  : spray.io.Pipelines = """ + $show(pipelines ));$skip(62); 
  
  pipelines.commandPipeline(IOBridge.Connect("kaka" , 54));$skip(61); 
  
  pipelines.eventPipeline(IOBridge.Connected(null, null));$skip(75); 
    

	pipelines.commandPipeline(Become(new Stage("3") >> new Stage("4")));$skip(119); 
	
	//pipelines.commandPipeline(IOBridge.Connect("kaka", 0))
	
	pipelines.commandPipeline(IOBridge.Connect("kaka", 54));$skip(61); 
  
  pipelines.eventPipeline(IOBridge.Connected(null, null))
                                                  
                                                  
                                                  
                
    type Pipe = Int => Unit
                                                  
    trait PipeBuilder {
    	def apply(tail: Pipe): Pipe
    }
                                                  
    class B(name: String) extends PipeBuilder {
    	def apply(tail: Pipe) = { x =>
    		println(name + ": "+ x)
    		tail(x)
    	}
    };$skip(551); 
                 
    val kaka = new B("kaka");System.out.println("""kaka  : Testing.B = """ + $show(kaka ));$skip(27); 
    val apa = new B("apa");System.out.println("""apa  : Testing.B = """ + $show(apa ));$skip(62); 
    
    
    
    
    val a = kaka(x => println("end" + x));System.out.println("""a  : Int => Unit = """ + $show(a ));$skip(19); 
    val b = apa(a);System.out.println("""b  : Int => Unit = """ + $show(b ));$skip(14); 
    
    b(5)}
                                                  
}
