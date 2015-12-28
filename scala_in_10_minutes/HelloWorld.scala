object HelloWorld {
    def main(args: Array[String]) {
        val name = if (args.size > 0) args(0) else "Scala"
        println("Hello World! " + name)
    }
}
