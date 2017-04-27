import akka.actor._
import java.util.UUID
import java.util.Date
import scala.util.Properties
import com.mongodb.casbah.MongoURI
import com.mongodb.casbah.MongoCollection
import com.mongodb.casbah.MongoClient
import com.mongodb.casbah.MongoClientURI
import com.mongodb.casbah.commons.MongoDBObject
import com.mongodb.casbah.WriteConcern
import com.mongodb.DBObject


object Database {
  case class User(
    username: String,   // stores to _id
    accessToken: String,
    refreshToken: String,
    deviceToken: String,
    claimedBy: Option[UUID],    // TODO: needs index
    expiresAt: Date = new Date 
  )

  case class Put(u: User)
  case class PutIfCurrent(old: User, u: User)
  case class FindUnclaimed(serversUp: Set[UUID], limit: Int)
  case class Delete(u: User)
  
  sealed trait Response
  case class Found(users: Set[User]) extends Response
  case object PutSuccess extends Response
  case object PutFail extends Response
  
  private val Uri = Properties.envOrElse("MONGOHQ_URL", 
      "mongodb://localhost/untalk")
      
  private def toDbObj(u: User): DBObject = {
	  MongoDBObject(
	    "_id" -> u.username,
		"accessToken" -> u.accessToken,
		"refreshToken" -> u.refreshToken,
		"deviceToken" -> u.deviceToken,
		"claimedBy" -> (u.claimedBy match {  
		  case Some(uuid) => uuid.toString
		  case _ => "UNCLAIMED"
		}),
		"expiresAt" -> u.expiresAt)
  }
  
  private def validUUID(s: String): Option[UUID] =
    try
      Some(UUID.fromString(s))
    catch {
        case _: Exception =>
          None
    }
          
  private def parseUUID(s: String): Option[UUID] = s match {
    case "UNCLAIMED" => None
    case u if validUUID(u).isDefined => validUUID(u)
    case _ => { println("error: Garbage UUID found: " + s); None}  // TODO: fix
      	
  }
  
  private def fromDbObj(obj: DBObject) = {
    import com.mongodb.casbah.Implicits._
    for {
      u <- obj.getAs[String]("_id")
      a <- obj.getAs[String]("accessToken")
      r <- obj.getAs[String]("refreshToken")
      d <- obj.getAs[String]("deviceToken")
      c <- obj.getAs[String]("claimedBy")
      e <- obj.getAs[Date]("expiresAt")
    } yield User(u, a, r, d, parseUUID(c), e)
  }
}
class Database extends Actor with ActorLogging {
  import Database._
  
  
  var client: MongoClient = _
  
  var users: Option[MongoCollection] = None 
  
  override def postStop {
    if (client != null)
      client.close()
  }
  
  def connect() {
    if (users.isDefined)
      return
  
    val uri = MongoClientURI(Uri)
    client = MongoClient()
      
    val dbOpt = for (db <- uri.database) yield client.getDB(db)
  
    
    
    users = for (db <- dbOpt) yield {
      
	  for {
	    user <- uri.username
	    pass <- uri.password
	  } db.authenticate(user, new String(pass))
      
	  db("Users")
    }
      
  }
   
  def executeCommand(cmd: (MongoCollection => Unit)) {
    connect()
    cmd(users.get)
  }
  
  def receive = {
    case Put(u) => put(u)
    case PutIfCurrent(old: User, u: User) => putIfCurrent(old, u)
    case FindUnclaimed(uuids: Set[UUID], limit: Int) => findUnclaimed(uuids, limit)
    case Delete(u: User) => delete(u)  
  }
  
  def findUnclaimed(uuids: Set[UUID], limit: Int) = executeCommand { c =>
    import com.mongodb.casbah.query.Implicits._
    
    require(uuids != Set.empty)
    
    val q = "claimedBy" $nin (uuids map (_.toString))
    
    log.debug("Executing query: " + q)
    
    val results = c.find(q).limit(limit)
    var parsedResults = (for {
      dbObj <- results 
      r <- fromDbObj(dbObj)
    } yield r) toSet
    
    log.debug("Results: " + parsedResults)
    
    sender ! Found(parsedResults)  
  }
  
  def put(u: User) = executeCommand { c =>
    log.debug("Saving: " + u)
   
    val result = c.save(toDbObj(u))
    
    sender ! PutSuccess
    /*
    val e = result.getLastError()
    if (e == null) {
    	  sender ! PutSuccess
    } else {
      //log.debug("ERROR: " + e)
      sender ! PutFail
    }*/
    
    
  }
  
  def putIfCurrent(o: User, u:User) = executeCommand { c =>
     
    val old = toDbObj(o)
    val result = c.findAndModify(old, toDbObj(u))
    
    val success = for {
      r <- result
      dbObj <- fromDbObj(r)
    } yield dbObj == o
    
    success match {
      case Some(true) =>
      	log.debug("Updated from: " + o)
      	log.debug("To: " + u)
      	sender ! PutSuccess
      case _ =>
        log.debug("Failed update to: " + u)
        sender ! PutFail
    }     
  }
  
  def delete(u: User) {
    log.debug("Deleting: " + u)
    executeCommand (_.remove(toDbObj(u)))
  }
}