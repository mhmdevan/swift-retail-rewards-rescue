import Foundation
import RxSwift

protocol SchedulerProviding {
    var main: ImmediateSchedulerType { get }
    var background: ImmediateSchedulerType { get }
}

struct DefaultSchedulerProvider: SchedulerProviding {
    let main: ImmediateSchedulerType
    let background: ImmediateSchedulerType

    init(
        main: ImmediateSchedulerType = MainScheduler.instance,
        background: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    ) {
        self.main = main
        self.background = background
    }
}

struct ImmediateSchedulerProvider: SchedulerProviding {
    let main: ImmediateSchedulerType = CurrentThreadScheduler.instance
    let background: ImmediateSchedulerType = CurrentThreadScheduler.instance
}
