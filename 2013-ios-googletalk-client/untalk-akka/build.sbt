import com.typesafe.sbt.SbtStartScript

seq(SbtStartScript.startScriptForClassesSettings: _*)


name := "untalk"

version := "1.0"

scalaVersion := "2.10.0"

resolvers += "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/"

resolvers += "spray repo nightly" at "http://nightlies.spray.io/"

libraryDependencies += "com.typesafe.akka" %% "akka-actor" % "2.1.0"

libraryDependencies += "io.spray" % "spray-io" % "1.1-20130207"

libraryDependencies += "io.spray" % "spray-can" % "1.1-20130207"

libraryDependencies += "com.rabbitmq" % "amqp-client" % "2.8.1"

libraryDependencies += "org.mongodb" %% "casbah" % "2.5.0"