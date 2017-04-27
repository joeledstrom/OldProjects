import spray.io.PipelineStage
import spray.io.PipelineContext
import spray.io.Pipelines
import spray.io._




object Testing {

	
	case class Become(stage: PipelineStage) extends Command

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
		}                                 //> dynamic: (initial: spray.io.PipelineStage)spray.io.PipelineStage{def apply(c
                                                  //| ontext: spray.io.PipelineContext,cpl: spray.io.Command => Unit,epl: spray.io
                                                  //| .Event => Unit): spray.io.Pipelines{val commandPipeline: spray.io.Command =>
                                                  //|  Unit; val eventPipeline: spray.io.Event => Unit}}

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
  }
  
  val pipeline =
  	new Stage("A") >>
  	new Stage("B") >>
  	dynamic {
  		new Stage("1") >>
  		new Stage("2")
  	} >>
  	new Stage("C") >>
  	new Stage("D")                            //> pipeline  : spray.io.PipelineStage = spray.io.PipelineStage$$anon$2@55ab965
                                                  //| 5
  
  val pipelines = pipeline(
      context = null,
      commandPL = {cmd => println("base command")},
      eventPL = {cmd => println("base event")}
  )                                               //> pipelines  : spray.io.Pipelines = spray.io.Pipelines$$anon$1@34a1a081
  
  pipelines.commandPipeline(IOBridge.Connect("kaka" , 54))
                                                  //> A: command passing
                                                  //| B: command passing
                                                  //| 1: command passing
                                                  //| 2: command passing
                                                  //| C: command passing
                                                  //| D: command passing
                                                  //| base command
  
  pipelines.eventPipeline(IOBridge.Connected(null, null))
                                                  //> D: event passing
                                                  //| C: event passing
                                                  //| 2: event passing
                                                  //| 1: event passing
                                                  //| B: event passing
                                                  //| A: event passing
                                                  //| base event
    

	pipelines.commandPipeline(Become(new Stage("3") >> new Stage("4")))
                                                  //> A: command passing
                                                  //| B: command passing
                                                  //| 1: command passing
                                                  //| 2: command passing
	
	//pipelines.commandPipeline(IOBridge.Connect("kaka", 0))
	
	pipelines.commandPipeline(IOBridge.Connect("kaka", 54))
                                                  //> A: command passing
                                                  //| B: command passing
                                                  //| 3: command passing
                                                  //| 4: command passing
                                                  //| C: command passing
                                                  //| D: command passing
                                                  //| base command
  
  pipelines.eventPipeline(IOBridge.Connected(null, null))
                                                  //> D: event passing
                                                  //| C: event passing
                                                  //| 4: event passing
                                                  //| 3: event passing
                                                  //| B: event passing
                                                  //| A: event passing
                                                  //| base event
                                                  
                                                  
                                                  
                
    type Pipe = Int => Unit
                                                  
    trait PipeBuilder {
    	def apply(tail: Pipe): Pipe
    }
                                                  
    class B(name: String) extends PipeBuilder {
    	def apply(tail: Pipe) = { x =>
    		println(name + ": "+ x)
    		tail(x)
    	}
    }
                 
    val kaka = new B("kaka")                      //> kaka  : Testing.B = Testing$$anonfun$main$1$B$1@285855bd
    val apa = new B("apa")                        //> apa  : Testing.B = Testing$$anonfun$main$1$B$1@3f64fffc
    
    
    
    
    val a = kaka(x => println("end" + x))         //> a  : Int => Unit = <function1>
    val b = apa(a)                                //> b  : Int => Unit = <function1>
    
    b(5)                                          //> apa: 5
                                                  //| kaka: 5
                                                  //| end5
                                                  
}