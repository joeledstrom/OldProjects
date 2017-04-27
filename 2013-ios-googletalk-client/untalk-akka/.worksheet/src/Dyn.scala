import spray.io.PipelineStage
import spray.io.PipelineContext
import spray.io.Pipelines
import spray.io._


object Dyn {

	case class Become(stage: PipelineStage) extends Command;import org.scalaide.worksheet.runtime.library.WorksheetSupport._; def main(args: Array[String])=$execute{;$skip(697); 

	def dynamic(initialStage: PipelineStage) = {
		
		
		new PipelineStage {
			def apply(context: PipelineContext, tailCommands: CPL, tailEvents: EPL) = {
			
				def buildPipelines(stage: PipelineStage) = stage(context,
      		commandPL = {cmd => println("base command")},
      		eventPL = tailEvents)
			
			
			
	  		Pipelines(
	  			commandPL = {
	  				case Become(newStage) =>
	  				
	  				case cmd =>
	  				tailCommands(cmd)
	  			},
	  			eventPL = { ev =>
	  				tailEvents(ev)
	  			}
	  		)
  		}
		}
	};System.out.println("""dynamic: (initialStage: spray.io.PipelineStage)spray.io.PipelineStage{def apply(context: spray.io.PipelineContext,tailCommands: spray.io.Command => Unit,tailEvents: spray.io.Event => Unit): spray.io.Pipelines{val commandPipeline: spray.io.Command => Unit; val eventPipeline: spray.io.Event => Unit}}""")}
}


object Testing {
  class Stage(val name: String) extends PipelineStage {
  	def apply(context: PipelineContext, tailCommands: CPL, tailEvents: EPL) =
  		Pipelines(
  			{ cmd =>
  				println(name + ": command passing")
  				tailCommands(cmd)
  			},
  			{ ev =>
  				println(name + ": event passing")
  				tailEvents(ev)
  			}
  		)
  }
  
  val pipeline =
  	new Stage("A") >>
  	new Stage("B") >>
  	new Stage("C") >>
  	new Stage("D") >>
  	new Stage("E") >>
  	new Stage("F")
  
  val pipelines = pipeline(
      context = null,
      commandPL = {cmd => println("base command")},
      eventPL = {cmd => println("base event")}
  )
  
  pipelines.commandPipeline(IOBridge.Connect("kaka", 54))
  
  pipelines.eventPipeline(IOBridge.Connected(null, null))
}
