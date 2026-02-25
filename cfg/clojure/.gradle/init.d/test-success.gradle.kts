import org.gradle.BuildAdapter
import org.gradle.BuildResult
import java.io.File

val requestedTasks = gradle.startParameter.taskNames.map { it.substringAfterLast(":") }
val fullTestSuiteRequested = requestedTasks.size == 1 && requestedTasks.single() == "test"

if (fullTestSuiteRequested) {
    val marker = File("/tmp/test-success")

    gradle.taskGraph.whenReady {
        if (marker.exists()) {
            marker.delete()
        }
    }

    gradle.addBuildListener(object : BuildAdapter() {
        override fun buildFinished(result: BuildResult) {
            if (result.failure == null) {
                marker.writeText("success\n")
            }
        }
    })
}
