import BackgroundTasks

enum BackgroundRefreshService {
    static let taskIdentifier = "com.natgeodaily.refresh"

    static func registerHandler() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handle(refreshTask)
        }
    }

    static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Earliest fire: 1 hour from now; OS decides exact timing.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        scheduleRefresh()

        let fetchTask = Task {
            do {
                let entry = try await NatGeoFeedService.shared.fetchLatestPhoto()
                await CacheService.shared.save(entry)
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = { fetchTask.cancel() }
    }
}
