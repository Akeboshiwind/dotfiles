// Adds printClasspath task to all Gradle projects for clojure-lsp integration
// clojure-lsp uses this to resolve dependencies for hover docs, completions, etc.
// Skips if project already defines the task (e.g. xtdb)

allprojects {
    afterEvaluate {
        if (tasks.findByName("printClasspath") == null) {
            tasks.register("printClasspath") {
                doLast {
                    val sourceSets = try {
                        project.extensions.getByType(SourceSetContainer::class.java)
                    } catch (e: Exception) {
                        null
                    }

                    val classpath = sourceSets?.let { ss ->
                        // Prefer dev (clojurephant convention), fall back to main
                        val sourceSet = try {
                            ss.getByName("dev")
                        } catch (e: Exception) {
                            try {
                                ss.getByName("main")
                            } catch (e: Exception) {
                                null
                            }
                        }
                        sourceSet?.runtimeClasspath?.asPath
                    } ?: ""

                    println(classpath)
                }
            }
        }
    }
}
